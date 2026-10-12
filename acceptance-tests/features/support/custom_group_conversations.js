const assert = require("node:assert/strict");
const { expect } = require("@playwright/test");
const {
  clubSiteUrl,
  ensureState,
  kootenayClubName,
  testLocalDeliveryFacts,
  waitForLiveViewConnected
} = require("./member_message");
const { withMemberHarness } = require("./member_harness");
const {
  ensureClubAdmins,
  ensureClubWithSlug,
  ensureCustomGroup,
  ensureOrdinaryClubMembers,
  kootenayClubName: customGroupKootenayClubName
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

async function openBoardConversation(world) {
  const subject = world.lastMessageSubject;
  const message = subject && world.messages && world.messages[subject];
  assert.ok(message, "Expected a Board conversation to exist before opening it");

  await withMemberHarness(world, "Carol", async (member) => {
    const url = clubSiteUrl(
      member.baseUrl,
      club(world),
      `/messages/${encodeURIComponent(message.messageId)}?group_id=${encodeURIComponent(boardId(world))}`
    );
    const response = await member.page.goto(url);
    assert.equal(response && response.status(), 200);
    await waitForLiveViewConnected(member);
    await expect(member.page.getByRole("heading", { name: message.subject, exact: true })).toBeVisible();
  });
}

function assertBoardAddress(world, expectedAddress) {
  const result = serverCommands.runCommand(
    `
group = Memba.Membership.ClubGroupQueries.get_group(Map.fetch!(payload, "groupId"))
club = Memba.Membership.ClubGroupQueries.get_club(Map.fetch!(payload, "clubId"))

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
  |> Memba.Messaging.ConversationListing.list_for_group()
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

function messageRecipientIds(world, subject) {
  return serverCommands.runCommand(
    `
%{
  recipientIds:
    Map.fetch!(payload, "messageId")
    |> Memba.Messaging.DeliveryQueries.list_recipient_deliveries()
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
    Memba.Messaging.ConversationGroupAccessQueries.member_has_conversation_access?(
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
  assertBoardAddress,
  assertBoardConversation,
  assertMembersCannotReadOrReceiveLastConversation,
  ensureBoardMembers,
  ensureConversationBackground,
  openBoardConversation,
  sendBoardConversationOnWebsite,
  startBoardConversationFixture
};
