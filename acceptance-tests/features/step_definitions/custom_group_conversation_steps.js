const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertBoardAddress,
  assertBoardConversation,
  assertMembersCannotReadOrReceiveLastConversation,
  ensureBoardMembers,
  ensureConversationBackground,
  sendBoardConversationOnWebsite
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

Then(
  /^(.+) should neither be able to read it nor receive its email$/,
  async function (personNamesText) {
    await assertMembersCannotReadOrReceiveLastConversation(
      this,
      parsePersonList(personNamesText)
    );
  }
);

function parsePersonList(text) {
  return text
    .replace(/,?\s+and\s+/g, ", ")
    .split(/\s*,\s*/)
    .map((name) => name.trim())
    .filter(Boolean);
}
