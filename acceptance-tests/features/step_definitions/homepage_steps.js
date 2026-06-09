const { Given, When, Then } = require("@cucumber/cucumber");
const {
  assertHomepageFitsScreen,
  assertMembaHomepage,
  assertHomepageVolunteeringPromise,
  visitHomepage
} = require("../support/homepage");

Given("I am using a phone", async function () {
  await this.page.setViewportSize({ width: 390, height: 844 });
});

When("I visit the homepage", async function () {
  await visitHomepage(this);
});

Then("I should see the Memba homepage", async function () {
  await assertMembaHomepage(this);
});

Then("I should see that volunteering should not feel like work", async function () {
  await assertHomepageVolunteeringPromise(this);
});

Then("the homepage should fit the screen", async function () {
  await assertHomepageFitsScreen(this);
});
