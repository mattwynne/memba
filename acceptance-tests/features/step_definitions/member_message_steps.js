const { Given, When, Then } = require("@cucumber/cucumber");
const {
  addMembers,
  assertEveryAddressedMemberEmailDeliveryStatus,
  assertEachAddressedMemberHasSeparateDeliveryRecord,
  assertEachDeliverySentThroughEmailProvider,
  assertEachAddressedMemberReceivedEmailInTestMailbox,
  assertLastMessageAddressedTo,
  assertLastMessageNotAddressedTo,
  assertMemberMessageAddressedTo,
  assertMemberMessageNotAddressedTo,
  assertMemberEmailDeliveryStatus,
  assertMemberSeesMessageInClub,
  assertMemberWasToldMessageWasNotSent,
  assertMemberWasToldToContactSupport,
  assertOperatorDeliveryReason,
  assertOperatorDeliveryStatus,
  createClub,
  createPeople,
  kootenayClubName,
  makeClubMessageSendingUnavailable,
  nelsonClubName,
  openMemberMessage,
  reportRecipientEmailStatus,
  sendMemberMessageToKootenayMembers,
  sendMessageToKootenayMembers,
  trySendMemberMessageToKootenayMembers
} = require("../support/member_message");
const {
  memberBrowserAction,
  signInMember,
  withMemberHarness,
  withStaffHarness
} = require("../support/member_harness");

Given("Kootenay Mountaineering Club is a club", async function () {
  await withStaffHarness(this, (staff) => createClub(staff, kootenayClubName));
});

Given("Nelson Paddling Club is a club", async function () {
  await withStaffHarness(this, (staff) => createClub(staff, nelsonClubName));
});

Given("Alice, Bob, and Carol are people", async function () {
  await withStaffHarness(this, (staff) => createPeople(staff, ["Alice", "Bob", "Carol"]));
});

Given("Alice, Bob, Carol, and Dana are people", async function () {
  await withStaffHarness(this, (staff) => createPeople(staff, ["Alice", "Bob", "Carol", "Dana"]));
});

Given("Pat is a person", async function () {
  await withStaffHarness(this, (staff) => createPeople(staff, ["Pat"]));
});

Given("Alice, Bob, and Carol are members of Kootenay Mountaineering Club", async function () {
  await withStaffHarness(this, (staff) => addMembers(staff, ["Alice", "Bob", "Carol"], kootenayClubName));
});

Given("Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club", async function () {
  await withStaffHarness(this, (staff) => addMembers(staff, ["Alice", "Bob", "Carol", "Dana"], kootenayClubName));
});

Given("Pat is a member of Nelson Paddling Club", async function () {
  await withStaffHarness(this, (staff) => addMembers(staff, ["Pat"], nelsonClubName));
});

When(
  "{word} sends the message {string} to Kootenay Mountaineering Club members",
  async function (senderName, subject) {
    await withMemberHarness(this, senderName, (member) =>
      sendMemberMessageToKootenayMembers(member, senderName, subject)
    );
  }
);

Given("club message sending is unavailable", async function () {
  await makeClubMessageSendingUnavailable(this);
});

When(
  "{word} tries to send the message {string} to Kootenay Mountaineering Club members",
  async function (senderName, subject) {
    await signInMember(this, senderName);
    await memberBrowserAction(this, `failed member message send for ${senderName}`, () =>
      trySendMemberMessageToKootenayMembers(this, senderName, subject)
    );
  }
);

Given(
  "{word} has sent the message {string} to Kootenay Mountaineering Club members",
  async function (senderName, subject) {
    await withStaffHarness(this, (staff) => sendMessageToKootenayMembers(staff, senderName, subject));
  }
);

Then("{word} should be told the message was not sent", async function (viewerName) {
  await memberBrowserAction(this, `not-sent failure notice for ${viewerName}`, () =>
    assertMemberWasToldMessageWasNotSent(this)
  );
});

Then("{word} should be told to contact support", async function (viewerName) {
  await memberBrowserAction(this, `support failure notice for ${viewerName}`, () =>
    assertMemberWasToldToContactSupport(this)
  );
});

Then(
  "{word} should see the message {string} in Kootenay Mountaineering Club",
  async function (viewerName, subject) {
    await withMemberHarness(this, viewerName, (member) =>
      assertMemberSeesMessageInClub(member, subject, kootenayClubName)
    );
  }
);

Then(/^(\w+) should see the message was addressed to (.+)$/, async function (
  viewerName,
  expectedNamesText
) {
  await withMemberHarness(this, viewerName, (member) =>
    assertMemberMessageAddressedTo(member, parsePersonList(expectedNamesText))
  );
});

Then("{word} should not see {word} in the addressed members", async function (viewerName, excludedName) {
  await withMemberHarness(this, viewerName, (member) =>
    assertMemberMessageNotAddressedTo(member, excludedName)
  );
});

Then(
  "{word} should see every addressed member's status as {string}",
  async function (viewerName, expectedStatus) {
    await withMemberHarness(this, viewerName, (member) =>
      assertEveryAddressedMemberEmailDeliveryStatus(member, member.lastMessageSubject, expectedStatus)
    );
  }
);

Then("the message should be addressed to Alice, Bob, and Carol", async function () {
  await withStaffHarness(this, (staff) => assertLastMessageAddressedTo(staff, ["Alice", "Bob", "Carol"]));
});

Then("the message should not be addressed to {word}", async function (personName) {
  await withStaffHarness(this, (staff) => assertLastMessageNotAddressedTo(staff, personName));
});

Then("each addressed member should have a separate email delivery", async function () {
  await withStaffHarness(this, (staff) => assertEachAddressedMemberHasSeparateDeliveryRecord(staff));
});

Then("each delivery should be sent through the email provider", async function () {
  await withStaffHarness(this, (staff) => assertEachDeliverySentThroughEmailProvider(staff));
});

Then("each addressed member should receive the email in the test mailbox", async function () {
  await withStaffHarness(this, (staff) => assertEachAddressedMemberReceivedEmailInTestMailbox(staff));
});

Then(
  "{word}'s status for {string} should be {string}",
  async function (viewerName, subject, expectedStatus) {
    await withMemberHarness(this, viewerName, (member) =>
      assertMemberEmailDeliveryStatus(member, viewerName, subject, expectedStatus)
    );
  }
);

When("{word} views the message {string}", async function (viewerName, subject) {
  await withMemberHarness(this, viewerName, (member) => openMemberMessage(member, subject));
});

Then(
  "{word} should see {word}'s status for {string} as {string}",
  async function (viewerName, recipientName, subject, expectedStatus) {
    await withMemberHarness(this, viewerName, (member) =>
      assertMemberEmailDeliveryStatus(member, recipientName, subject, expectedStatus)
    );
  }
);

When(
  "{word}'s email for {string} is reported as delivered",
  async function (recipientName, subject) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "delivered"));
  }
);

Given(
  "{word}'s email for {string} has been reported as delivered",
  async function (recipientName, subject) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "delivered"));
  }
);

When(
  "{word}'s email for {string} is reported as delayed because {string}",
  async function (recipientName, subject, reason) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "delayed", { reason }));
  }
);

Given(
  "{word}'s email for {string} has been reported as delayed because {string}",
  async function (recipientName, subject, reason) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "delayed", { reason }));
  }
);

When(
  "{word}'s email for {string} is reported as bounced because {string}",
  async function (recipientName, subject, reason) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "bounced", { reason }));
  }
);

Given(
  "{word}'s email for {string} has been reported as bounced because {string}",
  async function (recipientName, subject, reason) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "bounced", { reason }));
  }
);

When(
  "{word}'s email for {string} is reported as a spam complaint because {string}",
  async function (recipientName, subject, reason) {
    await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "spam_complaint", { reason }));
  }
);

When("{word} opens the email for {string}", async function (recipientName, subject) {
  await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "opened"));
});

Given("{word} has opened the email for {string}", async function (recipientName, subject) {
  await withStaffHarness(this, (staff) => reportRecipientEmailStatus(staff, recipientName, subject, "opened"));
});

Then(
  "Memba staff should see {word}'s delivery for {string} as {string}",
  async function (recipientName, subject, expectedStatus) {
    await withStaffHarness(this, (staff) => assertOperatorDeliveryStatus(staff, recipientName, subject, expectedStatus));
  }
);

Then(
  "Memba staff should see {word}'s delivery reason {string}",
  async function (recipientName, expectedReason) {
    await withStaffHarness(this, (staff) => assertOperatorDeliveryReason(staff, recipientName, expectedReason));
  }
);

function parsePersonList(text) {
  return text
    .replace(/,?\s+and\s+/g, ", ")
    .split(/\s*,\s*/)
    .map((name) => name.trim())
    .filter(Boolean);
}
