const assert = require("node:assert/strict");
const { When, Then } = require("@cucumber/cucumber");
const { expect: playwrightExpect } = require("@playwright/test");
const { appUrl } = require("../support/member_message");
const serverCommands = require("../support/server_commands");

When("Pat starts creating the club {string}", async function (clubName) {
  await openClubsPage(this);
  await this.page.locator("#club-name-input").fill(clubName);
  await this.page.locator("#club-name-input").blur();
  this.pendingClubName = clubName;
});

Then("Memba should suggest the slug {string}", async function (expectedSlug) {
  await playwrightExpect(this.page.locator("#club-slug-input")).toHaveValue(expectedSlug);
  this.pendingClubSlug = expectedSlug;
});

When("Pat saves the club", async function () {
  await this.page.locator("#create-club-button").click();
  await playwrightExpect(this.page.locator("#clubs-index")).toBeVisible();
  await playwrightExpect(this.page.locator("body")).toContainText("Club created");

  const clubName = this.pendingClubName;
  const clubSlug = this.pendingClubSlug || slugFor(clubName);
  const club = await fetchClubBySlug(clubSlug);

  assert.equal(club && club.clubName, clubName);
  rememberClub(this, clubName, club);
});

Then(/^(.+) should have the slug "([^"]+)"$/, async function (clubName, expectedSlug) {
  const club = await fetchKnownClub(this, clubName);
  assert.equal(club.clubSlug, expectedSlug);

  await openClubsPage(this);
  const row = this.page.locator(`[data-testid="club-row"][data-club-name=${cssString(clubName)}]`);
  await playwrightExpect(row).toHaveCount(1);
  await playwrightExpect(row).toHaveAttribute("data-club-slug", expectedSlug);
});

When(/^Pat tries to change (.+)'s slug to "([^"]+)"$/, async function (clubName, slug) {
  const club = await fetchKnownClub(this, clubName);
  this.previousClubSlugs = this.previousClubSlugs || {};
  this.previousClubSlugs[clubName] = club.clubSlug;

  await this.page.goto(appUrl(this.baseUrl, `/admin/clubs/${encodeURIComponent(club.clubId)}`));
  await playwrightExpect(this.page.locator("#club-show")).toBeVisible();
  await this.page.locator("#edit-club-slug-input").fill(slug);
  await this.page.locator("#edit-club-slug-input").blur();
});

Then("Memba should reject the club slug as invalid", async function () {
  await playwrightExpect(this.page.locator("#edit-club-slug-feedback")).toHaveAttribute(
    "data-status",
    "invalid"
  );
  await playwrightExpect(this.page.locator("#update-club-button")).toBeDisabled();
});

Then("Memba should reject the club slug as already taken", async function () {
  await playwrightExpect(this.page.locator("#edit-club-slug-feedback")).toHaveAttribute(
    "data-status",
    "taken"
  );
  await playwrightExpect(this.page.locator("#update-club-button")).toBeDisabled();
});

Then(/^(.+) should keep its previous slug$/, async function (clubName) {
  const expectedSlug = this.previousClubSlugs && this.previousClubSlugs[clubName];
  assert.ok(expectedSlug, `Expected previous slug for ${clubName}`);

  const club = await fetchKnownClub(this, clubName);
  assert.equal(club.clubSlug, expectedSlug);
});

async function openClubsPage(world) {
  await world.page.goto(appUrl(world.baseUrl, "/admin/clubs"));
  await playwrightExpect(world.page.locator("#clubs-index")).toBeVisible();
}

async function fetchKnownClub(world, clubName) {
  const remembered = world.clubs && world.clubs[clubName];

  if (remembered && remembered.clubId) {
    const club = await fetchClubById(remembered.clubId);
    rememberClub(world, clubName, club);
    return club;
  }

  const slug = slugFor(clubName);
  const club = await fetchClubBySlug(slug);
  assert.ok(club, `Expected ${clubName} to exist`);
  rememberClub(world, clubName, club);
  return club;
}

async function fetchClubById(clubId) {
  return serverCommands.runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
club = Memba.Membership.get_club(club_id)
if club do
  %{clubId: club.club_id, clubName: club.name, clubSlug: club.slug}
else
  nil
end
`,
    { clubId }
  );
}

async function fetchClubBySlug(slug) {
  return serverCommands.runCommand(
    `
slug = Map.fetch!(payload, "slug")
club = Memba.Membership.get_club_by_slug(slug)
if club do
  %{clubId: club.club_id, clubName: club.name, clubSlug: club.slug}
else
  nil
end
`,
    { slug }
  );
}

function rememberClub(world, clubName, club) {
  world.clubs = world.clubs || {};
  world.clubs[clubName] = {
    clubId: club.clubId,
    name: club.clubName,
    slug: club.clubSlug
  };
}

function slugFor(clubName) {
  return clubName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 32);
}

function cssString(value) {
  return JSON.stringify(value);
}
