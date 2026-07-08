const { Given, When, Then } = require("@cucumber/cucumber");
const { removeMemberFromClub } = require("../support/member_message");
const {
  assertMemberAbsent,
  assertMemberHasNoRoles,
  assertMemberRoles,
  assertMembersPresent,
  ensureActiveMembers,
  ensureMemberRoles,
  parsePersonList,
  viewMemberList
} = require("../support/list_members");

Given(
  /^Alice, Bob, and Carol are active members of (.+)$/,
  async function (clubName) {
    ensureActiveMembers(this, ["Alice", "Bob", "Carol"], clubName);
  }
);

Given(/^(\w+) has the roles (.+) and (.+) in (.+)$/, async function (personName, firstRole, secondRole, clubName) {
  ensureMemberRoles(this, personName, [firstRole, secondRole], clubName);
});

Given(/^(\w+) has the role (.+) in (.+)$/, async function (personName, roleName, clubName) {
  ensureMemberRoles(this, personName, [roleName], clubName);
});

Given(/^(\w+) is removed from (.+)$/, async function (personName, clubName) {
  removeMemberFromClub(this, personName, clubName);
});

When(/^(\w+) views the member list for (.+)$/, async function (viewerName, clubName) {
  await viewMemberList(this, viewerName, clubName);
});

Then(
  /^(\w+)'s member row should show the roles (.+) and (.+)$/,
  async function (personName, firstRole, secondRole) {
    await assertMemberRoles(this, personName, [firstRole, secondRole]);
  }
);

Then(/^(\w+)'s member row should show the role (.+)$/, async function (personName, roleName) {
  await assertMemberRoles(this, personName, [roleName]);
});

Then(/^(\w+)'s member row should show no roles$/, async function (personName) {
  await assertMemberHasNoRoles(this, personName);
});

Then(/^(\w+) should not appear in the member list$/, async function (personName) {
  await assertMemberAbsent(this, personName);
});

Then(/^(.+) should appear in the member list$/, async function (personNamesText) {
  await assertMembersPresent(this, parsePersonList(personNamesText));
});
