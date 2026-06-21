const assert = require("node:assert/strict");
const { expect: playwrightExpect } = require("@playwright/test");
const {
  appUrl,
  ensureState
} = require("./member_message");
const serverCommands = require("./server_commands");

const staffEmail = process.env.ACCEPTANCE_STAFF_EMAIL || "acceptance-staff@memba.io";
async function withStaffHarness(world, action) {
  await withReusableHarnessWorld(world, "staff", async (harnessWorld) => {
    if (!harnessWorld.signedInStaff) {
      await signInStaff(harnessWorld);
      harnessWorld.signedInStaff = true;
    }

    await action(harnessWorld);
  });
}

async function withMemberHarness(world, memberName, action) {
  await withReusableHarnessWorld(
    world,
    `member:${memberName}`,
    async (harnessWorld) => {
      guardPageAgainstAdminRoutes(harnessWorld, memberName);

      if (!harnessWorld.signedInMember) {
        await signInMember(harnessWorld, memberName);
        harnessWorld.signedInMember = true;
      }

      await memberBrowserAction(harnessWorld, `member action for ${memberName}`, () => action(harnessWorld));
    },
    { memberName }
  );
}

async function memberBrowserAction(world, description, action) {
  assertMemberPageIsNotAdmin(world, `${description} before action`);
  const result = await action();
  assertMemberPageIsNotAdmin(world, `${description} after action`);

  return result;
}

function assertMemberPageIsNotAdmin(world, description = "member browser helper") {
  const currentUrl = currentPageUrl(world.page);

  if (currentUrl && isAdminRoute(currentUrl, world.baseUrl)) {
    throw new Error(`Member browser helper reached staff/admin route during ${description}: ${currentUrl}`);
  }
}

async function withReusableHarnessWorld(world, key, action, options = {}) {
  ensureHarnessState(world);
  world.harnesses = world.harnesses || {};

  let harnessWorld = world.harnesses[key];

  if (!harnessWorld) {
    const context = await world.browser.newContext();
    const page = await context.newPage();
    harnessWorld = {
      ...world,
      context,
      page,
      harnessKey: key
    };
    world.harnesses[key] = harnessWorld;
  }

  syncHarnessState(world, harnessWorld, options);

  await action(harnessWorld);
  copyHarnessState(world, harnessWorld);
}

async function closeHarnesses(world) {
  const harnesses = Object.values((world && world.harnesses) || {});
  world.harnesses = {};

  await Promise.all(
    harnesses.map(async (harnessWorld) => {
      if (harnessWorld.context) {
        await harnessWorld.context.close();
      }
    })
  );
}

function syncHarnessState(world, harnessWorld, options = {}) {
  Object.assign(harnessWorld, {
    baseUrl: world.baseUrl,
    clubs: world.clubs,
    people: world.people,
    memberships: world.memberships,
    messages: world.messages,
    replies: world.replies,
    lastReply: world.lastReply,
    inboundEmails: world.inboundEmails,
    inboundEmailSenders: world.inboundEmailSenders,
    lastMessageSubject: world.lastMessageSubject,
    localDeliveryFactsBeforeSend: world.localDeliveryFactsBeforeSend,
    mailboxEmailsBeforeSend: world.mailboxEmailsBeforeSend,
    replyDeliveryFactsAfterSend: world.replyDeliveryFactsAfterSend,
    replyDeliveryFactsBeforeSend: world.replyDeliveryFactsBeforeSend,
    addressedMemberNames: world.addressedMemberNames,
    addressedMemberIds: world.addressedMemberIds,
    deliveries: world.deliveries,
    reportedDeliveryStatuses: world.reportedDeliveryStatuses,
    signInRequests: world.signInRequests,
    signInLinks: world.signInLinks
  });

  if (options.memberName) {
    harnessWorld.memberName = options.memberName;
  }
}

function ensureHarnessState(world) {
  ensureState(world);
  world.signInRequests = world.signInRequests || {};
  world.signInLinks = world.signInLinks || {};

  return world;
}

function copyHarnessState(world, harnessWorld) {
  for (const key of [
    "addressedMemberIds",
    "addressedMemberNames",
    "currentOperatorDelivery",
    "lastMessageSubject",
    "localDeliveryFactsBeforeSend",
    "mailboxEmailsBeforeSend",
    "messages",
    "replies",
    "lastReply",
    "replyDeliveryFactsAfterSend",
    "replyDeliveryFactsBeforeSend",
    "inboundEmails",
    "inboundEmailSenders"
  ]) {
    if (Object.prototype.hasOwnProperty.call(harnessWorld, key)) {
      world[key] = harnessWorld[key];
    }
  }
}

async function signInStaff(world) {
  serverCommands.ensurePerson({ personName: "Acceptance Staff", email: staffEmail });
  await signInDirectly(world, staffEmail, { returnTo: "/admin/clubs" });
  await playwrightExpect(world.page.locator("#admin-layout[data-surface='admin']")).toBeVisible();
}

async function completeStaffOnboardingIfNeeded(world) {
  await world.page.waitForLoadState("networkidle").catch(() => {});

  const nameField = world.page.getByLabel("Your name");

  if (!currentPageUrl(world.page).includes("/auth/onboard") && (await nameField.count()) === 0) {
    return;
  }

  await nameField.fill("Acceptance Staff");
  await world.page.getByRole("button", { name: "Continue to Memba staff" }).click();
  await playwrightExpect(world.page.locator("#admin-layout[data-surface='admin']")).toBeVisible();
}

async function signInMember(world, memberName) {
  const person = personFromWorld(world, memberName);
  const email = signInEmailForPerson(person);

  await signInDirectly(world, email);
  assertMemberPageIsNotAdmin(world, `signing in ${memberName} as a member`);
}

async function signInDirectly(world, email, options = {}) {
  const configuredPath = world.directSignInLinks && world.directSignInLinks[email];

  if (configuredPath) {
    await world.page.goto(browserAppUrl(world, configuredPath));
    return;
  }

  const response = await world.context.request.post(appUrl(world.baseUrl, "/dev/test-support/sign-in"), {
    data: { email },
    headers: { "content-type": "application/json" }
  });

  assert.equal(response.status(), 204, `Expected direct sign-in route to return 204, got ${response.status()}`);
  await world.page.goto(appUrl(world.baseUrl, options.returnTo || "/"));
}

function guardPageAgainstAdminRoutes(world, memberName) {
  const page = world.page;

  if (!page || typeof page.goto !== "function" || page.__membaMemberAdminGuard) {
    return page;
  }

  const originalGoto = page.goto.bind(page);

  page.goto = async (targetUrl, ...args) => {
    if (isAdminRoute(targetUrl, world.baseUrl)) {
      throw new Error(
        `Member browser helper attempted to navigate to staff/admin route for ${memberName}: ${targetUrl}`
      );
    }

    const result = await originalGoto(targetUrl, ...args);
    assertMemberPageIsNotAdmin(world, `navigation for ${memberName}`);

    return result;
  };

  page.__membaMemberAdminGuard = true;

  return page;
}

function isAdminRoute(url, baseUrl) {
  const pathname = pathForUrl(url, baseUrl);

  return pathname === "/admin" || pathname.startsWith("/admin/");
}

function pathForUrl(url, baseUrl) {
  try {
    return new URL(url, `${baseUrl || "http://memba.test"}/`).pathname;
  } catch (_error) {
    return "";
  }
}

function currentPageUrl(page) {
  if (!page) {
    return null;
  }

  if (typeof page.url === "function") {
    return page.url();
  }

  return page.currentUrl || null;
}

function personFromWorld(world, memberName) {
  ensureHarnessState(world);
  const person = world.people[memberName];

  assert.ok(person, `Expected ${memberName} to be known in the scenario`);
  assert.ok(
    signInEmailForPerson(person),
    `Expected ${memberName} to have a primary email address for member sign-in`
  );

  return person;
}

function signInEmailForPerson(person) {
  return person.email || person.primaryEmail;
}

function browserAppUrl(world, url) {
  const parsed = new URL(url, `${world.baseUrl}/`);
  const base = new URL(world.baseUrl);

  if (parsed.hostname === "localhost" || parsed.hostname === "127.0.0.1") {
    parsed.protocol = base.protocol;
    parsed.hostname = base.hostname;
    parsed.port = base.port;
  }

  return parsed.toString();
}

module.exports = {
  assertMemberPageIsNotAdmin,
  memberBrowserAction,
  closeHarnesses,
  signInMember,
  withMemberHarness,
  withStaffHarness
};
