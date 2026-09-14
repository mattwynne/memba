const { Given, When, Then } = require("@cucumber/cucumber");
const {
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
} = require("../support/custom_group_conversations");

Given("Bob, Carol, and Eve are its ordinary active club members", function () {
  ensureConversationBackground(this);
});

Given("Alice, Bob, and Carol are the only members of its custom group Board", function () {
  ensureBoardMembers(this);
});

Given("Board's email address is {string}", function (expectedAddress) {
  assertBoardAddress(this, expectedAddress);
});

When(/^(\w+) sends "([^"]+)" to Board on the website$/, async function (personName, subject) {
  await sendBoardConversationOnWebsite(this, personName, subject);
});

Then(/^"([^"]+)" should be a Board conversation$/, async function (subject) {
  await assertBoardConversation(this, subject);
});

Then(/^(.+) should be able to read it$/, async function (personNamesText) {
  await assertMembersCanReadLastConversation(this, parsePersonList(personNamesText));
});

Then(/^(.+) should each receive its initial email$/, async function (personNamesText) {
  await assertInitialEmailRecipients(this, parsePersonList(personNamesText));
});

Then(
  /^(.+) should neither be able to read it nor receive its email$/,
  async function (personNamesText) {
    await assertMembersCannotReadOrReceiveLastConversation(
      this,
      parsePersonList(personNamesText)
    );
  }
);

Then("it should not appear among Everyone's conversations", async function () {
  await assertAbsentFromEveryone(this);
});

Then(/^Board should have the conversation "([^"]+)"$/, async function (subject) {
  await assertBoardConversation(this, subject);
});

Then(
  /^(\w+) should not receive its initial email or become its follower$/,
  async function (personName) {
    await assertNoInitialEmailOrFollow(this, personName);
  }
);

Then(
  /^(\w+) should neither belong to Board nor gain permission to read or reply to the conversation$/,
  function (personName) {
    assertNoBoardMembershipOrConversationAccess(this, personName);
  }
);

Then(/^(\w+) should be following "([^"]+)"$/, function (personName, subject) {
  assertFollowing(this, personName, subject);
});

Given("Pat belongs to Nelson Paddling Club but not KMC", function () {
  ensureOtherClubMember(this, "Pat");
});

Given("Robin has no club membership", function () {
  ensurePersonWithoutMembership(this, "Robin");
});

Given("Eve is no longer an active member of KMC", function () {
  endKootenayMembership(this, "Eve");
});

Then(/^no Board conversation named "([^"]+)" should be created$/, function (subject) {
  assertNoBoardConversation(this, subject);
});

Then(
  /^(\w+) should receive the existing message-not-posted rejection email$/,
  async function (personName) {
    await assertMessageNotPostedRejection(this, personName);
  }
);

When(
  /^(\w+) tries to reply "([^"]+)" to that conversation (on the website|by email)$/,
  async function (personName, body, channel) {
    await tryReplyWithoutBoardAccess(this, personName, body, channel);
  }
);

Then(/^"([^"]+)" should not be added to that conversation$/, function (body) {
  assertReplyNotAdded(this, body);
});

Then(/^(\w+) should not gain access to that conversation$/, function (personName) {
  assertNoConversationAccess(this, personName);
});

When(
  /^(\w+) replies by email "([^"]+)" to "([^"]+)"$/,
  async function (personName, body, subject) {
    await replyToBoardByEmail(this, personName, body, subject);
  }
);

Then(
  /^"([^"]+)" should be a reply in Board's "([^"]+)" conversation$/,
  async function (body, subject) {
    await assertBoardReply(this, body, subject);
  }
);

Then(/^(\w+) should be following that conversation$/, function (personName) {
  assertFollowingLastConversation(this, personName);
});

Then(
  /^(\w+) should receive (\w+)'s reply by email$/,
  async function (recipientName, senderName) {
    await assertReplyDelivered(this, recipientName, senderName);
  }
);

Then(/^(.+) should not receive it$/, async function (personNamesText) {
  await assertReplyNotDelivered(this, parsePersonList(personNamesText));
});

Given(
  /^(\w+) started Board's conversation "([^"]+)"$/,
  function (personName, subject) {
    startBoardConversationFixture(this, personName, subject);
  }
);

Given(/^(\w+) follows "([^"]+)"$/, async function (personName, subject) {
  await followBoardConversation(this, personName, subject);
});

Given(/^(\w+) does not follow "([^"]+)"$/, async function (personName, subject) {
  await doNotFollowBoardConversation(this, personName, subject);
});

Given(/^(\w+) has stopped following "([^"]+)"$/, async function (personName, subject) {
  await stopFollowingBoardConversation(this, personName, subject);
});

When(
  /^(\w+) replies "([^"]+)" to "([^"]+)" on the website$/,
  async function (personName, body, subject) {
    await replyOnWebsite(this, personName, body, subject);
  }
);

Then(/^(\w+) should still be able to read the whole conversation$/, async function (personName) {
  await assertCanReadWholeConversation(this, personName);
});

function parsePersonList(text) {
  return text
    .replace(/,?\s+and\s+/g, ", ")
    .split(/\s*,\s*/)
    .map((name) => name.trim())
    .filter(Boolean);
}
