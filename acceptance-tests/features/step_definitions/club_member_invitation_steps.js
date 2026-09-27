const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertAskedForName,
  assertInvitationReceived,
  enterInviteeName,
  followInvitationLink,
  inviteEmailToClub
} = require("../support/club_member_invitations");

Given("{word} has invited {string} to join {word} {word} {word}", async function (actorName, email, word1, word2, word3) {
  await inviteEmailToClub(this, actorName, email, clubName(word1, word2, word3));
  await assertInvitationReceived(this, email, clubName(word1, word2, word3));
});

When("{word} accepts the invitation as {string}", async function (personName, name) {
  const targetClubName = inferredClubName(this);
  await followInvitationLink(this, personName, targetClubName);
  await assertAskedForName(this, personName, targetClubName);
  await enterInviteeName(this, personName, name, targetClubName);
});

Then("{string} should receive an invitation to join {word} {word} {word}", async function (email, word1, word2, word3) {
  await assertInvitationReceived(this, email, clubName(word1, word2, word3));
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
