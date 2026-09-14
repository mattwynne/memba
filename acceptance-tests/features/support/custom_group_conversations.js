const assert = require("node:assert/strict");
const { expect } = require("@playwright/test");
const {
  assertEachAddressedMemberReceivedEmailInTestMailbox,
  assertInboundRejectionEmail,
  assertReplyEmailDeliveredToMembers,
  clubSiteUrl,
  emailFor,
  ensureState,
  followConversation,
  kootenayClubName,
  openMemberMessage,
  postMemberReply,
  recordAcceptedInboundRootMessage,
  removeMemberFromClub,
  sendInboundClubEmailReply,
  testLocalDeliveryFacts,
  unfollowConversation,
  waitForLiveViewConnected
} = require("./member_message");
const { withMemberHarness } = require("./member_harness");
const {
  ensureClubAdmins,
  ensureClubWithSlug,
  ensureCustomGroup,
  ensureOrdinaryClubMembers,
  kootenayClubName: customGroupKootenayClubName,
  nelsonClubName
} = require("./custom_group_creation");
const serverCommands = require("./server_commands");

const boardName = "Board";
const boardAddress = "board@kmc.clubs.memba.io";

assert.equal(customGroupKootenayClubName, kootenayClubName);

function ensureConversationBackground(world) {
  ensureState(world);
  ensureClubWithSlug(world, kootenayClubName, "kmc");
  ensureClubAdmins(world, ["Alice", "Dan"]);
  ensureOrdinaryClubMembers(world, ["Bob", "Carol", "Eve"]);
}

function ensureBoardMembers(world) {
  return ensureCustomGroup(
    world,
    kootenayClubName,
    boardName,
    "board",
    ["Alice", "Bob", "Carol"]
  );
}

function assertBoardAddress(world, expectedAddress) {
  const result = serverCommands.runCommand(
    `
group = Memba.Membership.get_group(Map.fetch!(payload, "groupId"))
club = Memba.Membership.get_club(Map.fetch!(payload, "clubId"))

%{
  address: Memba.ClubInboundEmailAddress.address(club, group.email_slug),
  emailSlug: group.email_slug
}
`,
    {
      clubId: club(world).clubId,
      groupId: boardId(world)
    }
  );

  assert.equal(result.emailSlug, "board");
  assert.equal(result.address, expectedAddress);
}

async function sendBoardConversationOnWebsite(world, senderName, subject) {
  const groupId = boardId(world);
  const clubState = club(world);
  const body = `${subject} details.`;

  await withMemberHarness(world, senderName, async (member) => {
    member.localDeliveryFactsBeforeSend = await testLocalDeliveryFacts(member);

    await member.page.goto(
      clubSiteUrl(member.baseUrl, clubState, `/groups/${encodeURIComponent(groupId)}`)
    );
    await expect(member.page.locator("#member-group-name")).toHaveText(boardName);
    await waitForLiveViewConnected(member);

    await member.page.locator("#member-section-action-new-message").click();

    const compose = member.page.locator("#member-message-compose");
    await expect(compose).toHaveAttribute("data-audience-group-id", groupId);
    await expect(compose).toHaveAttribute("data-compose-state", "composing");
    await waitForLiveViewConnected(member);

    await member.page.getByLabel("Subject").fill(subject);
    await member.page.getByLabel("Message").fill(body);
    await member.page.getByRole("button", { name: "Send message" }).click();
    await expect(compose).toHaveAttribute("data-compose-state", "sent");

    const messageId = await compose.getAttribute("data-sent-message-id");
    assert.ok(messageId, `Expected ${JSON.stringify(subject)} to expose a message id`);

    member.messages[subject] = {
      body,
      clubId: clubState.clubId,
      clubSlug: clubState.slug,
      messageId,
      senderName,
      subject
    };
    member.lastMessageSubject = subject;
  });
}

async function assertBoardConversation(world, subject) {
  const message = await ensureMessage(world, subject);
  const snapshot = conversationSnapshot(world, subject);

  assert.equal(snapshot.groupId, boardId(world));
  assert.equal(snapshot.messageId, message.messageId);

  await withMemberHarness(world, "Alice", async (member) => {
    await openBoard(member);
    await expect(conversationRow(member, subject)).toBeVisible();
  });
}

async function assertMembersCanReadLastConversation(world, personNames) {
  const subject = lastSubject(world);
  const message = await ensureMessage(world, subject);

  for (const personName of personNames) {
    assert.equal(memberHasAccess(world, personName, subject, "read"), true);

    await withMemberHarness(world, personName, async (member) => {
      const response = await member.page.goto(messageUrl(member, message));
      assert.equal(response && response.status(), 200);
      await expect(member.page.getByRole("heading", { name: subject })).toBeVisible();
    });
  }
}

async function assertInitialEmailRecipients(world, personNames) {
  await ensureMessage(world, lastSubject(world));
  world.addressedMemberNames = personNames;
  await assertEachAddressedMemberReceivedEmailInTestMailbox(world);
}

async function assertMembersCannotReadOrReceiveLastConversation(world, personNames) {
  const subject = lastSubject(world);
  const message = await ensureMessage(world, subject);

  for (const personName of personNames) {
    assert.equal(memberHasAccess(world, personName, subject, "read"), false);
    assert.equal(messageRecipientIds(world, subject).includes(person(world, personName).personId), false);

    await withMemberHarness(world, personName, async (member) => {
      const response = await member.page.goto(messageUrl(member, message));
      assert.equal(response && response.status(), 404);
      await expect(member.page.getByText(subject, { exact: true })).toHaveCount(0);
    });
  }

  const facts = await testLocalDeliveryFacts(world);
  const messageFacts = facts.filter((fact) => fact.message_id === message.messageId);

  for (const personName of personNames) {
    assert.equal(
      messageFacts.some((fact) => fact.recipient_id === person(world, personName).personId),
      false
    );
  }
}

async function assertAbsentFromEveryone(world) {
  const subject = lastSubject(world);
  const everyoneId = serverCommands.runCommand(
    `
%{groupId: Memba.Membership.SystemGroups.everyone_group_id(Map.fetch!(payload, "clubId"))}
`,
    { clubId: club(world).clubId }
  ).groupId;

  assert.equal(groupConversationSubjects(everyoneId).includes(subject), false);

  await withMemberHarness(world, "Alice", async (member) => {
    await member.page.goto(
      clubSiteUrl(member.baseUrl, club(world), `/groups/${encodeURIComponent(everyoneId)}`)
    );
    await expect(conversationRow(member, subject)).toHaveCount(0);
  });
}

async function assertNoInitialEmailOrFollow(world, personName) {
  const subject = lastSubject(world);
  const message = await ensureMessage(world, subject);
  const personId = person(world, personName).personId;

  assert.equal(messageRecipientIds(world, subject).includes(personId), false);
  assert.equal(following(world, personName, subject), false);

  const facts = await testLocalDeliveryFacts(world);
  assert.equal(
    facts.some(
      (fact) => fact.message_id === message.messageId && fact.recipient_id === personId
    ),
    false
  );
}

function assertNoBoardMembershipOrConversationAccess(world, personName) {
  assert.equal(activeBoardMember(world, personName), false);
  assert.equal(memberHasAccess(world, personName, lastSubject(world), "read"), false);
  assert.equal(memberHasAccess(world, personName, lastSubject(world), "write"), false);
}

function assertFollowing(world, personName, subject) {
  assert.equal(following(world, personName, subject), true);
}

function ensureOtherClubMember(world, personName) {
  ensureClubWithSlug(world, nelsonClubName, "nelson");
  ensureOrdinaryClubMembers(world, [personName], nelsonClubName);
}

function ensurePersonWithoutMembership(world, personName) {
  ensureState(world);
  const created = serverCommands.ensurePerson({
    personName,
    email: emailFor(personName)
  });

  world.people[personName] = {
    email: emailFor(personName),
    emailAddresses: [emailFor(personName)],
    name: personName,
    personId: created.personId
  };
}

function endKootenayMembership(world, personName) {
  removeMemberFromClub(world, personName, kootenayClubName);
}

function assertNoBoardConversation(world, subject) {
  assert.equal(groupConversationSubjects(boardId(world)).includes(subject), false);
}

async function assertMessageNotPostedRejection(world, personName) {
  await assertInboundRejectionEmail(world, personName, "wasn't posted");
}

async function tryReplyWithoutBoardAccess(world, personName, body, channel) {
  const subject = lastSubject(world);
  const message = await ensureMessage(world, subject);
  const countBefore = conversationMessageBodies(message.messageId).length;

  if (channel === "on the website") {
    await withMemberHarness(world, personName, async (member) => {
      const response = await member.page.goto(messageUrl(member, message));
      assert.equal(response && response.status(), 404);
      await expect(member.page.locator("#member-message-reply-form")).toHaveCount(0);
    });
  } else {
    assert.equal(channel, "by email");

    await sendInboundClubEmailReply(world, personName, subject, body, {
      requireReply: false,
      toAddress: boardAddress
    });
  }

  world.lastMessageSubject = subject;
  world.customGroupReplyAttempt = {
    body,
    countBefore,
    messageId: message.messageId,
    personName
  };
}

function assertReplyNotAdded(world, body) {
  const attempt = world.customGroupReplyAttempt;
  assert.ok(attempt, "Expected an attempted Board reply");

  const bodies = conversationMessageBodies(attempt.messageId);
  assert.equal(bodies.length, attempt.countBefore);
  assert.equal(bodies.includes(body), false);
}

function assertNoConversationAccess(world, personName) {
  const subject = lastSubject(world);
  assert.equal(memberHasAccess(world, personName, subject, "read"), false);
  assert.equal(memberHasAccess(world, personName, subject, "write"), false);
}

async function replyToBoardByEmail(world, personName, body, subject) {
  await sendInboundClubEmailReply(world, personName, subject, body, {
    requireReply: true,
    toAddress: boardAddress
  });
  world.lastMessageSubject = subject;
}

async function assertBoardReply(world, body, subject) {
  const message = await ensureMessage(world, subject);
  const replies = boardConversationEntries(world, message.messageId);
  assert.equal(replies.some((entry) => entry.body === body && entry.replyToMessageId), true);

  await withMemberHarness(world, "Carol", async (member) => {
    await member.page.goto(messageUrl(member, message));
    await expect(
      member.page.locator(
        '#member-conversation-replies [data-testid="member-conversation-entry"]',
        { hasText: body }
      )
    ).toBeVisible();
  });
}

function assertFollowingLastConversation(world, personName) {
  assertFollowing(world, personName, lastSubject(world));
}

async function assertReplyDelivered(world, recipientName, senderName) {
  await assertReplyEmailDeliveredToMembers(world, senderName, [recipientName], boardName);
}

async function assertReplyNotDelivered(world, personNames) {
  const reply = world.lastReply;
  assert.ok(reply, "Expected a reply before asserting excluded recipients");

  serverCommands.dispatchPendingEmailDeliveries();
  const facts = serverCommands
    .listLocalDeliveryFacts()
    .filter((fact) => fact.message_id === reply.messageId);

  for (const personName of personNames) {
    assert.equal(
      facts.some((fact) => fact.recipient_id === person(world, personName).personId),
      false
    );
  }
}

function startBoardConversationFixture(world, senderName, subject) {
  const sender = person(world, senderName);
  const result = serverCommands.sendClubMessage({
    audienceGroupId: boardId(world),
    body: `${subject} details.`,
    clubId: club(world).clubId,
    senderId: sender.personId,
    senderName,
    subject
  });

  world.messages[subject] = {
    body: result.body,
    clubId: result.clubId,
    clubSlug: club(world).slug,
    messageId: result.messageId,
    senderName,
    subject
  };
  world.lastMessageSubject = subject;
  serverCommands.dispatchPendingEmailDeliveries();
}

async function followBoardConversation(world, personName, subject) {
  await withMemberHarness(world, personName, (member) =>
    followConversation(member, personName, subject)
  );
}

async function doNotFollowBoardConversation(world, personName, subject) {
  if (!following(world, personName, subject)) {
    return;
  }

  await withMemberHarness(world, personName, (member) =>
    unfollowConversation(member, personName, subject)
  );
}

async function stopFollowingBoardConversation(world, personName, subject) {
  await withMemberHarness(world, personName, (member) =>
    unfollowConversation(member, personName, subject)
  );
}

async function replyOnWebsite(world, personName, body, subject) {
  await withMemberHarness(world, personName, (member) =>
    postMemberReply(member, personName, subject, body)
  );
  world.lastMessageSubject = subject;
}

async function assertCanReadWholeConversation(world, personName) {
  const subject = lastSubject(world);
  const message = await ensureMessage(world, subject);
  const entries = boardConversationEntries(world, message.messageId);

  assert.equal(memberHasAccess(world, personName, subject, "read"), true);
  assert.ok(entries.length >= 2, "Expected the root message and reply");

  await withMemberHarness(world, personName, async (member) => {
    await openMemberMessage(member, subject);

    for (const entry of entries) {
      await expect(member.page.getByText(entry.body, { exact: true })).toBeVisible();
    }
  });
}

async function ensureMessage(world, subject) {
  if (!world.messages[subject]) {
    await recordAcceptedInboundRootMessage(world, subject);
  }

  world.lastMessageSubject = subject;
  return world.messages[subject];
}

async function openBoard(world) {
  await world.page.goto(
    clubSiteUrl(world.baseUrl, club(world), `/groups/${encodeURIComponent(boardId(world))}`)
  );
  await expect(world.page.locator("#member-group-name")).toHaveText(boardName);
}

function conversationSnapshot(world, subject) {
  return serverCommands.runCommand(
    `
group_id = Map.fetch!(payload, "groupId")
subject = Map.fetch!(payload, "subject")

message =
  group_id
  |> Memba.Messaging.list_conversations_for_group()
  |> Enum.find(&(&1.subject == subject))

if message do
  %{groupId: group_id, messageId: message.message_id, subject: message.subject}
else
  %{groupId: group_id, messageId: nil, subject: nil}
end
`,
    { groupId: boardId(world), subject }
  );
}

function groupConversationSubjects(groupId) {
  return serverCommands.runCommand(
    `
%{
  subjects:
    Map.fetch!(payload, "groupId")
    |> Memba.Messaging.list_conversations_for_group()
    |> Enum.map(& &1.subject)
}
`,
    { groupId }
  ).subjects;
}

function boardConversationEntries(world, messageId) {
  return serverCommands.runCommand(
    `
entries =
  Memba.Messaging.list_conversation_messages_for_group(
    Map.fetch!(payload, "messageId"),
    Map.fetch!(payload, "groupId")
  )

%{
  entries:
    Enum.map(entries, fn entry ->
      %{
        body: entry.body,
        messageId: entry.message_id,
        replyToMessageId: entry.reply_to_message_id
      }
    end)
}
`,
    { groupId: boardId(world), messageId }
  ).entries;
}

function conversationMessageBodies(messageId) {
  return serverCommands.runCommand(
    `
%{
  bodies:
    Map.fetch!(payload, "messageId")
    |> Memba.Messaging.list_conversation_messages()
    |> Enum.map(& &1.body)
}
`,
    { messageId }
  ).bodies;
}

function messageRecipientIds(world, subject) {
  return serverCommands.runCommand(
    `
%{
  recipientIds:
    Map.fetch!(payload, "messageId")
    |> Memba.Messaging.list_recipient_deliveries()
    |> Enum.map(& &1.recipient_id)
}
`,
    { messageId: world.messages[subject].messageId }
  ).recipientIds;
}

function memberHasAccess(world, personName, subject, accessLevel) {
  const message = world.messages[subject];

  return serverCommands.runCommand(
    `
%{
  allowed:
    Memba.Messaging.member_has_conversation_access?(
      Map.fetch!(payload, "messageId"),
      Map.fetch!(payload, "clubId"),
      Map.fetch!(payload, "personId"),
      Map.fetch!(payload, "accessLevel")
    )
}
`,
    {
      accessLevel,
      clubId: message.clubId,
      messageId: message.messageId,
      personId: person(world, personName).personId
    }
  ).allowed;
}

function activeBoardMember(world, personName) {
  return serverCommands.runCommand(
    `
%{
  active:
    Memba.Membership.active_member_of_group?(
      Map.fetch!(payload, "groupId"),
      Map.fetch!(payload, "personId")
    )
}
`,
    {
      groupId: boardId(world),
      personId: person(world, personName).personId
    }
  ).active;
}

function following(world, personName, subject) {
  return serverCommands.runCommand(
    `
%{
  following:
    Memba.Messaging.following_conversation?(
      Map.fetch!(payload, "conversationId"),
      Map.fetch!(payload, "personId")
    )
}
`,
    {
      conversationId: world.messages[subject].messageId,
      personId: person(world, personName).personId
    }
  ).following;
}

function messageUrl(world, message) {
  return clubSiteUrl(
    world.baseUrl,
    club(world),
    `/messages/${encodeURIComponent(message.messageId)}?group_id=${encodeURIComponent(
      boardId(world)
    )}`
  );
}

function conversationRow(world, subject) {
  return world.page.locator(
    `[data-testid="club-message-row"][data-message-subject="${subject}"]`
  );
}

function boardId(world) {
  const groupId = world.groups && world.groups[`${kootenayClubName}:${boardName}`];
  assert.ok(groupId, "Expected the Board custom group");
  return groupId;
}

function club(world) {
  const clubState = world.clubs && world.clubs[kootenayClubName];
  assert.ok(clubState, `Expected ${kootenayClubName}`);
  return clubState;
}

function person(world, personName) {
  const personState = world.people && world.people[personName];
  assert.ok(personState, `Expected person ${personName}`);
  return personState;
}

function lastSubject(world) {
  const subject = world.lastMessageSubject;
  assert.ok(subject, "Expected a current Board conversation");
  return subject;
}

module.exports = {
  assertAbsentFromEveryone,
  assertBoardAddress,
  assertBoardConversation,
  assertBoardReply,
  assertCanReadWholeConversation,
  assertFollowing,
  assertFollowingLastConversation,
  assertInitialEmailRecipients,
  assertMembersCanReadLastConversation,
  assertMembersCannotReadOrReceiveLastConversation,
  assertMessageNotPostedRejection,
  assertNoBoardConversation,
  assertNoBoardMembershipOrConversationAccess,
  assertNoConversationAccess,
  assertNoInitialEmailOrFollow,
  assertReplyDelivered,
  assertReplyNotAdded,
  assertReplyNotDelivered,
  doNotFollowBoardConversation,
  endKootenayMembership,
  ensureBoardMembers,
  ensureConversationBackground,
  ensureOtherClubMember,
  ensurePersonWithoutMembership,
  followBoardConversation,
  replyOnWebsite,
  replyToBoardByEmail,
  sendBoardConversationOnWebsite,
  startBoardConversationFixture,
  stopFollowingBoardConversation,
  tryReplyWithoutBoardAccess
};
