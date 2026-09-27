const { Then } = require("@cucumber/cucumber");
const {
  assertActiveMember,
  assertSignedInToClub
} = require("../support/request_account");

Then(/^(\w+) should be an active member of (.+)$/, function (personName, clubName) {
  assertActiveMember(this, personName, clubName);
});

Then(/^(\w+) should be signed in to (.+)$/, async function (personName, clubName) {
  await assertSignedInToClub(this, personName, clubName);
});
