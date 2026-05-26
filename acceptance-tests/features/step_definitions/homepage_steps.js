const { When, Then } = require("@cucumber/cucumber");
const { expect } = require("@playwright/test");

When("I visit the homepage", async function () {
  await this.page.goto(this.baseUrl);
});

Then("I should see the Memba homepage", async function () {
  await expect(this.page).toHaveTitle(/Memba/);
});
