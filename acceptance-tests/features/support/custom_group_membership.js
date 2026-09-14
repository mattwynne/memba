const assert = require("node:assert/strict");
const { expect } = require("@playwright/test");
const { clubSiteUrl, waitForLiveViewConnected } = require("./member_message");
const { withMemberHarness } = require("./member_harness");
const { kootenayClubName } = require("./custom_group_creation");

async function openAddMemberPicker(world, memberName, groupName) {
  await withMemberHarness(world, memberName, async (member) => {
    const club = world.clubs && world.clubs[kootenayClubName];
    const groupId = world.groups && world.groups[`${kootenayClubName}:${groupName}`];

    assert.ok(club, `Expected ${kootenayClubName}`);
    assert.ok(groupId, `Expected ${groupName} custom group`);

    await member.page.goto(
      clubSiteUrl(
        member.baseUrl,
        club,
        `/groups/${encodeURIComponent(groupId)}/members`
      )
    );
    await waitForLiveViewConnected(member);
    await member.page.locator("#member-section-action-add-group-member").click();
    await expect(member.page.locator("#custom-group-member-picker")).toBeVisible();
  });
}

async function assertAddMemberSearchFocused(world, memberName) {
  await withMemberHarness(world, memberName, async (member) => {
    await expect(member.page.locator("#custom-group-member-search")).toBeFocused();
  });
}

async function pasteIntoAddMemberSearch(world, memberName, query) {
  await withMemberHarness(world, memberName, async (member) => {
    const search = member.page.locator("#custom-group-member-search");

    await search.evaluate((input, value) => {
      input.value = value;
      input.dispatchEvent(
        new InputEvent("input", {
          bubbles: true,
          data: value,
          inputType: "insertFromPaste"
        })
      );
    }, query);
  });
}

async function assertOnlyMemberOffered(world, memberName, expectedName) {
  await withMemberHarness(world, memberName, async (member) => {
    const candidates = member.page.locator(
      "#custom-group-member-candidates [data-testid='custom-group-member-candidate']"
    );

    await expect(candidates).toHaveCount(1);
    await expect(candidates).toContainText(expectedName);
  });
}

async function pressEscapeInAddMemberPicker(world, memberName) {
  await withMemberHarness(world, memberName, async (member) => {
    await member.page.keyboard.press("Escape");
  });
}

async function closeAddMemberPicker(world, memberName) {
  await withMemberHarness(world, memberName, async (member) => {
    await member.page.locator("#custom-group-member-picker-close").click();
  });
}

async function assertAddMemberPickerClosedWithTriggerFocused(world, memberName) {
  await withMemberHarness(world, memberName, async (member) => {
    await expect(member.page.locator("#custom-group-member-picker")).toHaveCount(0);
    await expect(member.page.locator("#member-section-action-add-group-member")).toBeFocused();
  });
}

module.exports = {
  assertAddMemberPickerClosedWithTriggerFocused,
  assertAddMemberSearchFocused,
  assertOnlyMemberOffered,
  closeAddMemberPicker,
  openAddMemberPicker,
  pasteIntoAddMemberSearch,
  pressEscapeInAddMemberPicker
};
