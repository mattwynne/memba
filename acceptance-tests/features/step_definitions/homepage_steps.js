const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertHomepageFitsScreen,
  assertHomepageRequestAccess,
  assertHomepageSignIn,
  assertHomepageStaffAccess,
  assertMembaHomepage,
  assertNoHomepageVolunteeringPromise,
  assertHomepageVolunteeringPromise,
  visitHomepage
} = require("../support/homepage");

Given("I am using a phone", async function () {
  await this.page.setViewportSize({ width: 390, height: 844 });
});

When("I visit the homepage", async function () {
  await visitHomepage(this);
});

When("{word} visits the homepage", async function (_personName) {
  await visitHomepage(this);
});

Then("I should see the Memba homepage", async function () {
  await assertMembaHomepage(this);
});

Then("I should see that volunteering should not feel like work", async function () {
  await assertHomepageVolunteeringPromise(this);
});

Then("{word} should see that volunteering should not feel like work", async function (_personName) {
  await assertHomepageVolunteeringPromise(this);
});

Then("{word} should not see the public volunteering promise", async function (_personName) {
  await assertNoHomepageVolunteeringPromise(this);
});

Then("{word} should be invited to request access for a group", async function (_personName) {
  await assertHomepageRequestAccess(this);
});

Then("{word} should be offered to sign in", async function (_personName) {
  await assertHomepageSignIn(this);
});

Then("{word} should be offered Memba staff access", async function (_personName) {
  await assertHomepageStaffAccess(this);
});

Then("the homepage should fit the screen", async function () {
  await assertHomepageFitsScreen(this);
});
