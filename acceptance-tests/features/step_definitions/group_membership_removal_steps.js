const { Given, When, Then } = require("@cucumber/cucumber");
const { expect } = require("@playwright/test");
const { startBoardConversationFixture } = require("../support/custom_group_conversations");
const { openBoardConversation } = require("../support/custom_group_lifecycle");
const { removeThroughBrowser } = require("../support/custom_group_membership");
const { withMemberHarness } = require("../support/member_harness");

Given('Carol is reading Board\'s conversation "September agenda"', async function () {
  startBoardConversationFixture(this, "Bob", "September agenda");
  await openBoardConversation(this);
  await withMemberHarness(this, "Carol", async (member) => {
    await expect(member.page.getByText("September agenda details.", { exact: true })).toBeVisible();
  });
});

When("Bob removes Carol from Board", async function () {
  await removeThroughBrowser(this, "Bob", "Carol");
});

Then(
  "Carol's open page should stop displaying {string} without her navigating or refreshing",
  async function (subject) {
    // Reuse Carol's already-open page: no navigation, reload, or injected notification.
    await withMemberHarness(this, "Carol", async (member) => {
      await expect(member.page.getByRole("heading", { name: subject, exact: true })).toHaveCount(0);
      await expect(member.page.getByText(`${subject} details.`, { exact: true })).toHaveCount(0);
      await expect(member.page.locator("#member-group-access-guidance")).toBeVisible();
    });
  }
);
