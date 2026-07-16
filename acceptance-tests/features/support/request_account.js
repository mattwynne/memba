const assert = require("node:assert/strict");
const { expect: playwrightExpect } = require("@playwright/test");
const {
  appUrl,
  cssString,
  emailFor,
  ensureState,
  projectionTimeoutMs,
  testMailboxEmails,
  waitForMailboxEmails
} = require("./member_message");
const {
  assertDoesNotReceiveSignInLink,
  requestSignInLinkForEmail,
  signInDirectly
} = require("./authentication");
const serverCommands = require("./server_commands");

const defaultRequestNote = "We want to bring our club communications into Memba.";

async function ensurePerson(world, personName) {
  ensureState(world);

  const email = requestEmailFor(personName);
  const person = serverCommands.ensurePerson({ personName, email });

  world.people[personName] = {
    alternateEmails: [],
    email: person.email,
    emailAddresses: [{ email: person.email, isPrimary: true }],
    name: person.personName,
    personId: person.personId,
    primaryEmail: person.email
  };

  return world.people[personName];
}

async function signInPerson(world, personName) {
  await ensurePerson(world, personName);
  await signInDirectly(world, personName, { returnTo: "/" });
}

async function openGetStartedPage(world) {
  await world.page.goto(appUrl(world.baseUrl, "/get-started"));
  await playwrightExpect(world.page.locator("#get-started-flow")).toBeVisible({
    timeout: projectionTimeoutMs(world)
  });
}

async function submitRequestThroughBrowser(world, personName, clubName) {
  ensureState(world);
  world.onboardingRequests = world.onboardingRequests || {};

  const person = world.people[personName] || {
    email: requestEmailFor(personName),
    name: personName
  };
  await openGetStartedPage(world);

  if ((await world.page.locator("#get-started-verification-form").count()) > 0) {
    await completeGetStartedVerification(world, personName, person.email);
  }

  if ((await world.page.locator("#get-started-signed-in-requester").count()) === 0) {
    await world.page.getByLabel("Your name").fill(personName);
  }

  await world.page.getByLabel("Group or club name").fill(clubName);
  await world.page.getByLabel("What would you like Memba to help with?").fill(defaultRequestNote);

  const previousEmails = await testMailboxEmails(world);

  await world.page.getByRole("button", { name: "Request access" }).click();

  world.onboardingRequests[clubName] = {
    clubName,
    email: person.email,
    note: defaultRequestNote,
    personName,
    previousEmails
  };
  world.lastOnboardingRequestClubName = clubName;
}

async function completeGetStartedVerification(world, personName, email) {
  world.signInLinks = world.signInLinks || {};

  const previousEmails = await testMailboxEmails(world);

  await world.page.getByLabel("Email address").fill(email);
  await world.page.getByRole("button", { name: "Email me a sign-in link" }).click();
  await playwrightExpect(world.page).toHaveURL(/\/auth\/check-email/);

  const emails = await waitForMailboxEmails(
    world,
    previousEmails.length + 1,
    `get-started sign-in email for ${email}`
  );
  const previousIds = previousEmails.map(mailboxMessageId).filter(Boolean);
  const newEmails = emails.filter((mailboxEmail) => !previousIds.includes(mailboxMessageId(mailboxEmail)));
  const signInEmail = newEmails.find(
    (mailboxEmail) =>
      mailboxEmail.subject === "Sign in to Memba" &&
      mailboxEmailTo(mailboxEmail).includes(email) &&
      signInLinkFromTextBody(mailboxEmailText(mailboxEmail))
  );

  assert.ok(
    signInEmail,
    `Expected get-started sign-in email for ${email}; saw ${JSON.stringify(newEmails.map(mailboxEmailSummary))}`
  );

  const signInLink = signInLinkFromTextBody(mailboxEmailText(signInEmail));
  world.signInLinks[personName] = browserReachableUrl(world, signInLink);

  await world.page.goto(world.signInLinks[personName]);
  await playwrightExpect(world.page).toHaveURL(/\/get-started/);
  await playwrightExpect(world.page.locator("#get-started-request-form")).toBeVisible({
    timeout: projectionTimeoutMs(world)
  });
}

async function createRequestDirectly(world, personName, clubName) {
  ensureState(world);
  world.onboardingRequests = world.onboardingRequests || {};

  const existingPerson = world.people && world.people[personName];
  const email = (existingPerson && existingPerson.email) || requestEmailFor(personName);
  const result = serverCommands.runCommand(
    `
person_name = Map.fetch!(payload, "personName")
email = Map.fetch!(payload, "email")
club_name = Map.fetch!(payload, "clubName")
note = Map.fetch!(payload, "note")
requester_person_id = Map.get(payload, "requesterPersonId")

opts =
  if requester_person_id do
    [verified_identity_email: email, requester_person_id: requester_person_id]
  else
    [verified_identity_email: email]
  end

{:ok, request} =
  Memba.Onboarding.create_request(
    %{
      requester_name: person_name,
      requester_email: email,
      requested_club_name: club_name,
      note: note
    },
    opts
  )

%{
  requestId: request.request_id,
  requesterName: request.requester_name,
  requesterEmail: request.requester_email,
  requesterPersonId: request.requester_person_id,
  requestedClubName: request.requested_club_name,
  note: request.note,
  status: request.status
}
`,
    {
      clubName,
      email,
      note: defaultRequestNote,
      personName,
      requesterPersonId: existingPerson && existingPerson.personId
    }
  );

  world.people[personName] = world.people[personName] || {
    alternateEmails: [],
    email,
    emailAddresses: [{ email, isPrimary: true }],
    name: personName,
    personId: null,
    primaryEmail: email
  };

  world.onboardingRequests[clubName] = {
    clubName,
    email,
    note: defaultRequestNote,
    personName,
    requestId: result.requestId
  };
  world.lastOnboardingRequestClubName = clubName;

  return result;
}

async function assertReviewAcknowledgement(world) {
  await playwrightExpect(world.page.locator("#get-started-request-acknowledgement")).toBeVisible({
    timeout: projectionTimeoutMs(world)
  });
  await playwrightExpect(world.page.locator("#get-started-request-acknowledgement")).toContainText(
    "we’ll read your request"
  );
  await playwrightExpect(world.page.locator("#get-started-request-acknowledgement")).toContainText(
    "no group space, membership, or sign-in access"
  );
}

async function assertStaffNotified(world, personName) {
  const request = lastRequestByPerson(world, personName);
  const emails = await waitForMailboxEmails(
    world,
    request.previousEmails.length + 1,
    `new request notification for ${request.clubName}`
  );
  const previousIds = request.previousEmails.map(mailboxMessageId).filter(Boolean);
  const newEmails = emails.filter((email) => !previousIds.includes(mailboxMessageId(email)));
  const notification = newEmails.find(
    (email) =>
      email.subject === `New Memba request: ${request.clubName}` &&
      mailboxEmailTo(email).includes("hello@memba.io") &&
      mailboxEmailText(email).includes(personName) &&
      mailboxEmailText(email).includes(request.email) &&
      mailboxEmailText(email).includes(request.clubName)
  );

  assert.ok(
    notification,
    `Expected staff notification email for ${request.clubName}; saw ${JSON.stringify(
      newEmails.map(mailboxEmailSummary)
    )}`
  );

  request.staffNotificationLink = staffRequestLinkFromText(mailboxEmailText(notification));
}

async function assertKnownReadOnlyDetails(world, personName) {
  const person = personFor(world, personName);
  const panel = world.page.locator("#get-started-signed-in-requester");

  await playwrightExpect(panel).toBeVisible({ timeout: projectionTimeoutMs(world) });
  await playwrightExpect(panel).toContainText(person.name);
  await playwrightExpect(panel).toContainText(person.email);
  await playwrightExpect(world.page.locator("#get-started-requester-name")).toHaveCount(0);
  await playwrightExpect(world.page.locator("#get-started-requester-email")).toHaveCount(0);
}

function assertRequestRecordedWithKnownDetails(world, personName, clubName) {
  const person = personFor(world, personName);
  const request = requestByClubName(clubName);

  assert.equal(request.requesterName, person.name);
  assert.equal(request.requesterEmail, person.email);
  assert.equal(request.requestedClubName, clubName);
  assert.equal(request.requesterPersonId, person.personId);
}

async function followStaffNotificationLink(world, personName) {
  const request = lastRequestByPerson(world, personName);
  const link = request.staffNotificationLink || appUrl(world.baseUrl, `/admin/requests/${request.requestId}`);

  await world.page.goto(browserReachableUrl(world, link));
  await playwrightExpect(world.page.locator('[data-testid="convert-request-panel"]')).toBeVisible({
    timeout: projectionTimeoutMs(world)
  });
}

async function assertPreparingToConvertRequest(world, personName, clubName) {
  const request = lastRequestByPerson(world, personName);
  const panel = world.page.locator(`[data-testid="convert-request-panel"]#convert-request-panel-${request.requestId}`);

  await playwrightExpect(panel).toBeVisible({ timeout: projectionTimeoutMs(world) });
  await playwrightExpect(panel).toContainText(clubName);
  await playwrightExpect(panel).toContainText(request.email);
}

async function openRequestsInbox(world) {
  await world.page.goto(appUrl(world.baseUrl, "/admin/requests"));
  await playwrightExpect(world.page.locator("#admin-requests-index")).toBeVisible({
    timeout: projectionTimeoutMs(world)
  });
}

async function assertRequestVisible(world, personName, clubName) {
  const row = requestRow(world, clubName);

  await playwrightExpect(row).toBeVisible({ timeout: projectionTimeoutMs(world) });
  await playwrightExpect(row.locator('[data-testid="admin-request-requester"]')).toContainText(personName);
  await playwrightExpect(row.locator('[data-testid="admin-request-club"]')).toContainText(clubName);
}

async function assertSuggestedSlug(world, clubName, expectedSlug) {
  await openConversionPanel(world, clubName);

  const panel = world.page.locator('[data-testid="convert-request-panel"]');
  await playwrightExpect(panel.getByLabel("Club slug")).toHaveValue(expectedSlug);
  await playwrightExpect(panel.locator('[id^="convert-request-club-slug-feedback-"]')).toContainText("available");
}

async function convertRequest(world, personName, clubName, options = {}) {
  ensureState(world);
  world.onboardingWelcomeEmailBaselines = world.onboardingWelcomeEmailBaselines || {};

  await openConversionPanel(world, clubName);

  const panel = world.page.locator('[data-testid="convert-request-panel"]');
  const previousEmails = await testMailboxEmails(world);

  if (options.slug) {
    await panel.getByLabel("Club slug").fill(options.slug);
  }

  await panel.getByRole("button", { name: "Convert request" }).click();
  await playwrightExpect(requestRow(world, clubName)).toHaveCount(0, {
    timeout: projectionTimeoutMs(world)
  });

  const club = clubByName(clubName);
  assert.ok(club, `Expected ${clubName} to exist after conversion`);
  world.clubs[clubName] = { clubId: club.clubId, name: club.clubName, slug: club.clubSlug };
  world.onboardingWelcomeEmailBaselines[personName] = {
    clubName,
    email: requestEmailFor(personName),
    previousEmails
  };
  world.lastOnboardingRequestClubName = clubName;
}

async function rejectRequest(world, personName, clubName, internalNote) {
  ensureState(world);
  world.onboardingRejectionEmailBaselines = world.onboardingRejectionEmailBaselines || {};
  world.onboardingRejectionEmailBaselines[personName] = {
    clubName,
    email: requestEmailFor(personName),
    previousEmails: await testMailboxEmails(world)
  };

  await openRequestsInbox(world);

  const row = requestRow(world, clubName);
  await row.getByRole("button", { name: `Reject request for ${clubName}` }).click();

  const panel = world.page.locator('[data-testid="reject-request-panel"]');
  await playwrightExpect(panel).toBeVisible({ timeout: projectionTimeoutMs(world) });
  await panel.getByLabel("Internal rejection notes").fill(internalNote);
  await panel.getByRole("button", { name: "Reject request" }).click();

  await playwrightExpect(requestRow(world, clubName)).toHaveCount(0, {
    timeout: projectionTimeoutMs(world)
  });
  world.lastOnboardingRequestClubName = clubName;
}

async function assertRequestLeavesInbox(world, clubName) {
  await openRequestsInbox(world);
  await playwrightExpect(requestRow(world, clubName)).toHaveCount(0, {
    timeout: projectionTimeoutMs(world)
  });
}

function assertClubDoesNotExist(clubName) {
  assert.equal(clubByName(clubName), null, `Expected ${clubName} not to exist as a club`);
}

function assertClubExists(clubName, expectedSlug) {
  const club = clubByName(clubName);

  assert.ok(club, `Expected ${clubName} to exist as a club`);
  if (expectedSlug) {
    assert.equal(club.clubSlug, expectedSlug);
  }
}

function assertActiveMember(world, personName, clubName) {
  const membership = activeMembership(personName, clubName, requestEmailFor(personName, world));

  assert.ok(membership, `Expected ${personName} to be an active member of ${clubName}`);
  world.memberships[`${clubName}:${personName}`] = {
    clubId: membership.clubId,
    membershipId: membership.membershipId,
    personId: membership.personId
  };
}

function assertNoDuplicatePerson(world, personName) {
  const person = personFor(world, personName);
  const result = personCountByEmail(person.email);

  assert.equal(result.count, 1, `Expected exactly one person with ${person.email}`);
  assert.equal(result.personIds[0], person.personId);
}

async function assertCannotSignInToClub(world, personName, clubName) {
  const email = requestEmailFor(personName);

  await requestSignInLinkForEmail(world, email, personName);
  await assertDoesNotReceiveSignInLink(world, personName);
  assert.equal(clubByName(clubName), null, `Expected ${clubName} not to exist`);
}

async function assertRequesterNotEmailedAboutRejection(world, personName) {
  const baseline = world.onboardingRejectionEmailBaselines && world.onboardingRejectionEmailBaselines[personName];
  assert.ok(baseline, `Expected rejection email baseline for ${personName}`);

  const deadline = Date.now() + 1000;
  let emails = [];

  do {
    emails = await testMailboxEmails(world);
    const previousIds = baseline.previousEmails.map(mailboxMessageId).filter(Boolean);
    const newEmails = emails.filter((email) => !previousIds.includes(mailboxMessageId(email)));

    assert.equal(
      newEmails.filter((email) => mailboxEmailTo(email).includes(baseline.email)).length,
      0,
      `Expected no rejection email to ${baseline.email}; saw ${JSON.stringify(newEmails.map(mailboxEmailSummary))}`
    );

    await new Promise((resolve) => setTimeout(resolve, 100));
  } while (Date.now() <= deadline);
}

async function assertWelcomeEmail(world, personName, clubName) {
  const baseline = world.onboardingWelcomeEmailBaselines && world.onboardingWelcomeEmailBaselines[personName];
  assert.ok(baseline, `Expected welcome email baseline for ${personName}`);

  const emails = await waitForMailboxEmails(
    world,
    baseline.previousEmails.length + 1,
    `welcome email for ${personName} and ${clubName}`
  );
  const previousIds = baseline.previousEmails.map(mailboxMessageId).filter(Boolean);
  const newEmails = emails.filter((email) => !previousIds.includes(mailboxMessageId(email)));
  const welcomeEmail = newEmails.find(
    (email) =>
      email.subject === `Welcome to ${clubName} on Memba` &&
      mailboxEmailTo(email).includes(baseline.email) &&
      mailboxEmailText(email).includes(`Welcome to ${clubName} on Memba`)
  );

  assert.ok(
    welcomeEmail,
    `Expected welcome email to ${baseline.email} for ${clubName}; saw ${JSON.stringify(
      newEmails.map(mailboxEmailSummary)
    )}`
  );

  const welcomeLink = signInLinkFromTextBody(mailboxEmailText(welcomeEmail));
  assert.ok(welcomeLink, `Expected welcome email to include a sign-in link; saw ${mailboxEmailText(welcomeEmail)}`);

  world.onboardingWelcomeLinks = world.onboardingWelcomeLinks || {};
  world.onboardingWelcomeLinks[personName] = browserReachableUrl(world, welcomeLink);
}

async function followWelcomeLink(world, personName) {
  const link = world.onboardingWelcomeLinks && world.onboardingWelcomeLinks[personName];
  assert.ok(link, `Expected ${personName} to have a welcome link`);

  await world.page.goto(link);
}

async function assertSignedInToClub(world, personName, clubName) {
  const club = world.clubs[clubName] || clubByName(clubName);
  const email = requestEmailFor(personName, world);
  const identityLabel = clubIdentityLabelFor(world, personName, email);

  assert.ok(club, `Expected ${clubName} to be known before asserting signed-in club access`);
  world.clubs[clubName] = { clubId: club.clubId, name: club.clubName || clubName, slug: club.clubSlug || club.slug };

  await playwrightExpect(
    world.page.locator(`#member-club-home[data-club-id=${cssString(world.clubs[clubName].clubId)}]`)
  ).toBeVisible({ timeout: projectionTimeoutMs(world) });
  await playwrightExpect(world.page.locator("#club-site-identity-menu .app-menu__who-name")).toContainText(identityLabel);
}

function clubIdentityFallbackLabelFor(email) {
  return String(email).split("@")[0].trim() || "Member";
}

function clubIdentityLabelFor(world, personName, email) {
  const person = world.people && world.people[personName];
  const name = person && typeof person.name === "string" ? person.name.trim() : "";
  return name || clubIdentityFallbackLabelFor(email);
}

async function openConversionPanel(world, clubName) {
  await openRequestsInbox(world);

  const row = requestRow(world, clubName);
  await playwrightExpect(row).toBeVisible({ timeout: projectionTimeoutMs(world) });
  await row.getByRole("button", { name: `Convert request for ${clubName}` }).click();

  const panel = world.page.locator('[data-testid="convert-request-panel"]');
  await playwrightExpect(panel).toBeVisible({ timeout: projectionTimeoutMs(world) });
}

function requestRow(world, clubName) {
  return world.page.locator(
    `[data-testid="admin-request-row"][data-requested-club-name=${cssString(clubName)}]`
  );
}

function requestEmailFor(personName, world = null) {
  const person = world && world.people && world.people[personName];
  return person && person.email ? person.email : emailFor(personName);
}

function personFor(world, personName) {
  ensureState(world);
  const person = world.people && world.people[personName];
  assert.ok(person, `Expected ${personName} to be known in the scenario`);
  return person;
}

function lastRequestByPerson(world, personName) {
  const requests = Object.values(world.onboardingRequests || {}).filter(
    (request) => request.personName === personName
  );
  assert.ok(requests.length > 0, `Expected ${personName} to have made an onboarding request`);
  return requests[requests.length - 1];
}

function requestByClubName(clubName) {
  return serverCommands.runCommand(
    `
import Ecto.Query
club_name = Map.fetch!(payload, "clubName")

request =
  Memba.Onboarding.Request
  |> where([request], request.requested_club_name == ^club_name)
  |> order_by([request], desc: request.inserted_at)
  |> limit(1)
  |> Memba.Repo.one()

if request do
  %{
    requestId: request.request_id,
    requesterName: request.requester_name,
    requesterEmail: request.requester_email,
    requesterPersonId: request.requester_person_id,
    requestedClubName: request.requested_club_name,
    status: request.status
  }
else
  nil
end
`,
    { clubName }
  );
}

function clubByName(clubName) {
  return serverCommands.runCommand(
    `
import Ecto.Query
club_name = Map.fetch!(payload, "clubName")

club =
  Memba.Membership.Projections.Club
  |> where([club], club.name == ^club_name)
  |> order_by([club], desc: club.inserted_at)
  |> limit(1)
  |> Memba.Repo.one()

if club do
  %{clubId: club.club_id, clubName: club.name, clubSlug: club.slug}
else
  nil
end
`,
    { clubName }
  );
}

function activeMembership(personName, clubName, email) {
  return serverCommands.runCommand(
    `
import Ecto.Query
club_name = Map.fetch!(payload, "clubName")
email = Map.fetch!(payload, "email")

club =
  Memba.Membership.Projections.Club
  |> where([club], club.name == ^club_name)
  |> limit(1)
  |> Memba.Repo.one()

person = Memba.Membership.get_person_by_email(email)

membership =
  if club && person do
    Memba.Membership.Projections.Membership
    |> where([membership],
      membership.club_id == ^club.club_id and
        membership.person_id == ^person.person_id and
        membership.active == true
    )
    |> limit(1)
    |> Memba.Repo.one()
  end

if club && person && membership do
  %{
    clubId: club.club_id,
    clubName: club.name,
    clubSlug: club.slug,
    membershipId: membership.membership_id,
    personId: person.person_id,
    personName: person.name
  }
else
  nil
end
`,
    { clubName, email, personName }
  );
}

function personCountByEmail(email) {
  return serverCommands.runCommand(
    `
import Ecto.Query
email = Map.fetch!(payload, "email")

person_ids =
  Memba.Membership.Projections.Person
  |> where([person], person.email == ^email)
  |> order_by([person], asc: person.person_id)
  |> select([person], person.person_id)
  |> Memba.Repo.all()

%{count: length(person_ids), personIds: person_ids}
`,
    { email }
  );
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
    from: email.from,
    subject: email.subject,
    to: email.to,
    text_body: email.text_body
  };
}

function staffRequestLinkFromText(textBody) {
  const match = String(textBody || "").match(/https?:\/\/\S+\/admin\/requests\/req_[^\s<]+/);
  return match && match[0];
}

function signInLinkFromTextBody(textBody) {
  const match = String(textBody || "").match(/https?:\/\/\S+\/auth\/(?:sign-in|magic)\/\S+/);
  return match && match[0];
}

function browserReachableUrl(world, url) {
  const parsed = new URL(url, `${world.baseUrl}/`);
  const base = new URL(world.baseUrl);

  if (parsed.hostname === "localhost" || parsed.hostname === "127.0.0.1") {
    parsed.protocol = base.protocol;
    parsed.hostname = base.hostname;
    parsed.port = base.port;
  }

  return parsed.toString();
}

module.exports = {
  assertActiveMember,
  assertCannotSignInToClub,
  assertClubDoesNotExist,
  assertClubExists,
  assertKnownReadOnlyDetails,
  assertNoDuplicatePerson,
  assertPreparingToConvertRequest,
  assertRequestLeavesInbox,
  assertRequestRecordedWithKnownDetails,
  assertRequestVisible,
  assertRequesterNotEmailedAboutRejection,
  assertReviewAcknowledgement,
  assertSignedInToClub,
  assertStaffNotified,
  assertSuggestedSlug,
  assertWelcomeEmail,
  convertRequest,
  createRequestDirectly,
  ensurePerson,
  followStaffNotificationLink,
  followWelcomeLink,
  openGetStartedPage,
  openRequestsInbox,
  rejectRequest,
  signInPerson,
  submitRequestThroughBrowser
};
