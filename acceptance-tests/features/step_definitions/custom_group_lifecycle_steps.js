const { Given, When, Then } = require("@cucumber/cucumber");
const {
  addCarolToLifecycleGroups,
  assertCarolCannotAccessLifecycleConversations,
  assertCarolInEveryoneOnly,
  assertCarolNotFollowingLifecycleConversations,
  assertCarolOutsideLifecycleGroups,
  assertLifecycleAccessGuidance,
  assertNoFutureLifecycleEmails,
  endCarolMembership,
  ensureBoardConversationWithReply,
  ensureLifecycleBoard,
  followLifecycleConversations,
  prepareDepartedCarol,
  reactivateCarol
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
