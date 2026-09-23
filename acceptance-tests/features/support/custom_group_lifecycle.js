const assert = require("node:assert/strict");
const { expect } = require("@playwright/test");
const {
  assertInboundRejectionEmail,
  clubSiteUrl,
  removeMemberFromClub,
  waitForLiveViewConnected
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

function addCarolToBoard(world) {
  addCustomGroupMember(world, kootenayClubName, boardName, "Carol");
}

function followBoardConversation(world) {
  followFixture(world, "Carol", boardSubject);
}

async function openBoardConversation(world) {
  await withMemberHarness(world, "Carol", async (member) => {
    const response = await member.page.goto(messageUrl(member, world, boardSubject));
    assert.equal(response && response.status(), 200);
    await waitForLiveViewConnected(member);
    await expect(member.page.getByRole("heading", { name: boardSubject })).toBeVisible();
  });
}

function removeCarolFromBoard(world, actorName) {
  removeBoardMember(world, actorName, "Carol");
}

function removeBoardMember(world, actorName, targetName) {
  const result = serverCommands.runCommand(
    `
case Memba.Membership.remove_custom_group_member(
       %{
         removal_operation_id: Ecto.UUID.generate(),
         club_id: Map.fetch!(payload, "clubId"),
         group_id: Map.fetch!(payload, "groupId"),
         membership_id: Map.fetch!(payload, "membershipId"),
         person_id: Map.fetch!(payload, "personId"),
         actor_person_id: Map.fetch!(payload, "actorPersonId")
       },
       consistency: :strong
     ) do
  :ok -> %{status: "ok"}
  {:ok, _outcome} -> %{status: "ok"}
  {:error, reason} -> raise "Could not remove custom-group member: #{inspect(reason)}"
end
`,
    {
      actorPersonId: person(world, actorName).personId,
      clubId: club(world).clubId,
      groupId: groupId(world, boardName),
      membershipId: world.memberships[`${kootenayClubName}:${targetName}`].membershipId,
      personId: person(world, targetName).personId
    }
  );

  assert.equal(result.status, "ok");
}

async function assertCarolLostBoardAccess(world) {
  const state = boardConversationState(world, "Carol", boardSubject);
  assert.equal(state.activeMember, false);
  assert.equal(state.read, false);
  assert.equal(state.write, false);

  await withMemberHarness(world, "Carol", async (member) => {
    await expect(member.page.getByRole("heading", { name: boardSubject })).toHaveCount(0);
    const response = await member.page.goto(messageUrl(member, world, boardSubject));
    assert.ok(response && [403, 404].includes(response.status()));
    await expect(member.page.getByRole("heading", { name: boardSubject })).toHaveCount(0);
  });
}

function assertCarolStaleActionsRejected(world) {
  const result = serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
conversation_id = Map.fetch!(payload, "conversationId")
person_id = Map.fetch!(payload, "personId")
group_id = Map.fetch!(payload, "groupId")

post_result =
  Memba.Messaging.send_club_message_as_current_member(
    %{
      message_id: Memba.ID.generate(:message),
      club_id: club_id,
      sender_id: person_id,
      audience_group_id: group_id,
      subject: "Stale Board post",
      body: "This must not be posted."
    },
    consistency: :strong
  )

reply_result =
  Memba.Messaging.post_message_reply(
    %{
      message_id: Memba.ID.generate(:message),
      conversation_id: conversation_id,
      sender_id: person_id,
      body: "Stale web reply"
    },
    consistency: :strong
  )

follow_result =
  Memba.Messaging.follow_conversation_as_current_member(
    %{club_id: club_id, conversation_id: conversation_id, member_id: person_id},
    consistency: :strong
  )

%{
  postRejected: match?({:error, _}, post_result),
  replyRejected: match?({:error, _}, reply_result),
  followRejected: match?({:error, _}, follow_result)
}
`,
    {
      clubId: club(world).clubId,
      conversationId: world.messages[boardSubject].messageId,
      groupId: groupId(world, boardName),
      personId: person(world, "Carol").personId
    }
  );

  assert.deepEqual(result, {
    followRejected: true,
    postRejected: true,
    replyRejected: true
  });
  world.staleActionsRejected = true;
}

function attemptCarolEmailReply(world) {
  const before = conversationEntryCount(world, boardSubject);
  const result = serverCommands.runCommand(
    `
result =
  Memba.Messaging.post_message_reply(
    %{
      message_id: Memba.ID.generate(:message),
      conversation_id: Map.fetch!(payload, "conversationId"),
      sender_id: Map.fetch!(payload, "personId"),
      body: "Rejected email reply"
    },
    consistency: :strong
  )

%{rejected: match?({:error, _}, result)}
`,
    {
      conversationId: world.messages[boardSubject].messageId,
      personId: person(world, "Carol").personId
    }
  );

  assert.equal(result.rejected, true);
  assert.equal(conversationEntryCount(world, boardSubject), before);
  world.emailReplyRejected = true;
}

function assertUsualStaleAuthorization(world) {
  assert.equal(world.staleActionsRejected, true);
  assert.equal(world.emailReplyRejected, true);
}

function assertCarolStillActiveAndBoardListed(world) {
  const state = serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
person_id = Map.fetch!(payload, "personId")
group_id = Map.fetch!(payload, "groupId")
%{
  activeClubMember: Memba.Membership.active_member_of_club?(club_id, person_id),
  boardListed: group_id in (Memba.Membership.list_discoverable_groups_for_member(club_id, person_id) |> Enum.map(& &1.group_id))
}
`,
    {
      clubId: club(world).clubId,
      groupId: groupId(world, boardName),
      personId: person(world, "Carol").personId
    }
  );
  assert.equal(state.activeClubMember, true);
  assert.equal(state.boardListed, true);
}

function postBoardReply(world, body) {
  const messageId = createReplyFixture(world, boardSubject, "Bob", body);
  world.messages[body] = { messageId, subject: body };
  world.lastLifecycleMessageId = messageId;
  return messageId;
}

function startBoardConversation(world, subject) {
  const result = serverCommands.sendClubMessage({
    audienceGroupId: groupId(world, boardName),
    body: `${subject} details.`,
    clubId: club(world).clubId,
    senderId: person(world, "Bob").personId,
    senderName: "Bob",
    subject
  });
  world.messages[subject] = result;
  world.lastLifecycleMessageId = result.messageId;
  return result.messageId;
}

function assertNoCarolDeliveries(world, labels) {
  const carolId = person(world, "Carol").personId;
  for (const label of labels) {
    const messageId = lifecycleMessageId(world, label);
    assert.equal(
      serverCommands
        .runCommand(
          `%{recipientIds: Memba.Messaging.list_recipient_deliveries(Map.fetch!(payload, "messageId")) |> Enum.map(& &1.recipient_id)}`,
          { messageId }
        )
        .recipientIds.includes(carolId),
      false
    );
  }
}

function markCarolDeliveryQueued(world, label) {
  const messageId = lifecycleMessageId(world, label);
  assert.equal(recipientDeliveryState(messageId, person(world, "Carol").personId).exists, true);
  world.queuedLifecycleMessageId = messageId;
}

function assertCarolReceivesLifecycleEmail(world, label) {
  const messageId = lifecycleMessageId(world, label);
  serverCommands.dispatchPendingEmailDeliveries();
  const carolId = person(world, "Carol").personId;
  assert.equal(
    serverCommands.listLocalDeliveryFacts().some(
      (delivery) => delivery.message_id === messageId && delivery.recipient_id === carolId
    ),
    true
  );
}

function assertConversationLinkDenied(world) {
  return assertCarolLostBoardAccess(world);
}

function assertDeliveredCopyPreserved(world, label) {
  const messageId = world.messages[label].messageId;
  const state = recipientDeliveryState(messageId, person(world, "Carol").personId);
  assert.equal(state.exists, true);
  assert.equal(state.status, "sent");
}

function assertCarolStillFollowingBoard(world) {
  assert.equal(boardConversationState(world, "Carol", boardSubject).following, true);
}

function assertFollowDoesNotGrantAccess(world) {
  const state = boardConversationState(world, "Carol", boardSubject);
  assert.equal(state.following, true);
  assert.equal(state.read, false);
}

function assertNoCarolEmailOrBacklog(world, label) {
  assertNoCarolDeliveries(world, [label]);
}

async function assertCarolCanReadBoardMessage(world, label) {
  const state = boardConversationState(world, "Carol", boardSubject);
  assert.equal(state.read, true);
  const body = label === boardSubject ? `${label} details.` : label;
  await withMemberHarness(world, "Carol", async (member) => {
    await member.page.goto(messageUrl(member, world, boardSubject));
    await waitForLiveViewConnected(member);
    await expect(member.page.getByText(body, { exact: true })).toBeVisible();
  });
}

function makeBobOnlyBoardMember(world) {
  removeBoardMember(world, "Bob", "Alice");
  if (MembershipState(world, "Carol")) removeBoardMember(world, "Bob", "Carol");
}

function emptyBoard(world) {
  for (const name of ["Alice", "Bob", "Carol"]) {
    if (MembershipState(world, name)) removeBoardMember(world, "Alice", name);
  }
}

function assertBoardMembers(world, expectedNames) {
  const names = serverCommands.runCommand(
    `%{names: Memba.Membership.list_active_members_of_group(Map.fetch!(payload, "groupId")) |> Enum.map(& &1.name) |> Enum.sort()}`,
    { groupId: groupId(world, boardName) }
  ).names;
  assert.deepEqual(names, [...expectedNames].sort());
}

function assertBoardUnchangedAndListed(world) {
  const state = serverCommands.runCommand(
    `
group = Memba.Membership.get_group(Map.fetch!(payload, "groupId"))
club_id = Map.fetch!(payload, "clubId")
%{
  discoverable: Map.fetch!(payload, "groupId") in (Memba.Membership.list_discoverable_groups_for_member(club_id, Map.fetch!(payload, "personId")) |> Enum.map(& &1.group_id)),
  name: group.name,
  emailSlug: group.email_slug,
  conversationSubjects: Memba.Messaging.list_conversations_for_group(group.group_id) |> Enum.map(& &1.subject)
}
`,
    {
      clubId: club(world).clubId,
      groupId: groupId(world, boardName),
      personId: person(world, "Eve").personId
    }
  );
  assert.equal(state.discoverable, true);
  assert.equal(state.name, boardName);
  assert.equal(state.emailSlug, "board");
  assert.ok(state.conversationSubjects.includes(boardSubject));
}

function assertBoardNotArchived(world) {
  assert.ok(serverCommands.runCommand(
    `%{exists: not is_nil(Memba.Membership.get_group(Map.fetch!(payload, "groupId")))}`,
    { groupId: groupId(world, boardName) }
  ).exists);
}

function assertNoBoardConversation(world, subject) {
  const subjects = serverCommands.runCommand(
    `%{subjects: Memba.Messaging.list_conversations_for_group(Map.fetch!(payload, "groupId")) |> Enum.map(& &1.subject)}`,
    { groupId: groupId(world, boardName) }
  ).subjects;
  assert.equal(subjects.includes(subject), false);
}

async function assertEveAuthorizationRejection(world) {
  await assertInboundRejectionEmail(world, "Eve", "wasn't posted");
}

function assertNoRecipientForRejectedInbound(world, subject) {
  assertNoBoardConversation(world, subject);
}

function MembershipState(world, personName) {
  return serverCommands.runCommand(
    `%{active: Memba.Membership.active_member_of_group?(Map.fetch!(payload, "groupId"), Map.fetch!(payload, "personId"))}`,
    { groupId: groupId(world, boardName), personId: person(world, personName).personId }
  ).active;
}

function boardConversationState(world, personName, subject) {
  const message = world.messages[subject];
  return serverCommands.runCommand(
    `
message_id = Map.fetch!(payload, "messageId")
person_id = Map.fetch!(payload, "personId")
club_id = Map.fetch!(payload, "clubId")
%{
  activeMember: Memba.Membership.active_member_of_group?(Map.fetch!(payload, "groupId"), person_id),
  following: Memba.Messaging.following_conversation?(message_id, person_id),
  read: Memba.Messaging.member_has_conversation_access?(message_id, club_id, person_id, :read),
  write: Memba.Messaging.member_has_conversation_access?(message_id, club_id, person_id, :write)
}
`,
    {
      clubId: club(world).clubId,
      groupId: groupId(world, boardName),
      messageId: message.messageId,
      personId: person(world, personName).personId
    }
  );
}

function recipientDeliveryState(messageId, recipientId) {
  return serverCommands.runCommand(
    `
delivery = Memba.Messaging.list_recipient_deliveries(Map.fetch!(payload, "messageId")) |> Enum.find(&(&1.recipient_id == Map.fetch!(payload, "recipientId")))
%{exists: not is_nil(delivery), status: if(delivery, do: to_string(delivery.status), else: nil)}
`,
    { messageId, recipientId }
  );
}

function lifecycleMessageId(world, label) {
  if (world.messages[label] && world.messages[label].messageId) {
    return world.messages[label].messageId;
  }

  if (world.lastReply && world.lastReply.body === label) {
    return world.lastReply.messageId;
  }

  throw new Error(`Expected lifecycle message ${JSON.stringify(label)}`);
}

function conversationEntryCount(world, subject) {
  return serverCommands.runCommand(
    `%{count: Memba.Messaging.list_conversation_messages(Map.fetch!(payload, "messageId")) |> Enum.count()}`,
    { messageId: world.messages[subject].messageId }
  ).count;
}

function messageUrl(member, world, subject) {
  return clubSiteUrl(
    member.baseUrl,
    club(world),
    `/messages/${encodeURIComponent(world.messages[subject].messageId)}?group_id=${encodeURIComponent(groupId(world, boardName))}`
  );
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
  addCarolToBoard,
  addCarolToLifecycleGroups,
  assertBoardMembers,
  assertBoardNotArchived,
  assertBoardUnchangedAndListed,
  assertCarolCanReadBoardMessage,
  assertCarolCannotAccessLifecycleConversations,
  assertCarolInEveryoneOnly,
  assertCarolLostBoardAccess,
  assertCarolNotFollowingLifecycleConversations,
  assertCarolOutsideLifecycleGroups,
  assertCarolReceivesLifecycleEmail,
  assertCarolStillActiveAndBoardListed,
  assertCarolStillFollowingBoard,
  assertConversationLinkDenied,
  assertDeliveredCopyPreserved,
  assertEveAuthorizationRejection,
  assertFollowDoesNotGrantAccess,
  assertLifecycleAccessGuidance,
  assertNoBoardConversation,
  assertNoCarolDeliveries,
  assertNoCarolEmailOrBacklog,
  assertNoFutureLifecycleEmails,
  assertNoRecipientForRejectedInbound,
  assertUsualStaleAuthorization,
  attemptCarolEmailReply,
  emptyBoard,
  endCarolMembership,
  ensureBoardConversationWithReply,
  ensureLifecycleBoard,
  followBoardConversation,
  followLifecycleConversations,
  makeBobOnlyBoardMember,
  markCarolDeliveryQueued,
  openBoardConversation,
  postBoardReply,
  prepareDepartedCarol,
  reactivateCarol,
  removeBoardMember,
  removeCarolFromBoard,
  startBoardConversation,
  assertCarolStaleActionsRejected
};
