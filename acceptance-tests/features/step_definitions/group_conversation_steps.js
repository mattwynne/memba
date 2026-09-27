const assert = require("node:assert/strict");
const { When, Then } = require("@cucumber/cucumber");
const { expect } = require("@playwright/test");
const {
  ensureState,
  kootenayClubName,
  openMemberClubHome,
  waitForLiveViewConnected
} = require("../support/member_message");
const { withMemberHarness } = require("../support/member_harness");
const serverCommands = require("../support/server_commands");

When(/^(\w+) selects the (.+) group$/, async function (personName, groupName) {
  this.currentGroupViewer = personName;
  this.currentGroupName = groupName;

  await withMemberHarness(this, personName, async (member) => {
    await openMemberClubHome(member, kootenayClubName);
    await selectGroup(member, groupName);
  });
});

Then(
  /^(\w+) should see (\w+) in the member list$/,
  async function (viewerName, memberName) {
    await viewMembersAndAssertPresence(this, viewerName, memberName, true);
  }
);

Then(/^(\w+) should see the (.+) group selected$/, async function (personName, groupName) {
  const groupId = groupIdFor(this, kootenayClubName, groupName);

  await withMemberHarness(this, personName, async (member) => {
    await expect(
      member.page.locator(
        `#member-club-home[data-selected-group-id="${groupId}"] ` +
          `[data-testid="member-group-link"][data-group-id="${groupId}"][aria-current="true"]`
      )
    ).toBeVisible();
    await expect(member.page.locator("#member-group-name")).toHaveText(groupName);
  });
});

Then(
  /^(\w+) should see neither (.+) conversations nor its membership list$/,
  async function (personName, groupName) {
    await withMemberHarness(this, personName, async (member) => {
      await expect(member.page.locator("#member-group-name")).toHaveText(groupName);
      await expect(member.page.locator("#member-section-tabs")).toHaveCount(0);
      await expect(member.page.locator("[data-testid='club-message-row']")).toHaveCount(0);
      await expect(member.page.locator("[data-testid='club-member-row']")).toHaveCount(0);
    });
  }
);

Then(
  /^(\w+) should see Board's name and the club Admin email address$/,
  async function (personName) {
    const adminEmail = clubAdminEmailAddress(this, kootenayClubName);

    await withMemberHarness(this, personName, async (member) => {
      await expect(member.page.locator("#member-group-name")).toHaveText("Board");
      await expect(member.page.locator("#member-group-admin-email")).toHaveText(adminEmail);
    });
  }
);

Then(/^(\w+) should not belong to Board$/, function (personName) {
  assert.equal(activeGroupMemberNames(this, "Board").includes(personName), false);
});

async function selectGroup(world, groupName) {
  const link = groupLink(world, groupName);
  await expect(link).toBeVisible();
  const groupId = await link.getAttribute("data-group-id");
  const targetUrl = new URL(await link.getAttribute("href"), world.page.url()).toString();
  await link.click();
  await expect(world.page).toHaveURL(targetUrl);
  await expect(world.page.locator("#member-group-name")).toHaveText(groupName);
  await expect(world.page.locator("#member-club-home")).toHaveAttribute(
    "data-selected-group-id",
    groupId
  );
}

async function viewMembersAndAssertPresence(
  world,
  viewerName,
  memberName,
  expectedToBePresent
) {
  const personId = personIdFor(world, memberName);

  await withMemberHarness(world, viewerName, async (member) => {
    await waitForLiveViewConnected(member);
    const conversationsLink = member.page.locator("#member-section-tab-conversations");
    const membersLink = member.page.locator("#member-section-tab-members");
    const action = member.page.locator("#member-section-tabs-action");

    await expect(membersLink).toBeVisible();
    await expect(membersLink).not.toHaveAttribute("role", "tab");
    await expect(membersLink).not.toHaveAttribute("tabindex", "-1");

    if ((await membersLink.getAttribute("aria-current")) !== "page") {
      await expect(conversationsLink).toHaveAttribute("aria-current", "page");
      await expect(conversationsLink).not.toHaveAttribute("role", "tab");

      await membersLink.click();
      await expect(membersLink).toHaveAttribute("aria-current", "page");
      await expect(conversationsLink).not.toHaveAttribute("aria-current", "page");
    }

    assert.ok(
      (await action.locator("a, button").count()) <= 1,
      "Expected at most one contextual action for the active group section"
    );
    await expect(member.page.locator("#member-section-panel-members")).toBeVisible();
    await expect(member.page.locator("#member-section-panel-conversations")).toBeHidden();

    const row = member.page.locator(
      `[data-testid="club-member-row"][data-member-id="${personId}"]`
    );

    if (expectedToBePresent) {
      await expect(row).toBeVisible();
    } else {
      await expect(row).toHaveCount(0);
    }
  });
}

function groupLink(world, groupName) {
  const groupId = groupIdFor(world, kootenayClubName, groupName);
  return world.page.locator(
    `#member-group-rail [data-testid="member-group-link"][data-group-id="${groupId}"]`
  );
}

function groupIdFor(world, clubName, groupName) {
  world.groups = world.groups || {};
  const key = groupKeyForWorld(clubName, groupName);

  if (world.groups[key]) {
    return world.groups[key];
  }

  const result = serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
group_name = Map.fetch!(payload, "groupName")

group_id =
  case group_name do
    "Everyone" -> Memba.Membership.SystemGroups.everyone_group_id(club_id)
    "Admin" -> Memba.Membership.SystemGroups.admin_group_id(club_id)
  end

%{groupId: group_id}
`,
    { clubId: clubFor(world, clubName).clubId, groupName }
  );

  world.groups[key] = result.groupId;
  return result.groupId;
}

function clubFor(world, clubName) {
  ensureState(world);
  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to be a known club`);
  return club;
}

function personIdFor(world, personName) {
  ensureState(world);
  const person = world.people[personName];
  assert.ok(person, `Expected ${personName} to be a known person`);
  return person.personId;
}

function activeGroupMemberNames(world, groupName) {
  const groupId = groupIdFor(world, kootenayClubName, groupName);

  return serverCommands.runCommand(
    `
group_id = Map.fetch!(payload, "groupId")
%{names: Enum.map(Memba.Membership.list_active_members_of_group(group_id), & &1.name)}
`,
    { groupId }
  ).names;
}

function clubAdminEmailAddress(world, clubName) {
  const club = clubFor(world, clubName);

  return serverCommands.runCommand(
    `
slug = Map.fetch!(payload, "slug")
%{
  email:
    Memba.ClubInboundEmailAddress.address(
      slug,
      Memba.Membership.SystemGroups.admin_email_slug()
    )
}
`,
    { slug: club.slug }
  ).email;
}

function groupKeyForWorld(clubName, groupName) {
  return `${clubName}:${groupName}`;
}
