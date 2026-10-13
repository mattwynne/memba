const { Given, When, Then } = require("@cucumber/cucumber");
const { expect } = require("@playwright/test");
const { ensureMember, signInDirectly, openClubPage, kootenayClubName } = require("../support/authentication");

async function openSettings(page) {
  await expect(page.locator(".phx-connected #club-site-identity-menu-button")).toBeVisible();
  const link = page.locator("#club-site-account-settings-link");
  if (!(await link.isVisible())) await page.locator("#club-site-identity-menu-button").click();
  await expect(link).toBeVisible();
  await link.click();
  await expect(page.locator("#my-settings")).toBeVisible();
  await expect(page.locator(".phx-connected #my-settings")).toBeVisible();
}

Given("Alice is signed in as a member of Kootenay Mountaineering Club", async function () {
  await ensureMember(this, "Alice Smith", kootenayClubName);
  this.people.Alice = this.people["Alice Smith"];
  await signInDirectly(this, "Alice");
  await openClubPage(this, kootenayClubName);
});

Given("Alice is known as {string}", async function (name) {
  await this.page.locator("#club-site-identity-menu-button").click();
  await expect(this.page.locator("#club-site-identity-menu .app-menu__who-name")).toHaveText(name);
  await this.page.locator("#club-site-identity-menu-button").click();
});

Given("Alice has an untouched name edit open in another Account settings tab", async function () {
  this.profileOtherPage = await this.context.newPage();
  await this.profileOtherPage.goto(this.page.url());
  await openSettings(this.profileOtherPage);
  await this.profileOtherPage.getByRole("button", { name: "Edit", exact: true }).click();
  await expect(this.profileOtherPage.getByLabel("Your name", { exact: true })).toHaveValue(this.people.Alice.name);
  this.profileOtherUrl = this.profileOtherPage.url();
  this.profileOtherNavigations = 0;
  this.profileOtherPage.on("framenavigated", (frame) => {
    if (frame === this.profileOtherPage.mainFrame()) this.profileOtherNavigations += 1;
  });
});

When("Alice opens Account settings from their member menu", async function () {
  await openSettings(this.page);
});

When("Alice edits their Profile name to {string} and saves it", async function (name) {
  await this.page.getByRole("button", { name: "Edit", exact: true }).click();
  await this.page.getByLabel("Your name", { exact: true }).fill(name);
  await this.page.getByRole("button", { name: "Save", exact: true }).click();
});

Then("Alice should see {string} in their Profile and member menu", async function (name) {
  await expect(this.page.locator("#my-settings-profile-name")).toHaveText(name);
  await this.page.locator("#club-site-identity-menu-button").click();
  await expect(this.page.locator("#club-site-identity-menu .app-menu__who-name")).toHaveText(name);
});

Then("Alice's member menu avatar should show the initials {string}", async function (initials) {
  await expect(this.page.locator("#club-site-identity-menu-button .global-bar__avatar")).toHaveText(initials);
});

Then("the untouched name form in the other tab should show {string} without reloading", async function (name) {
  await expect(this.profileOtherPage.getByLabel("Your name", { exact: true })).toHaveValue(name);
  await expect(this.profileOtherPage).toHaveURL(this.profileOtherUrl);
  require("node:assert/strict").equal(this.profileOtherNavigations, 0);
});
