const assert = require("node:assert/strict");
const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertMemberDoesNotSeeMessage,
  assertMemberSeesMessage,
  assertSmokeClubExists,
  ensureSmokeMemberSignedIn,
  ensureStaffSignedIn
} = require("../../lib/browser");
const { sendEmail } = require("../../lib/smtp");

Given("the production smoke configuration is valid", async function () {
  assert.equal(this.config.clubName, "Test", "Expected the default smoke club name to be Test");
  assert.equal(this.config.clubSlug, "test", "Expected the default smoke club slug to be test");
  assert.equal(this.config.inboundAddress, "test@clubs.memba.io", "Expected the default inbound address");
  assert.notEqual(
    this.config.unknown.email.toLowerCase(),
    this.config.member.email.toLowerCase(),
    "Unknown-sender smoke requires MEMBA_SMOKE_UNKNOWN_EMAIL to differ from the known member address"
  );
});

Given("Memba staff can sign in", async function () {
  await ensureStaffSignedIn(this);
});

Given("the smoke club exists", async function () {
  await assertSmokeClubExists(this);
});

Given("the smoke member can sign in", async function () {
  await ensureSmokeMemberSignedIn(this);
});

When("an unknown sender emails the smoke club", async function () {
  const subject = uniqueSubject("Smoke unknown sender");
  const body = "This should be rejected because the sender is unknown.";
  this.messages.current = { body, from: this.config.unknown.email, kind: "unknown", subject };

  await sendEmail({
    body,
    from: this.config.unknown.email,
    password: this.config.unknown.smtpPassword,
    subject,
    to: this.config.inboundAddress,
    user: this.config.unknown.smtpUser
  });
});

When("the smoke member emails the smoke club", async function () {
  const subject = uniqueSubject("Smoke accepted member");
  const body = "This should become a club message.";
  this.messages.current = { body, from: this.config.member.email, kind: "accepted", subject };

  await sendEmail({
    body,
    from: this.config.member.email,
    password: this.config.member.smtpPassword,
    subject,
    to: this.config.inboundAddress,
    user: this.config.member.smtpUser
  });
});

When("the smoke member emails the smoke club with an attachment", async function () {
  const subject = uniqueSubject("Smoke attachment rejected");
  const body = "This should be rejected because it has an attachment.";
  this.messages.current = { body, from: this.config.member.email, kind: "attachment", subject };

  await sendEmail({
    attachment: {
      content: "Memba smoke-test attachment.\n",
      contentType: "text/plain",
      filename: "memba-smoke-test.txt"
    },
    body,
    from: this.config.member.email,
    password: this.config.member.smtpPassword,
    subject,
    to: this.config.inboundAddress,
    user: this.config.member.smtpUser
  });
});

Then("the unknown sender receives an unknown-sender rejection email", async function () {
  const message = currentMessage(this);
  await this.mailboxes.unknown.waitForEmail(
    (email) =>
      email.subject === "Your email was not posted" &&
      email.toEmails.includes(this.config.unknown.email.toLowerCase()) &&
      /could not find a member account|unknown sender/i.test(`${email.text}\n${email.html}`),
    {
      after: subjectTimestamp(message.subject),
      description: `unknown-sender rejection for ${message.subject}`,
      intervalMs: this.config.poll.intervalMs,
      timeoutMs: this.config.poll.timeoutMs,
      text: "Your email was not posted"
    }
  );
});

Then("the smoke member receives an attachment-not-supported rejection email", async function () {
  const message = currentMessage(this);
  await this.mailboxes.member.waitForEmail(
    (email) =>
      email.subject === "Your email was not posted" &&
      email.toEmails.includes(this.config.member.email.toLowerCase()) &&
      /attachments are not supported/i.test(`${email.text}\n${email.html}`),
    {
      after: subjectTimestamp(message.subject),
      description: `attachment rejection for ${message.subject}`,
      intervalMs: this.config.poll.intervalMs,
      timeoutMs: this.config.poll.timeoutMs,
      text: "Your email was not posted"
    }
  );
});

Then("the smoke member sees that club message", async function () {
  const message = currentMessage(this);
  await assertMemberSeesMessage(this, message.subject, message.body);
});

Then("the smoke member receives a distributed copy of that club message", async function () {
  const message = currentMessage(this);
  await this.mailboxes.member.waitForEmail(
    (email) =>
      email.subject === message.subject &&
      email.toEmails.includes(this.config.member.email.toLowerCase()) &&
      `${email.text}\n${email.html}`.includes(message.body),
    {
      after: subjectTimestamp(message.subject),
      description: `distributed member copy for ${message.subject}`,
      intervalMs: this.config.poll.intervalMs,
      timeoutMs: this.config.poll.timeoutMs,
      text: message.subject
    }
  );
});

Then("the smoke member should not see that club message", async function () {
  const message = currentMessage(this);
  await assertMemberDoesNotSeeMessage(this, message.subject);
});

function uniqueSubject(prefix) {
  const now = new Date();
  const compact = now.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}Z$/, "Z");
  return `${prefix} ${compact}`;
}

function subjectTimestamp(subject) {
  const match = String(subject).match(/(\d{8}T\d{6}Z)$/);
  if (!match) {
    return new Date(Date.now() - 60_000);
  }
  const value = match[1];
  return new Date(
    `${value.slice(0, 4)}-${value.slice(4, 6)}-${value.slice(6, 8)}T${value.slice(9, 11)}:${value.slice(11, 13)}:${value.slice(13, 15)}Z`
  );
}

function currentMessage(world) {
  assert.ok(world.messages.current, "Expected a smoke email to have been sent in this scenario");
  return world.messages.current;
}
