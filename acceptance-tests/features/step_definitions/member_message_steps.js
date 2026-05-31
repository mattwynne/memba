const assert = require("node:assert/strict");
const { Given, When, Then } = require("@cucumber/cucumber");
const { expect: playwrightExpect } = require("@playwright/test");
const {
  addMembers,
  appUrl,
  assertEachAddressedMemberHasSeparateDeliveryRecord,
  assertEachDeliverySentThroughEmailProvider,
  assertEachAddressedMemberReceivedEmailInTestMailbox,
  assertLastMessageAddressedTo,
  assertLastMessageNotAddressedTo,
  assertOperatorDeliveryReason,
  assertOperatorDeliveryStatus,
  assertReceiptStatus,
  createClub,
  createPeople,
  kootenayClubName,
  nelsonClubName,
  reportRecipientEmailStatus,
  sendMessageToKootenayMembers,
  testMailboxEmails,
  waitForMailboxEmails
} = require("../support/member_message");

async function withStaffHarness(world, action) {
  world.clubs = world.clubs || {};
  world.people = world.people || {};
  world.memberships = world.memberships || {};
  world.messages = world.messages || {};
  world.deliveries = world.deliveries || {};
  world.reportedDeliveryStatuses = world.reportedDeliveryStatuses || {};

  const context = await world.browser.newContext();
  const page = await context.newPage();
  const harnessWorld = {
    ...world,
    context,
    page,
    clubs: world.clubs,
    people: world.people,
    memberships: world.memberships,
    messages: world.messages,
    deliveries: world.deliveries,
    reportedDeliveryStatuses: world.reportedDeliveryStatuses
  };

  try {
    await signInStaff(harnessWorld);
    await action(harnessWorld);
    copyHarnessState(world, harnessWorld);
  } finally {
    await context.close();
  }
}

function copyHarnessState(world, harnessWorld) {
  for (const key of [
    "addressedMemberIds",
    "addressedMemberNames",
    "currentOperatorDelivery",
    "lastMessageSubject",
    "mailboxEmailsBeforeSend"
  ]) {
    if (Object.prototype.hasOwnProperty.call(harnessWorld, key)) {
      world[key] = harnessWorld[key];
    }
  }
}

async function signInStaff(world) {
  const staffEmail = process.env.ACCEPTANCE_STAFF_EMAIL || "acceptance-staff@memba.io";
  const previousEmails = await testMailboxEmails(world);

  await world.page.goto(appUrl(world.baseUrl, "/auth"));
  await world.page.getByLabel("Email address").fill(staffEmail);
  await world.page.getByRole("button", { name: "Email me a sign-in link" }).click();

  const emails = await waitForMailboxEmails(
    world,
    previousEmails.length + 1,
    `staff harness sign-in email for ${staffEmail}`
  );
  const previousIds = previousEmails.map(mailboxMessageId).filter(Boolean);
  const email = emails
    .filter((mailboxEmail) => !previousIds.includes(mailboxMessageId(mailboxEmail)))
    .find(
      (mailboxEmail) =>
        mailboxEmail.subject === "Sign in to Memba" &&
        mailboxEmail.to.some((recipient) => recipient.includes(staffEmail))
    );

  assert.ok(email, `Expected staff harness sign-in email for ${staffEmail}`);

  const signInLink = String(email.text_body || "").match(/https?:\/\/\S+\/auth\/magic\/\S+/);
  assert.ok(signInLink, `Expected staff harness email to contain a sign-in link; saw ${email.text_body}`);

  await world.page.goto(signInLink[0]);
  await playwrightExpect(world.page.locator("#admin-layout[data-surface='admin']")).toBeVisible();
}

function mailboxMessageId(email) {
  return email && email.headers && email.headers["Message-ID"];
}

Given("Kootenay Mountaineering Club is a club", async function () {
  await withStaffHarness(this, (staff) => createClub(staff, kootenayClubName));
});

Given("Nelson Paddling Club is a club", async function () {
  await withStaffHarness(this, (staff) => createClub(staff, nelsonClubName));
});

Given("Alice, Bob, and Carol are people", async function () {
  await withStaffHarness(this, (staff) => createPeople(staff, ["Alice", "Bob", "Carol"]));
});

Given("Pat is a person", async function () {
  await withStaffHarness(this, (staff) => createPeople(staff, ["Pat"]));
});

Given("Alice, Bob, and Carol are members of Kootenay Mountaineering Club", async function () {
  await withStaffHarness(this, (staff) => addMembers(staff, ["Alice", "Bob", "Carol"], kootenayClubName));
});

Given("Pat is a member of Nelson Paddling Club", async function () {
  await withStaffHarness(this, (staff) => addMembers(staff, ["Pat"], nelsonClubName));
});

When(
  "{word} sends the message {string} to Kootenay Mountaineering Club members",
  async function (senderName, subject) {
    await withStaffHarness(this, (staff) => sendMessageToKootenayMembers(staff, senderName, subject));
  }
);

Given(
  "{word} has sent the message {string} to Kootenay Mountaineering Club members",
  async function (senderName, subject) {
    await withStaffHarness(this, (staff) => sendMessageToKootenayMembers(staff, senderName, subject));
  }
);

Then("the message should be addressed to Alice, Bob, and Carol", async function () {
  await withStaffHarness(this, (staff) => assertLastMessageAddressedTo(staff, ["Alice", "Bob", "Carol"]));
});

Then("the message should not be addressed to {word}", async function (personName) {
  await withStaffHarness(this, (staff) => assertLastMessageNotAddressedTo(staff, personName));
});

Then("each addressed member should have a separate delivery record", async function () {
  await withStaffHarness(this, (staff) => assertEachAddressedMemberHasSeparateDeliveryRecord(staff));
});

Then("each delivery should be sent through the email provider", async function () {
  await withStaffHarness(this, (staff) => assertEachDeliverySentThroughEmailProvider(staff));
});

Then("each addressed member should receive the email in the test mailbox", async function () {
  await withStaffHarness(this, (staff) => assertEachAddressedMemberReceivedEmailInTestMailbox(staff));
});

Then(
  "{word}'s receipt status for {string} should be {string}",
  async function (recipientName, subject, expectedStatus) {
    await withStaffHarness(this, (staff) => assertReceiptStatus(staff, recipientName, subject, expectedStatus));
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

When(
  "{word}'s email for {string} is reported as bounced because {string}",
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

Then(
  "operators should see {word}'s delivery for {string} as {string}",
  async function (recipientName, subject, expectedStatus) {
    await withStaffHarness(this, (staff) => assertOperatorDeliveryStatus(staff, recipientName, subject, expectedStatus));
  }
);

Then(
  "operators should see {word}'s delivery reason {string}",
  async function (recipientName, expectedReason) {
    await withStaffHarness(this, (staff) => assertOperatorDeliveryReason(staff, recipientName, expectedReason));
  }
);
