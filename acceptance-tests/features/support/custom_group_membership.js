const assert = require("node:assert/strict");
const { expect } = require("@playwright/test");
const {
  clubSiteUrl,
  testMailboxEmails,
  waitForLiveViewConnected
} = require("./member_message");
const { withMemberHarness } = require("./member_harness");
const { kootenayClubName, nelsonClubName } = require("./custom_group_creation");
const serverCommands = require("./server_commands");

const boardName = "Board";

async function admitThroughBrowser(world, actorName, targetName, groupName = boardName) {
  await rememberWelcomeBaseline(world);
  const groupId = groupIdFor(world, groupName);
  const target = personFor(world, targetName);

  if (groupMembershipState(world, groupName, targetName).activeMember) {
    await pushForgedAdmission(world, actorName, targetName, groupName);
    return;
  }

  await withMemberHarness(world, actorName, async (member) => {
    await openGroupMembers(member, world, groupId);

    const addSelf = member.page.locator("#member-group-add-self");

    if (actorName === targetName && (await addSelf.count()) === 1) {
      await addSelf.click();
    } else {
      await member.page.locator("#member-section-action-add-group-member").click();
      await expect(member.page.locator("#custom-group-member-picker")).toBeVisible();
      await member.page
        .locator(`#custom-group-member-candidate-add-${target.personId}`)
        .click();
    }

    await expect(member.page.locator(`#club-member-${target.personId}`)).toBeVisible();
  });
}

async function removeThroughBrowser(world, actorName, targetName, groupName = boardName) {
  const groupId = groupIdFor(world, groupName);
  const target = personFor(world, targetName);

  await withMemberHarness(world, actorName, async (member) => {
    await openGroupMembers(member, world, groupId);
    await member.page
      .locator(`#custom-group-member-remove-start-${target.personId}`)
      .click();
    await expect(
      member.page.locator(`#custom-group-member-remove-confirmation-${target.personId}`)
    ).toBeVisible();
    await member.page
      .locator(`#custom-group-member-remove-confirm-${target.personId}`)
      .click();
    await expect(member.page.locator(`#club-member-${target.personId}`)).toHaveCount(0);
  });
}

async function pushForgedAdmission(world, actorName, targetName, groupName = boardName) {
  await rememberWelcomeBaseline(world);
  const groupId = groupIdFor(world, groupName);
  const target = personFor(world, targetName);
  const membershipId = admissionMembershipId(world, targetName);

  await withMemberHarness(world, actorName, async (member) => {
    await openGroupMembers(member, world, groupId);

    await member.page.evaluate(
      ({ membershipId: submittedMembershipId, personId }) =>
        new Promise((resolve, reject) => {
          const root = document.querySelector("[data-phx-main]");
          const view = window.liveSocket.getViewByEl(root);
          const timeout = window.setTimeout(
            () =>
              reject(
                new Error(
                  "Timed out waiting for the forged add_custom_group_member LiveView event"
                )
              ),
            10_000
          );

          try {
            view.pushEvent(
              "click",
              root,
              root,
              "add_custom_group_member",
              {},
              {
                value: {
                  membership_id: submittedMembershipId,
                  person_id: personId
                }
              },
              (reply) => {
                window.clearTimeout(timeout);
                resolve(reply);
              }
            );
          } catch (error) {
            window.clearTimeout(timeout);
            reject(error);
          }
        }),
      { membershipId, personId: target.personId }
    );
  });
}

function assertGroupMembership(world, groupName, personName, expected) {
  assert.equal(groupMembershipState(world, groupName, personName).activeMember, expected);
}

function assertNoBoardConversationAccess(world, personName) {
  const state = groupMembershipState(world, boardName, personName);

  assert.equal(state.activeMember, false);
  assert.equal(state.canReadAllConversations, false);
}

function groupMembershipState(world, groupName, personName) {
  return serverCommands.runCommand(
    `
import Ecto.Query

group_id = Map.fetch!(payload, "groupId")
person_id = Map.fetch!(payload, "personId")

memberships =
  Memba.Membership.Projections.GroupMembership
  |> where([membership],
    membership.group_id == ^group_id and
      membership.person_id == ^person_id and
      membership.active == true
  )
  |> Memba.Repo.aggregate(:count, :membership_id)

conversations = Memba.Messaging.ConversationListing.list_for_group(group_id)

%{
  activeMember: Memba.Membership.MembershipQueries.active_member_of_group?(group_id, person_id),
  activeMembershipCount: memberships,
  canReadAllConversations:
    Memba.Membership.MembershipQueries.active_member_of_group?(group_id, person_id) and
      Enum.all?(conversations, fn message ->
      Memba.Messaging.ConversationGroupAccessQueries.member_has_conversation_access?(
        message.message_id,
        message.club_id,
        person_id,
        :read
      )
    end)
}
`,
    {
      groupId: groupIdFor(world, groupName),
      personId: personFor(world, personName).personId
    }
  );
}

function admissionMembershipId(world, personName) {
  const kmcMembership = world.memberships[`${kootenayClubName}:${personName}`];

  if (kmcMembership) {
    return kmcMembership.membershipId;
  }

  const attempted =
    world.attemptMemberships &&
    world.attemptMemberships[`${kootenayClubName}:${personName}`];

  if (attempted) {
    return attempted;
  }

  const otherMembership = world.memberships[`${nelsonClubName}:${personName}`];
  assert.ok(otherMembership, `Expected a membership identity for ${personName}`);
  return otherMembership.membershipId;
}

async function openGroupMembers(member, world, groupId) {
  await member.page.goto(
    clubSiteUrl(
      member.baseUrl,
      clubFor(world),
      `/groups/${encodeURIComponent(groupId)}/members`
    )
  );
  await waitForLiveViewConnected(member);
}

function groupIdFor(world, groupName) {
  if (["Admin", "Everyone"].includes(groupName)) {
    return serverCommands.runCommand(
      `
kind = Map.fetch!(payload, "kind")
group_id =
  if kind == "Admin" do
    Memba.Membership.SystemGroups.admin_group_id(Map.fetch!(payload, "clubId"))
  else
    Memba.Membership.SystemGroups.everyone_group_id(Map.fetch!(payload, "clubId"))
  end

%{groupId: group_id}
`,
      { clubId: clubFor(world).clubId, kind: groupName }
    ).groupId;
  }

  const groupId = world.groups && world.groups[`${kootenayClubName}:${groupName}`];
  assert.ok(groupId, `Expected ${groupName} group`);
  return groupId;
}

function clubFor(world) {
  const club = world.clubs && world.clubs[kootenayClubName];
  assert.ok(club, `Expected ${kootenayClubName}`);
  return club;
}

function personFor(world, personName) {
  const person = world.people && world.people[personName];
  assert.ok(person, `Expected person ${personName}`);
  return person;
}

async function rememberWelcomeBaseline(world) {
  if (world.groupWelcomeBaselineIds === undefined) {
    world.groupWelcomeBaselineIds = (await testMailboxEmails(world)).map(mailboxIdentity);
  }
}

function mailboxIdentity(email) {
  return (
    email.id ||
    (email.headers && email.headers["Message-ID"]) ||
    JSON.stringify(email)
  );
}

module.exports = {
  admitThroughBrowser,
  assertGroupMembership,
  assertNoBoardConversationAccess,
  removeThroughBrowser
};
