const assert = require("node:assert/strict");
const { expect } = require("@playwright/test");

function appUrl(config, path) {
  return new URL(path, `${config.baseUrl}/`).toString();
}

function clubSiteUrl(config, path = "/") {
  const url = new URL(path, `${config.baseUrl}/`);
  url.hostname = `${config.clubSlug}.${config.clubSiteBaseDomain}`;
  return url.toString();
}

async function signInWithMagicLink(world, { email, mailbox, label }) {
  const since = new Date(Date.now() - 30 * 1000);
  await world.page.goto(appUrl(world.config, "/auth"));
  await expect(world.page.locator("[data-phx-main].phx-connected")).toBeVisible({ timeout: 30000 });
  await world.page.getByLabel("Email address").fill(email);
  await world.page.getByRole("button", { name: "Email me a sign-in link" }).click();
  await expect(world.page.locator("#auth-email-progress-message")).toContainText(
    /Preparing your sign-in link…|If this email can sign in, the link is on its way\./,
    { timeout: 30000 }
  );

  const message = await mailbox.waitForEmail(
    (emailMessage) =>
      emailMessage.subject === "Sign in to Memba" &&
      emailMessage.toEmails.includes(email.toLowerCase()) &&
      magicLink(emailMessage),
    {
      after: since,
      description: `magic-link email for ${label || email}`,
      intervalMs: world.config.poll.intervalMs,
      timeoutMs: world.config.poll.timeoutMs,
      text: "Sign in to Memba"
    }
  );

  await world.page.goto(rewriteLocalhostMagicLink(world.config, magicLink(message)));
  await world.page.waitForLoadState("networkidle").catch(() => {});
}

async function ensureStaffSignedIn(world) {
  await signInWithMagicLink(world, {
    email: world.config.staff.email,
    mailbox: world.mailboxes.staff,
    label: "smoke staff"
  });

  const nameField = world.page.getByLabel("Your name");
  if (await nameField.count()) {
    await nameField.fill("Smoke Test Staff");
    await world.page.getByRole("button", { name: "Continue to Memba staff" }).click();
  }

  await world.page.goto(appUrl(world.config, "/admin/clubs"));
  await expect(world.page.locator("#admin-layout[data-surface='admin']")).toBeVisible({ timeout: 30000 });
}

async function assertSmokeClubExists(world) {
  await world.page.goto(appUrl(world.config, "/admin/clubs"));
  await expect(world.page.locator("#admin-layout[data-surface='admin']")).toBeVisible({ timeout: 30000 });

  const clubRow = world.page.locator(
    `[data-testid="club-row"][data-club-slug="${cssStringValue(world.config.clubSlug)}"]`
  );
  await expect(clubRow).toBeVisible();
  await expect(clubRow).toContainText(world.config.clubName);
}

async function ensureSmokeMemberSignedIn(world) {
  await signInWithMagicLink(world, {
    email: world.config.member.email,
    mailbox: world.mailboxes.member,
    label: "smoke member"
  });

  await world.page.goto(clubSiteUrl(world.config, "/"));
  await expect(world.page.locator("#club-site-layout[data-surface='club-site']")).toBeVisible();
  await expect(world.page.locator("#club-site-identity-menu .app-menu__who-name")).toContainText(
    clubIdentityLabelFor(world.config.member)
  );
}

async function openSmokeClubHome(world) {
  await world.page.goto(clubSiteUrl(world.config, "/"));
  await expect(world.page.locator("#club-site-layout[data-surface='club-site']")).toBeVisible();
}

async function assertMemberSeesMessage(world, subject, body) {
  const deadline = Date.now() + world.config.poll.timeoutMs;

  while (Date.now() <= deadline) {
    await openSmokeClubHome(world);
    const row = messageRow(world, subject);
    if ((await row.count()) > 0) {
      const messageId = await row.getAttribute("data-message-id");
      assert.ok(messageId, `Expected message row for ${subject} to expose data-message-id`);

      await row.getByRole("link").first().click();
      await expect(world.page.locator("#member-message-body")).toContainText(body, {
        timeout: world.config.poll.intervalMs
      });
      return;
    }

    await new Promise((resolve) => setTimeout(resolve, world.config.poll.intervalMs));
  }

  throw new Error(`Timed out waiting for member-visible club message: ${subject}`);
}

async function assertMemberDoesNotSeeMessage(world, subject) {
  await openSmokeClubHome(world);
  await expect(messageRow(world, subject)).toHaveCount(0, { timeout: world.config.poll.timeoutMs });
}

function messageRow(world, subject) {
  return world.page.locator(`[data-testid="club-message-row"][data-message-subject="${cssStringValue(subject)}"]`);
}

function magicLink(emailMessage) {
  const text = `${emailMessage.text || ""}\n${emailMessage.html || ""}`;
  const match = text.match(/https?:\/\/\S+\/auth\/(?:sign-in|magic)\/[^\s<"]+/);
  return match && match[0].replace(/&amp;/g, "&");
}

function rewriteLocalhostMagicLink(config, link) {
  const parsed = new URL(link);
  const base = new URL(config.baseUrl);
  if (parsed.hostname === "localhost" || parsed.hostname === "127.0.0.1") {
    parsed.protocol = base.protocol;
    parsed.hostname = base.hostname;
    parsed.port = base.port;
  }
  return parsed.toString();
}

function cssStringValue(value) {
  return String(value).replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\n/g, "\\a ");
}

function clubIdentityFallbackLabelFor(email) {
  return String(email).split("@")[0].trim() || "Member";
}

function clubIdentityLabelFor(member) {
  const name = member && typeof member.name === "string" ? member.name.trim() : "";
  return name || clubIdentityFallbackLabelFor(member && member.email);
}

module.exports = {
  assertMemberDoesNotSeeMessage,
  assertMemberSeesMessage,
  assertSmokeClubExists,
  ensureSmokeMemberSignedIn,
  ensureStaffSignedIn
};
