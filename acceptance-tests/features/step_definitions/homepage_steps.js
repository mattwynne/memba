const { When, Then } = require("@cucumber/cucumber");
const {
  assertMembaHomepage,
  visitHomepage
} = require("../support/homepage");

When("I visit the homepage", async function () {
  await visitHomepage(this);
});

Then("I should see the Memba homepage", async function () {
  await assertMembaHomepage(this);
});
