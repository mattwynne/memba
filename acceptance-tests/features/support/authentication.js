const assert = require("node:assert/strict");
const { expect: playwrightExpect } = require("@playwright/test");
const {
  appUrl,
  clubSiteUrl,
  cssString,
  emailFor,
  ensureState,
  kootenayClubName,
  nelsonClubName,
  recordMembershipProjectionCheckpoint,
  testMailboxEmails,
  waitForMailboxEmails
} = require("./member_message");
const serverCommands = require("./server_commands");

const staffEmail = process.env.ACCEPTANCE_STAFF_EMAIL || "acceptance-staff@memba.io";
const signInSubject = "Sign in to Memba";

function authEmailFor(name) {
  if (name === "Pat") {
    return "pat@memba.io";
  }

  return emailFor(name);
}

async function ensureMember(world, personName, clubName) {
  ensureState(world);

  const result = serverCommands.ensureMember({
    clubName,
    clubSlug: clubSlugFor(clubName),
    personName,
    email: authEmailFor(personName)
  });

  world.clubs[clubName] = {
    clubId: result.clubId,
    name: result.clubName,
    slug: result.clubSlug
  };

  world.people[personName] = {
    alternateEmails: [],
    email: result.email,
    emailAddresses: [{ email: result.email, isPrimary: true }],
    name: result.personName,
    personId: result.personId,
    primaryEmail: result.email
  };

  world.memberships[`${clubName}:${personName}`] = {
    clubId: result.clubId,
    membershipId: result.membershipId,
    personId: result.personId
  };
  recordMembershipProjectionCheckpoint(world, result);
}

function clubSlugFor(clubName) {
  if (clubName === kootenayClubName) {
    return "kmc";
  }

  return clubName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 32);
}

async function recordNonMember(world, personName) {
  ensureState(world);
  const email = authEmailFor(personName);

  world.people[personName] = world.people[personName] || {
    alternateEmails: [],
    email,
    emailAddresses: [{ email, isPrimary: true }],
    name: personName,
    personId: null,
    primaryEmail: email
  };
}

async function requestSignInLinkForPerson(world, personName) {
  const person = personFromWorld(world, personName);
  await requestSignInLinkForEmail(world, person.email, personName);
}

async function requestSignInLinkForEmail(world, email, personName = email) {
  ensureState(world);
  world.signInRequests = world.signInRequests || {};
  world.signInLinks = world.signInLinks || {};

  const previousEmails = await testMailboxEmails(world);
  await world.page.goto(appUrl(world.baseUrl, "/auth"));
  await world.page.getByLabel("Email address").fill(email);
  await world.page.getByRole("button", { name: "Email me a sign-in link" }).click();
  await playwrightExpect(
    world.page.getByText("If that email address can sign in to Memba, the sign-in email is on its way.")
  ).toBeVisible();

  await playwrightExpect(world.page).toHaveURL(/\/auth\/check-email\/[^/?#]+/);

  world.signInRequests[personName] = {
    authEmailRequestId: authEmailRequestIdFromCurrentPage(world),
    checkEmailUrl: world.page.url(),
    email,
    previousEmails
  };
}

async function assertReceivesSignInLink(world, personName) {
  const request = signInRequestFor(world, personName);
  const emails = await waitForMailboxEmails(
    world,
    request.previousEmails.length + 1,
    `sign-in email for ${request.email}`
  );
  const previousIds = request.previousEmails.map(mailboxMessageId).filter(Boolean);
  const newEmails = emails.filter((email) => !previousIds.includes(mailboxMessageId(email)));
  const email = newEmails.find((mailboxEmail) => signInEmailMatches(mailboxEmail, request.email));

  assert.ok(
    email,
    `Expected ${request.email} to receive a sign-in email; saw ${JSON.stringify(newEmails.map(emailSummary))}`
  );

  const signInLink = signInLinkFromTextBody(email.text_body);
  assert.ok(signInLink, `Expected sign-in email to contain a sign-in link; saw ${email.text_body}`);

  world.signInEmails = world.signInEmails || {};
  world.signInEmails[personName] = email;
  world.signInLinks[personName] = browserAppUrl(world, signInLink);
}

async function assertReceivesSignInEmailWithMembaSprigIcon(world, personName) {
  const email = await capturedSignInEmail(world, personName);
  const htmlBody = mailboxEmailHtml(email);

  assert.ok(
    htmlBody.includes('d="M32 33 C40 32 46 26 48 16 C39 17.5 33 24 32 33 Z"'),
    `Expected sign-in email to include the Memba sprig icon; saw ${htmlBody}`
  );
  assert.ok(
    !htmlBody.includes('d="M 18 34 L 28 44 L 46 24"'),
    `Expected sign-in email not to include the old check icon; saw ${htmlBody}`
  );
}

async function assertSignInEmailUsesStandardMembaFooter(world, personName) {
  const request = signInRequestFor(world, personName);
  const email = await capturedSignInEmail(world, personName);

  assertStandardMembaFooter(email, request.email, `sign-in email for ${request.email}`);
}

async function assertDoesNotReceiveSignInLink(world, personName) {
  const request = signInRequestFor(world, personName);
  const deadline = Date.now() + 1000;
  let emails = [];

  do {
    emails = await testMailboxEmails(world);
    const previousIds = request.previousEmails.map(mailboxMessageId).filter(Boolean);
    const newEmails = emails.filter((email) => !previousIds.includes(mailboxMessageId(email)));

    assert.equal(
      newEmails.filter((email) => signInEmailMatches(email, request.email)).length,
      0,
      `Expected ${request.email} not to receive a sign-in email; saw ${JSON.stringify(newEmails.map(emailSummary))}`
    );

    await new Promise((resolve) => setTimeout(resolve, 100));
  } while (Date.now() <= deadline);
}

async function assertSignInEmailProgressStarted(world, personName) {
  const request = signInRequestFor(world, personName);

  assert.ok(request.authEmailRequestId, `Expected ${personName} to have an auth-email request id`);
  await playwrightExpect(world.page).toHaveURL(/\/auth\/check-email\/[^/?#]+/);
  await playwrightExpect(world.page.locator("#auth-email-progress")).toBeVisible();
  await playwrightExpect(world.page.locator("#auth-email-progress-message")).toContainText(
    /Preparing your sign-in link…|If this email can sign in, the link is on its way\./
  );
}

async function recordSignInEmailProviderAccepted(world, personName) {
  const request = signInRequestFor(world, personName);
  serverCommands.recordAuthEmailProviderAccepted({ requestId: request.authEmailRequestId });
}

async function assertAuthEmailAcceptedByMailboxProvider(world, _personName) {
  await playwrightExpect(world.page.locator("#auth-email-progress-message")).toContainText(
    "Your mailbox provider has accepted the email. It should appear shortly."
  );
}

async function assertNoInboxPlacementClaim(world) {
  await playwrightExpect(world.page.locator("body")).not.toContainText("in your inbox");
  await playwrightExpect(world.page.locator("body")).not.toContainText("email is in the inbox");
}

async function assertNeutralSignInEmailInstructions(world, personName) {
  const request = signInRequestFor(world, personName);

  assert.ok(request.authEmailRequestId, `Expected ${personName} to have an auth-email request id`);
  await playwrightExpect(world.page).toHaveURL(/\/auth\/check-email\/[^/?#]+/);
  await playwrightExpect(world.page.locator("#sign-in-link-sent-notice")).toContainText(
    "If that email address can sign in to Memba, the sign-in email is on its way."
  );
  await playwrightExpect(world.page.locator("#auth-email-progress-message")).toContainText(
    /Preparing your sign-in link…|If this email can sign in, the link is on its way\./
  );
}

async function assertSignInEmailPrivacyPreserved(world, personName) {
  const request = signInRequestFor(world, personName);
  const body = world.page.locator("body");

  await playwrightExpect(body).not.toContainText(request.email);
  await playwrightExpect(body).not.toContainText("unknown email");
  await playwrightExpect(body).not.toContainText("not recognised");
  await playwrightExpect(body).not.toContainText("not recognized");
  await playwrightExpect(body).not.toContainText("does not have an account");
  await playwrightExpect(body).not.toContainText("not found");
}

async function followSignInLink(world, personName) {
  await followSignInLinkUrl(world, signInLinkFor(world, personName));
}

async function followSameSignInLinkAgain(world, personName) {
  await followSignInLinkUrl(world, signInLinkFor(world, personName));
}

async function followSignInLinkForEmail(world, email) {
  const request = signInRequestFor(world, email);
  await assertReceivesSignInLink(world, email);
  await followSignInLinkUrl(world, world.signInLinks[email] || world.signInLinks[request.email]);
}

async function followUnissuedSignInLink(world) {
  await followSignInLinkUrl(world, appUrl(world.baseUrl, "/auth/sign-in/not-issued-by-memba"));
}

async function followSignInLinkUrl(world, url) {
  await world.page.goto(browserAppUrl(world, url));
}

async function signInDirectly(world, personNameOrEmail, options = {}) {
  const email = options.email || emailForDirectSignIn(world, personNameOrEmail);
  const returnTo = options.returnTo || "/";

  if (world.directSignInLinks && world.directSignInLinks[email]) {
    await followSignInLinkUrl(world, world.directSignInLinks[email]);
    return;
  }

  const response = await world.context.request.post(appUrl(world.baseUrl, "/dev/test-support/sign-in"), {
    data: { email },
    headers: { "content-type": "application/json" }
  });

  assert.equal(response.status(), 204, `Expected direct sign-in route to return 204, got ${response.status()}`);
  await world.page.goto(appUrl(world.baseUrl, returnTo));
}

async function signInAsStaffDirectly(world, personName, options = {}) {
  const email = options.email || staffEmailFor(personName);
  serverCommands.ensurePerson({ personName: options.staffName || personName, email });
  await signInDirectly(world, email, { email, returnTo: options.returnTo || "/admin/clubs" });
}

function emailForDirectSignIn(world, personNameOrEmail) {
  if (String(personNameOrEmail).includes("@")) {
    return personNameOrEmail;
  }

  return personFromWorld(world, personNameOrEmail).email;
}

function staffEmailFor(personName) {
  return `${String(personName).trim().toLowerCase()}@memba.io`;
}

async function expireSignInLink(world, personName) {
  const request = signInRequestFor(world, personName);
  const response = await world.context.request.post(appUrl(world.baseUrl, "/dev/test-support/auth-links/expire"), {
    data: { email: request.email },
    headers: { "content-type": "application/json" }
  });

  assert.equal(response.status(), 204, `Expected test support expiry route to return 204, got ${response.status()}`);
}

async function tryOpenStaffOnlyArea(world) {
  await world.page.goto(appUrl(world.baseUrl, "/admin/clubs"));
  await playwrightExpect(world.page).toHaveURL(/\/auth$/);
}

async function assertSignedIn(world, personName) {
  const person = personFromWorld(world, personName);
  await playwrightExpect(world.page.locator("body")).toContainText(`Signed in as ${signedInEmailFor(world, personName, person)}`);
}

async function assertStillSignedIn(world, personName) {
  await assertSignedIn(world, personName);
}

async function assertSignedInAsStaff(world, _personName) {
  await completeStaffOnboardingIfNeeded(world);
  await playwrightExpect(world.page.locator("#admin-layout[data-surface='admin']")).toBeVisible();
  await playwrightExpect(world.page.getByRole("link", { name: "Clubs" })).toBeVisible();
}

async function completeStaffOnboardingIfNeeded(world) {
  await world.page.waitForLoadState("networkidle").catch(() => {});

  const nameField = world.page.getByLabel("Your name");

  if (!currentPageUrl(world.page).includes("/auth/onboard") && (await nameField.count()) === 0) {
    return;
  }

  await nameField.fill("Acceptance Staff");
  await world.page.getByRole("button", { name: "Continue to Memba staff" }).click();
  await playwrightExpect(world.page.locator("#admin-layout[data-surface='admin']")).toBeVisible();
}

async function openClubPage(world, clubName) {
  ensureState(world);
  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to be known in the scenario`);
  await world.page.goto(clubSiteUrl(world.baseUrl, club));
  await playwrightExpect(world.page.locator("#club-site-layout[data-surface='club-site']")).toBeVisible();
}

async function signOut(world) {
  const clubIdentityMenuButton = world.page.locator("#club-site-identity-menu-button");

  if ((await clubIdentityMenuButton.count()) > 0 && (await clubIdentityMenuButton.isVisible())) {
    await clubIdentityMenuButton.click();
  }

  const clubSignOutButton = world.page.locator("#club-site-sign-out-button");

  if ((await clubSignOutButton.count()) > 0 && (await clubSignOutButton.isVisible())) {
    await clubSignOutButton.click();
    return;
  }

  await world.page.getByRole("button", { name: "Sign out" }).click();
}

async function assertSignedInOnClubPage(world, personName) {
  const person = personFromWorld(world, personName);
  const email = signedInEmailFor(world, personName, person);
  await playwrightExpect(world.page.locator("#club-site-layout[data-surface='club-site']")).toBeVisible();
  await assertClubIdentityVisible(world, clubIdentityLabelFor(person, email));
  await world.page.locator("#club-site-identity-menu-button").click();
  await playwrightExpect(world.page.locator("#club-site-sign-out-button")).toBeVisible();
}

async function assertClubIdentityVisible(world, label) {
  await playwrightExpect(world.page.locator("#club-site-layout[data-surface='club-site']")).toBeVisible();
  await playwrightExpect(world.page.locator("#club-site-identity-menu .app-menu__who-name")).toContainText(label);
}

function clubIdentityFallbackLabelFor(email) {
  return String(email).split("@")[0].trim() || "Member";
}

function clubIdentityLabelFor(person, email) {
  const name = person && typeof person.name === "string" ? person.name.trim() : "";
  return name || clubIdentityFallbackLabelFor(email);
}

async function assertClubMarketingPage(world, clubName) {
  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to be known in the scenario`);
  await playwrightExpect(world.page.locator("#public-club-page-page")).toBeVisible();
  await playwrightExpect(world.page.locator("#public-club-page-page")).toHaveAttribute("data-club-id", club.clubId);
  await playwrightExpect(world.page.getByRole("heading", { name: `Welcome to ${clubName}` })).toBeVisible();
  await playwrightExpect(world.page.getByRole("link", { name: "Email me a sign-in link" })).toBeVisible();
  await playwrightExpect(world.page.locator("body")).not.toContainText("Signed in as");
}

async function assertPoweredByMembaInClubFooter(world) {
  await playwrightExpect(world.page.locator("#club-site-layout header")).not.toContainText("Powered by Memba");
  await playwrightExpect(world.page.locator("#club-site-layout footer")).toContainText("Powered by Memba");
}

async function assertNotSignedIn(world) {
  await playwrightExpect(world.page).toHaveURL(/\/auth$/);
  await playwrightExpect(
    world.page.getByText("That sign-in link is no longer valid. Please ask for a new sign-in link.")
  ).toBeVisible();
}

async function assertSignedOut(world) {
  await playwrightExpect(world.page).toHaveURL(/\/$/);
  await playwrightExpect(world.page.locator("#admin-layout[data-surface='admin']")).toHaveCount(0);
  await playwrightExpect(world.page.locator("body")).not.toContainText("Signed in as");

  if ((await world.page.locator("#public-club-page-page").count()) > 0) {
    await playwrightExpect(world.page.getByRole("link", { name: "Email me a sign-in link" })).toBeVisible();
  } else {
    await playwrightExpect(world.page.getByRole("link", { name: "Sign in" }).first()).toBeVisible();
  }
}

async function assertOnStaffOnlyHomepage(world) {
  await playwrightExpect(world.page).toHaveURL(/\/admin\/clubs/);
  await playwrightExpect(world.page.getByRole("heading", { name: "Clubs", exact: true })).toBeVisible();
}

async function assertOnHomepage(world) {
  await playwrightExpect(world.page).toHaveURL(/\/$/);
}

async function assertSeesClub(world, clubName) {
  const clubCard = world.page.getByRole("heading", { name: clubName }).first();
  const adminClubRow = world.page.locator(`[data-testid="club-row"][data-club-name=${cssString(clubName)}]`).first();

  if (await clubCard.count()) {
    await playwrightExpect(clubCard).toBeVisible();
  } else {
    await playwrightExpect(adminClubRow).toBeVisible();
  }
}

function personFromWorld(world, personName) {
  ensureState(world);
  const person = world.people[personName];
  assert.ok(person, `Expected ${personName} to be known in the scenario`);
  return person;
}

function signInRequestFor(world, personName) {
  const request = world.signInRequests && world.signInRequests[personName];
  assert.ok(request, `Expected ${personName} to have requested a sign-in link`);
  return request;
}

function signedInEmailFor(world, personName, person) {
  const request = world.signInRequests && world.signInRequests[personName];

  return (request && request.email) || person.email;
}

function signInLinkFor(world, personName) {
  const link = world.signInLinks && world.signInLinks[personName];
  assert.ok(link, `Expected ${personName} to have received a sign-in link`);
  return link;
}

function currentPageUrl(page) {
  if (!page) {
    return "";
  }

  if (typeof page.url === "function") {
    return page.url();
  }

  return page.currentUrl || "";
}

function authEmailRequestIdFromCurrentPage(world) {
  const url = new URL(world.page.url());
  const match = url.pathname.match(/\/auth\/check-email\/([^/]+)$/);

  assert.ok(match, `Expected check-email URL with auth request id, got ${url.toString()}`);

  return match[1];
}

function signInEmailMatches(email, recipientEmail) {
  return (
    email.subject === signInSubject &&
    Array.isArray(email.to) &&
    email.to.some((recipient) => String(recipient).includes(recipientEmail))
  );
}

function signInLinkFromTextBody(textBody) {
  const match = String(textBody || "").match(/https?:\/\/\S+\/auth\/(?:sign-in|magic)\/\S+/);
  return match && match[0];
}

async function capturedSignInEmail(world, personName) {
  if (!(world.signInEmails && world.signInEmails[personName])) {
    await assertReceivesSignInLink(world, personName);
  }

  const email = world.signInEmails && world.signInEmails[personName];
  assert.ok(email, `Expected ${personName} to have received a sign-in email`);
  return email;
}

function assertStandardMembaFooter(email, recipientEmail, description) {
  const htmlBody = mailboxEmailHtml(email);

  assert.ok(
    /Delivered (?:by|for) /.test(htmlBody) && htmlBody.includes('href="https://memba.io"'),
    `Expected ${description} to include the standard Memba delivery footer; saw ${htmlBody}`
  );
  assert.ok(
    htmlBody.includes(`Sent to ${recipientEmail}.`),
    `Expected ${description} to include the recipient in the footer; saw ${htmlBody}`
  );
  assert.ok(
    !htmlBody.includes("help@memba.io"),
    `Expected ${description} not to hard-code the support mailbox; saw ${htmlBody}`
  );
}

function mailboxEmailHtml(email) {
  return String((email && (email.html_body || email.htmlBody || email.html)) || "");
}

function browserAppUrl(world, url) {
  const parsed = new URL(url, `${world.baseUrl}/`);
  const base = new URL(world.baseUrl);

  if (parsed.hostname === "localhost" || parsed.hostname === "127.0.0.1") {
    parsed.protocol = base.protocol;
    parsed.hostname = base.hostname;
    parsed.port = base.port;
  }

  return parsed.toString();
}

function mailboxMessageId(email) {
  return email && email.headers && email.headers["Message-ID"];
}

function emailSummary(email) {
  return { subject: email.subject, to: email.to, text_body: email.text_body, html_body: email.html_body };
}

module.exports = {
  assertDoesNotReceiveSignInLink,
  assertAuthEmailAcceptedByMailboxProvider,
  assertNoInboxPlacementClaim,
  assertNeutralSignInEmailInstructions,
  assertNotSignedIn,
  assertOnStaffOnlyHomepage,
  assertReceivesSignInLink,
  assertReceivesSignInEmailWithMembaSprigIcon,
  assertSeesClub,
  assertSignInEmailUsesStandardMembaFooter,
  assertSignedIn,
  assertSignedInAsStaff,
  assertSignInEmailPrivacyPreserved,
  assertSignInEmailProgressStarted,
  assertStillSignedIn,
  ensureMember,
  expireSignInLink,
  followSameSignInLinkAgain,
  followSignInLink,
  followUnissuedSignInLink,
  kootenayClubName,
  nelsonClubName,
  openClubPage,
  recordNonMember,
  recordSignInEmailProviderAccepted,
  requestSignInLinkForEmail,
  requestSignInLinkForPerson,
  signInAsStaffDirectly,
  signInDirectly,
  signOut,
  assertSignedOut,
  assertSignedInOnClubPage,
  assertPoweredByMembaInClubFooter,
  assertClubMarketingPage,
  assertOnHomepage,
  tryOpenStaffOnlyArea
};
