const assert = require("node:assert/strict");
const test = require("node:test");

const {
  HOMEPAGE_VOLUNTEERING_PROMISE,
  assertHomepageFitsScreen,
  assertHomepageStaffAccess,
  assertMembaHomepage,
  assertHomepageVolunteeringPromise,
  homepageUrl,
  visitHomepage
} = require("../features/support/homepage");

test("homepage URL points at the real root route", () => {
  assert.equal(homepageUrl("http://127.0.0.1:4444"), "http://127.0.0.1:4444/");
  assert.equal(homepageUrl("http://127.0.0.1:4444/"), "http://127.0.0.1:4444/");
});

test("homepage visit step drives the browser to the real homepage route", async () => {
  const visited = [];
  const world = {
    baseUrl: "http://127.0.0.1:4444",
    page: {
      async goto(url) {
        visited.push(url);
      }
    }
  };

  await visitHomepage(world);

  assert.deepEqual(visited, ["http://127.0.0.1:4444/"]);
});

test("homepage assertion step checks browser-visible homepage content", async () => {
  const expectations = [];
  const page = {
    getByRole(role, options) {
      return { role, options };
    }
  };
  const expect = (target) => ({
    async toHaveURL(expected) {
      expectations.push({ target, matcher: "toHaveURL", expected });
    },
    async toHaveTitle(expected) {
      expectations.push({ target, matcher: "toHaveTitle", expected });
    },
    async toBeVisible() {
      expectations.push({ target, matcher: "toBeVisible" });
    }
  });

  await assertMembaHomepage({ baseUrl: "http://127.0.0.1:4444", page }, { expect });

  assert.equal(expectations[0].matcher, "toHaveURL");
  assert.ok(expectations[0].expected.test("http://127.0.0.1:4444/"));
  assert.equal(expectations[0].expected.test("http://127.0.0.1:4444/clubs"), false);

  assert.equal(expectations[1].matcher, "toHaveTitle");
  assert.match("Memba", expectations[1].expected);

  assert.deepEqual(
    expectations
      .filter((expectation) => expectation.matcher === "toBeVisible")
      .map((expectation) => expectation.target),
    [
      { role: "heading", options: { name: HOMEPAGE_VOLUNTEERING_PROMISE } },
      { role: "link", options: { name: "Request access for your group" } },
      { role: "link", options: { name: "Sign in" } }
    ]
  );
});

test("homepage volunteering assertion checks the browser-visible hero promise", async () => {
  const expectations = [];
  const page = {
    getByRole(role, options) {
      return { role, options };
    }
  };
  const expect = (target) => ({
    async toBeVisible() {
      expectations.push({ target, matcher: "toBeVisible" });
    }
  });

  await assertHomepageVolunteeringPromise({ page }, { expect });

  assert.deepEqual(expectations, [
    {
      target: { role: "heading", options: { name: HOMEPAGE_VOLUNTEERING_PROMISE } },
      matcher: "toBeVisible"
    }
  ]);
});

test("homepage fit assertion checks horizontal overflow", async () => {
  const expectations = [];
  const page = {
    viewportSize() {
      return { width: 390, height: 844 };
    },
    async evaluate(callback) {
      const originalDocument = global.document;
      global.document = {
        body: { scrollWidth: 390 },
        documentElement: { clientWidth: 390, scrollWidth: 390 }
      };

      try {
        return callback();
      } finally {
        global.document = originalDocument;
      }
    }
  };
  const expect = (target) => ({
    async toBeLessThanOrEqual(expected) {
      expectations.push({ target, matcher: "toBeLessThanOrEqual", expected });
    }
  });

  await assertHomepageFitsScreen({ page }, { expect });

  assert.deepEqual(expectations, [
    { target: 390, matcher: "toBeLessThanOrEqual", expected: 390 }
  ]);
});

test("homepage staff access assertion checks the staff bar and console link", async () => {
  const expectations = [];
  const staffBar = {
    selector: "#homepage-staff-bar",
    getByText(text, options) {
      return { parent: this.selector, method: "getByText", text, options };
    }
  };
  const page = {
    locator(selector, options) {
      if (selector === "#homepage-staff-bar") {
        return staffBar;
      }

      return { selector, options };
    }
  };
  const expect = (target) => ({
    async toBeVisible() {
      expectations.push({ target, matcher: "toBeVisible" });
    },
    async toHaveAttribute(attribute, expected) {
      expectations.push({ target, matcher: "toHaveAttribute", attribute, expected });
    },
    async toHaveCount(expected) {
      expectations.push({ target, matcher: "toHaveCount", expected });
    }
  });

  await assertHomepageStaffAccess({ page }, { expect });

  assert.deepEqual(expectations, [
    { target: staffBar, matcher: "toBeVisible" },
    {
      target: {
        parent: "#homepage-staff-bar",
        method: "getByText",
        text: "Memba staff",
        options: { exact: true }
      },
      matcher: "toBeVisible"
    },
    {
      target: {
        selector: "a#staff-console-link",
        options: { hasText: "Open the staff console" }
      },
      matcher: "toBeVisible"
    },
    {
      target: {
        selector: "a#staff-console-link",
        options: { hasText: "Open the staff console" }
      },
      matcher: "toHaveAttribute",
      attribute: "href",
      expected: "/admin/clubs"
    },
    {
      target: { selector: "a#admin-home-link", options: undefined },
      matcher: "toHaveCount",
      expected: 0
    }
  ]);
});
