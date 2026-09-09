const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertExactlyOneMembershipAdministrator,
  assertMemberRemovalBlocked,
  assertMembershipAdministrator,
  assertNotMembershipAdministrator,
  assertOnlyActiveMember,
  ensureClubHasNoActiveMembers,
  ensureMembershipAdministrator,
  ensureMembershipAdministrators,
  ensureOnlyMembershipAdministrator,
  ensureOrdinaryMember,
  makeMembershipAdministrator,
  removeMemberAsStaff,
  tryMakeMembershipAdministrator,
  tryRemoveMembershipAdministrator
} = require("../support/membership_administration");
const {
  assertActiveMember,
  assertNotActiveMember
} = require("../support/club_member_invitations");

Given(/^(\w+) is an Admin of (.+)$/, function (personName, clubName) {
  ensureMembershipAdministrator(this, personName, clubName);
});

Given(/^(.+) are members of the (.+) Admin group$/, function (personNamesText, clubName) {
  for (const personName of parsePersonList(personNamesText)) {
    ensureMembershipAdministrator(this, personName, clubName);
  }
});

Given(/^(\w+) is the only Admin of (.+)$/, function (personName, clubName) {
  ensureOnlyMembershipAdministrator(this, personName, clubName);
});

Given(/^(.+) are Admins of (.+)$/, function (personNamesText, clubName) {
  ensureMembershipAdministrators(this, parsePersonList(personNamesText), clubName);
});

Given(/^(.+) exists as a club with no active members$/, async function (clubName) {
  await ensureClubHasNoActiveMembers(this, clubName);
});

Given(/^(\w+) is the only active member of (.+)$/, function (personName, clubName) {
  assertOnlyActiveMember(this, personName, clubName);
});

Given(/^(\w+) is an ordinary member of (.+)$/, function (personName, clubName) {
  ensureOrdinaryMember(this, personName, clubName);
});

When(/^(\w+) makes (\w+) an Admin of (.+)$/, function (actorName, targetName, clubName) {
  makeMembershipAdministrator(this, actorName, targetName, clubName);
});

When(/^(\w+) tries to make (\w+) an Admin of (.+)$/, function (actorName, targetName, clubName) {
  tryMakeMembershipAdministrator(this, actorName, targetName, clubName);
});

When(
  /^(\w+) tries to remove (\w+) as an Admin of (.+)$/,
  function (actorName, targetName, clubName) {
    tryRemoveMembershipAdministrator(this, actorName, targetName, clubName);
  }
);

When(/^(\w+) tries to remove (\w+) from (.+)$/, async function (_actorName, targetName, clubName) {
  await removeMemberAsStaff(this, targetName, clubName);
});

When(/^(\w+) removes (\w+) from (.+)$/, async function (_actorName, targetName, clubName) {
  await removeMemberAsStaff(this, targetName, clubName);
});

Then(/^(\w+) should be an Admin of (.+)$/, function (personName, clubName) {
  assertMembershipAdministrator(this, personName, clubName);
});

Then(/^(\w+) should still be an Admin of (.+)$/, function (personName, clubName) {
  assertMembershipAdministrator(this, personName, clubName);
});

Then(/^(\w+) should not be an Admin of (.+)$/, function (personName, clubName) {
  assertNotMembershipAdministrator(this, personName, clubName);
});

Then(/^(\w+) should be told to make another member an Admin first$/, async function (_actorName) {
  await assertMemberRemovalBlocked(this, "Make another member an Admin before removing this member.");
});

Then(
  /^(\w+) should be told that an established club must retain an active member$/,
  async function (_actorName) {
    await assertMemberRemovalBlocked(this, "An established club must retain an active member.");
  }
);

Then(/^(\w+) should still be an active member of (.+)$/, async function (personName, clubName) {
  await assertActiveMember(this, personName, clubName);
});

Then(/^(\w+) should no longer be an active member of (.+)$/, async function (personName, clubName) {
  await assertNotActiveMember(this, personName, clubName);
});

Then(/^exactly one of (.+) should be an Admin of (.+)$/, function (personNamesText, clubName) {
  assertExactlyOneMembershipAdministrator(this, parsePersonList(personNamesText), clubName);
});

function parsePersonList(text) {
  return text
    .replace(/,?\s+and\s+/g, ", ")
    .split(/\s*,\s*/)
    .map((name) => name.trim())
    .filter(Boolean);
}
