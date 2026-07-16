const assert = require("node:assert/strict");
const { expect: playwrightExpect } = require("@playwright/test");
const {
  appUrl,
  clubSiteUrl,
  cssString,
  emailFor,
  ensureState,
  projectionTimeoutMs,
  testMailboxEmails,
  waitForMailboxEmails
} = require("./member_message");
const { ensureMember, signInAsStaffDirectly, signInDirectly } = require("./authentication");
const serverCommands = require("./server_commands");

async function ensureClub(world, clubName) {
  ensureState(world);

  if (world.clubs[clubName]) {
    return world.clubs[clubName];
  }

  const club = serverCommands.ensureClub({
    clubName,
    clubSlug: clubSlugFor(clubName)
  });

  world.clubs[clubName] = {
    clubId: club.clubId,
    name: club.clubName,
    slug: club.clubSlug
  };

  return world.clubs[clubName];
}

async function ensurePerson(world, personName) {
  ensureState(world);

  if (world.people[personName] && world.people[personName].personId) {
    return world.people[personName];
  }

  const person = serverCommands.ensurePerson({
    personName,
    email: emailFor(personName)
  });

  world.people[personName] = personState(person.personName, person.email, person.personId);
  return world.people[personName];
}

async function ensurePersonIsNotMember(world, personName, clubName) {
  const club = await ensureClub(world, clubName);
  await ensurePerson(world, personName);

  assert.equal(
    activeMembershipCountByEmail(club.clubId, emailForPerson(world, personName)),
    0,
    `Expected ${personName} not to be an active member of ${clubName}`
  );
}

async function ensureActiveMember(world, personName, clubName) {
  const member = await ensureMember(world, personName, clubName);
  return member;
}

async function inviteEmailToClub(world, actorName, email, clubName, options = {}) {
  const club = await ensureClub(world, clubName);
  const previousEmails = await testMailboxEmails(world);

  if (actorHasClubMembership(world, actorName, clubName)) {
    await submitMemberInvitation(world, actorName, club, email);
  } else {
    await submitStaffInvitation(world, actorName, club, email);
  }

  world.clubMemberInvitationRequests = world.clubMemberInvitationRequests || [];
  world.clubMemberInvitationRequests.push({
    actorName,
    clubName,
    email: normalizeEmail(email),
    previousEmails,
    resend: Boolean(options.resend)
  });
}

async function tryInviteEmailToClub(world, actorName, email, clubName) {
  const club = await ensureClub(world, clubName);
  const previousEmails = await testMailboxEmails(world);
  const attempt = { actorName, clubName, email: normalizeEmail(email), previousEmails };

  if (actorHasClubMembership(world, actorName, clubName)) {
    const response = await openMemberInvitationForm(world, actorName, club);
    attempt.status = response && response.status();

    if (attempt.status === 403) {
      attempt.rejected = true;
      attempt.message = await safeText(response);
    } else {
      await fillAndSubmitMemberInvitation(world, email);
      attempt.submitted = true;
    }
  } else {
    await submitStaffInvitation(world, actorName, club, email);
    attempt.submitted = true;
  }

  world.lastClubMemberInvitationAttempt = attempt;

  if (attempt.submitted) {
    world.clubMemberInvitationRequests = world.clubMemberInvitationRequests || [];
    world.clubMemberInvitationRequests.push({
      actorName,
      clubName,
      email: normalizeEmail(email),
      previousEmails,
      tryOnly: true
    });
  }
}

async function invitePersonToClub(world, actorName, personName, clubName, options = {}) {
  const person = await ensurePerson(world, personName);
  await inviteEmailToClub(world, actorName, person.email, clubName, options);
}

async function tryInvitePersonToClub(world, actorName, personName, clubName) {
  const person = await ensurePerson(world, personName);
  await tryInviteEmailToClub(world, actorName, person.email, clubName);
  world.lastClubMemberInvitationAttempt.personName = personName;
}

async function assertInvitationReceived(world, recipient, clubName, options = {}) {
  ensureState(world);
  const emailAddress = recipientEmail(world, recipient);
  const request = latestInvitationRequest(world, emailAddress, clubName);
  const expectedCount = request.previousEmails.length + 1;
  const emails = await waitForMailboxEmails(
    world,
    expectedCount,
    `club member invitation email for ${emailAddress}`
  );
  const previousIds = request.previousEmails.map(mailboxMessageId).filter(Boolean);
  const newEmails = emails.filter((email) => !previousIds.includes(mailboxMessageId(email)));
  const invitationEmail = newEmails.find((email) => invitationEmailMatches(email, emailAddress, clubName));

  assert.ok(
    invitationEmail,
    `Expected ${emailAddress} to receive an invitation to ${clubName}; saw ${JSON.stringify(
      newEmails.map(emailSummary)
    )}`
  );

  const invitationLink = invitationLinkFromEmail(invitationEmail);
  assert.ok(invitationLink, `Expected invitation email to include a link; saw ${invitationEmail.text_body}`);

  const recipientName = recipientNameFor(world, recipient, emailAddress);
  rememberInvitationLink(world, recipientName, clubName, browserAppUrl(world, invitationLink));

  if (options.another) {
    world.clubMemberInvitationEmailCounts = world.clubMemberInvitationEmailCounts || {};
    const key = invitationKey(emailAddress, clubName);
    world.clubMemberInvitationEmailCounts[key] = (world.clubMemberInvitationEmailCounts[key] || 0) + 1;
    assert.ok(
      world.clubMemberInvitationEmailCounts[key] >= 1,
      `Expected another invitation email count for ${emailAddress} to ${clubName}`
    );
  }
}

async function assertInvitationNotReceived(world, recipient, clubName) {
  ensureState(world);
  const emailAddress = recipientEmail(world, recipient);
  const attempt = latestInvitationAttempt(world, emailAddress, clubName);
  const previousIds = attempt.previousEmails.map(mailboxMessageId).filter(Boolean);
  const deadline = Date.now() + 1000;

  do {
    const emails = await testMailboxEmails(world);
    const newEmails = emails.filter((email) => !previousIds.includes(mailboxMessageId(email)));
    const invitations = newEmails.filter((email) => invitationEmailMatches(email, emailAddress, clubName));

    assert.deepEqual(
      invitations.map(emailSummary),
      [],
      `Expected ${emailAddress} not to receive an invitation to ${clubName}`
    );

    await new Promise((resolve) => setTimeout(resolve, 100));
  } while (Date.now() <= deadline);
}

async function assertNotActiveMember(world, personName, clubName) {
  const club = await ensureClub(world, clubName);
  const email = emailForPerson(world, personName);

  assert.equal(
    activeMembershipCountByEmail(club.clubId, email),
    0,
    `Expected ${personName} <${email}> not to be an active member of ${clubName}`
  );
}

async function followInvitationLink(world, personName, clubName, options = {}) {
  const link = invitationLinkFor(world, personName, clubName);
  await world.page.goto(link);

  if (options.same) {
    world.followedSameInvitationLink = true;
  }
}

async function assertAskedForName(world, personName, clubName) {
  const club = await ensureClub(world, clubName);

  await playwrightExpect(world.page).toHaveURL(/\/invitations\/club-members\/profile$/);
  await playwrightExpect(
    world.page.locator(`#club-member-profile-completion[data-club-id=${cssString(club.clubId)}]`)
  ).toBeVisible({ timeout: projectionTimeoutMs(world) });
  await playwrightExpect(world.page.getByRole("heading", { name: "Tell us your name" })).toBeVisible();
  await playwrightExpect(world.page.getByLabel("Your name")).toBeVisible();

  world.pendingProfileCompletion = { personName, clubName };
}

async function enterInviteeName(world, personName, name, clubName) {
  await world.page.getByLabel("Your name").fill(name);
  await world.page.locator("#complete-club-member-profile-button").click();

  const club = await ensureClub(world, clubName);
  await playwrightExpect(world.page.locator(`#member-club-home[data-club-id=${cssString(club.clubId)}]`)).toBeVisible({
    timeout: projectionTimeoutMs(world)
  });

  const person = personByEmail(emailForPerson(world, personName));
  assert.ok(person && person.personId, `Expected ${personName} to have a profile after accepting an invitation`);
  world.people[personName] = personState(person.personName || name.trim(), person.email, person.personId);
}

async function assertActiveMember(world, personName, clubName) {
  const club = await ensureClub(world, clubName);
  const email = emailForPerson(world, personName);

  assert.equal(
    activeMembershipCountByEmail(club.clubId, email),
    1,
    `Expected ${personName} <${email}> to be an active member of ${clubName}`
  );
}

async function assertOnlyOneActiveMembership(world, personName, clubName) {
  const club = await ensureClub(world, clubName);
  const email = emailForPerson(world, personName);

  assert.equal(
    activeMembershipCountByEmail(club.clubId, email),
    1,
    `Expected ${personName} <${email}> to have exactly one active membership of ${clubName}`
  );
}

async function assertSignedInToClub(world, personName, clubName) {
  const club = await ensureClub(world, clubName);
  const email = emailForPerson(world, personName);
  const identityLabel = clubIdentityLabelFor(world, personName, email);

  await playwrightExpect(world.page.locator(`#member-club-home[data-club-id=${cssString(club.clubId)}]`)).toBeVisible({
    timeout: projectionTimeoutMs(world)
  });
  await playwrightExpect(world.page.locator("#club-site-identity-menu .app-menu__who-name")).toContainText(identityLabel);
}

async function leaveWithoutEnteringName(world) {
  await world.page.goto(appUrl(world.baseUrl, "/"));
}

async function openAddMemberFlow(world, actorName, clubName) {
  const club = await ensureClub(world, clubName);
  await ensureStaffSignedIn(world, actorName);

  await world.page.goto(appUrl(world.baseUrl, `/admin/clubs/${club.clubId}`));
  await playwrightExpect(world.page.locator("#club-show")).toBeVisible({ timeout: projectionTimeoutMs(world) });
  await world.page.getByRole("link", { name: "Invite member" }).click();
  await playwrightExpect(world.page.locator("#club-member-invitation-new")).toBeVisible({
    timeout: projectionTimeoutMs(world)
  });
}

async function assertAskedForEmailOnly(world) {
  await playwrightExpect(world.page.locator("#club-member-invitation-form")).toBeVisible();
  await playwrightExpect(world.page.getByLabel("Invitee email address")).toBeVisible();
  await playwrightExpect(world.page.locator("#person-name-input")).toHaveCount(0);
  await playwrightExpect(world.page.getByLabel("Person name")).toHaveCount(0);
}

async function assertCannotCreateDirectActiveMember(world) {
  await playwrightExpect(world.page.locator("#club-member-invitation-form")).toBeVisible();
  await playwrightExpect(world.page.getByRole("button", { name: "Add selected person as member" })).toHaveCount(0);
  await playwrightExpect(world.page.getByRole("button", { name: "Create person" })).toHaveCount(0);
  await playwrightExpect(world.page.getByLabel("Person to add as member")).toHaveCount(0);
}

async function assertAlreadyMemberMessage(world, personName, clubName) {
  const attempt = world.lastClubMemberInvitationAttempt;
  assert.ok(attempt, "Expected an invitation attempt before checking the already-member message");
  assert.equal(attempt.personName || personName, personName);
  assert.equal(attempt.clubName, clubName);

  await playwrightExpect(
    world.page.getByText("That email address is already an active member of this club.")
  ).toBeVisible({ timeout: projectionTimeoutMs(world) });
}

async function assertSinglePendingInvitation(world, email, clubName) {
  const club = await ensureClub(world, clubName);
  const normalizedEmail = normalizeEmail(email);
  const count = pendingInvitationCount(club.clubId, normalizedEmail);

  assert.equal(
    count,
    1,
    `Expected one pending invitation for ${normalizedEmail} to ${clubName}, got ${count}`
  );
}

async function assertCannotInviteMembers(world, actorName, clubName) {
  const attempt = world.lastClubMemberInvitationAttempt;

  assert.ok(attempt, "Expected an invitation attempt before checking authorization rejection");
  assert.equal(attempt.actorName, actorName);
  assert.equal(attempt.clubName, clubName);
  assert.equal(attempt.rejected, true, `Expected ${actorName}'s invitation attempt to be rejected`);
  assert.equal(attempt.status, 403);
  assert.match(attempt.message || "", /Forbidden|forbidden|cannot invite|not authorized/i);

  if (world.page) {
    await playwrightExpect(world.page.locator("#member-club-invitation-form")).toHaveCount(0);
  }
}

async function inviteAndAccept(world, personName, email, clubName, fullName) {
  await ensureClub(world, clubName);
  await inviteEmailToClub(world, "Pat", email, clubName);
  await assertInvitationReceived(world, email, clubName);
  await followInvitationLink(world, personName, clubName);
  await assertAskedForName(world, personName, clubName);
  await enterInviteeName(world, personName, fullName, clubName);
  await assertActiveMember(world, personName, clubName);
}

async function ensureStaffSignedIn(world, actorName) {
  if (world.staffSignedInAs === actorName) {
    return;
  }

  await signInAsStaffDirectly(world, actorName, { email: staffEmailFor(actorName) });
  world.staffSignedInAs = actorName;
}

async function submitStaffInvitation(world, actorName, club, email) {
  await ensureStaffSignedIn(world, actorName);

  await world.page.goto(appUrl(world.baseUrl, `/admin/clubs/${club.clubId}/invitations/new`));
  await playwrightExpect(world.page.locator("#club-member-invitation-new")).toBeVisible({
    timeout: projectionTimeoutMs(world)
  });

  await world.page.getByLabel("Invitee email address").fill(email);
  await world.page.locator("#send-club-member-invitation-button").click();
}

async function submitMemberInvitation(world, actorName, club, email) {
  await openMemberInvitationForm(world, actorName, club);
  await fillAndSubmitMemberInvitation(world, email);
}

async function openMemberInvitationForm(world, actorName, club) {
  await ensureMemberSignedIn(world, actorName);

  const response = await world.page.goto(clubSiteUrl(world.baseUrl, club, "/members/invitations/new"));

  if (response && response.status() === 403) {
    return response;
  }

  await playwrightExpect(world.page.locator("#member-club-invitation-new")).toBeVisible({
    timeout: projectionTimeoutMs(world)
  });
  await playwrightExpect(world.page.locator("#member-club-invitation-form")).toBeVisible();

  return response;
}

async function fillAndSubmitMemberInvitation(world, email) {
  await world.page.getByLabel("Invitee email address").fill(email);
  await world.page.locator("#send-member-club-invitation-button").click();
}

async function ensureMemberSignedIn(world, actorName) {
  const person = personFromWorld(world, actorName);
  await signInDirectly(world, person.email);
}

function activeMembershipCountByEmail(clubId, email) {
  return serverCommands.runCommand(
    `
import Ecto.Query

club_id = Map.fetch!(payload, "clubId")
email = Memba.Accounts.normalize_email(Map.fetch!(payload, "email"))

count =
  Memba.Membership.Projections.Membership
  |> join(:inner, [membership], email_address in Memba.Membership.Projections.PersonEmailAddress,
    on: email_address.person_id == membership.person_id
  )
  |> where([membership, _email_address], membership.club_id == ^club_id)
  |> where([membership, _email_address], membership.active == true)
  |> where([_membership, email_address], email_address.normalized_email == ^email)
  |> Memba.Repo.aggregate(:count, :membership_id)

%{count: count}
`,
    { clubId, email }
  ).count;
}

function pendingInvitationCount(clubId, email) {
  return serverCommands.runCommand(
    `
import Ecto.Query

club_id = Map.fetch!(payload, "clubId")
email = Memba.Accounts.normalize_email(Map.fetch!(payload, "email"))

count =
  Memba.Membership.Projections.ClubInvitation
  |> where([invitation], invitation.club_id == ^club_id)
  |> where([invitation], invitation.normalized_email == ^email)
  |> where([invitation], invitation.status == "pending")
  |> Memba.Repo.aggregate(:count, :invitation_id)

%{count: count}
`,
    { clubId, email }
  ).count;
}

function personByEmail(email) {
  return serverCommands.runCommand(
    `
email = Memba.Accounts.normalize_email(Map.fetch!(payload, "email"))

case Memba.Membership.get_person_by_email(email) do
  nil -> %{personId: nil}
  person -> %{personId: person.person_id, personName: person.name, email: person.email}
end
`,
    { email }
  );
}

function latestInvitationRequest(world, email, clubName) {
  const normalizedEmail = normalizeEmail(email);
  const matchingRequests = (world.clubMemberInvitationRequests || []).filter(
    (request) => request.email === normalizedEmail && request.clubName === clubName
  );
  const request = matchingRequests[matchingRequests.length - 1];

  assert.ok(request, `Expected an invitation request for ${normalizedEmail} to ${clubName}`);
  return request;
}

function latestInvitationAttempt(world, email, clubName) {
  const normalizedEmail = normalizeEmail(email);
  const matchingAttempts = [world.lastClubMemberInvitationAttempt]
    .concat(world.clubMemberInvitationRequests || [])
    .filter(Boolean)
    .filter((attempt) => attempt.email === normalizedEmail && attempt.clubName === clubName);
  const attempt = matchingAttempts[matchingAttempts.length - 1];

  assert.ok(attempt, `Expected an invitation attempt for ${normalizedEmail} to ${clubName}`);
  return attempt;
}

function rememberInvitationLink(world, personName, clubName, link) {
  world.clubMemberInvitationLinks = world.clubMemberInvitationLinks || {};
  world.clubMemberInvitationLinks[personName] = world.clubMemberInvitationLinks[personName] || {};
  world.clubMemberInvitationLinks[personName][clubName] = link;
}

function invitationLinkFor(world, personName, clubName) {
  const link = world.clubMemberInvitationLinks && world.clubMemberInvitationLinks[personName] && world.clubMemberInvitationLinks[personName][clubName];
  assert.ok(link, `Expected ${personName} to have an invitation link for ${clubName}`);
  return link;
}

function invitationEmailMatches(email, recipientEmail, clubName) {
  return (
    email.subject === `You're invited to join ${clubName}` &&
    Array.isArray(email.to) &&
    email.to.some((recipient) => String(recipient).includes(recipientEmail)) &&
    String(email.text_body || "").includes("/invitations/club-members/")
  );
}

function invitationLinkFromEmail(email) {
  const match = String(email.text_body || "").match(/https?:\/\/\S+\/invitations\/club-members\/\S+/);
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
  return email && (email.id || (email.headers && email.headers["Message-ID"]));
}

function emailSummary(email) {
  return { subject: email.subject, to: email.to, text_body: email.text_body };
}

function recipientEmail(world, recipient) {
  if (String(recipient).includes("@")) {
    return normalizeEmail(recipient);
  }

  return emailForPerson(world, recipient);
}

function recipientNameFor(world, recipient, email) {
  if (!String(recipient).includes("@")) {
    return recipient;
  }

  const personName = personNameFromEmail(email);
  ensureState(world);
  world.people[personName] = world.people[personName] || personState(personName, email, null);
  return personName;
}

function emailForPerson(world, personName) {
  ensureState(world);

  if (world.people[personName] && world.people[personName].email) {
    return normalizeEmail(world.people[personName].email);
  }

  return normalizeEmail(emailFor(personName));
}

function personNameFromEmail(email) {
  const localPart = String(email).split("@")[0] || "invitee";
  return localPart
    .split(/[^a-z0-9]+/i)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(" ") || "Invitee";
}

function personState(personName, email, personId) {
  const normalizedEmail = normalizeEmail(email);

  return {
    alternateEmails: [],
    email: normalizedEmail,
    emailAddresses: [{ email: normalizedEmail, isPrimary: true }],
    name: personName,
    personId,
    primaryEmail: normalizedEmail
  };
}

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function clubIdentityFallbackLabelFor(email) {
  return String(email).split("@")[0].trim() || "Member";
}

function clubIdentityLabelFor(world, personName, email) {
  const person = world.people && world.people[personName];
  const name = person && typeof person.name === "string" ? person.name.trim() : "";
  return name || clubIdentityFallbackLabelFor(email);
}

function clubSlugFor(clubName) {
  return String(clubName || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 32)
    .replace(/^-+|-+$/g, "");
}

function staffEmailFor(personName) {
  return `${String(personName).trim().toLowerCase()}@memba.io`;
}

function actorHasClubMembership(world, actorName, clubName) {
  ensureState(world);
  return Boolean(world.memberships && world.memberships[`${clubName}:${actorName}`]);
}

function personFromWorld(world, personName) {
  ensureState(world);
  const person = world.people && world.people[personName];

  assert.ok(person, `Expected ${personName} to be known in the scenario`);
  assert.ok(person.email, `Expected ${personName} to have an email address`);

  return person;
}

async function safeText(response) {
  if (!response || typeof response.text !== "function") {
    return "";
  }

  try {
    return await response.text();
  } catch (_error) {
    return "";
  }
}

function invitationKey(email, clubName) {
  return `${clubName}:${normalizeEmail(email)}`;
}

module.exports = {
  assertActiveMember,
  assertAlreadyMemberMessage,
  assertAskedForEmailOnly,
  assertAskedForName,
  assertCannotInviteMembers,
  assertCannotCreateDirectActiveMember,
  assertInvitationReceived,
  assertInvitationNotReceived,
  assertNotActiveMember,
  assertOnlyOneActiveMembership,
  assertSignedInToClub,
  assertSinglePendingInvitation,
  ensureActiveMember,
  ensureClub,
  ensurePerson,
  ensurePersonIsNotMember,
  enterInviteeName,
  followInvitationLink,
  inviteAndAccept,
  inviteEmailToClub,
  invitePersonToClub,
  leaveWithoutEnteringName,
  openAddMemberFlow,
  tryInviteEmailToClub,
  tryInvitePersonToClub
};
