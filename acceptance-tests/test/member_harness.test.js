const assert = require("node:assert/strict");
const test = require("node:test");

const {
  assertMemberPageIsNotAdmin,
  memberBrowserAction,
  withMemberHarness
} = require("../features/support/member_harness");
const { appUrl, kootenayClubName } = require("../features/support/member_message");

class FakeBrowser {
  constructor(mailbox = []) {
    this.contexts = [];
    this.mailbox = mailbox;
  }

  async newContext() {
    const context = new FakeContext(this.mailbox);
    this.contexts.push(context);

    return context;
  }
}

class FakeContext {
  constructor(mailbox) {
    this.closed = false;
    this.mailbox = mailbox;
    this.request = new FakeRequest(mailbox);
    this.page = new FakePage(mailbox, this.request);
  }

  async newPage() {
    return this.page;
  }

  async close() {
    this.closed = true;
  }
}

class FakeRequest {
  constructor(mailbox) {
    this.mailbox = mailbox;
  }

  async get(url) {
    return new FakeResponse(200, { data: [...this.mailbox], url });
  }
}

class FakeResponse {
  constructor(status, body) {
    this.responseStatus = status;
    this.body = body;
  }

  status() {
    return this.responseStatus;
  }

  async json() {
    return this.body;
  }

  async text() {
    return JSON.stringify(this.body);
  }
}

class FakePage {
  constructor(mailbox, request) {
    this.actions = [];
    this.currentUrl = "about:blank";
    this.fields = {};
    this.mailbox = mailbox;
    this.request = request;
  }

  async goto(url) {
    this.currentUrl = url;
    this.actions.push(["goto", url]);
  }

  url() {
    return this.currentUrl;
  }

  getByLabel(label) {
    return {
      fill: async (value) => {
        this.fields[label] = value;
        this.actions.push(["fill", label, value]);
      }
    };
  }

  getByRole(role, options) {
    return {
      click: async () => {
        this.actions.push(["click", role, options]);

        if (role === "button" && options.name === "Email me a sign-in link") {
          const email = this.fields["Email address"];
          const messageNumber = this.mailbox.length + 1;

          this.mailbox.push({
            headers: { "Message-ID": `<sign-in-${messageNumber}@example.test>` },
            subject: "Sign in to Memba",
            text_body: `Use http://127.0.0.1:4444/auth/magic/token-${messageNumber} to sign in`,
            to: [`${email}`]
          });
        }
      }
    };
  }
}

function worldWithBrowser() {
  return {
    baseUrl: "http://127.0.0.1:4444",
    browser: new FakeBrowser(),
    clubs: { [kootenayClubName]: { clubId: "club-1", name: kootenayClubName } },
    people: { Alice: { email: "alice@example.test", name: "Alice", personId: "person-alice" } }
  };
}

test("withMemberHarness signs in with the member email and shares scenario state", async () => {
  const world = worldWithBrowser();

  await withMemberHarness(world, "Alice", async (member) => {
    assert.equal(member.people, world.people);
    assert.equal(member.clubs, world.clubs);
    await member.page.goto(appUrl(member.baseUrl, "/?club_id=club-1"));
    member.lastMessageSubject = "Trip planning night";
  });

  const context = world.browser.contexts[0];

  assert.equal(context.closed, true);
  assert.equal(world.lastMessageSubject, "Trip planning night");
  assert.deepEqual(context.page.actions, [
    ["goto", "http://127.0.0.1:4444/auth"],
    ["fill", "Email address", "alice@example.test"],
    ["click", "button", { name: "Email me a sign-in link" }],
    ["goto", "http://127.0.0.1:4444/auth/magic/token-1"],
    ["goto", "http://127.0.0.1:4444/?club_id=club-1"]
  ]);
});

test("withMemberHarness fails fast when member helpers navigate to admin routes", async () => {
  const world = worldWithBrowser();

  await assert.rejects(
    () =>
      withMemberHarness(world, "Alice", async (member) => {
        await member.page.goto(appUrl(member.baseUrl, "/admin/messages/message-1"));
      }),
    /Member browser helper attempted to navigate to staff\/admin route for Alice:/
  );

  assert.equal(world.browser.contexts[0].closed, true);
  assert.equal(
    world.browser.contexts[0].page.actions.some(
      (action) => action[0] === "goto" && String(action[1]).includes("/admin/messages")
    ),
    false
  );
});

test("memberBrowserAction catches final admin-route browser state", async () => {
  const page = new FakePage([], new FakeRequest([]));
  const world = { baseUrl: "http://127.0.0.1:4444", page };

  await assert.rejects(
    () =>
      memberBrowserAction(world, "checking member receipts", async () => {
        page.currentUrl = "http://127.0.0.1:4444/admin/deliveries";
      }),
    /Member browser helper reached staff\/admin route during checking member receipts after action:/
  );
});

test("assertMemberPageIsNotAdmin allows member-facing URLs", () => {
  const page = new FakePage([], new FakeRequest([]));
  page.currentUrl = "http://127.0.0.1:4444/messages/message-1?club_id=club-1";

  assert.doesNotThrow(() =>
    assertMemberPageIsNotAdmin({ baseUrl: "http://127.0.0.1:4444", page }, "message detail")
  );
});
