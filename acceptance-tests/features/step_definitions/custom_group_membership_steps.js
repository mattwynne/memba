const { Given, Then, When } = require("@cucumber/cucumber");
const {
  admitThroughBrowser,
  assertCanReadConversation,
  assertFormerFollowNotRestored,
  assertGroupMembership,
  assertNoBoardConversationAccess,
  assertNoOldBoardEmails,
  assertNotActiveKmcMember,
  assertOneActiveBoardMembership,
  assertOnlyBoardMembers,
  assertOrdinaryClubMember,
  assertWelcomeCount,
  assertWelcomeLink,
  endCarolMembership,
  ensureInvitedRobin,
  prepareReturnedCarol,
  pushForgedAdmission
} = require("../support/custom_group_membership");

When(/^(\w+) adds (\w+) to Board$/, async function (actorName, targetText) {
  const targetName = reflexiveTarget(actorName, targetText);
  this.lastAdmissionActor = actorName;
  await admitThroughBrowser(this, actorName, targetName);
});

Given("Bob has added Carol to Board", async function () {
  await admitThroughBrowser(this, "Bob", "Carol");
});

When(/^(\w+) also adds (\w+) to Board$/, async function (actorName, targetName) {
  this.lastAdmissionActor = actorName;
  await admitThroughBrowser(this, actorName, targetName);
});

When(
  /^(\w+) directly tries to add (herself|himself|\w+) to Board$/,
  async function (actorName, targetText) {
    await pushForgedAdmission(
      this,
      actorName,
      reflexiveTarget(actorName, targetText),
      "Board"
    );
  }
);

When(/^(\w+) tries to add (\w+) to Board$/, async function (actorName, targetName) {
  await pushForgedAdmission(this, actorName, targetName, "Board");
});

When(
  /^(\w+) tries to add (\w+) to Admin as though it were a custom group$/,
  async function (actorName, targetName) {
    await pushForgedAdmission(this, actorName, targetName, "Admin");
  }
);

Given("Robin has been invited to KMC but has not joined", function () {
  ensureInvitedRobin(this);
});

Given("Carol is no longer an active member of KMC", function () {
  endCarolMembership(this);
});

Given("Carol has rejoined KMC after losing her Board membership", function () {
  prepareReturnedCarol(this);
});

Then(/^(\w+) should belong to Board$/, function (personName) {
  assertGroupMembership(this, "Board", personName, true);
});

Then("Bob should remain an ordinary club member", function () {
  assertOrdinaryClubMember(this, "Bob");
});

Then("Dan should still have no access to Board conversations", function () {
  assertNoBoardConversationAccess(this, "Dan");
});

Then(/^he should be able to read "([^"]+)"$/, async function (subject) {
  await assertCanReadConversation(this, this.lastAdmissionActor, subject);
});

Then("Carol should have one active Board membership", function () {
  assertOneActiveBoardMembership(this, "Carol");
});

Then("Carol should have received one Board welcome email", async function () {
  await assertWelcomeCount(this, "Carol", "Board", 1);
});

Then("Alice and Bob should remain Board's only members", function () {
  assertOnlyBoardMembers(this, ["Alice", "Bob"]);
});

Then(
  /^(\w+) should not become an active KMC member through that attempt$/,
  function (personName) {
    assertNotActiveKmcMember(this, personName);
  }
);

Then(/^(\w+) should not belong to Admin$/, function (personName) {
  assertGroupMembership(this, "Admin", personName, false);
});

Then("Eve should remain an ordinary club member", function () {
  assertOrdinaryClubMember(this, "Eve");
});

Then(
  /^Carol should be able to read "([^"]+)" and "([^"]+)"$/,
  async function (subject, replyBody) {
    await assertCanReadConversation(this, "Carol", subject, replyBody);
  }
);

Then("Carol should be able to read Board's whole conversation history", async function () {
  await assertCanReadConversation(this, "Carol", "September agenda", "Include the hut budget");
});

Then("Carol should receive a welcome email with a link to Board", async function () {
  await assertWelcomeLink(this, "Carol", "Board");
});

Then("Carol should not be sent old conversation emails from Board", function () {
  assertNoOldBoardEmails(this, "Carol");
});

Then("Carol's former conversation follows should not be restored", function () {
  assertFormerFollowNotRestored(this, "Carol", "September agenda");
});

function reflexiveTarget(actorName, targetText) {
  return ["herself", "himself"].includes(targetText) ? actorName : targetText;
}
