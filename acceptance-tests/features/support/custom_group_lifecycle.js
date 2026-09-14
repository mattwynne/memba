const assert = require("node:assert/strict");
const { expect } = require("@playwright/test");
const {
  clubSiteUrl,
  removeMemberFromClub
} = require("./member_message");
const { withMemberHarness } = require("./member_harness");
const {
  addCustomGroupMember,
  ensureCustomGroup,
  kootenayClubName
} = require("./custom_group_creation");
const { ensureOrdinaryMember } = require("./membership_administration");
const {
  startBoardConversationFixture
} = require("./custom_group_conversations");
const serverCommands = require("./server_commands");

const boardName = "Board";
const tripsName = "Trips";
const boardSubject = "September agenda";
const tripsSubject = "Trips planning";

function ensureLifecycleBoard(world) {
  ensureCustomGroup(world, kootenayClubName, boardName, "board", ["Alice", "Bob"]);
}

function ensureBoardConversationWithReply(world, subject, replyBody) {
  startBoardConversationFixture(world, "Alice", subject);
  createReplyFixture(world, subject, "Bob", replyBody);
}

function addCarolToLifecycleGroups(world) {
  ensureCustomGroup(world, kootenayClubName, tripsName, "trips", ["Alice", "Carol"]);
  addCustomGroupMember(world, kootenayClubName, boardName, "Carol");
  ensureTripsConversation(world);
}

function followLifecycleConversations(world) {
  followFixture(world, "Carol", boardSubject);
  followFixture(world, "Carol", tripsSubject);
  serverCommands.dispatchPendingEmailDeliveries();
}

function endCarolMembership(world) {
  removeMemberFromClub(world, "Carol", kootenayClubName);
}

function prepareDepartedCarol(world) {
  addCarolToLifecycleGroups(world);
  followLifecycleConversations(world);
  endCarolMembership(world);
}

function reactivateCarol(world) {
  ensureOrdinaryMember(world, "Carol", kootenayClubName);
}

function assertCarolOutsideLifecycleGroups(world) {
  const state = lifecycleState(world);

  assert.equal(state.groups.Board.activeMember, false);
  assert.equal(state.groups.Trips.activeMember, false);
}

function assertCarolNotFollowingLifecycleConversations(world) {
  const state = lifecycleState(world);

  assert.equal(state.conversations[boardSubject].following, false);
  assert.equal(state.conversations[tripsSubject].following, false);
}

async function assertCarolCannotAccessLifecycleConversations(world) {
  const state = lifecycleState(world);

  for (const subject of [boardSubject, tripsSubject]) {
    assert.equal(state.conversations[subject].read, false);
    assert.equal(state.conversations[subject].write, false);

    const message = world.messages[subject];
    const groupId = state.conversations[subject].groupId;

    await withMemberHarness(world, "Carol", async (member) => {
      const response = await member.page.goto(
        clubSiteUrl(
          member.baseUrl,
          club(world),
          `/messages/${encodeURIComponent(message.messageId)}?group_id=${encodeURIComponent(
            groupId
          )}`
        )
      );

      assert.ok(
        response && [403, 404].includes(response.status()),
        `Expected Carol's ${subject} request to be forbidden or not found`
      );
      await expect(member.page.getByRole("heading", { name: subject })).toHaveCount(0);
    });
  }
}

function assertCarolInEveryoneOnly(world) {
  const state = lifecycleState(world);

  assert.equal(state.activeClubMember, true);
  assert.equal(state.everyoneMember, true);
  assert.equal(state.groups.Board.activeMember, false);
  assert.equal(state.groups.Trips.activeMember, false);
}

async function assertNoFutureLifecycleEmails(world) {
  const futureMessageIds = createFutureMessagesAndReplies(world);
  const carolId = person(world, "Carol").personId;

  serverCommands.dispatchPendingEmailDeliveries();

  const deliveries = serverCommands.listLocalDeliveryFacts();
  const result = serverCommands.runCommand(
    `
message_ids = Map.fetch!(payload, "messageIds")
recipient_id = Map.fetch!(payload, "recipientId")

recipient_message_ids =
  Enum.flat_map(message_ids, fn message_id ->
    message_id
    |> Memba.Messaging.list_recipient_deliveries()
    |> Enum.filter(&(&1.recipient_id == recipient_id))
    |> Enum.map(& &1.message_id)
  end)

%{recipientMessageIds: recipient_message_ids}
`,
    { messageIds: futureMessageIds, recipientId: carolId }
  );

  assert.deepEqual(result.recipientMessageIds, []);
  assert.equal(
    deliveries.some(
      (delivery) =>
        futureMessageIds.includes(delivery.message_id) && delivery.recipient_id === carolId
    ),
    false
  );
}

async function assertLifecycleAccessGuidance(world) {
  const state = lifecycleState(world);

  for (const groupName of [boardName, tripsName]) {
    const groupId = state.groups[groupName].groupId;
    assert.equal(state.groups[groupName].discoverable, true);
    assert.equal(state.groups[groupName].activeMember, false);

    await withMemberHarness(world, "Carol", async (member) => {
      const response = await member.page.goto(
        clubSiteUrl(
          member.baseUrl,
          club(world),
          `/groups/${encodeURIComponent(groupId)}`
        )
      );

      assert.equal(response && response.status(), 200);
      await expect(member.page.locator("#member-group-name")).toHaveText(groupName);
      await expect(member.page.locator("#member-group-access-guidance")).toBeVisible();
    });
  }
}

function ensureTripsConversation(world) {
  if (world.messages[tripsSubject]) {
    return;
  }

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

function createReplyFixture(world, subject, senderName, body) {
  const result = serverCommands.runCommand(
    `
message_id = Memba.ID.generate(:message)

:ok =
  Memba.Messaging.post_message_reply(
    %{
      message_id: message_id,
      conversation_id: Map.fetch!(payload, "conversationId"),
      sender_id: Map.fetch!(payload, "senderId"),
      body: Map.fetch!(payload, "body")
    },
    consistency: :strong
  )

%{messageId: message_id}
`,
    {
      body,
      conversationId: world.messages[subject].messageId,
      senderId: person(world, senderName).personId
    }
  );

  return result.messageId;
}

function followFixture(world, personName, subject) {
  const result = serverCommands.runCommand(
    `
case Memba.Messaging.follow_conversation_as_current_member(
       %{
         club_id: Map.fetch!(payload, "clubId"),
         conversation_id: Map.fetch!(payload, "conversationId"),
         member_id: Map.fetch!(payload, "memberId")
       },
       consistency: :strong
     ) do
  :ok -> %{status: "ok"}
  {:error, reason} -> raise "Could not follow conversation: #{inspect(reason)}"
end
`,
    {
      clubId: club(world).clubId,
      conversationId: world.messages[subject].messageId,
      memberId: person(world, personName).personId
    }
  );

  assert.deepEqual(result, { status: "ok" });
}

function createFutureMessagesAndReplies(world) {
  return [
    [boardName, boardSubject, "Future Board conversation"],
    [tripsName, tripsSubject, "Future Trips conversation"]
  ].flatMap(([groupName, existingSubject, futureSubject]) => {
    const root = serverCommands.sendClubMessage({
      audienceGroupId: groupId(world, groupName),
      body: `${futureSubject} details.`,
      clubId: club(world).clubId,
      senderId: person(world, "Alice").personId,
      senderName: "Alice",
      subject: futureSubject
    });
    const replyId = createReplyFixture(
      world,
      existingSubject,
      "Alice",
      `Future reply in ${groupName}`
    );

    return [root.messageId, replyId];
  });
}

function lifecycleState(world) {
  const payload = {
    boardGroupId: groupId(world, boardName),
    boardMessageId: world.messages[boardSubject].messageId,
    clubId: club(world).clubId,
    personId: person(world, "Carol").personId,
    tripsGroupId: groupId(world, tripsName),
    tripsMessageId: world.messages[tripsSubject].messageId
  };

  return serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
person_id = Map.fetch!(payload, "personId")
everyone_group_id = Memba.Membership.SystemGroups.everyone_group_id(club_id)

discoverable_group_ids =
  club_id
  |> Memba.Membership.list_discoverable_groups_for_member(person_id)
  |> Enum.map(& &1.group_id)

group_state = fn group_id ->
  %{
    activeMember: Memba.Membership.active_member_of_group?(group_id, person_id),
    discoverable: group_id in discoverable_group_ids,
    groupId: group_id
  }
end

conversation_state = fn message_id, group_id ->
  %{
    following: Memba.Messaging.following_conversation?(message_id, person_id),
    groupId: group_id,
    read:
      Memba.Messaging.member_has_conversation_access?(
        message_id,
        club_id,
        person_id,
        :read
      ),
    write:
      Memba.Messaging.member_has_conversation_access?(
        message_id,
        club_id,
        person_id,
        :write
      )
  }
end

%{
  activeClubMember: Memba.Membership.active_member_of_club?(club_id, person_id),
  everyoneMember: Memba.Membership.active_member_of_group?(everyone_group_id, person_id),
  groups: %{
    Board: group_state.(Map.fetch!(payload, "boardGroupId")),
    Trips: group_state.(Map.fetch!(payload, "tripsGroupId"))
  },
  conversations: %{
    "September agenda" =>
      conversation_state.(
        Map.fetch!(payload, "boardMessageId"),
        Map.fetch!(payload, "boardGroupId")
      ),
    "Trips planning" =>
      conversation_state.(
        Map.fetch!(payload, "tripsMessageId"),
        Map.fetch!(payload, "tripsGroupId")
      )
  }
}
`,
    payload
  );
}

function groupId(world, groupName) {
  const value = world.groups && world.groups[`${kootenayClubName}:${groupName}`];
  assert.ok(value, `Expected ${groupName} custom group`);
  return value;
}

function club(world) {
  const value = world.clubs && world.clubs[kootenayClubName];
  assert.ok(value, `Expected ${kootenayClubName}`);
  return value;
}

function person(world, personName) {
  const value = world.people && world.people[personName];
  assert.ok(value, `Expected person ${personName}`);
  return value;
}

module.exports = {
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
};
