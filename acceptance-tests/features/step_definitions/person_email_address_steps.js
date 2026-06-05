const assert = require("node:assert/strict");
const { Given, When, Then } = require("@cucumber/cucumber");
const { expect: playwrightExpect } = require("@playwright/test");
const {
  addMembers,
  createClub,
  createPerson,
  cssString,
  kootenayClubName,
  projectionPollIntervalMs,
  projectionTimeoutMs,
  testMailboxEmails,
  updatePersonEmailAddresses
} = require("../support/member_message");
const {
  assertReceivesSignInLink,
  assertSignedInAsStaff,
  followSignInLink,
  requestSignInLinkForEmail
} = require("../support/authentication");
const { withStaffHarness } = require("../support/member_harness");
const { scopedEmailAddress } = require("../support/scoping");

Given("{word}'s primary email address is {string}", async function (personName, primaryEmail) {
  await withStaffHarness(this, async (staff) => {
    await ensurePersonEmailAddresses(staff, personName, [
      { email: scopedEmailAddress(this, primaryEmail), isPrimary: true },
      ...alternateEmailAddressesFor(staff, personName)
    ]);
  });
});

Given("{word}'s alternate email address is {string}", async function (personName, alternateEmail) {
  await withStaffHarness(this, async (staff) => {
    const current = personEmailAddressesFor(staff, personName);
    const primary = current.find((emailAddress) => emailAddress.isPrimary) || {
      email: defaultPrimaryEmailFor(personName),
      isPrimary: true
    };
    const displayAlternateEmail = scopedEmailAddress(this, alternateEmail);
    const alternates = current.filter(
      (emailAddress) => !emailAddress.isPrimary && emailAddress.email !== displayAlternateEmail
    );

    await ensurePersonEmailAddresses(staff, personName, [
      primary,
      ...alternates,
      { email: displayAlternateEmail, isPrimary: false }
    ]);
  });
});

Then("{word} should receive a sign-in link at {string}", async function (personName, expectedEmail) {
  await assertReceivesSignInLink(this, personName);
  const request = this.signInRequests && this.signInRequests[personName];

  assert.equal(request && request.email, scopedEmailAddress(this, expectedEmail));
});

Then("{word} should receive the email at {string}", async function (_personName, recipientEmail) {
  await assertMessageEmailRecipient(this, scopedEmailAddress(this, recipientEmail));
});

Then("{word} should not receive the email at {string}", async function (_personName, recipientEmail) {
  await assertNoMessageEmailRecipient(this, scopedEmailAddress(this, recipientEmail));
});

Given("{word} is signed in as Memba staff", async function (personName) {
  await requestSignInLinkForEmail(this, scopedEmailAddress(this, staffEmailFor(personName)), personName);
  await assertReceivesSignInLink(this, personName);
  await followSignInLink(this, personName);
  await assertSignedInAsStaff(this, personName);
});

When(
  "{word} creates a person named {word} with primary email {string} and alternate email {string}",
  async function (_staffName, personName, primaryEmail, alternateEmail) {
    await ensureStaffClub(this);
    await createPerson(this, personName, kootenayClubName, {
      emailAddresses: [
        { email: scopedEmailAddress(this, primaryEmail), isPrimary: true },
        { email: scopedEmailAddress(this, alternateEmail), isPrimary: false }
      ]
    });
  }
);

Given(
  "{word} has primary email {string} and alternate email {string}",
  async function (personName, primaryEmail, alternateEmail) {
    await ensurePersonEmailAddresses(this, personName, [
      { email: scopedEmailAddress(this, primaryEmail), isPrimary: true },
      { email: scopedEmailAddress(this, alternateEmail), isPrimary: false }
    ]);
  }
);

When(
  "{word} makes {string} {word}'s primary email address",
  async function (_staffName, newPrimaryEmail, personName) {
    const displayNewPrimaryEmail = scopedEmailAddress(this, newPrimaryEmail);
    const nextEmailAddresses = personEmailAddressesFor(this, personName).map((emailAddress) => ({
      email: emailAddress.email,
      isPrimary: emailAddress.email === displayNewPrimaryEmail
    }));

    assert.ok(
      nextEmailAddresses.some((emailAddress) => emailAddress.isPrimary),
      `Expected ${personName} to have known email address ${newPrimaryEmail}`
    );

    await updatePersonEmailAddresses(this, personName, kootenayClubName, nextEmailAddresses);
  }
);

Then("{word}'s primary email address should be {string}", async function (personName, expectedEmail) {
  const person = personFor(this, personName);
  const displayExpectedEmail = scopedEmailAddress(this, expectedEmail);
  assert.equal(person.primaryEmail, displayExpectedEmail);

  await playwrightExpect(personRow(this, personName).locator('[data-testid="person-primary-email"]')).toContainText(
    displayExpectedEmail
  );
});

Then("{word}'s alternate email addresses should include {string}", async function (personName, expectedEmail) {
  const person = personFor(this, personName);
  const displayExpectedEmail = scopedEmailAddress(this, expectedEmail);
  assert.ok(
    person.alternateEmails.includes(displayExpectedEmail),
    `Expected ${personName}'s alternate emails to include ${displayExpectedEmail}; saw ${person.alternateEmails.join(", ")}`
  );

  await playwrightExpect(personRow(this, personName).locator('[data-testid="person-alternate-emails"]')).toContainText(
    displayExpectedEmail
  );
});

async function ensurePersonEmailAddresses(world, personName, emailAddresses) {
  await ensureStaffClub(world);

  if (world.people && world.people[personName]) {
    await updatePersonEmailAddresses(world, personName, kootenayClubName, emailAddresses);
  } else {
    await createPerson(world, personName, kootenayClubName, { emailAddresses });
  }
}

async function ensureStaffClub(world) {
  if (!world.clubs || !world.clubs[kootenayClubName]) {
    await createClub(world, kootenayClubName);
  }
}

function personEmailAddressesFor(world, personName) {
  const person = personFor(world, personName);

  return person.emailAddresses && person.emailAddresses.length > 0
    ? person.emailAddresses
    : [{ email: person.email || person.primaryEmail, isPrimary: true }];
}

function alternateEmailAddressesFor(world, personName) {
  if (!world.people || !world.people[personName]) {
    return [];
  }

  return personEmailAddressesFor(world, personName).filter((emailAddress) => !emailAddress.isPrimary);
}

function personFor(world, personName) {
  const person = world.people && world.people[personName];
  assert.ok(person, `Expected ${personName} to be known in the scenario`);

  return person;
}

function personRow(world, personName) {
  const person = personFor(world, personName);

  return world.page
    .locator(`[data-testid="person-row"][data-person-id=${cssString(person.personId)}]`)
    .last();
}

function staffEmailFor(personName) {
  return `${String(personName).trim().toLowerCase()}@memba.io`;
}

function defaultPrimaryEmailFor(personName) {
  return `${String(personName).trim().toLowerCase()}@example.test`;
}

async function assertMessageEmailRecipient(world, recipientEmail) {
  const subject = world.lastMessageSubject;
  assert.ok(subject, "Expected a club message to have been sent before checking mailbox delivery");

  await waitForMessageEmailMatching(world, (email) => messageEmailMatches(email, subject, recipientEmail));
}

async function assertNoMessageEmailRecipient(world, recipientEmail) {
  const subject = world.lastMessageSubject;
  assert.ok(subject, "Expected a club message to have been sent before checking mailbox delivery");

  const deadline = Date.now() + Math.min(1000, projectionTimeoutMs(world));

  do {
    const matchingEmail = newMessageEmails(world, await testMailboxEmails(world)).find((email) =>
      messageEmailMatches(email, subject, recipientEmail)
    );

    assert.equal(
      matchingEmail,
      undefined,
      `Expected no ${subject} email to ${recipientEmail}; saw ${JSON.stringify(mailboxEmailSummary(matchingEmail))}`
    );

    await delay(Math.min(100, projectionPollIntervalMs(world)));
  } while (Date.now() <= deadline);
}

async function waitForMessageEmailMatching(world, predicate) {
  const deadline = Date.now() + projectionTimeoutMs(world);
  let emails = [];

  do {
    emails = newMessageEmails(world, await testMailboxEmails(world));
    const matchingEmail = emails.find(predicate);

    if (matchingEmail) {
      return matchingEmail;
    }

    await delay(Math.min(projectionPollIntervalMs(world), Math.max(0, deadline - Date.now())));
  } while (Date.now() <= deadline);

  throw new Error(
    `Timed out waiting for matching club-message email; saw ${JSON.stringify(emails.map(mailboxEmailSummary))}`
  );
}

function newMessageEmails(world, emails) {
  const previousIds = (world.mailboxEmailsBeforeSend || []).map(mailboxMessageId).filter(Boolean);

  return emails.filter((email) => !previousIds.includes(mailboxMessageId(email)));
}

function messageEmailMatches(email, subject, recipientEmail) {
  return (
    email &&
    email.subject === subject &&
    Array.isArray(email.to) &&
    email.to.some((recipient) => String(recipient).includes(recipientEmail))
  );
}

function mailboxMessageId(email) {
  return email && email.headers && email.headers["Message-ID"];
}

function mailboxEmailSummary(email) {
  return email && { subject: email.subject, to: email.to, text_body: email.text_body };
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
