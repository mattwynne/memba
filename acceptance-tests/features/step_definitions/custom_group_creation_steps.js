const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertOnlyGroupMember,
  createCustomGroupInBrowser,
  ensureClubAdmins,
  ensureClubWithSlug,
  ensureOrdinaryClubMembers,
  kootenayClubName
} = require("../support/custom_group_creation");

Given("Kootenay Mountaineering Club has club email slug {string}", function (slug) {
  ensureClubWithSlug(this, kootenayClubName, slug);
});

Given("Alice and Dan are its club admins", function () {
  ensureClubAdmins(this, ["Alice", "Dan"]);
});

Given("Bob and Eve are its ordinary active club members", function () {
  ensureOrdinaryClubMembers(this, ["Bob", "Eve"]);
});

When(
  /^(\w+) creates the custom group "([^"]+)" in (.+)$/,
  async function (actorName, groupName, clubName) {
    await createCustomGroupInBrowser(this, actorName, clubName, groupName);
  }
);

Then(/^(\w+) should be its only member$/, function (personName) {
  assertOnlyGroupMember(this, this.lastCreationAttempt.groupName, personName);
});
