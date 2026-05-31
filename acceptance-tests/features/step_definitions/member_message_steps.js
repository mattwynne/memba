const { Given, When, Then } = require("@cucumber/cucumber");
const {
  addMembers,
  assertEachAddressedMemberHasSeparateDeliveryRecord,
  assertEachDeliverySentThroughEmailProvider,
  assertLastMessageAddressedTo,
  assertLastMessageNotAddressedTo,
  assertReceiptStatus,
  createClub,
  createPeople,
  kootenayClubName,
  nelsonClubName,
  reportRecipientEmailStatus,
  sendMessageToKootenayMembers
} = require("../support/member_message");

Given("Kootenay Mountaineering Club is a club", async function () {
  await createClub(this, kootenayClubName);
});

Given("Nelson Paddling Club is a club", async function () {
  await createClub(this, nelsonClubName);
});

Given("Alice, Bob, and Carol are people", async function () {
  await createPeople(this, ["Alice", "Bob", "Carol"]);
});

Given("Pat is a person", async function () {
  await createPeople(this, ["Pat"]);
});

Given("Alice, Bob, and Carol are members of Kootenay Mountaineering Club", async function () {
  await addMembers(this, ["Alice", "Bob", "Carol"], kootenayClubName);
});

Given("Pat is a member of Nelson Paddling Club", async function () {
  await addMembers(this, ["Pat"], nelsonClubName);
});

When(
  "{word} sends the message {string} to Kootenay Mountaineering Club members",
  async function (senderName, subject) {
    await sendMessageToKootenayMembers(this, senderName, subject);
  }
);

Given(
  "{word} has sent the message {string} to Kootenay Mountaineering Club members",
  async function (senderName, subject) {
    await sendMessageToKootenayMembers(this, senderName, subject);
  }
);

Then("the message should be addressed to Alice, Bob, and Carol", async function () {
  await assertLastMessageAddressedTo(this, ["Alice", "Bob", "Carol"]);
});

Then("the message should not be addressed to {word}", async function (personName) {
  await assertLastMessageNotAddressedTo(this, personName);
});

Then("each addressed member should have a separate delivery record", async function () {
  await assertEachAddressedMemberHasSeparateDeliveryRecord(this);
});

Then("each delivery should be sent through the email provider", async function () {
  await assertEachDeliverySentThroughEmailProvider(this);
});

Then(
  "{word}'s receipt status for {string} should be {string}",
  async function (recipientName, subject, expectedStatus) {
    await assertReceiptStatus(this, recipientName, subject, expectedStatus);
  }
);

When(
  "{word}'s email for {string} is reported as delivered",
  async function (recipientName, subject) {
    await reportRecipientEmailStatus(this, recipientName, subject, "delivered");
  }
);

Given(
  "{word}'s email for {string} has been reported as delivered",
  async function (recipientName, subject) {
    await reportRecipientEmailStatus(this, recipientName, subject, "delivered");
  }
);

When(
  "{word}'s email for {string} is reported as delayed because {string}",
  async function (recipientName, subject, reason) {
    await reportRecipientEmailStatus(this, recipientName, subject, "delayed", { reason });
  }
);

When(
  "{word}'s email for {string} is reported as bounced because {string}",
  async function (recipientName, subject, reason) {
    await reportRecipientEmailStatus(this, recipientName, subject, "bounced", { reason });
  }
);

When(
  "{word}'s email for {string} is reported as a spam complaint because {string}",
  async function (recipientName, subject, reason) {
    await reportRecipientEmailStatus(this, recipientName, subject, "spam_complaint", { reason });
  }
);

When("{word} opens the email for {string}", async function (recipientName, subject) {
  await reportRecipientEmailStatus(this, recipientName, subject, "opened");
});
