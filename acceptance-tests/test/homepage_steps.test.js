const assert = require("node:assert/strict");
const test = require("node:test");

const {
  assertMembaHomepage,
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
      { role: "heading", options: { name: "Keep every member in the loop." } },
      { role: "link", options: { name: "Sign In" } }
    ]
  );
});
