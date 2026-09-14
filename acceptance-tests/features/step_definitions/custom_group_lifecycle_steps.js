const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertCarolBelongsToEveryone,
  assertCarolHasNoConversationAccess,
  assertCarolNoLongerFollows,
  assertCarolOutsideCustomGroups,
  assertCarolReceivesNoFutureGroupEmail,
  assertCarolSeesAccessGuidance,
  endCarolMembership,
  ensureBoardConversationWithReply,
  ensureLifecycleBackground,
  followLifecycleConversations,
  rejoinCarol,
  setupDepartureMemberships,
  setupEndedDeparture
} = require("../support/custom_group_lifecycle");

Given("Alice and Bob are the only members of its custom group Board", function () {
  ensureLifecycleBackground(this);
});

Given(
  "Board has the conversation {string} with the reply {string}",
  function (subject, replyBody) {
    ensureBoardConversationWithReply(this, subject, replyBody);
  }
);

Given("Carol belongs to Board and the custom group Trips", function () {
  setupDepartureMemberships(this);
});

Given("Carol follows conversations in both groups", function () {
  followLifecycleConversations(this);
});

When("Carol's KMC membership ends", async function () {
  await endCarolMembership(this);
});

Then("Carol should no longer belong to Board or Trips", function () {
  assertCarolOutsideCustomGroups(this);
});

Then("Carol should no longer follow their conversations", function () {
  assertCarolNoLongerFollows(this);
});

Then("Carol should have no access to their conversations", async function () {
  await assertCarolHasNoConversationAccess(this);
});

Then(
  "Carol should receive no future conversation or followed-reply emails from either group",
  async function () {
    await assertCarolReceivesNoFutureGroupEmail(this);
  }
);

Given(
  "Carol belonged to Board and Trips before her KMC membership ended",
  async function () {
    await setupEndedDeparture(this);
  }
);

When("Carol becomes an active KMC member again", function () {
  rejoinCarol(this);
});

Then("Carol should belong to Everyone", function () {
  assertCarolBelongsToEveryone(this);
});

Then("Carol should belong to neither Board nor Trips", function () {
  assertCarolOutsideCustomGroups(this);
});

Then(
  "Carol should have no access to their conversations or future group emails",
  async function () {
    await assertCarolHasNoConversationAccess(this);
    await assertCarolReceivesNoFutureGroupEmail(this);
  }
);

Then("Carol should see their access guidance", async function () {
  await assertCarolSeesAccessGuidance(this);
});
