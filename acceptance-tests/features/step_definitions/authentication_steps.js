const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertReceivesSignInLink,
  assertSeesClub,
  assertSignedIn,
  assertSignedOut,
  ensureMember,
  followSignInLink,
  requestSignInLinkForPerson,
  signOut
} = require("../support/authentication");

Given(
  "{word} is a member of Kootenay Mountaineering Club",
  { timeout: 60000 },
  async function (personName) {
    await ensureMember(this, personName, "Kootenay Mountaineering Club");
  }
);

Given("Alice is a member of Nelson Paddling Club", async function () {
  await ensureMember(this, "Alice", "Nelson Paddling Club");
});

When("{word} signs in with their email address", async function (personName) {
  await requestSignInLinkForPerson(this, personName);
  await assertReceivesSignInLink(this, personName);
  await followSignInLink(this, personName);
});

Then("{word} should be signed in", async function (personName) {
  await assertSignedIn(this, personName);
});

When("{word} signs out", async function (_personName) {
  await signOut(this);
});

Then("{word} should be signed out", async function (_personName) {
  await assertSignedOut(this);
});

Then("{word} should see Kootenay Mountaineering Club in their clubs", async function (_personName) {
  await assertSeesClub(this, "Kootenay Mountaineering Club");
});
