const assert = require("node:assert/strict");
const { Given, When, Then } = require("@cucumber/cucumber");
const { expect: playwrightExpect } = require("@playwright/test");
const {
  assertReceivesSignInLink,
  followSignInLink,
  requestSignInLinkForPerson,
  signInDirectly
} = require("../support/authentication");
const { appUrl, kootenayClubName } = require("../support/member_message");
const serverCommands = require("../support/server_commands");

const productionClubBaseDomain = "clubs.memba.io";
Given("Kootenay Mountaineering Club has the slug {string}", async function (slug) {
  await ensureClubHasSlug(this, kootenayClubName, slug);
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

When(
  "{word} opens the private message URL on {string} while signed out",
  async function (_personName, host) {
    const subject = this.lastMessageSubject;
    await this.page.goto(clubHostUrl(this, host, `/messages/${messageIdFor(this, subject)}`));
    await playwrightExpect(this.page).toHaveURL(/\/auth$/);
  }
);

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

Then("{word} should return to the private message URL on {string}", async function (_personName, host) {
  const subject = this.lastMessageSubject;
  const currentUrl = new URL(this.page.url());
  assert.equal(currentUrl.hostname, localHostForProductionHost(host));
  assert.equal(currentUrl.pathname, `/messages/${messageIdFor(this, subject)}`);
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

function defaultPort(protocol) {
  return protocol === "https:" ? "443" : "80";
}
