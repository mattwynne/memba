const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertDoesNotReceiveSignInLink,
  assertNotSignedIn,
  assertOnStaffOnlyHomepage,
  assertReceivesSignInLink,
  assertSeesClub,
  assertSignedIn,
  assertSignedInAsStaff,
  ensureMember,
  expireSignInLink,
  followSameSignInLinkAgain,
  followSignInLink,
  followUnissuedSignInLink,
  recordNonMember,
  requestSignInLinkForEmail,
  requestSignInLinkForPerson,
  tryOpenStaffOnlyArea
} = require("../support/authentication");

Given("{word} is a member of Kootenay Mountaineering Club", async function (personName) {
  await ensureMember(this, personName, "Kootenay Mountaineering Club");
});

Given("Alice is a member of Nelson Paddling Club", async function () {
  await ensureMember(this, "Alice", "Nelson Paddling Club");
});

Given("{word} is not a member of any club", async function (personName) {
  await recordNonMember(this, personName);
});

When("{word} requests a sign-in link for their email address", async function (personName) {
  await requestSignInLinkForPerson(this, personName);
});

When("{word} requests a sign-in link for {string}", async function (personName, email) {
  await requestSignInLinkForEmail(this, email, personName);
});

Then("{word} should receive a sign-in link", async function (personName) {
  await assertReceivesSignInLink(this, personName);
});

Then("{word} should not receive a sign-in link", async function (personName) {
  await assertDoesNotReceiveSignInLink(this, personName);
});

When("{word} follows the sign-in link", async function (personName) {
  await followSignInLink(this, personName);
});

When("{word} follows the same sign-in link again", async function (personName) {
  await followSameSignInLinkAgain(this, personName);
});

When("{word} follows a sign-in link that Memba did not issue", async function (_personName) {
  await followUnissuedSignInLink(this);
});

Given("{word} has received a sign-in link for their email address", async function (personName) {
  await requestSignInLinkForPerson(this, personName);
  await assertReceivesSignInLink(this, personName);
});

Given("{word} has already followed the sign-in link", async function (personName) {
  await followSignInLink(this, personName);
});

Given("the sign-in link has expired", async function () {
  await expireSignInLink(this, "Alice");
});

Given("{word} has tried to open the staff-only area", async function (_personName) {
  await tryOpenStaffOnlyArea(this);
});

Then("{word} should be signed in", async function (personName) {
  await assertSignedIn(this, personName);
});

Then("{word} should be signed in as Memba staff", async function (personName) {
  await assertSignedInAsStaff(this, personName);
});

Then("{word} should not be signed in", async function (_personName) {
  await assertNotSignedIn(this);
});

Then("{word} should be on the staff-only homepage", async function (_personName) {
  await assertOnStaffOnlyHomepage(this);
});

Then("{word} should see Kootenay Mountaineering Club in their clubs", async function (_personName) {
  await assertSeesClub(this, "Kootenay Mountaineering Club");
});

Then("{word} should see Nelson Paddling Club in their clubs", async function (_personName) {
  await assertSeesClub(this, "Nelson Paddling Club");
});

Then("{word} should be able to see Kootenay Mountaineering Club in their clubs", async function (_personName) {
  await assertSeesClub(this, "Kootenay Mountaineering Club");
});
