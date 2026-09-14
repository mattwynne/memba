const assert = require("node:assert/strict");
const { expect } = require("@playwright/test");
const {
  clubSiteUrl,
  emailFor,
  removeMemberFromClub,
  testLocalDeliveryFacts
} = require("./member_message");
const { withMemberHarness } = require("./member_harness");
const {
  addCustomGroupMember,
  ensureCustomGroup,
  kootenayClubName
} = require("./custom_group_creation");
const {
  ensureConversationBackground,
  startBoardConversationFixture
} = require("./custom_group_conversations");
const serverCommands = require("./server_commands");

const boardName = "Board";
const tripsName = "Trips";
const agendaSubject = "September agenda";
const tripsSubject = "Trips departure planning";

function ensureLifecycleBackground(world) {
  ensureConversationBackground(world);
  ensureCustomGroup(world, kootenayClubName, boardName, "board", ["Alice", "Bob"]);

  const names = serverCommands.runCommand(
    `
%{
  names:
    Map.fetch!(payload, "groupId")
    |> Memba.Membership.list_active_members_of_group()
    |> Enum.map(& &1.name)
}
`,
    { groupId: groupId(world, boardName) }
  ).names;

  assert.deepEqual(names, ["Alice", "Bob"]);
}

function ensureBoardConversationWithReply(world, subject, replyBody) {
  startBoardConversationFixture(world, "Alice", subject);

  serverCommands.runCommand(
    `
:ok =
  Memba.Messaging.post_message_reply(
    %{
      message_id: Memba.ID.generate(:message),
      conversation_id: Map.fetch!(payload, "conversationId"),
      sender_id: Map.fetch!(payload, "senderId"),
      body: Map.fetch!(payload, "body")
    },
    consistency: :strong
  )

%{status: "replied"}
`,
    {
      body: replyBody,
      conversationId: world.messages[subject].messageId,
      senderId: person(world, "Bob").personId
    }
  );

  serverCommands.dispatchPendingEmailDeliveries();
}

function setupDepartureMemberships(world) {
  addCustomGroupMember(world, kootenayClubName, boardName, "Carol");
  ensureCustomGroup(world, kootenayClubName, tripsName, "trips", ["Alice", "Carol"]);

  if (!world.messages[tripsSubject]) {
    const result = serverCommands.sendClubMessage({
      audienceGroupId: groupId(world, tripsName),
      body: `${tripsSubject} details.`,
      clubId: club(world).clubId,
      senderId: person(world, "Alice").personId,
      senderName: "Alice",
      subject: tripsSubject
    });

    world.messages[tripsSubject] = {
      body: result.body,
      clubId: result.clubId,
      clubSlug: club(world).slug,
      messageId: result.messageId,
      senderName: "Alice",
      subject: tripsSubject
    };
  }

  serverCommands.dispatchPendingEmailDeliveries();
}

function followLifecycleConversations(world) {
  for (const subject of [agendaSubject, tripsSubject]) {
    const result = serverCommands.runCommand(
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

%{
  following:
    Memba.Messaging.following_conversation?(
      Map.fetch!(payload, "conversationId"),
      Map.fetch!(payload, "personId")
    )
}
`,
      {
        clubId: club(world).clubId,
        conversationId: message(world, subject).messageId,
        personId: person(world, "Carol").personId
      }
    );

    assert.equal(result.following, true);
  }
}

async function endCarolMembership(world) {
  await testLocalDeliveryFacts(world);
  removeMemberFromClub(world, "Carol", kootenayClubName);
}

async function setupEndedDeparture(world) {
  setupDepartureMemberships(world);
  followLifecycleConversations(world);
  await endCarolMembership(world);
}

function rejoinCarol(world) {
  const member = serverCommands.ensureMember({
    clubName: kootenayClubName,
    clubSlug: club(world).slug,
    personName: "Carol",
    email: emailFor("Carol")
  });

  world.memberships[`${kootenayClubName}:Carol`] = {
    clubId: member.clubId,
    membershipId: member.membershipId,
    personId: member.personId
  };
}

function assertCarolBelongsToEveryone(world) {
  const status = lifecycleMembershipStatus(world);
  assert.equal(status.activeClubMember, true);
  assert.equal(status.everyone, true);
}

function assertCarolOutsideCustomGroups(world) {
  const status = lifecycleMembershipStatus(world);

  assert.equal(status.boardExists, true);
  assert.equal(status.tripsExists, true);
  assert.equal(status.board, false);
  assert.equal(status.trips, false);
  assert.equal(status.authoritativeBoard, false);
  assert.equal(status.authoritativeTrips, false);
}

function assertCarolNoLongerFollows(world) {
  const status = lifecycleConversationStatus(world);
  assert.equal(status.boardFollowing, false);
  assert.equal(status.tripsFollowing, false);
}

async function assertCarolHasNoConversationAccess(world) {
  const status = lifecycleConversationStatus(world);

  assert.equal(status.boardRead, false);
  assert.equal(status.boardWrite, false);
  assert.equal(status.tripsRead, false);
  assert.equal(status.tripsWrite, false);

  await withMemberHarness(world, "Carol", async (member) => {
    const expectedStatus = lifecycleMembershipStatus(world).activeClubMember ? 404 : 403;

    for (const [groupName, subject] of [
      [boardName, agendaSubject],
      [tripsName, tripsSubject]
    ]) {
      const response = await member.page.goto(
        clubSiteUrl(
          member.baseUrl,
          club(world),
          `/messages/${encodeURIComponent(message(world, subject).messageId)}` +
            `?group_id=${encodeURIComponent(groupId(world, groupName))}`
        )
      );

      assert.equal(response && response.status(), expectedStatus);
      await expect(member.page.getByText(subject, { exact: true })).toHaveCount(0);
      await expect(member.page.locator("#member-message-reply-form")).toHaveCount(0);
    }
  });
}

async function assertCarolReceivesNoFutureGroupEmail(world) {
  const generatedMessageIds = createFutureGroupActivity(world);
  serverCommands.dispatchPendingEmailDeliveries();

  const personId = person(world, "Carol").personId;
  const facts = await testLocalDeliveryFacts(world);
  const futureFacts = facts.filter((fact) => generatedMessageIds.includes(fact.message_id));

  assert.equal(
    futureFacts.some((fact) => fact.recipient_id === personId),
    false,
    "Expected no post-departure Board or Trips email to reach Carol's provider boundary"
  );
}

async function assertCarolSeesAccessGuidance(world) {
  await withMemberHarness(world, "Carol", async (member) => {
    for (const groupName of [boardName, tripsName]) {
      const selectedGroupId = groupId(world, groupName);

      await member.page.goto(
        clubSiteUrl(
          member.baseUrl,
          club(world),
          `/groups/${encodeURIComponent(selectedGroupId)}`
        )
      );

      await expect(member.page.locator("#member-club-home")).toHaveAttribute(
        "data-selected-group-id",
        selectedGroupId
      );
      await expect(member.page.locator("#member-group-name")).toHaveText(groupName);
      await expect(member.page.locator("#member-group-access-guidance")).toBeVisible();
    }
  });
}

function lifecycleMembershipStatus(world) {
  return serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
person_id = Map.fetch!(payload, "personId")
board_id = Map.fetch!(payload, "boardId")
trips_id = Map.fetch!(payload, "tripsId")

%{
  activeClubMember: Memba.Membership.active_member_of_club?(club_id, person_id),
  everyone:
    Memba.Membership.active_member_of_group?(
      Memba.Membership.SystemGroups.everyone_group_id(club_id),
      person_id
    ),
  boardExists: not is_nil(Memba.Membership.get_group(board_id)),
  tripsExists: not is_nil(Memba.Membership.get_group(trips_id)),
  board: Memba.Membership.active_member_of_group?(board_id, person_id),
  trips: Memba.Membership.active_member_of_group?(trips_id, person_id),
  authoritativeBoard:
    Memba.Membership.active_member_of_group_authoritatively?(club_id, board_id, person_id),
  authoritativeTrips:
    Memba.Membership.active_member_of_group_authoritatively?(club_id, trips_id, person_id)
}
`,
    lifecycleIds(world)
  );
}

function lifecycleConversationStatus(world) {
  return serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
person_id = Map.fetch!(payload, "personId")
board_conversation_id = Map.fetch!(payload, "boardConversationId")
trips_conversation_id = Map.fetch!(payload, "tripsConversationId")

%{
  boardFollowing:
    Memba.Messaging.following_conversation?(board_conversation_id, person_id),
  tripsFollowing:
    Memba.Messaging.following_conversation?(trips_conversation_id, person_id),
  boardRead:
    Memba.Messaging.member_has_conversation_access?(
      board_conversation_id,
      club_id,
      person_id,
      :read
    ),
  boardWrite:
    Memba.Messaging.member_has_conversation_access?(
      board_conversation_id,
      club_id,
      person_id,
      :write
    ),
  tripsRead:
    Memba.Messaging.member_has_conversation_access?(
      trips_conversation_id,
      club_id,
      person_id,
      :read
    ),
  tripsWrite:
    Memba.Messaging.member_has_conversation_access?(
      trips_conversation_id,
      club_id,
      person_id,
      :write
    )
}
`,
    {
      ...lifecycleIds(world),
      boardConversationId: message(world, agendaSubject).messageId,
      tripsConversationId: message(world, tripsSubject).messageId
    }
  );
}

function createFutureGroupActivity(world) {
  return serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
sender_id = Map.fetch!(payload, "senderId")

message_ids =
  Enum.flat_map(Map.fetch!(payload, "groups"), fn group ->
    reply_id = Memba.ID.generate(:message)
    root_id = Memba.ID.generate(:message)

    :ok =
      Memba.Messaging.post_message_reply(
        %{
          message_id: reply_id,
          conversation_id: Map.fetch!(group, "conversationId"),
          sender_id: sender_id,
          body: "#{Map.fetch!(group, "name")} followed reply after departure."
        },
        consistency: :strong
      )

    :ok =
      Memba.Messaging.send_club_message(
        %{
          message_id: root_id,
          club_id: club_id,
          sender_id: sender_id,
          audience_group_id: Map.fetch!(group, "groupId"),
          subject: "#{Map.fetch!(group, "name")} after Carol's departure",
          body: "Future private-group conversation."
        },
        consistency: :strong
      )

    [reply_id, root_id]
  end)

carol_id = Map.fetch!(payload, "carolId")

Enum.each(message_ids, fn message_id ->
  if Enum.any?(
       Memba.Messaging.list_recipient_deliveries(message_id),
       &(&1.recipient_id == carol_id)
     ) do
    raise "Carol was resolved as a recipient after departure"
  end
end)

%{messageIds: message_ids}
`,
    {
      carolId: person(world, "Carol").personId,
      clubId: club(world).clubId,
      groups: [
        {
          conversationId: message(world, agendaSubject).messageId,
          groupId: groupId(world, boardName),
          name: boardName
        },
        {
          conversationId: message(world, tripsSubject).messageId,
          groupId: groupId(world, tripsName),
          name: tripsName
        }
      ],
      senderId: person(world, "Alice").personId
    }
  ).messageIds;
}

function lifecycleIds(world) {
  return {
    boardId: groupId(world, boardName),
    clubId: club(world).clubId,
    personId: person(world, "Carol").personId,
    tripsId: groupId(world, tripsName)
  };
}

function club(world) {
  const result = world.clubs && world.clubs[kootenayClubName];
  assert.ok(result, `Expected ${kootenayClubName}`);
  return result;
}

function person(world, personName) {
  const result = world.people && world.people[personName];
  assert.ok(result, `Expected person ${personName}`);
  return result;
}

function groupId(world, groupName) {
  const result = world.groups && world.groups[`${kootenayClubName}:${groupName}`];
  assert.ok(result, `Expected custom group ${groupName}`);
  return result;
}

function message(world, subject) {
  const result = world.messages && world.messages[subject];
  assert.ok(result, `Expected conversation ${subject}`);
  return result;
}

module.exports = {
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
};
