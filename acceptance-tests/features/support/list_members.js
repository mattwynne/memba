const assert = require("node:assert/strict");
const { expect: playwrightExpect } = require("@playwright/test");
const {
  clubSiteUrl,
  cssString,
  emailFor,
  ensureState,
  kootenayClubName,
  projectionTimeoutMs,
  recordMembershipProjectionCheckpoint
} = require("./member_message");
const { signInMember } = require("./member_harness");
const serverCommands = require("./server_commands");

function ensureActiveMembers(world, personNames, clubName) {
  ensureState(world);

  const unknownMemberships = personNames.filter(
    (personName) => !world.memberships[`${clubName}:${personName}`]
  );

  if (unknownMemberships.length > 0) {
    const results = serverCommands.ensureMembers(
      unknownMemberships.map((personName) => ({
        clubName,
        clubSlug: clubSlugFor(clubName),
        personName,
        email: emailFor(personName)
      }))
    );

    for (const result of results) {
      world.clubs[clubName] = { clubId: result.clubId, name: result.clubName, slug: result.clubSlug };
      world.people[result.personName] = personStateFromCommand(result);
      world.memberships[`${clubName}:${result.personName}`] = {
        clubId: result.clubId,
        membershipId: result.membershipId,
        personId: result.personId
      };
      recordMembershipProjectionCheckpoint(world, result);
    }
  }

  return personNames.map((personName) => world.memberships[`${clubName}:${personName}`]);
}

function ensureMemberRoles(world, personName, roleNames, clubName) {
  ensureState(world);
  ensureActiveMembers(world, [personName], clubName);

  const membership = world.memberships[`${clubName}:${personName}`];
  assert.ok(membership, `Expected ${personName} to be an active member of ${clubName}`);

  const roles = serverCommands.ensureMemberRoles({
    clubId: membership.clubId,
    membershipId: membership.membershipId,
    personId: membership.personId,
    roleNames
  });

  world.memberRoles = world.memberRoles || {};
  world.memberRoles[`${clubName}:${personName}`] = roleNames.slice();

  return roles;
}

async function viewMemberList(world, viewerName, clubName, { expect = playwrightExpect } = {}) {
  ensureState(world);
  ensureActiveMembers(world, [viewerName], clubName);

  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to exist before viewing its member list`);

  await signInMember(world, viewerName);
  await world.page.goto(clubSiteUrl(world.baseUrl, club, "/members"));
  await expect(world.page.locator("#member-section-panel-members:not([hidden])")).toBeVisible({
    timeout: projectionTimeoutMs(world)
  });

  return world;
}

async function assertMemberRoles(world, personName, expectedRoleNames, { expect = playwrightExpect } = {}) {
  const row = memberRow(world, personName);
  await expect(row).toBeVisible({ timeout: projectionTimeoutMs(world) });
  await expect(row.locator(".member-row__role")).toHaveText(expectedRoleNames, {
    timeout: projectionTimeoutMs(world)
  });

  return world;
}

async function assertMemberHasNoRoles(world, personName, { expect = playwrightExpect } = {}) {
  const row = memberRow(world, personName);
  await expect(row).toBeVisible({ timeout: projectionTimeoutMs(world) });
  await expect(row.locator(".member-row__role")).toHaveCount(0, { timeout: projectionTimeoutMs(world) });

  return world;
}

async function assertMemberAbsent(world, personName, { expect = playwrightExpect } = {}) {
  await expect(memberRow(world, personName)).toHaveCount(0, { timeout: projectionTimeoutMs(world) });

  return world;
}

async function assertMembersPresent(world, personNames, { expect = playwrightExpect } = {}) {
  for (const personName of personNames) {
    await expect(memberRow(world, personName)).toBeVisible({ timeout: projectionTimeoutMs(world) });
  }

  return world;
}

function memberRow(world, personName) {
  ensureState(world);
  const person = world.people[personName];
  assert.ok(person, `Expected ${personName} to be known before asserting their member row`);

  return world.page.locator(
    `[data-testid=${cssString("club-member-row")}][data-member-id=${cssString(person.personId)}]`
  );
}

function parsePersonList(text) {
  return String(text || "")
    .replace(/,?\s+and\s+/g, ", ")
    .split(/\s*,\s*/)
    .map((name) => name.trim())
    .filter(Boolean);
}

function personStateFromCommand(result) {
  return {
    alternateEmails: [],
    email: result.email,
    emailAddresses: [{ email: result.email, isPrimary: true }],
    name: result.personName,
    personId: result.personId,
    primaryEmail: result.email
  };
}

function clubSlugFor(clubName) {
  if (clubName === kootenayClubName) {
    return "kmc";
  }

  return String(clubName || "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 32);
}

module.exports = {
  assertMemberAbsent,
  assertMemberHasNoRoles,
  assertMemberRoles,
  assertMembersPresent,
  ensureActiveMembers,
  ensureMemberRoles,
  parsePersonList,
  viewMemberList
};
