const assert = require("node:assert/strict");
const { expect } = require("@playwright/test");
const {
  clubSiteUrl,
  removeMemberFromClub,
  testMailboxEmails,
  waitForLiveViewConnected
} = require("./member_message");
const { withMemberHarness } = require("./member_harness");
const {
  addCustomGroupMember,
  ensureCustomGroup,
  kootenayClubName,
  nelsonClubName
} = require("./custom_group_creation");
const {
  ensureOrdinaryMember
} = require("./membership_administration");
const {
  ensurePersonWithoutMembership
} = require("./custom_group_conversations");
const serverCommands = require("./server_commands");

const boardName = "Board";
const agendaSubject = "September agenda";

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

async function pushForgedRemoval(world, actorName, targetName, groupName = boardName) {
  const groupId = groupIdFor(world, groupName);
  const actor = personFor(world, actorName);
  const target = personFor(world, targetName);
  const membershipId = admissionMembershipId(world, targetName);

  return serverCommands.runCommand(
    `
result =
  Memba.Membership.remove_custom_group_member(
    %{
      club_id: Map.fetch!(payload, "clubId"),
      group_id: Map.fetch!(payload, "groupId"),
      membership_id: Map.fetch!(payload, "membershipId"),
      person_id: Map.fetch!(payload, "personId"),
      actor_person_id: Map.fetch!(payload, "actorPersonId"),
      removal_operation_id: Ecto.UUID.generate()
    },
    consistency: :strong
  )

%{result: inspect(result)}
`,
    {
      actorPersonId: actor.personId,
      clubId: clubFor(world).clubId,
      groupId,
      membershipId,
      personId: target.personId
    }
  );
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

function ensureInvitedRobin(world) {
  ensurePersonWithoutMembership(world, "Robin");
  const club = clubFor(world);
  const robin = personFor(world, "Robin");

  const invitation = serverCommands.runCommand(
    `
{:ok, invitation} =
  Memba.Membership.invite_club_member(
    %{
      club_id: Map.fetch!(payload, "clubId"),
      email: Map.fetch!(payload, "email")
    },
    consistency: :strong
  )

%{
  invitationId: invitation.invitation_id,
  membershipId: Memba.ID.generate(:membership)
}
`,
    { clubId: club.clubId, email: robin.email }
  );

  world.attemptMemberships = world.attemptMemberships || {};
  world.attemptMemberships[`${kootenayClubName}:Robin`] = invitation.membershipId;
  world.robinInvitationId = invitation.invitationId;
}

function endCarolMembership(world) {
  const membership = world.memberships[`${kootenayClubName}:Carol`];
  assert.ok(membership, "Expected Carol's KMC membership before ending it");

  removeMemberFromClub(world, "Carol", kootenayClubName);
  world.attemptMemberships = world.attemptMemberships || {};
  world.attemptMemberships[`${kootenayClubName}:Carol`] = membership.membershipId;
}

function prepareReturnedCarol(world) {
  addCustomGroupMember(world, kootenayClubName, boardName, "Carol");

  const message = messageFor(world, agendaSubject);
  const carol = personFor(world, "Carol");
  const club = clubFor(world);

  serverCommands.runCommand(
    `
:ok =
  Memba.Messaging.follow_conversation_as_current_member(
    %{
      club_id: Map.fetch!(payload, "clubId"),
      conversation_id: Map.fetch!(payload, "conversationId"),
      member_id: Map.fetch!(payload, "personId")
    },
    consistency: :strong
  )

%{status: "ok"}
`,
    {
      clubId: club.clubId,
      conversationId: message.messageId,
      personId: carol.personId
    }
  );

  removeMemberFromClub(world, "Carol", kootenayClubName);
  ensureOrdinaryMember(world, "Carol", kootenayClubName);
}

function assertGroupMembership(world, groupName, personName, expected) {
  assert.equal(groupMembershipState(world, groupName, personName).activeMember, expected);
}

function assertOrdinaryClubMember(world, personName) {
  const state = memberAuthorityState(world, personName);

  assert.equal(state.activeClubMember, true);
  assert.equal(state.clubAdmin, false);
  assert.equal(state.adminGroupMember, false);
}

function assertNoBoardConversationAccess(world, personName) {
  const state = groupMembershipState(world, boardName, personName);

  assert.equal(state.activeMember, false);
  assert.equal(state.canReadAllConversations, false);
}

async function assertCanReadConversation(world, personName, subject, expectedBody) {
  const message = messageFor(world, subject);
  const groupId = groupIdFor(world, boardName);

  assert.equal(conversationAccessState(world, personName, subject).read, true);

  await withMemberHarness(world, personName, async (member) => {
    await member.page.goto(
      clubSiteUrl(
        member.baseUrl,
        clubFor(world),
        `/messages/${encodeURIComponent(message.messageId)}?group_id=${encodeURIComponent(
          groupId
        )}`
      )
    );
    await waitForLiveViewConnected(member);
    await expect(member.page.getByRole("heading", { name: subject })).toBeVisible();

    if (expectedBody) {
      await expect(member.page.getByText(expectedBody, { exact: true })).toBeVisible();
    }
  });
}

function assertOneActiveBoardMembership(world, personName) {
  const state = groupMembershipState(world, boardName, personName);

  assert.equal(state.activeMembershipCount, 1);
}

async function assertWelcomeCount(world, personName, groupName, expectedCount) {
  const emails = await testMailboxEmails(world);
  const person = personFor(world, personName);
  const scenarioEmails = emailsAfterWelcomeBaseline(world, emails);

  assert.equal(
    scenarioEmails.filter(
      (email) =>
        String(email.subject || "").includes(`You've been added to ${groupName}`) &&
        JSON.stringify(email.to || "").includes(person.email)
    ).length,
    expectedCount
  );
}

async function assertWelcomeLink(world, personName, groupName) {
  const emails = await testMailboxEmails(world);
  const scenarioEmails = emailsAfterWelcomeBaseline(world, emails);
  const person = personFor(world, personName);
  const expectedPath = `/groups/${groupIdFor(world, groupName)}`;
  const email = scenarioEmails.find(
    (candidate) =>
      String(candidate.subject || "").includes(`You've been added to ${groupName}`) &&
      JSON.stringify(candidate.to || "").includes(person.email)
  );

  assert.ok(email, `Expected ${personName}'s ${groupName} welcome email`);
  assert.ok(
    String(email.text_body || email.textBody || "").includes(expectedPath),
    `Expected ${groupName} welcome email to link to ${expectedPath}`
  );
}

function assertOnlyBoardMembers(world, expectedNames) {
  assert.deepEqual(activeGroupMemberNames(world, boardName), [...expectedNames].sort());
}

function assertNotActiveKmcMember(world, personName) {
  assert.equal(memberAuthorityState(world, personName).activeClubMember, false);
}

function assertNoOldBoardEmails(world, personName) {
  const state = conversationAccessState(world, personName, agendaSubject);

  assert.equal(state.recipientDeliveryCount, 0);
}

function assertFormerFollowNotRestored(world, personName, subject) {
  assert.equal(conversationAccessState(world, personName, subject).following, false);
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

conversations = Memba.Messaging.list_conversations_for_group(group_id)

%{
  activeMember: Memba.Membership.active_member_of_group?(group_id, person_id),
  activeMembershipCount: memberships,
  canReadAllConversations:
    Memba.Membership.active_member_of_group?(group_id, person_id) and
      Enum.all?(conversations, fn message ->
      Memba.Messaging.member_has_conversation_access?(
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

function memberAuthorityState(world, personName) {
  return serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
person_id = Map.fetch!(payload, "personId")

%{
  activeClubMember: Memba.Membership.active_member_of_club?(club_id, person_id),
  adminGroupMember:
    Memba.Membership.active_member_of_group?(
      Memba.Membership.SystemGroups.admin_group_id(club_id),
      person_id
    ),
  clubAdmin:
    Memba.Membership.person_has_club_permission?(
      club_id,
      person_id,
      Memba.Membership.Permissions.club_manage_members()
    )
}
`,
    { clubId: clubFor(world).clubId, personId: personFor(world, personName).personId }
  );
}

function conversationAccessState(world, personName, subject) {
  const message = messageFor(world, subject);
  const person = personFor(world, personName);

  return serverCommands.runCommand(
    `
message_id = Map.fetch!(payload, "messageId")
club_id = Map.fetch!(payload, "clubId")
person_id = Map.fetch!(payload, "personId")

message_ids =
  message_id
  |> Memba.Messaging.list_conversation_messages()
  |> Enum.map(& &1.message_id)

recipient_delivery_count =
  Enum.reduce(message_ids, 0, fn current_message_id, count ->
    count +
      Enum.count(
        Memba.Messaging.list_recipient_deliveries(current_message_id),
        &(&1.recipient_id == person_id)
      )
  end)

%{
  following: Memba.Messaging.following_conversation?(message_id, person_id),
  read:
    Memba.Messaging.member_has_conversation_access?(
      message_id,
      club_id,
      person_id,
      :read
    ),
  recipientDeliveryCount: recipient_delivery_count
}
`,
    {
      clubId: clubFor(world).clubId,
      messageId: message.messageId,
      personId: person.personId
    }
  );
}

function activeGroupMemberNames(world, groupName) {
  return serverCommands.runCommand(
    `
names =
  Map.fetch!(payload, "groupId")
  |> Memba.Membership.list_active_members_of_group()
  |> Enum.map(& &1.name)
  |> Enum.sort()

%{names: names}
`,
    { groupId: groupIdFor(world, groupName) }
  ).names;
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

function messageFor(world, subject) {
  const message = world.messages && world.messages[subject];
  assert.ok(message, `Expected conversation ${subject}`);
  return message;
}

async function rememberWelcomeBaseline(world) {
  if (world.groupWelcomeBaselineIds === undefined) {
    world.groupWelcomeBaselineIds = (await testMailboxEmails(world)).map(mailboxIdentity);
  }
}

function emailsAfterWelcomeBaseline(world, emails) {
  const baselineIds = new Set(world.groupWelcomeBaselineIds || []);
  return emails.filter((email) => !baselineIds.has(mailboxIdentity(email)));
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
  assertCanReadConversation,
  assertFormerFollowNotRestored,
  assertGroupMembership,
  assertNoBoardConversationAccess,
  assertNoOldBoardEmails,
  assertNotActiveKmcMember,
  assertOneActiveBoardMembership,
  assertOnlyBoardMembers,
  assertOrdinaryClubMember,
  assertWelcomeCount,
  assertWelcomeLink,
  endCarolMembership,
  ensureInvitedRobin,
  prepareReturnedCarol,
  pushForgedAdmission,
  pushForgedRemoval,
  removeThroughBrowser,
  memberAuthorityState
};
