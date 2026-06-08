const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertMembershipAdministrator,
  assertNotMembershipAdministrator,
  assertOrdinaryMember,
  ensureMembershipAdministrator,
  ensureOnlyMembershipAdministrator,
  ensureOrdinaryMember,
  makeMembershipAdministrator,
  tryMakeMembershipAdministrator,
  tryRemoveMembershipAdministrator
} = require("../support/membership_administration");

Given(/^(\w+) is an Admin of (.+)$/, function (personName, clubName) {
  ensureMembershipAdministrator(this, personName, clubName);
});

Given(/^(\w+) is a Membership Admin of (.+)$/, function (personName, clubName) {
  ensureMembershipAdministrator(this, personName, clubName);
});

Given(/^(\w+) is the only Admin of (.+)$/, function (personName, clubName) {
  ensureOnlyMembershipAdministrator(this, personName, clubName);
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

Then(/^(\w+) should be an Admin of (.+)$/, function (personName, clubName) {
  assertMembershipAdministrator(this, personName, clubName);
});

Then(/^(\w+) should still be an Admin of (.+)$/, function (personName, clubName) {
  assertMembershipAdministrator(this, personName, clubName);
});

Then(/^(\w+) should not be an Admin of (.+)$/, function (personName, clubName) {
  assertNotMembershipAdministrator(this, personName, clubName);
});

Then(/^(\w+) should be an ordinary member of (.+)$/, function (personName, clubName) {
  assertOrdinaryMember(this, personName, clubName);
});
