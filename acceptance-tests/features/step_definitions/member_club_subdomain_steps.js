const assert = require("node:assert/strict");
const { Given, When, Then } = require("@cucumber/cucumber");
const { expect: playwrightExpect } = require("@playwright/test");
const {
  assertReceivesSignInLink,
  followSignInLink,
  requestSignInLinkForPerson,
  signInDirectly
} = require("../support/authentication");
const {
  appUrl,
  cssString,
  kootenayClubName
} = require("../support/member_message");
const serverCommands = require("../support/server_commands");

const productionClubBaseDomain = "clubs.memba.io";
const smokeTestClubName = "Smoke Test Club";
const smokeTestClubSlug = "test";
const smokeTestPersonName = "Smoke Tester";
const smokeTestMemberEmail = "test@memba.io";

Given("Kootenay Mountaineering Club has the slug {string}", async function (slug) {
  await ensureClubHasSlug(this, kootenayClubName, slug);
});

Given("the smoke-test club has been seeded", async function () {
  await ensureSmokeTestClubSeeded(this);
});

When("{word} signs in", async function (personName) {
  await signIn(this, personName);
});

When("{word} opens Kootenay Mountaineering Club from her clubs", async function (_personName) {
  await this.page
    .locator('[data-testid="my-club-link"]', { hasText: kootenayClubName })
    .click();
  await playwrightExpect(this.page.locator("#member-club-home")).toBeVisible();
});

When("{word} starts a message on {string}", async function (personName, host) {
  await signIn(this, personName);
  await this.page.goto(clubHostUrl(this, host, "/messages/new"));
  await playwrightExpect(this.page.locator('#member-message-compose[data-compose-state="composing"]')).toBeVisible();
});

When("{word} views the message {string} on {string}", async function (personName, subject, host) {
  await signIn(this, personName);
  await this.page.goto(clubHostUrl(this, host, `/messages/${messageIdFor(this, subject)}`));
  await playwrightExpect(this.page.getByRole("heading", { name: subject })).toBeVisible();
});

When(
  "{word} opens the private message URL on {string} while signed out",
  async function (_personName, host) {
    const subject = this.lastMessageSubject;
    await this.page.goto(clubHostUrl(this, host, `/messages/${messageIdFor(this, subject)}`));
    await playwrightExpect(this.page).toHaveURL(/\/auth$/);
  }
);

When("{word} opens the private message URL on {string}", async function (personName, host) {
  await signIn(this, personName);
  const subject = this.lastMessageSubject;
  await this.page.goto(clubHostUrl(this, host, `/messages/${messageIdFor(this, subject)}`));
});

When("{word} opens {string}", async function (_personName, host) {
  await this.page.goto(clubHostUrl(this, host));
});

When("{word} visits the Memba homepage", async function (_personName) {
  await this.page.goto(appUrl(this.baseUrl, "/"));
});

Then("{word} should be on {string}", async function (_personName, host) {
  assert.equal(new URL(this.page.url()).hostname, localHostForProductionHost(host));
});

Then("{word} should see the Kootenay Mountaineering Club member dashboard", async function (_personName) {
  const club = this.clubs && this.clubs[kootenayClubName];
  assert.ok(club, `Expected ${kootenayClubName} to be known in the scenario`);
  await playwrightExpect(this.page.locator(`#member-club-home[data-club-id="${club.clubId}"]`)).toBeVisible();
  await playwrightExpect(this.page.locator(".app-bar__club")).toContainText(kootenayClubName);
  await playwrightExpect(this.page.locator("#member-dashboard-hero")).toHaveCount(0);
});

Then("the message should be addressed to Kootenay Mountaineering Club members", async function () {
  await playwrightExpect(this.page.locator("#member-compose-selected-club")).toHaveText(kootenayClubName);
  await playwrightExpect(this.page.locator("#member-compose-recipient-summary")).toContainText(
    `of ${kootenayClubName}`
  );
});

Then("{word} should return to the private message URL on {string}", async function (_personName, host) {
  const subject = this.lastMessageSubject;
  const currentUrl = new URL(this.page.url());
  assert.equal(currentUrl.hostname, localHostForProductionHost(host));
  assert.equal(currentUrl.pathname, `/messages/${messageIdFor(this, subject)}`);
});

Then("{word} should see that they are not allowed to view it", async function (_personName) {
  await playwrightExpect(this.page.locator("body")).toContainText(/Forbidden|not authorized/i);
});

Then("Robin should see a link to the Memba homepage", async function () {
  const link = this.page.locator("#public-club-page-memba-home-link");
  await playwrightExpect(link).toBeVisible();
  await playwrightExpect(link).toContainText("Visit Memba home");

  const href = await link.getAttribute("href");
  assert.ok(href, "Expected public club page to expose a Memba homepage link href");

  const targetUrl = new URL(href, this.page.url());
  const currentUrl = new URL(this.page.url());

  assert.equal(targetUrl.pathname, "/");
  assert.equal(targetUrl.hostname, rootHostForLocalClubBaseDomain());
  assert.notEqual(targetUrl.hostname, currentUrl.hostname);
});

Then("Robin should see a not found page", async function () {
  await playwrightExpect(this.page.locator("body")).toContainText(/Not Found|not found/i);
});

Then("{word} should see Smoke Test Club in the staff club list", async function (_personName) {
  await playwrightExpect(
    this.page.locator(`[data-testid="club-row"][data-club-name=${cssString(smokeTestClubName)}]`)
  ).toBeVisible();
});

Then("Robin should not see the Smoke Test Club public page", async function () {
  await playwrightExpect(this.page.locator("#public-club-page-page")).toHaveCount(0);
  await playwrightExpect(this.page.locator("body")).not.toContainText(`Welcome to ${smokeTestClubName}`);
});

Then("Robin should not see Smoke Test Club", async function () {
  await playwrightExpect(this.page.locator("body")).not.toContainText(smokeTestClubName);
});

async function ensureClubHasSlug(world, clubName, slug) {
  const currentClub = world.clubs && world.clubs[clubName];
  const result = serverCommands.ensureClubSlug({
    clubId: currentClub && currentClub.clubId,
    clubName,
    clubSlug: slug
  });
  world.clubs = world.clubs || {};
  world.clubs[clubName] = { clubId: result.clubId, name: result.clubName, slug: result.clubSlug };
}

async function ensureSmokeTestClubSeeded(world) {
  const result = serverCommands.ensureSmokeTestClub({
    clubName: smokeTestClubName,
    clubSlug: smokeTestClubSlug,
    personName: smokeTestPersonName,
    email: smokeTestMemberEmail
  });

  world.clubs = world.clubs || {};
  world.people = world.people || {};
  world.memberships = world.memberships || {};

  world.clubs[smokeTestClubName] = { clubId: result.clubId, name: result.clubName, slug: result.clubSlug };
  world.people[smokeTestPersonName] = {
    alternateEmails: [],
    email: result.email,
    emailAddresses: [{ email: result.email, isPrimary: true }],
    name: result.personName,
    personId: result.personId,
    primaryEmail: result.email
  };
  world.memberships[`${smokeTestClubName}:${smokeTestPersonName}`] = {
    clubId: result.clubId,
    membershipId: result.membershipId,
    personId: result.personId
  };
}

async function signIn(world, personName) {
  if (new URL(world.page.url()).pathname === "/auth") {
    await requestSignInLinkForPerson(world, personName);
    await assertReceivesSignInLink(world, personName);
    await followSignInLink(world, personName);
  } else {
    await signInDirectly(world, personName);
  }
}

function messageIdFor(world, subject) {
  const message = world.messages && world.messages[subject];
  assert.ok(message && message.messageId, `Expected message ${JSON.stringify(subject)} to have been sent`);
  return encodeURIComponent(message.messageId);
}

function clubHostUrl(world, host, path = "/") {
  const baseUrl = new URL(world.baseUrl);
  const url = new URL(path, `${baseUrl.protocol}//${localHostForProductionHost(host)}:${baseUrl.port || defaultPort(baseUrl.protocol)}`);
  return url.toString();
}

function localHostForProductionHost(host) {
  const normalizedHost = String(host)
    .replace(/^https?:\/\//, "")
    .replace(/\/.*$/, "")
    .toLowerCase();

  if (normalizedHost.endsWith(`.${productionClubBaseDomain}`)) {
    const slug = normalizedHost.slice(0, -1 * (`.${productionClubBaseDomain}`).length);
    return `${slug}.${localClubBaseDomain()}`;
  }

  return normalizedHost;
}

function localClubBaseDomain() {
  return process.env.MEMBA_CLUB_SITE_BASE_DOMAIN || "lvh.me";
}

function rootHostForLocalClubBaseDomain() {
  const baseDomain = localClubBaseDomain();

  return baseDomain.startsWith("clubs.") ? baseDomain.slice("clubs.".length) : baseDomain;
}

function defaultPort(protocol) {
  return protocol === "https:" ? "443" : "80";
}
