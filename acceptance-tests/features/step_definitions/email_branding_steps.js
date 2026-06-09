const { Then } = require("@cucumber/cucumber");
const {
  assertReceivesSignInEmailWithMembaSprigIcon,
  assertSignInEmailUsesStandardMembaFooter
} = require("../support/authentication");
const {
  assertInboundRejectionEmailFrom,
  assertInboundRejectionEmailUsesStandardMembaFooter
} = require("../support/member_message");

Then("{word} should receive a sign-in email with the Memba sprig icon", async function (personName) {
  await assertReceivesSignInEmailWithMembaSprigIcon(this, personName);
});

Then("the sign-in email should use the standard Memba footer", async function () {
  await assertSignInEmailUsesStandardMembaFooter(this, "Alice");
});

Then("{word} should receive a rejection email from {string}", async function (senderName, expectedFromName) {
  await assertInboundRejectionEmailFrom(this, senderName, expectedFromName);
});

Then("the rejection email should use the standard Memba footer", async function () {
  await assertInboundRejectionEmailUsesStandardMembaFooter(this, "Robin");
});
