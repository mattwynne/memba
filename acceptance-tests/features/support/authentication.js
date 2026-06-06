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
}

function clubSlugFor(clubName) {
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

  world.signInRequests[personName] = { email, previousEmails };
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

  world.signInLinks[personName] = browserAppUrl(world, signInLink);
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
  await world.page.getByRole("button", { name: "Sign out" }).click();
}

async function assertSignedInOnClubPage(world, personName) {
  const person = personFromWorld(world, personName);
  await playwrightExpect(world.page.locator("#club-site-layout[data-surface='club-site']")).toBeVisible();
  await playwrightExpect(world.page.locator("#club-site-current-identity")).toContainText(
    `Signed in as ${signedInEmailFor(world, personName, person)}`
  );
  await playwrightExpect(world.page.locator("#club-site-sign-out-button")).toBeVisible();
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
  return { subject: email.subject, to: email.to, text_body: email.text_body };
}

module.exports = {
  assertDoesNotReceiveSignInLink,
  assertNotSignedIn,
  assertOnStaffOnlyHomepage,
  assertReceivesSignInLink,
  assertSeesClub,
  assertSignedIn,
  assertSignedInAsStaff,
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
