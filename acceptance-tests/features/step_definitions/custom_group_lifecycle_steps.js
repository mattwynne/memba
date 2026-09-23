const { Given, When, Then } = require("@cucumber/cucumber");
const {
  addCarolToBoard,
  addCarolToLifecycleGroups,
  assertBoardMembers,
  assertBoardNotArchived,
  assertBoardUnchangedAndListed,
  assertCarolCanReadBoardMessage,
  assertCarolCannotAccessLifecycleConversations,
  assertCarolInEveryoneOnly,
  assertCarolLostBoardAccess,
  assertCarolNotFollowingLifecycleConversations,
  assertCarolOutsideLifecycleGroups,
  assertCarolReceivesLifecycleEmail,
  assertCarolStillActiveAndBoardListed,
  assertCarolStillFollowingBoard,
  assertCarolStaleActionsRejected,
  assertConversationLinkDenied,
  assertDeliveredCopyPreserved,
  assertEveAuthorizationRejection,
  assertFollowDoesNotGrantAccess,
  assertLifecycleAccessGuidance,
  assertNoBoardConversation,
  assertNoCarolDeliveries,
  assertNoCarolEmailOrBacklog,
  assertNoFutureLifecycleEmails,
  assertNoRecipientForRejectedInbound,
  assertUsualStaleAuthorization,
  attemptCarolEmailReply,
  emptyBoard,
  endCarolMembership,
  ensureBoardConversationWithReply,
  ensureLifecycleBoard,
  followBoardConversation,
  followLifecycleConversations,
  makeBobOnlyBoardMember,
  markCarolDeliveryQueued,
  openBoardConversation,
  postBoardReply,
  prepareDepartedCarol,
  reactivateCarol,
  removeBoardMember,
  removeCarolFromBoard,
  startBoardConversation
} = require("../support/custom_group_lifecycle");

Given("Alice and Bob are the only members of its custom group Board", function () {
  ensureLifecycleBoard(this);
});

Given(
  "Board has the conversation {string} with the reply {string}",
  function (subject, replyBody) {
    ensureBoardConversationWithReply(this, subject, replyBody);
  }
);

Given("Carol belongs to Board and the custom group Trips", function () {
  addCarolToLifecycleGroups(this);
});

Given("Carol follows conversations in both groups", function () {
  followLifecycleConversations(this);
});

When("Carol's KMC membership ends", function () {
  endCarolMembership(this);
});

Then("Carol should no longer belong to Board or Trips", function () {
  assertCarolOutsideLifecycleGroups(this);
});

Then("Carol should no longer follow their conversations", function () {
  assertCarolNotFollowingLifecycleConversations(this);
});

Then("Carol should have no access to their conversations", async function () {
  await assertCarolCannotAccessLifecycleConversations(this);
});

Then(
  "Carol should receive no future conversation or followed-reply emails from either group",
  async function () {
    await assertNoFutureLifecycleEmails(this);
  }
);

Given("Carol belonged to Board and Trips before her KMC membership ended", function () {
  prepareDepartedCarol(this);
});

When("Carol becomes an active KMC member again", function () {
  reactivateCarol(this);
});

Then("Carol should belong to Everyone", function () {
  assertCarolInEveryoneOnly(this);
});

Then("Carol should belong to neither Board nor Trips", function () {
  assertCarolOutsideLifecycleGroups(this);
});

Then(
  "Carol should have no access to their conversations or future group emails",
  async function () {
    await assertCarolCannotAccessLifecycleConversations(this);
    assertCarolNotFollowingLifecycleConversations(this);
    await assertNoFutureLifecycleEmails(this);
  }
);

Then("Carol should see their access guidance", async function () {
  await assertLifecycleAccessGuidance(this);
});

Given("Carol belongs to Board and follows {string}", function (subject) {
  if (subject !== "September agenda") throw new Error(`Unexpected Board subject: ${subject}`);
  addCarolToBoard(this);
  followBoardConversation(this);
});

Given("Carol is viewing {string}", async function (subject) {
  if (subject !== "September agenda") throw new Error(`Unexpected Board subject: ${subject}`);
  await openBoardConversation(this);
});

When("Carol leaves Board", function () {
  removeCarolFromBoard(this, "Carol");
});

Then("Carol should immediately lose access to every Board conversation", async function () {
  await assertCarolLostBoardAccess(this);
});

Then(
  "{string} should no longer be available in her open view or through its link",
  async function (subject) {
    if (subject !== "September agenda") throw new Error(`Unexpected Board subject: ${subject}`);
    await assertCarolLostBoardAccess(this);
  }
);

Then(
  "Carol should no longer be allowed to post, reply to, or follow Board conversations",
  function () {
    assertCarolStaleActionsRejected(this);
  }
);

Then("an email reply from Carol should not be added to {string}", function (subject) {
  if (subject !== "September agenda") throw new Error(`Unexpected Board subject: ${subject}`);
  attemptCarolEmailReply(this);
});

Then("Carol should see the usual authorization error for each stale action", function () {
  assertUsualStaleAuthorization(this);
});

Then("Carol should remain an active KMC member and see Board listed", function () {
  assertCarolStillActiveAndBoardListed(this);
});

When("Bob starts the Board conversation {string}", function (subject) {
  startBoardConversation(this, subject);
});

Then(
  "no email delivery should be created for Carol for {string} or {string}",
  function (firstLabel, secondLabel) {
    assertNoCarolDeliveries(this, [firstLabel, secondLabel]);
  }
);

Given("Bob has posted the reply {string} to {string}", function (body, subject) {
  if (subject !== "September agenda") throw new Error(`Unexpected Board subject: ${subject}`);
  postBoardReply(this, body);
});

Given("Bob has added Carol back to Board", function () {
  addCarolToBoard(this);
});

Given("Carol's email delivery for {string} is queued", function (label) {
  markCarolDeliveryQueued(this, label);
});

Then("Carol should still receive {string} by email", function (label) {
  assertCarolReceivesLifecycleEmail(this, label);
});

Then("its conversation link should no longer give Carol access", async function () {
  await assertConversationLinkDenied(this);
});

Given("Carol belongs to Board", function () {
  addCarolToBoard(this);
});

Given("Carol has received the Board message {string} by email", function (subject) {
  startBoardConversation(this, subject);
  assertCarolReceivesLifecycleEmail(this, subject);
});

Then("Carol's delivered copy of {string} should not be withdrawn", function (subject) {
  assertDeliveredCopyPreserved(this, subject);
});

Then("Carol should still follow {string}", function (subject) {
  if (subject !== "September agenda") throw new Error(`Unexpected Board subject: ${subject}`);
  assertCarolStillFollowingBoard(this);
});

Then("the follow should not give Carol access to it", function () {
  assertFollowDoesNotGrantAccess(this);
});

When("Bob adds Carol back to Board", function () {
  addCarolToBoard(this);
});

Then("Carol should receive no email or backlog for {string}", function (label) {
  assertNoCarolEmailOrBacklog(this, label);
});

Then("Carol should be able to read {string} on the website", async function (label) {
  await assertCarolCanReadBoardMessage(this, label);
});

Given("Carol followed {string} before leaving Board", function (subject) {
  if (subject !== "September agenda") throw new Error(`Unexpected Board subject: ${subject}`);
  addCarolToBoard(this);
  followBoardConversation(this);
  removeCarolFromBoard(this, "Carol");
});

Then("Carol should receive {string} by email", function (label) {
  assertCarolReceivesLifecycleEmail(this, label);
});

Then("Carol should still be following {string}", function (subject) {
  if (subject !== "September agenda") throw new Error(`Unexpected Board subject: ${subject}`);
  assertCarolStillFollowingBoard(this);
});

Given("Bob is Board's only remaining member", function () {
  makeBobOnlyBoardMember(this);
});

When("Bob leaves Board", function () {
  removeBoardMember(this, "Bob", "Bob");
});

Then("Board should have no members", function () {
  assertBoardMembers(this, []);
});

Then("Board should remain listed for KMC members", function () {
  assertBoardUnchangedAndListed(this);
});

Then("its name, email address, and conversation history should be unchanged", function () {
  assertBoardUnchangedAndListed(this);
});

Then("Board should not be archived", function () {
  assertBoardNotArchived(this);
});

Given("Board has no members", function () {
  emptyBoard(this);
});

Then("Carol should be Board's only member", function () {
  assertBoardMembers(this, ["Carol"]);
});

Then("Board should not have the conversation {string}", function (subject) {
  assertNoBoardConversation(this, subject);
});

Then("Eve should receive the usual authorization rejection", async function () {
  await assertEveAuthorizationRejection(this);
});

Then("no group recipient should receive an email for it", function () {
  assertNoRecipientForRejectedInbound(this, "Can Board consider a hut repair?");
});
