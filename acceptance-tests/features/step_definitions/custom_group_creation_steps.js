const { Given, When, Then } = require("@cucumber/cucumber");
const {
  addCustomGroupMember,
  assertBlankNameFeedback,
  assertConcurrentLoserSawDuplicate,
  assertDuplicateNameFeedback,
  assertDuplicateNameFeedbackAbsent,
  assertEachClubHasBoard,
  assertGroupAddress,
  assertGroupBelongsToClub,
  assertInboundConversationBelongsToGroup,
  assertNameAccepted,
  assertNoAdditionalGroup,
  assertNoCustomGroup,
  assertNoProposedAddress,
  assertOneConcurrentGroup,
  assertOnlyConcurrentWinnerJoined,
  assertOnlyGroupMember,
  assertProposedAddress,
  assertStoredAddressMatchesProposal,
  assertStoredEmailSlug,
  assertSystemGroupsUnchanged,
  changeNewGroupName,
  clearNewGroupName,
  concurrentlyCreateCustomGroup,
  createCustomGroupInBrowser,
  ensureClubAdmins,
  ensureClubWithSlug,
  ensureCustomGroup,
  ensureOrdinaryClubMembers,
  enterNewGroupName,
  kootenayClubName,
  nelsonClubName,
  submitEnteredCustomGroup,
  tryCreateCustomGroupInBrowser
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

Given(/^(\w+) belongs to the custom group (.+)$/, function (personName, groupName) {
  ensureCustomGroup(this, kootenayClubName, groupName);
  addCustomGroupMember(this, kootenayClubName, groupName, personName);
});

Given(/^(.+) has a custom group named "([^"]+)"$/, function (clubName, groupName) {
  const canonicalName = clubName === "KMC" ? kootenayClubName : clubName;

  if (!this.clubs || !this.clubs[canonicalName]) {
    const slug = canonicalName === nelsonClubName ? "nelson" : "kmc";
    ensureClubWithSlug(this, canonicalName, slug);
  }

  ensureCustomGroup(this, canonicalName, groupName);
});

Given(/^KMC already has a group named "([^"]+)"$/, function (groupName) {
  ensureCustomGroup(this, kootenayClubName, groupName);
});

Given(
  /^KMC has the custom group "([^"]+)" with stored email slug "([^"]+)"$/,
  function (groupName, emailSlug) {
    ensureCustomGroup(this, kootenayClubName, groupName, emailSlug);
  }
);

Given(
  /^Nelson Paddling Club has a Board group with stored email slug "([^"]+)"$/,
  function (emailSlug) {
    ensureClubWithSlug(this, nelsonClubName, "nelson");
    ensureCustomGroup(this, nelsonClubName, "Board", emailSlug);
  }
);

Given("Bob belongs to Elected committee", function () {
  addCustomGroupMember(this, kootenayClubName, "Elected committee", "Bob");
});

Given(/^(\w+) has entered "([^"]+)" as a new group name$/, async function (personName, name) {
  await enterNewGroupName(this, personName, name);
});

When(
  /^(\w+) creates the custom group "([^"]+)" in (.+)$/,
  async function (actorName, groupName, clubName) {
    await createCustomGroupInBrowser(this, actorName, clubName, groupName);
  }
);

When(
  /^(\w+) tries to create the custom group "([^"]+)" in (.+)$/,
  async function (actorName, groupName, clubName) {
    await tryCreateCustomGroupInBrowser(this, actorName, clubName, groupName);
  }
);

When(
  /^(\w+) tries to create a custom group named "([^"]+)" in (.+)$/,
  async function (actorName, groupName, clubName) {
    await tryCreateCustomGroupInBrowser(this, actorName, clubName, groupName);
  }
);

When(
  /^Alice and Dan concurrently try to create the custom group "([^"]+)"$/,
  async function (groupName) {
    await concurrentlyCreateCustomGroup(this, ["Alice", "Dan"], kootenayClubName, groupName);
  }
);

When(/^(\w+) enters "([^"]+)" as a new group name$/, async function (personName, name) {
  await enterNewGroupName(this, personName, name);
});

When("she changes the name to {string}", async function (name) {
  await changeNewGroupName(this, name);
});

When(/^(\w+) clears the name$/, async function (_personName) {
  await clearNewGroupName(this);
});

When(/^(\w+) creates the group$/, async function (_personName) {
  await submitEnteredCustomGroup(this);
});

Then(/^(\w+) should belong to (.+)$/, function (groupName, clubName) {
  assertGroupBelongsToClub(this, groupName, clubName);
});

Then(/^(\w+) should be its only member$/, function (personName) {
  assertOnlyGroupMember(this, this.lastCreationAttempt.groupName, personName);
});

Then(/^no custom group named "([^"]+)" should be created$/, function (groupName) {
  assertNoCustomGroup(this, kootenayClubName, groupName);
});

Then("she should be told that the group name is already in use", async function () {
  await assertDuplicateNameFeedback(this);
});

Then("no additional group should be created", function () {
  assertNoAdditionalGroup(this);
});

Then("each club should have its own Board group", function () {
  assertEachClubHasBoard(this);
});

Then("the existing system group should be unchanged", function () {
  assertSystemGroupsUnchanged(this);
});

Then("Kootenay Mountaineering Club should have exactly one Board group", function () {
  assertOneConcurrentGroup(this);
});

Then("only its successful creator should join through creation", function () {
  assertOnlyConcurrentWinnerJoined(this);
});

Then("the other admin should be told that the name is already in use", function () {
  assertConcurrentLoserSawDuplicate(this);
});

Then(/^(.+) should have the stored email slug "([^"]+)"$/, function (groupName, emailSlug) {
  assertStoredEmailSlug(this, kootenayClubName, groupName, emailSlug);
});

Then(/^(.+)'s email address should be "([^"]+)"$/, function (groupName, address) {
  assertGroupAddress(this, kootenayClubName, groupName, address);
});

Then(/^"([^"]+)" should be an (.+) conversation$/, async function (subject, groupName) {
  await assertInboundConversationBelongsToGroup(this, subject, groupName);
});

Then(/^its stored email slug should still be "([^"]+)"$/, function (emailSlug) {
  assertStoredEmailSlug(this, kootenayClubName, "Elected committee", emailSlug);
});

Then(/^(.+)'s address should remain "([^"]+)"$/, function (groupName, address) {
  assertGroupAddress(this, kootenayClubName, groupName, address);
});

Then(/^she should see the proposed address "([^"]+)"$/, async function (address) {
  await assertProposedAddress(this, address);
});

Then(/^(.+) should not yet exist$/, function (groupName) {
  assertNoCustomGroup(this, kootenayClubName, groupName);
});

Then("she should be told immediately that the name is already in use", async function () {
  await assertDuplicateNameFeedback(this);
});

Then("the duplicate-name feedback should disappear", async function () {
  await assertDuplicateNameFeedbackAbsent(this);
});

Then(/^the proposed address should become "([^"]+)"$/, async function (address) {
  await assertProposedAddress(this, address);
});

Then("the name should be accepted", async function () {
  await assertNameAccepted(this);
});

Then(/^the proposed address should be "([^"]+)"$/, async function (address) {
  await assertProposedAddress(this, address);
});

Then("its stored address should match the proposed address", function () {
  assertStoredAddressMatchesProposal(this);
});

Then("she should be told that the group needs a name", async function () {
  await assertBlankNameFeedback(this);
});

Then("no proposed email address should be shown", async function () {
  await assertNoProposedAddress(this);
});
