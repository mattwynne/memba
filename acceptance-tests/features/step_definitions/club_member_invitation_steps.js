const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertAlreadyMemberMessage,
  assertAskedForEmailOnly,
  assertAskedForName,
  assertCannotCreateDirectActiveMember,
  assertCannotInviteMembers,
  assertActiveMember,
  assertInvitationReceived,
  assertInvitationNotReceived,
  assertNotActiveMember,
  assertOnlyOneActiveMembership,
  assertSinglePendingInvitation,
  ensureActiveMember,
  ensureClub,
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
} = require("../support/club_member_invitations");
const {
  assertNotMembershipAdministrator,
  ensureMembershipAdministrator
} = require("../support/membership_administration");

Given("{word} {word} {word} exists as a club", async function (word1, word2, word3) {
  await ensureClub(this, clubName(word1, word2, word3));
});

Given("{word} is not a member of {word} {word} {word}", async function (personName, word1, word2, word3) {
  await ensurePersonIsNotMember(this, personName, clubName(word1, word2, word3));
});

Given("{word} is a Membership Admin of {word} {word} {word}", async function (personName, word1, word2, word3) {
  ensureMembershipAdministrator(this, personName, clubName(word1, word2, word3));
});

Given("{word} is an active member of {word} {word} {word}", async function (personName, word1, word2, word3) {
  await ensureActiveMember(this, personName, clubName(word1, word2, word3));
});

Given("{word} has invited {string} to join {word} {word} {word}", async function (actorName, email, word1, word2, word3) {
  await inviteEmailToClub(this, actorName, email, clubName(word1, word2, word3));
  await assertInvitationReceived(this, email, clubName(word1, word2, word3));
});

Given(/^(\w+) has invited (\w+) to join (\w+) (\w+) (\w+)$/, async function (actorName, personName, word1, word2, word3) {
  const targetClubName = clubName(word1, word2, word3);
  await invitePersonToClub(this, actorName, personName, targetClubName);
  await assertInvitationReceived(this, personName, targetClubName);
});

Given("{word} has accepted an invitation to join {word} {word} {word}", async function (personName, word1, word2, word3) {
  const targetClubName = clubName(word1, word2, word3);
  await inviteAndAccept(this, personName, `${personName.toLowerCase()}@example.com`, targetClubName, `${personName} Example`);
});

When("{word} invites {string} to join {word} {word} {word}", async function (actorName, email, word1, word2, word3) {
  await inviteEmailToClub(this, actorName, email, clubName(word1, word2, word3));
});

When(/^(\w+) invites (\w+) to join (\w+) (\w+) (\w+)$/, async function (actorName, personName, word1, word2, word3) {
  await invitePersonToClub(this, actorName, personName, clubName(word1, word2, word3));
});

When("{word} invites {string} to join {word} {word} {word} again", async function (actorName, email, word1, word2, word3) {
  await inviteEmailToClub(this, actorName, email, clubName(word1, word2, word3), { resend: true });
});

When("{word} follows the invitation link", async function (personName) {
  await followInvitationLink(this, personName, inferredClubName(this));
});

When("{word} accepts the invitation", async function (personName) {
  const targetClubName = inferredClubName(this);
  await followInvitationLink(this, personName, targetClubName);
});

When("{word} accepts the invitation as {string}", async function (personName, name) {
  const targetClubName = inferredClubName(this);
  await followInvitationLink(this, personName, targetClubName);
  await assertAskedForName(this, personName, targetClubName);
  await enterInviteeName(this, personName, name, targetClubName);
});

When("{word} returns to the invitation and completes their profile as {string}", async function (personName, name) {
  const targetClubName = inferredClubName(this);
  await followInvitationLink(this, personName, targetClubName, { same: true });
  await assertAskedForName(this, personName, targetClubName);
  await enterInviteeName(this, personName, name, targetClubName);
});

When("{word} follows the same invitation link again", async function (personName) {
  await followInvitationLink(this, personName, inferredClubName(this), { same: true });
});

When("{word} enters {string} as their name", async function (personName, name) {
  await enterInviteeName(this, personName, name, inferredClubName(this));
});

When("{word} leaves without entering their name", async function (_personName) {
  await leaveWithoutEnteringName(this);
});

When("{word} wants to add a new member to {word} {word} {word}", async function (actorName, word1, word2, word3) {
  await openAddMemberFlow(this, actorName, clubName(word1, word2, word3));
});

When(/^(\w+) tries to invite (\w+) to join (\w+) (\w+) (\w+)$/, async function (actorName, personName, word1, word2, word3) {
  await tryInvitePersonToClub(this, actorName, personName, clubName(word1, word2, word3));
});

When("{word} tries to invite {string} to join {word} {word} {word}", async function (actorName, email, word1, word2, word3) {
  await tryInviteEmailToClub(this, actorName, email, clubName(word1, word2, word3));
});

Then("{string} should receive an invitation to join {word} {word} {word}", async function (email, word1, word2, word3) {
  await assertInvitationReceived(this, email, clubName(word1, word2, word3));
});

Then("{string} should receive another invitation to join {word} {word} {word}", async function (email, word1, word2, word3) {
  await assertInvitationReceived(this, email, clubName(word1, word2, word3), { another: true });
});

Then(/^(\w+) should receive an invitation to join (\w+) (\w+) (\w+)$/, async function (personName, word1, word2, word3) {
  await assertInvitationReceived(this, personName, clubName(word1, word2, word3));
});

Then("{word} should not be an active member of {word} {word} {word} yet", async function (personName, word1, word2, word3) {
  await assertNotActiveMember(this, personName, clubName(word1, word2, word3));
});

Then("{word} should still not be an active member of {word} {word} {word}", async function (personName, word1, word2, word3) {
  await assertNotActiveMember(this, personName, clubName(word1, word2, word3));
});

Then("{word} should be asked for their name", async function (personName) {
  await assertAskedForName(this, personName, inferredClubName(this));
});

Then("{word} should be asked for the member's email address only", async function (_actorName) {
  await assertAskedForEmailOnly(this);
});

Then("{word} should not be able to create an active member directly from a name and email address", async function (_actorName) {
  await assertCannotCreateDirectActiveMember(this);
});

Then("{word} should see that {word} is already a member of {word} {word} {word}", async function (_actorName, personName, word1, word2, word3) {
  await assertAlreadyMemberMessage(this, personName, clubName(word1, word2, word3));
});

Then("{word} should be an ordinary member of {word} {word} {word}", async function (personName, word1, word2, word3) {
  const targetClubName = clubName(word1, word2, word3);

  await assertActiveMember(this, personName, targetClubName);
  assertNotMembershipAdministrator(this, personName, targetClubName);
});

Then("{word} should be told they cannot invite members to {word} {word} {word}", async function (actorName, word1, word2, word3) {
  await assertCannotInviteMembers(this, actorName, clubName(word1, word2, word3));
});

Then("{word} should be told she cannot invite members to {word} {word} {word}", async function (actorName, word1, word2, word3) {
  await assertCannotInviteMembers(this, actorName, clubName(word1, word2, word3));
});

Then("{string} should not receive an invitation to join {word} {word} {word}", async function (email, word1, word2, word3) {
  await assertInvitationNotReceived(this, email, clubName(word1, word2, word3));
});

Then("there should still be only one pending invitation for {string} to join {word} {word} {word}", async function (email, word1, word2, word3) {
  await assertSinglePendingInvitation(this, email, clubName(word1, word2, word3));
});

Then("{word} should still have only one active membership of {word} {word} {word}", async function (personName, word1, word2, word3) {
  await assertOnlyOneActiveMembership(this, personName, clubName(word1, word2, word3));
});

function clubName(word1, word2, word3) {
  return [word1, word2, word3].join(" ");
}

function inferredClubName(world) {
  const clubNames = Object.keys(world.clubs || {});

  if (clubNames.length === 1) {
    return clubNames[0];
  }

  if (world.pendingProfileCompletion && world.pendingProfileCompletion.clubName) {
    return world.pendingProfileCompletion.clubName;
  }

  throw new Error(`Expected exactly one known club in the scenario; saw ${clubNames.join(", ")}`);
}
