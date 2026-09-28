const { Given, Then, When } = require("@cucumber/cucumber");
const {
  assertBoardConversationAccess,
  assertBoardMembership,
  assertNoAdminRequestConversationAccess,
  assertRequestAccessWithoutComposer,
  assertRequestStatus,
  assertTargetedBoardAdd,
  captureWelcomeEmail,
  confirmTargetedBoardAdd,
  ensureAliceIsOnlyBoardMember,
  ensureEveIsOrdinaryMember,
  ensureKootenayClub,
  openBoardAs,
  openRequestEmailAction,
  openWelcomeLink,
  requestBoardAccess
} = require("../support/custom_group_access_request");

Given("KMC is a club", function () {
  ensureKootenayClub(this);
});

Given("Eve is its ordinary active club member", function () {
  ensureEveIsOrdinaryMember(this);
});

Given("Alice is the only member of its group Board", function () {
  ensureAliceIsOnlyBoardMember(this);
});

When("Eve opens Board", async function () {
  await openBoardAs(this, "Eve");
});

Then("Eve should be offered Request access without a message composer", async function () {
  await assertRequestAccessWithoutComposer(this, "Eve");
});

When("Eve requests access to Board", async function () {
  await requestBoardAccess(this, "Eve");
});

Then('Eve should see "Your request has been sent."', async function () {
  await assertRequestStatus(this, "Eve", "Your request has been sent.");
});

Then("Eve should still not belong to Board", function () {
  assertBoardMembership(this, "Eve", false);
});

When('Dan opens "Add Eve to Board" from the request email', async function () {
  await openRequestEmailAction(this, "Dan", "Add Eve to Board");
});

Then("Dan should be offered the action to add Eve to Board", async function () {
  await assertTargetedBoardAdd(this, "Dan", "Eve");
});

When("Dan confirms adding Eve to Board", async function () {
  await confirmTargetedBoardAdd(this, "Dan", "Eve");
});

Then("Eve should receive a welcome email with a link to Board", async function () {
  await captureWelcomeEmail(this, "Eve");
});

When("Eve opens Board from her welcome email", async function () {
  await openWelcomeLink(this, "Eve");
});

Then("Eve should have access to Board's conversations", async function () {
  await assertBoardConversationAccess(this, "Eve");
});

Then("Eve should still have no access to the Admin request conversation", async function () {
  await assertNoAdminRequestConversationAccess(this, "Eve");
});
