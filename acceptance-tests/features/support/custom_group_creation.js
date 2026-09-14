const assert = require("node:assert/strict");
const { expect } = require("@playwright/test");
const {
  clubSiteUrl,
  ensureState,
  recordAcceptedInboundRootMessage,
  waitForLiveViewConnected
} = require("./member_message");
const { withMemberHarness } = require("./member_harness");
const {
  ensureMembershipAdministrators,
  ensureOrdinaryMember
} = require("./membership_administration");
const serverCommands = require("./server_commands");

const kootenayClubName = "Kootenay Mountaineering Club";
const nelsonClubName = "Nelson Paddling Club";

function ensureClubWithSlug(world, clubName, clubSlug) {
  ensureState(world);

  const club = serverCommands.ensureClub({ clubName, clubSlug });
  world.clubs[clubName] = {
    clubId: club.clubId,
    name: club.clubName,
    slug: club.clubSlug
  };

  return world.clubs[clubName];
}

function ensureClubAdmins(world, personNames, clubName = kootenayClubName) {
  ensureMembershipAdministrators(world, personNames, clubName);
}

function ensureOrdinaryClubMembers(world, personNames, clubName = kootenayClubName) {
  for (const personName of personNames) {
    ensureOrdinaryMember(world, personName, clubName);
  }
}

function ensureCustomGroup(
  world,
  clubName,
  groupName,
  emailSlug = slugFor(groupName),
  memberNames = []
) {
  ensureState(world);
  world.groups = world.groups || {};

  const club = clubFor(world, clubName);
  const members = memberNames.map((personName) => memberFor(world, clubName, personName));
  const group = serverCommands.runCommand(
    `
import Ecto.Query

club_id = Map.fetch!(payload, "clubId")
group_name = Map.fetch!(payload, "groupName")
email_slug = Map.fetch!(payload, "emailSlug")
name_key = Memba.Membership.GroupName.uniqueness_key(group_name)

group =
  Memba.Membership.Projections.Group
  |> where([group], group.club_id == ^club_id)
  |> where([group], is_nil(group.group_key))
  |> where([group], group.name_uniqueness_key == ^name_key)
  |> Memba.Repo.one()

group =
  if group do
    group
  else
    group_id = Memba.ID.generate(:group)

    :ok =
      Memba.Membership.App.dispatch(
        %Memba.Membership.Commands.CreateGroup{
          club_id: club_id,
          group_id: group_id,
          group_key: nil,
          email_slug: email_slug,
          name: group_name
        },
        consistency: :strong
      )

    Memba.Repo.get!(Memba.Membership.Projections.Group, group_id)
  end

Enum.each(Map.fetch!(payload, "members"), fn member ->
  already_active? =
    Memba.Repo.exists?(
      from group_membership in Memba.Membership.Projections.GroupMembership,
        where:
          group_membership.group_id == ^group.group_id and
            group_membership.membership_id == ^Map.fetch!(member, "membershipId") and
            group_membership.active == true
    )

  unless already_active? do
    :ok =
      Memba.Membership.App.dispatch(
        %Memba.Membership.Commands.AddGroupMember{
          club_id: club_id,
          group_id: group.group_id,
          membership_id: Map.fetch!(member, "membershipId"),
          person_id: Map.fetch!(member, "personId")
        },
        consistency: :strong
      )
  end
end)

%{
  clubId: group.club_id,
  emailSlug: group.email_slug,
  groupId: group.group_id,
  name: group.name
}
`,
    {
      clubId: club.clubId,
      emailSlug,
      groupName,
      members
    }
  );

  rememberGroup(world, clubName, group);
  return group;
}

function addCustomGroupMember(world, clubName, groupName, personName) {
  const group = customGroup(world, clubName, groupName);
  assert.ok(group, `Expected ${groupName} to exist in ${clubName}`);
  ensureCustomGroup(world, clubName, group.name, group.emailSlug, [personName]);
}

async function createCustomGroupInBrowser(world, actorName, clubName, groupName) {
  const countBefore = customGroupCount(world, clubName);

  await withMemberHarness(world, actorName, async (member) => {
    await openNewGroupForm(member, clubName);
    await fillGroupName(member, groupName);
    const proposedAddress = await proposedAddressOnCurrentForm(member);
    await member.page.locator("#member-group-create-button").click();
    await expect(member.page.locator("#member-club-home")).toBeVisible();
    await expect(member.page.locator("#member-section-panel-members")).toBeVisible();

    world.lastProposedAddress = proposedAddress;
  });

  const group = customGroup(world, clubName, groupName);
  assert.ok(group, `Expected browser creation to create ${groupName} in ${clubName}`);
  rememberGroup(world, clubName, group);
  world.lastCreationAttempt = {
    actorName,
    clubName,
    countBefore,
    groupId: group.groupId,
    groupName,
    result: "created"
  };
}

async function tryCreateCustomGroupInBrowser(world, actorName, clubName, groupName) {
  const countBefore = customGroupCount(world, clubName);
  const existingSystemGroups = systemGroupSnapshot(world, clubName);

  await withMemberHarness(world, actorName, async (member) => {
    const response = await openNewGroupForm(member, clubName, { allowForbidden: true });

    if (response && response.status() === 403) {
      world.lastCreationAttempt = {
        actorName,
        clubName,
        countBefore,
        existingSystemGroups,
        groupName,
        result: "forbidden"
      };
      return;
    }

    await fillGroupName(member, groupName);
    await expect(member.page.locator("#member-group-name-input-error-1")).toContainText(
      "already a group"
    );
    await expect(member.page.locator("#member-group-create-button")).toBeDisabled();

    world.lastCreationAttempt = {
      actorName,
      clubName,
      countBefore,
      existingSystemGroups,
      groupName,
      result: "duplicate"
    };
  });
}

async function concurrentlyCreateCustomGroup(world, actorNames, clubName, groupName) {
  const countBefore = customGroupCount(world, clubName);

  for (const actorName of actorNames) {
    await withMemberHarness(world, actorName, async (member) => {
      await openNewGroupForm(member, clubName);
      await fillGroupName(member, groupName);
    });
  }

  const outcomes = await Promise.all(
    actorNames.map(async (actorName) => {
      let outcome;

      await withMemberHarness(world, actorName, async (member) => {
        await member.page.locator("#member-group-create-button").click();
        await Promise.any([
          member.page.waitForURL(/\/groups\/[^/]+\/members(?:[?#].*)?$/),
          expect(member.page.locator("#member-group-name-input-error-1")).toBeVisible()
        ]);

        if (await member.page.locator("#member-club-home").isVisible()) {
          outcome = { actorName, result: "created" };
        } else {
          await expect(member.page.locator("#member-group-name-input-error-1")).toContainText(
            "already a group"
          );
          outcome = { actorName, result: "duplicate" };
        }
      });

      return outcome;
    })
  );

  const group = customGroup(world, clubName, groupName);
  assert.ok(group, `Expected one concurrent creation of ${groupName}`);
  rememberGroup(world, clubName, group);
  world.concurrentCreation = { actorNames, clubName, countBefore, group, outcomes };
  world.lastCreationAttempt = {
    ...outcomes.find(({ result }) => result === "duplicate"),
    clubName,
    countBefore,
    groupName
  };
}

async function enterNewGroupName(world, actorName, groupName, { exerciseMidpointCaret = true } = {}) {
  await withMemberHarness(world, actorName, async (member) => {
    await openNewGroupForm(member, kootenayClubName);

    if (groupName === "Trips" && exerciseMidpointCaret) {
      await typeTripsThroughMidpoint(member);
    } else {
      await fillGroupName(member, groupName);
    }

    world.lastProposedAddress = await visibleProposedAddress(member);
  });

  world.currentGroupFormActor = actorName;
  world.enteredGroupName = groupName;
}

async function changeNewGroupName(world, groupName) {
  const actorName = world.currentGroupFormActor || "Alice";

  await withMemberHarness(world, actorName, async (member) => {
    if (groupName === "Trips") {
      await typeTripsThroughMidpoint(member);
    } else {
      await fillGroupName(member, groupName);
    }

    world.lastProposedAddress = await visibleProposedAddress(member);
  });

  world.enteredGroupName = groupName;
}

async function clearNewGroupName(world) {
  const actorName = world.currentGroupFormActor || "Alice";

  await withMemberHarness(world, actorName, async (member) => {
    const input = member.page.locator("#member-group-name-input");
    await input.fill("");
    await expect(input).toBeFocused();
    await expect(input).toHaveAttribute("aria-invalid", "true");
    await expect(member.page.locator("#member-group-name-input-error-1")).toHaveText(
      "Give the group a name."
    );
  });

  world.enteredGroupName = "";
  world.lastProposedAddress = null;
}

async function submitEnteredCustomGroup(world) {
  const actorName = world.currentGroupFormActor || "Alice";
  const clubName = kootenayClubName;
  const groupName = world.enteredGroupName;
  const countBefore = customGroupCount(world, clubName);

  await withMemberHarness(world, actorName, async (member) => {
    await member.page.locator("#member-group-create-button").click();
    await expect(member.page.locator("#member-club-home")).toBeVisible();
    await expect(member.page.locator("#member-section-panel-members")).toBeVisible();
  });

  const group = customGroup(world, clubName, groupName);
  assert.ok(group, `Expected submitted form to create ${groupName}`);
  rememberGroup(world, clubName, group);
  world.lastCreationAttempt = {
    actorName,
    clubName,
    countBefore,
    groupId: group.groupId,
    groupName,
    result: "created"
  };
}

async function assertDuplicateNameFeedback(world) {
  const actorName =
    (world.lastCreationAttempt && world.lastCreationAttempt.actorName) ||
    world.currentGroupFormActor ||
    "Alice";

  await withMemberHarness(world, actorName, async (member) => {
    await expect(member.page.locator("#member-group-name-input-error-1")).toContainText(
      "already a group"
    );
    await expect(member.page.locator("#member-group-name-input")).toHaveAttribute(
      "aria-invalid",
      "true"
    );
  });
}

async function assertDuplicateNameFeedbackAbsent(world) {
  const actorName = world.currentGroupFormActor || "Alice";

  await withMemberHarness(world, actorName, async (member) => {
    await expect(member.page.locator("#member-group-name-input-error-1")).toHaveCount(0);
    await expect(member.page.locator("#member-group-name-input")).not.toHaveAttribute(
      "aria-invalid",
      "true"
    );
  });
}

async function assertNameAccepted(world) {
  const actorName = world.currentGroupFormActor || "Alice";

  await withMemberHarness(world, actorName, async (member) => {
    await expect(member.page.locator("#member-group-name-input-error-1")).toHaveCount(0);
    await expect(member.page.locator("#member-group-create-button")).toBeEnabled();
  });
}

async function assertProposedAddress(world, expectedAddress) {
  const actorName = world.currentGroupFormActor || "Alice";

  await withMemberHarness(world, actorName, async (member) => {
    await expect(member.page.locator("#member-group-email-preview")).toHaveText(expectedAddress);
    await expect(member.page.locator("#member-group-email-preview")).toHaveAttribute(
      "data-state",
      "available"
    );
  });

  world.lastProposedAddress = expectedAddress;
}

async function assertNoProposedAddress(world) {
  const actorName = world.currentGroupFormActor || "Alice";

  await withMemberHarness(world, actorName, async (member) => {
    await expect(member.page.locator("#member-group-email-preview")).toBeEmpty();
    await expect(member.page.locator("#member-group-email-preview")).toHaveAttribute(
      "data-state",
      "empty"
    );
  });
}

async function assertBlankNameFeedback(world) {
  const actorName = world.currentGroupFormActor || "Alice";

  await withMemberHarness(world, actorName, async (member) => {
    await expect(member.page.locator("#member-group-name-input-error-1")).toHaveText(
      "Give the group a name."
    );
    await expect(member.page.locator("#member-group-name-input")).toHaveAttribute(
      "aria-invalid",
      "true"
    );
  });
}

function assertGroupBelongsToClub(world, groupName, clubName) {
  assert.ok(customGroup(world, clubName, groupName), `Expected ${groupName} in ${clubName}`);
}

function assertOnlyGroupMember(world, groupName, personName) {
  assert.deepEqual(activeGroupMemberNames(world, kootenayClubName, groupName), [personName]);
}

function assertNoCustomGroup(world, clubName, groupName) {
  assert.equal(customGroup(world, clubName, groupName), null);
}

function assertNoAdditionalGroup(world) {
  const attempt = world.lastCreationAttempt;
  assert.ok(attempt, "Expected a custom-group creation attempt");
  assert.equal(customGroupCount(world, attempt.clubName), attempt.countBefore);
}

function assertEachClubHasBoard(world) {
  const kmcBoard = customGroup(world, kootenayClubName, "Board");
  const nelsonBoard = customGroup(world, nelsonClubName, "Board");

  assert.ok(kmcBoard);
  assert.ok(nelsonBoard);
  assert.notEqual(kmcBoard.groupId, nelsonBoard.groupId);
}

function assertSystemGroupsUnchanged(world) {
  assert.deepEqual(
    systemGroupSnapshot(world, kootenayClubName),
    world.lastCreationAttempt.existingSystemGroups
  );
}

function assertOneConcurrentGroup(world) {
  const creation = world.concurrentCreation;
  assert.ok(creation, "Expected a concurrent custom-group creation attempt");
  assert.equal(customGroupCount(world, creation.clubName), creation.countBefore + 1);
}

function assertOnlyConcurrentWinnerJoined(world) {
  const creation = world.concurrentCreation;
  const winner = creation.outcomes.find(({ result }) => result === "created");
  const loser = creation.outcomes.find(({ result }) => result === "duplicate");

  assert.ok(winner, `Expected one successful outcome; saw ${JSON.stringify(creation.outcomes)}`);
  assert.ok(loser, `Expected one duplicate outcome; saw ${JSON.stringify(creation.outcomes)}`);
  assert.deepEqual(
    activeGroupMemberNames(world, creation.clubName, creation.group.name),
    [winner.actorName]
  );
}

function assertConcurrentLoserSawDuplicate(world) {
  const duplicateOutcomes = world.concurrentCreation.outcomes.filter(
    ({ result }) => result === "duplicate"
  );
  assert.equal(duplicateOutcomes.length, 1);
}

function assertStoredEmailSlug(world, clubName, groupName, expectedSlug) {
  const group = customGroup(world, clubName, groupName);
  assert.ok(group, `Expected ${groupName} in ${clubName}`);
  assert.equal(group.emailSlug, expectedSlug);
}

function assertGroupAddress(world, clubName, groupName, expectedAddress) {
  const group = customGroup(world, clubName, groupName);
  assert.ok(group, `Expected ${groupName} in ${clubName}`);
  assert.equal(groupAddress(world, clubName, group.emailSlug), expectedAddress);
}

function assertStoredAddressMatchesProposal(world) {
  const creation = world.lastCreationAttempt;
  assert.ok(creation && creation.groupId, "Expected a successfully created custom group");
  const group = customGroup(world, creation.clubName, creation.groupName);
  assert.equal(
    groupAddress(world, creation.clubName, group.emailSlug),
    world.lastProposedAddress
  );
}

async function assertInboundConversationBelongsToGroup(world, subject, groupName) {
  const message = await recordAcceptedInboundRootMessage(world, subject);
  const group = customGroup(world, kootenayClubName, groupName);
  assert.ok(group, `Expected ${groupName} in ${kootenayClubName}`);

  const result = serverCommands.runCommand(
    `
import Ecto.Query

conversation_id = Map.fetch!(payload, "conversationId")
group_id = Map.fetch!(payload, "groupId")

count =
  Memba.Messaging.Projections.ConversationGroupAccess
  |> where([access],
    access.conversation_id == ^conversation_id and
      access.group_id == ^group_id
  )
  |> Memba.Repo.aggregate(:count)

%{count: count}
`,
    { conversationId: message.messageId, groupId: group.groupId }
  );

  assert.equal(result.count, 1);
}

function customGroup(world, clubName, groupName) {
  const club = clubFor(world, clubName);

  return serverCommands.runCommand(
    `
import Ecto.Query

club_id = Map.fetch!(payload, "clubId")
name_key = Memba.Membership.GroupName.uniqueness_key(Map.fetch!(payload, "groupName"))

group =
  Memba.Membership.Projections.Group
  |> where([group], group.club_id == ^club_id)
  |> where([group], is_nil(group.group_key))
  |> where([group], group.name_uniqueness_key == ^name_key)
  |> Memba.Repo.one()

if group do
  %{
    clubId: group.club_id,
    emailSlug: group.email_slug,
    groupId: group.group_id,
    name: group.name
  }
else
  nil
end
`,
    { clubId: club.clubId, groupName }
  );
}

function customGroupCount(world, clubName) {
  const club = clubFor(world, clubName);

  return serverCommands.runCommand(
    `
import Ecto.Query

count =
  Memba.Membership.Projections.Group
  |> where([group], group.club_id == ^Map.fetch!(payload, "clubId"))
  |> where([group], is_nil(group.group_key))
  |> Memba.Repo.aggregate(:count)

%{count: count}
`,
    { clubId: club.clubId }
  ).count;
}

function activeGroupMemberNames(world, clubName, groupName) {
  const group = customGroup(world, clubName, groupName);
  assert.ok(group, `Expected ${groupName} in ${clubName}`);

  return serverCommands.runCommand(
    `
names =
  Map.fetch!(payload, "groupId")
  |> Memba.Membership.list_active_members_of_group()
  |> Enum.map(& &1.name)
  |> Enum.sort()

%{names: names}
`,
    { groupId: group.groupId }
  ).names;
}

function systemGroupSnapshot(world, clubName) {
  const club = clubFor(world, clubName);

  return serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")

groups =
  [
    Memba.Membership.SystemGroups.everyone_group_id(club_id),
    Memba.Membership.SystemGroups.admin_group_id(club_id)
  ]
  |> Enum.map(&Memba.Membership.get_group/1)
  |> Enum.map(fn group ->
    %{
      emailSlug: group.email_slug,
      groupId: group.group_id,
      groupKey: group.group_key,
      name: group.name
    }
  end)

%{groups: groups}
`,
    { clubId: club.clubId }
  ).groups;
}

async function openNewGroupForm(world, clubName, { allowForbidden = false } = {}) {
  const club = clubFor(world, clubName);
  const response = await world.page.goto(clubSiteUrl(world.baseUrl, club, "/groups/new"));

  if (allowForbidden && response && response.status() === 403) {
    return response;
  }

  await expect(world.page.locator("#member-group-new-form")).toBeVisible();
  await waitForLiveViewConnected(world);
  return response;
}

async function fillGroupName(world, groupName) {
  const input = world.page.locator("#member-group-name-input");
  await input.fill(groupName);
  await expect(input).toBeFocused();
  await expect(input).toHaveValue(groupName);

  const available = world.page.locator("#member-group-email-preview[data-state='available']");
  const duplicate = world.page.locator("#member-group-name-input-error-1");
  await Promise.any([expect(available).toBeVisible(), expect(duplicate).toBeVisible()]);
}

async function typeTripsThroughMidpoint(world) {
  const input = world.page.locator("#member-group-name-input");
  const preview = world.page.locator("#member-group-email-preview");

  await input.fill("");
  await input.pressSequentially("Trps");
  await expect(preview).toContainText("trps@");
  await expect(input).toBeFocused();

  await input.evaluate((element) => element.setSelectionRange(2, 2));
  await input.press("i");
  await expect(input).toHaveValue("Trips");
  await expect(preview).toContainText("trips@");
  await expect(input).toBeFocused();

  const caret = await input.evaluate((element) => ({
    end: element.selectionEnd,
    start: element.selectionStart
  }));
  assert.deepEqual(caret, { end: 3, start: 3 });
}

async function visibleProposedAddress(world) {
  const preview = world.page.locator("#member-group-email-preview");

  if ((await preview.getAttribute("data-state")) !== "available") {
    return null;
  }

  return (await preview.textContent()).trim();
}

async function proposedAddressOnCurrentForm(world) {
  const preview = world.page.locator("#member-group-email-preview[data-state='available']");
  await expect(preview).toBeVisible();
  return (await preview.textContent()).trim();
}

function rememberGroup(world, clubName, group) {
  world.groups = world.groups || {};
  world.groups[`${clubName}:${group.name}`] = group.groupId;
}

function memberFor(world, clubName, personName) {
  const membership = world.memberships[`${clubName}:${personName}`];
  const person = world.people[personName];

  assert.ok(membership, `Expected ${personName} to be a member of ${clubName}`);
  assert.ok(person, `Expected ${personName} to be known`);
  return { membershipId: membership.membershipId, personId: person.personId };
}

function clubFor(world, clubName) {
  ensureState(world);
  const club = world.clubs[canonicalClubName(clubName)];
  assert.ok(club, `Expected ${clubName} to be a known club`);
  return club;
}

function groupAddress(world, clubName, emailSlug) {
  const club = clubFor(world, clubName);
  const inboundDomain = process.env.ACCEPTANCE_CLUB_INBOUND_EMAIL_DOMAIN || "clubs.memba.io";
  return `${emailSlug}@${club.slug}.${inboundDomain}`;
}

function canonicalClubName(clubName) {
  return clubName === "KMC" ? kootenayClubName : clubName;
}

function slugFor(groupName) {
  return groupName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

module.exports = {
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
  concurrentlyCreateCustomGroup,
  createCustomGroupInBrowser,
  ensureClubAdmins,
  ensureClubWithSlug,
  ensureCustomGroup,
  ensureOrdinaryClubMembers,
  enterNewGroupName,
  clearNewGroupName,
  kootenayClubName,
  nelsonClubName,
  submitEnteredCustomGroup,
  tryCreateCustomGroupInBrowser
};
