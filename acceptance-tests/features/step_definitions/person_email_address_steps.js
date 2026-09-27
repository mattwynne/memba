const { Given } = require("@cucumber/cucumber");
const { assertSignedInAsStaff, signInAsStaffDirectly } = require("../support/authentication");

Given("{word} is signed in as Memba staff", async function (personName) {
  await signInAsStaffDirectly(this, personName, { email: staffEmailFor(personName) });
  await assertSignedInAsStaff(this, personName);
});

function staffEmailFor(personName) {
  return `${String(personName).trim().toLowerCase()}@memba.io`;
}
