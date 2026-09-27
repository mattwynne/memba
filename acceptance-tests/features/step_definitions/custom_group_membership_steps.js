const { Then, When } = require("@cucumber/cucumber");
const {
  admitThroughBrowser,
  assertGroupMembership,
  assertNoBoardConversationAccess
} = require("../support/custom_group_membership");

When(/^(\w+) adds (\w+) to Board$/, async function (actorName, targetText) {
  const targetName = reflexiveTarget(actorName, targetText);
  this.lastAdmissionActor = actorName;
  await admitThroughBrowser(this, actorName, targetName);
});

Then(/^(\w+) should belong to Board$/, function (personName) {
  assertGroupMembership(this, "Board", personName, true);
});

Then("Dan should still have no access to Board conversations", function () {
  assertNoBoardConversationAccess(this, "Dan");
});

function reflexiveTarget(actorName, targetText) {
  return ["herself", "himself"].includes(targetText) ? actorName : targetText;
}
