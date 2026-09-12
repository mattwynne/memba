const assert = require("node:assert/strict");
const test = require("node:test");

const playwrightTestPath = require.resolve("@playwright/test");
const originalPlaywrightTestCache = require.cache[playwrightTestPath];

function fakeExpect(locator) {
  return {
    async toBeVisible(options = {}) {
      locator.page.actions.push(["expect-visible", locator.selector, options.timeout]);
    },
    async toContainText(expectedText, options = {}) {
      locator.page.actions.push(["expect-text", locator.selector, expectedText, options.timeout]);
    }
  };
}

require.cache[playwrightTestPath] = {
  id: playwrightTestPath,
  filename: playwrightTestPath,
  loaded: true,
  exports: { expect: fakeExpect }
};

const serverCommands = require("../features/support/server_commands");
const originalRunCommand = serverCommands.runCommand;
const { removeMemberAsStaff } = require("../features/support/membership_administration");

class FakeLocator {
  constructor(page, selector) {
    this.page = page;
    this.selector = selector;
  }

  async click() {
    assert.equal(
      this.page.liveViewWaited,
      true,
      `${this.selector} was clicked before the LiveView connection was ready`
    );
    this.page.actions.push(["click", this.selector]);
  }
}

class FakePage {
  constructor() {
    this.actions = [];
    this.liveViewWaited = false;
  }

  async goto(url) {
    this.actions.push(["goto", url]);
  }

  locator(selector) {
    return new FakeLocator(this, selector);
  }

  async waitForFunction() {
    this.actions.push(["waitForLiveViewConnected"]);
    this.liveViewWaited = true;
  }
}

test.after(() => {
  serverCommands.runCommand = originalRunCommand;

  if (originalPlaywrightTestCache) {
    require.cache[playwrightTestPath] = originalPlaywrightTestCache;
  } else {
    delete require.cache[playwrightTestPath];
  }
});

test("staff member removal waits for the admin LiveView before clicking Remove", async () => {
  serverCommands.runCommand = () => ({
    activeMember: true,
    clubId: "club-1",
    clubSlug: "west-coast-paddlers",
    email: "robin@example.com",
    membershipAdministrator: true,
    membershipId: "membership-1",
    personId: "person-1",
    personName: "Robin"
  });

  const page = new FakePage();
  const world = {
    baseUrl: "http://lvh.me:4000",
    clubs: {},
    memberships: {},
    page,
    people: {},
    projectionTimeoutMs: 1234
  };

  await removeMemberAsStaff(world, "Robin", "West Coast Paddlers");

  assert.deepEqual(page.actions, [
    ["goto", "http://lvh.me:4000/admin/clubs/club-1"],
    ["expect-visible", "#club-show", 1234],
    ["waitForLiveViewConnected"],
    ["click", "#remove-member-button-membership-1"]
  ]);
});
