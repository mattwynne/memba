const assert = require("node:assert/strict");
const { Given, When, Then } = require("@cucumber/cucumber");
const { expect: playwrightExpect } = require("@playwright/test");
const {
  appUrl,
  clubSiteUrl,
  createPerson,
  cssString,
  kootenayClubName,
  projectionPollIntervalMs,
  projectionTimeoutMs,
  sendInboundClubEmail,
  testLocalDeliveryFacts,
  testMailboxEmails,
  updatePersonEmailAddresses,
  waitForMailboxEmails
} = require("../support/member_message");
const {
  assertReceivesSignInLink,
  assertSignedInAsStaff,
  followSignInLink,
  requestSignInLinkForEmail,
  signInDirectly,
  signInAsStaffDirectly
} = require("../support/authentication");
const serverCommands = require("../support/server_commands");

const verificationEmailSubject = "Verify this email address for your Memba account";

Given("{word}'s primary email address is {string}", async function (personName, primaryEmail) {
  await ensurePersonEmailAddresses(this, personName, [
    { email: primaryEmail, isPrimary: true },
    ...alternateEmailAddressesFor(this, personName)
  ]);
});

Given("{word}'s alternate email address is {string}", async function (personName, alternateEmail) {
  const current = this.people && this.people[personName] ? personEmailAddressesFor(this, personName) : [];
  const primary = current.find((emailAddress) => emailAddress.isPrimary) || {
    email: defaultPrimaryEmailFor(personName),
    isPrimary: true
  };
  const alternates = current.filter(
    (emailAddress) => !emailAddress.isPrimary && emailAddress.email !== alternateEmail
  );

  await ensurePersonEmailAddresses(this, personName, [
    primary,
    ...alternates,
    { email: alternateEmail, isPrimary: false }
  ]);
});

Given("{word} has verified alternate email {string}", async function (personName, alternateEmail) {
  const current = this.people && this.people[personName] ? personEmailAddressesFor(this, personName) : [];
  const primary = current.find((emailAddress) => emailAddress.isPrimary) || {
    email: defaultPrimaryEmailFor(personName),
    isPrimary: true
  };
  const alternates = current.filter(
    (emailAddress) => !emailAddress.isPrimary && emailAddress.email !== alternateEmail
  );

  await ensurePersonEmailAddresses(this, personName, [
    primary,
    ...alternates,
    { email: alternateEmail, isPrimary: false }
  ]);
});

Given("{word} has pending email address {string}", async function (personName, email) {
  await addPendingPersonEmailAddress(this, personName, email);
});

When("{word} opens Account settings from their member menu", async function (personName) {
  await signInDirectly(this, personName);
  await openClubPageForSettings(this, kootenayClubName);
  await this.page.locator("#club-site-identity-menu-button").click();
  await playwrightExpect(this.page.locator("#club-site-account-settings-link")).toBeVisible();
  await playwrightExpect(this.page.locator("#club-site-identity-menu-divider")).toBeVisible();
  await playwrightExpect(this.page.locator("#club-site-sign-out-button")).toBeVisible();
  await this.page.locator("#club-site-account-settings-link").click();
  await playwrightExpect(this.page.locator("#my-settings-title")).toContainText("Account settings");
});

When("{word} adds {string} to their Account settings", async function (personName, email) {
  await openAccountSettingsEmails(this, personName);
  await recordVerificationEmailBaseline(this, email);
  await this.page.locator("#settings-add-email-input").fill(email);
  await this.page.locator("#my-settings-add-email-button").click();
  await assertEmailRowState(this, email, "pending");
  await refreshPersonState(this, personName);
});

When("{word} verifies {string} from that email", async function (_personName, email) {
  const verificationUrl = await verificationUrlFor(this, email);
  await this.page.goto(browserUrl(this, verificationUrl));
});

When("{word} makes {string} their primary email address", async function (personName, email) {
  await openAccountSettingsEmails(this, personName);
  await emailRow(this, email).locator("button", { hasText: "Make primary" }).click();
  await assertEmailRowState(this, email, "primary");
  await refreshPersonState(this, personName);
});

When("{word} removes {string} from their Account settings", async function (personName, email) {
  await openAccountSettingsEmails(this, personName);
  await emailRow(this, email).locator("button", { hasText: "Remove" }).click();
  await playwrightExpect(emailRow(this, email)).toHaveCount(0);
  await refreshPersonState(this, personName);
});

When("{word} resends verification for {string}", async function (personName, email) {
  await openAccountSettingsEmails(this, personName);
  await recordVerificationEmailBaseline(this, email);
  await emailRow(this, email).locator("button", { hasText: "Resend verification" }).click();
});

When("{word} opens the old verification link for {string}", async function (_personName, email) {
  const verificationUrl = await verificationUrlFor(this, email);
  await this.page.goto(browserUrl(this, verificationUrl));
});

When("{word} emails Kootenay Mountaineering Club from {string}", async function (personName, fromAddress) {
  const club = this.clubs && this.clubs[kootenayClubName];
  assert.ok(club && club.slug, `Expected ${kootenayClubName} to be known before sending inbound mail`);
  const toAddress = `everyone@${club.slug}.${process.env.ACCEPTANCE_CLUB_INBOUND_EMAIL_DOMAIN || "clubs.memba.io"}`;

  await sendInboundClubEmail(this, personName, "Pending address message", toAddress, { fromAddress });
});

Then("{word} should see their name in Account settings", async function (personName) {
  await playwrightExpect(this.page.locator("#my-settings-title")).toContainText("Account settings");
  await playwrightExpect(this.page.locator("#my-settings-profile-name")).toContainText(personName);
});

Then("{word} should see Kootenay Mountaineering Club in their current clubs", async function (_personName) {
  await this.page.locator("#my-settings-tab-clubs").click();
  await playwrightExpect(this.page.locator("#my-settings-club-chip-list")).toContainText(kootenayClubName);
});

Then("{word} should see their primary email address", async function (personName) {
  const person = await refreshPersonState(this, personName);
  await this.page.locator("#my-settings-tab-emails").click();
  await playwrightExpect(emailRow(this, person.primaryEmail)).toContainText(person.primaryEmail);
  await playwrightExpect(emailRow(this, person.primaryEmail).locator(".my-settings-primary-badge")).toContainText(
    "Primary"
  );
});

Then("{word} should see {string} as pending verification", async function (_personName, email) {
  await assertEmailRowState(this, email, "pending");
});

Then("{word} should receive a verification email at {string}", async function (_personName, email) {
  await captureVerificationEmail(this, email);
});

Then("{word} should see {string}", async function (_personName, expectedText) {
  await playwrightExpect(this.page.locator("body")).toContainText(expectedText);
});

Then("{word} should see {string} as verified in Account settings", async function (personName, email) {
  await openAccountSettingsEmails(this, personName);
  await assertEmailRowState(this, email, "verified");
  await refreshPersonState(this, personName);
});

Then("{word} should not be able to make {string} primary", async function (_personName, email) {
  await assertEmailRowState(this, email, "pending");
  await playwrightExpect(emailRow(this, email).locator("button", { hasText: "Make primary" })).toHaveCount(0);
});

Then("{word} should not be able to remove {string}", async function (personName, email) {
  await openAccountSettingsEmails(this, personName);
  await playwrightExpect(emailRow(this, email).locator("button", { hasText: "Remove" })).toHaveCount(0);
});

Then("{word}'s alternate email addresses should not include {string}", async function (personName, unexpectedEmail) {
  const person = await refreshPersonState(this, personName);

  assert.ok(
    !person.alternateEmails.includes(unexpectedEmail),
    `Expected ${personName}'s alternate emails not to include ${unexpectedEmail}; saw ${person.alternateEmails.join(
      ", "
    )}`
  );

  if ((await personRow(this, personName).count()) > 0) {
    await playwrightExpect(personRow(this, personName).locator('[data-testid="person-alternate-emails"]')).not.toContainText(
      unexpectedEmail
    );
  }
});

Then("{word} should see that the verification link is no longer valid", async function (_personName) {
  await playwrightExpect(this.page.locator("body")).toContainText(/invalid|expired|no longer valid/i);
});

Then("{word}'s email addresses should not include {string}", async function (personName, unexpectedEmail) {
  const person = await refreshPersonState(this, personName);

  assert.ok(
    !person.emailAddresses.some((emailAddress) => emailAddress.email === unexpectedEmail),
    `Expected ${personName}'s email addresses not to include ${unexpectedEmail}; saw ${person.emailAddresses
      .map((emailAddress) => emailAddress.email)
      .join(", ")}`
  );
});

Then("Memba should reject the inbound email", async function () {
  const source = await lastInboundEmailSource(this);
  assert.equal(source && source.status, "rejected");
});

Then("Memba should not post the email as a club message from {word}", async function (_personName) {
  const source = await lastInboundEmailSource(this);
  assert.equal(source && source.messageId, null);
});

Then("{word} should receive a sign-in link at {string}", async function (personName, expectedEmail) {
  await assertReceivesSignInLink(this, personName);
  const request = this.signInRequests && this.signInRequests[personName];

  assert.equal(request && request.email, expectedEmail);
});

Then("{word} should receive the email at {string}", async function (_personName, recipientEmail) {
  await assertMessageEmailRecipient(this, recipientEmail);
});

Then("{word} should not receive the email at {string}", async function (_personName, recipientEmail) {
  await assertNoMessageEmailRecipient(this, recipientEmail);
});

Given("{word} is signed in as Memba staff", async function (personName) {
  await signInAsStaffDirectly(this, personName, { email: staffEmailFor(personName) });
  await assertSignedInAsStaff(this, personName);
});

When(
  "{word} creates a person named {word} with primary email {string} and alternate email {string}",
  async function (_staffName, personName, primaryEmail, alternateEmail) {
    await ensureStaffClub(this);
    await createPerson(this, personName, kootenayClubName, {
      emailAddresses: [
        { email: primaryEmail, isPrimary: true },
        { email: alternateEmail, isPrimary: false }
      ]
    });
  }
);

Given(
  "{word} has primary email {string} and alternate email {string}",
  async function (personName, primaryEmail, alternateEmail) {
    await ensurePersonEmailAddresses(this, personName, [
      { email: primaryEmail, isPrimary: true },
      { email: alternateEmail, isPrimary: false }
    ]);
  }
);

When(
  "{word} makes {string} {word}'s primary email address",
  async function (_staffName, newPrimaryEmail, personName) {
    const nextEmailAddresses = personEmailAddressesFor(this, personName).map((emailAddress) => ({
      email: emailAddress.email,
      isPrimary: emailAddress.email === newPrimaryEmail
    }));

    assert.ok(
      nextEmailAddresses.some((emailAddress) => emailAddress.isPrimary),
      `Expected ${personName} to have known email address ${newPrimaryEmail}`
    );

    await updatePersonEmailAddresses(this, personName, kootenayClubName, nextEmailAddresses);
  }
);

Then("{word}'s primary email address should be {string}", async function (personName, expectedEmail) {
  const person = await refreshPersonState(this, personName);
  assert.equal(person.primaryEmail, expectedEmail);

  if ((await personRow(this, personName).count()) > 0) {
    await playwrightExpect(personRow(this, personName).locator('[data-testid="person-primary-email"]')).toContainText(
      expectedEmail
    );
  }
});

Then("{word}'s alternate email addresses should include {string}", async function (personName, expectedEmail) {
  const person = await refreshPersonState(this, personName);
  assert.ok(
    person.alternateEmails.includes(expectedEmail),
    `Expected ${personName}'s alternate emails to include ${expectedEmail}; saw ${person.alternateEmails.join(", ")}`
  );

  if ((await personRow(this, personName).count()) > 0) {
    await playwrightExpect(personRow(this, personName).locator('[data-testid="person-alternate-emails"]')).toContainText(
      expectedEmail
    );
  }
});

async function openClubPageForSettings(world, clubName) {
  const club = world.clubs && world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to be known before opening club page`);
  await world.page.goto(clubSiteUrl(world.baseUrl, club));
  await playwrightExpect(world.page.locator("#club-site-layout[data-surface='club-site']")).toBeVisible();
}

async function openAccountSettingsEmails(world, personName) {
  if (!(await signedInClubShellVisible(world))) {
    await signInDirectly(world, personName);
  }

  const club = world.clubs && world.clubs[kootenayClubName];
  assert.ok(club && club.slug, `Expected ${kootenayClubName} to be known before opening Account settings`);
  await world.page.goto(clubSiteUrl(world.baseUrl, club, "/my/settings/emails"));
  await playwrightExpect(world.page.locator("#my-settings-title")).toContainText("Account settings");
  await playwrightExpect(world.page.locator("#my-settings")).toHaveAttribute("data-active-tab", "emails");
}

async function signedInClubShellVisible(world) {
  const shell = world.page.locator("#club-site-layout[data-surface='club-site']");
  return (await shell.count()) > 0 && (await shell.isVisible().catch(() => false));
}

async function recordVerificationEmailBaseline(world, email) {
  world.verificationEmailBaselines = world.verificationEmailBaselines || {};
  world.verificationEmails = world.verificationEmails || {};
  world.verificationUrls = world.verificationUrls || {};
  world.verificationEmailBaselines[email] = await testMailboxEmails(world);
}

async function captureVerificationEmail(world, email) {
  world.verificationEmailBaselines = world.verificationEmailBaselines || {};
  world.verificationEmails = world.verificationEmails || {};
  world.verificationUrls = world.verificationUrls || {};

  const previousEmails = world.verificationEmailBaselines[email] || [];
  const emails = await waitForMailboxEmails(
    world,
    previousEmails.length + 1,
    `verification email for ${email}`
  );
  const previousIds = previousEmails.map(mailboxMessageId).filter(Boolean);
  const newEmails = emails.filter((candidate) => !previousIds.includes(mailboxMessageId(candidate)));
  const verificationEmail = newEmails.find((candidate) => verificationEmailMatches(candidate, email));

  assert.ok(
    verificationEmail,
    `Expected ${email} to receive a verification email; saw ${JSON.stringify(newEmails.map(mailboxEmailSummary))}`
  );

  world.verificationEmails[email] = verificationEmail;
  world.verificationUrls[email] = verificationUrlFromEmail(verificationEmail);
  return verificationEmail;
}

async function verificationUrlFor(world, email) {
  if (!(world.verificationUrls && world.verificationUrls[email])) {
    await captureVerificationEmail(world, email);
  }

  return world.verificationUrls[email];
}

function verificationEmailMatches(email, recipientEmail) {
  return (
    email.subject === verificationEmailSubject &&
    mailboxEmailTo(email).includes(recipientEmail) &&
    /\/my\/settings\/email-verifications\//.test(mailboxEmailText(email))
  );
}

function verificationUrlFromEmail(email) {
  const match = mailboxEmailText(email).match(/https?:\/\/\S+\/my\/settings\/email-verifications\/\S+/);
  assert.ok(match, `Expected verification email to contain a verification URL; saw ${mailboxEmailText(email)}`);
  return match[0].replace(/[),.;]+$/u, "");
}

function mailboxMessageId(email) {
  return email && (email.id || (email.headers && email.headers["Message-ID"]));
}

function mailboxEmailTo(email) {
  const to = email && email.to;

  if (Array.isArray(to)) {
    return to.join(" ");
  }

  return String(to || "");
}

function mailboxEmailText(email) {
  return String((email && (email.text_body || email.textBody || email.text)) || "");
}

function mailboxEmailSummary(email) {
  return {
    subject: email && email.subject,
    to: email && email.to,
    text_body: email && email.text_body
  };
}

function browserUrl(world, url) {
  const parsed = new URL(url, `${world.baseUrl}/`);
  const base = new URL(world.baseUrl);

  if (parsed.hostname === "localhost" || parsed.hostname === "127.0.0.1") {
    parsed.protocol = base.protocol;
    parsed.hostname = base.hostname;
    parsed.port = base.port;
  }

  return parsed.toString();
}

function emailRow(world, email) {
  return world.page.locator('[data-testid="person-email-row"]', { hasText: email });
}

async function assertEmailRowState(world, email, expectedState) {
  const row = emailRow(world, email);
  await playwrightExpect(row).toBeVisible();
  await playwrightExpect(row).toHaveAttribute("data-state", expectedState);
}

async function addPendingPersonEmailAddress(world, personName, email) {
  const person = personFor(world, personName);
  const result = serverCommands.runCommand(
    `
person_id = Map.fetch!(payload, "personId")
email = Map.fetch!(payload, "email")

:ok = Memba.Membership.add_person_email_address(
  %{person_id: person_id, email: email},
  consistency: :strong
)

{:ok, %{issuer_result: %{token: token}}} =
  Memba.Membership.resend_person_email_address_verification(%{person_id: person_id, email: email})

person = Memba.Membership.get_person(person_id)

%{
  personId: person.person_id,
  personName: person.name,
  email: person.email,
  emailAddresses: Memba.Membership.list_person_email_addresses(person.person_id),
  verificationToken: token
}
`,
    { personId: person.personId, email }
  );

  world.people = world.people || {};
  world.people[personName] = personStateFromServer(result);
  world.verificationUrls = world.verificationUrls || {};
  world.verificationUrls[email] = appUrl(world.baseUrl, `/my/settings/email-verifications/${result.verificationToken}`);
}

async function refreshPersonState(world, personName) {
  const person = personFor(world, personName);
  const result = serverCommands.runCommand(
    `
person_id = Map.fetch!(payload, "personId")
person = Memba.Membership.get_person(person_id)

%{
  personId: person.person_id,
  personName: person.name,
  email: person.email,
  emailAddresses: Memba.Membership.list_person_email_addresses(person.person_id)
}
`,
    { personId: person.personId }
  );

  world.people = world.people || {};
  world.people[personName] = personStateFromServer(result);
  return world.people[personName];
}

async function lastInboundEmailSource(world) {
  const inboundEmail = world.lastInboundEmail;
  assert.ok(inboundEmail && inboundEmail.providerMessageId, "Expected an inbound email before checking source status");

  return serverCommands.runCommand(
    `
provider_message_id = Map.fetch!(payload, "providerMessageId")
source = Memba.Messaging.get_inbound_email_source("resend", provider_message_id)

%{
  status: source && source.status,
  messageId: source && source.message_id,
  rejectionReason: source && source.rejection_reason
}
`,
    { providerMessageId: inboundEmail.providerMessageId }
  );
}

async function ensurePersonEmailAddresses(world, personName, emailAddresses) {
  await ensureStaffClub(world);

  const currentPerson = world.people && world.people[personName];
  const result = serverCommands.ensurePersonEmailAddresses({
    personId: currentPerson && currentPerson.personId,
    personName,
    emailAddresses
  });
  world.people = world.people || {};
  world.people[personName] = personStateFromServer(result);
}

async function ensureStaffClub(world) {
  if (!world.clubs || !world.clubs[kootenayClubName]) {
    const result = serverCommands.ensureClubSlug({
      clubName: kootenayClubName,
      clubSlug: defaultClubSlugFor(kootenayClubName)
    });
    world.clubs = world.clubs || {};
    world.clubs[kootenayClubName] = { clubId: result.clubId, name: result.clubName, slug: result.clubSlug };
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

function defaultClubSlugFor(clubName) {
  if (clubName === kootenayClubName) {
    return "kmc";
  }

  return String(clubName)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 32);
}

function personStateFromServer(result) {
  const emailAddresses = result.emailAddresses.map((emailAddress) => ({
    email: emailAddress.email,
    isPrimary: Boolean(emailAddress["primary?"] || emailAddress.is_primary || emailAddress.isPrimary),
    verifiedAt: emailAddress.verified_at || emailAddress.verifiedAt
  }));
  const primaryEmailAddress = emailAddresses.find((emailAddress) => emailAddress.isPrimary);
  assert.ok(primaryEmailAddress, `Expected ${result.personName} to have a primary email address`);

  return {
    alternateEmails: emailAddresses
      .filter((emailAddress) => !emailAddress.isPrimary)
      .map((emailAddress) => emailAddress.email),
    email: primaryEmailAddress.email,
    emailAddresses,
    name: result.personName,
    personId: result.personId,
    primaryEmail: primaryEmailAddress.email
  };
}

async function assertMessageEmailRecipient(world, recipientEmail) {
  const subject = world.lastMessageSubject;
  assert.ok(subject, "Expected a club message to have been sent before checking mailbox delivery");

  await waitForMessageEmailMatching(world, (email) => messageEmailMatches(email, subject, recipientEmail));
}

async function assertNoMessageEmailRecipient(world, recipientEmail) {
  const subject = world.lastMessageSubject;
  assert.ok(subject, "Expected a club message to have been sent before checking mailbox delivery");

  await serverCommands.waitForProjectionBarrier({
    projectors: ["Memba.Messaging.Projectors.EmailDelivery"],
    timeoutMs: projectionTimeoutMs(world)
  });

  const matchingEmail = newMessageEmails(world, await testLocalDeliveryFacts(world)).find((email) =>
    messageEmailMatches(email, subject, recipientEmail)
  );

  assert.equal(
    matchingEmail,
    undefined,
    `Expected no ${subject} email to ${recipientEmail}; saw ${JSON.stringify(mailboxEmailSummary(matchingEmail))}`
  );
}

async function waitForMessageEmailMatching(world, predicate) {
  const deadline = Date.now() + projectionTimeoutMs(world);
  let emails = [];

  do {
    emails = newMessageEmails(world, await testLocalDeliveryFacts(world));
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
  const previousIds = (world.localDeliveryFactsBeforeSend || world.mailboxEmailsBeforeSend || [])
    .map(mailboxMessageId)
    .filter(Boolean);

  return emails.filter((email) => !previousIds.includes(mailboxMessageId(email)));
}

function messageEmailMatches(email, subject, recipientEmail) {
  return (
    email &&
    (email.subject === subject || email.subject.endsWith(`] ${subject}`)) &&
    Array.isArray(email.to) &&
    email.to.some((recipient) => String(recipient).includes(recipientEmail))
  );
}

function mailboxMessageId(email) {
  return email && (email.id || (email.headers && email.headers["Message-ID"]));
}

function mailboxEmailSummary(email) {
  return email && { subject: email.subject, to: email.to, text_body: email.text_body };
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
