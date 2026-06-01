const assert = require("node:assert/strict");
const { expect: playwrightExpect } = require("@playwright/test");
const {
  appUrl,
  ensureState,
  testMailboxEmails,
  waitForMailboxEmails
} = require("./member_message");

const staffEmail = process.env.ACCEPTANCE_STAFF_EMAIL || "acceptance-staff@memba.io";
const signInSubject = "Sign in to Memba";

async function withStaffHarness(world, action) {
  await withIsolatedHarnessWorld(world, async (harnessWorld) => {
    await signInStaff(harnessWorld);
    await action(harnessWorld);
  });
}

async function withMemberHarness(world, memberName, action) {
  await withIsolatedHarnessWorld(
    world,
    async (harnessWorld) => {
      guardPageAgainstAdminRoutes(harnessWorld, memberName);
      await signInMember(harnessWorld, memberName);
      await memberBrowserAction(harnessWorld, `member action for ${memberName}`, () => action(harnessWorld));
    },
    { memberName }
  );
}

async function memberBrowserAction(world, description, action) {
  assertMemberPageIsNotAdmin(world, `${description} before action`);
  const result = await action();
  assertMemberPageIsNotAdmin(world, `${description} after action`);

  return result;
}

function assertMemberPageIsNotAdmin(world, description = "member browser helper") {
  const currentUrl = currentPageUrl(world.page);

  if (currentUrl && isAdminRoute(currentUrl, world.baseUrl)) {
    throw new Error(`Member browser helper reached staff/admin route during ${description}: ${currentUrl}`);
  }
}

async function withIsolatedHarnessWorld(world, action, options = {}) {
  ensureHarnessState(world);

  const context = await world.browser.newContext();
  const page = await context.newPage();
  const harnessWorld = {
    ...world,
    context,
    page,
    clubs: world.clubs,
    people: world.people,
    memberships: world.memberships,
    messages: world.messages,
    deliveries: world.deliveries,
    reportedDeliveryStatuses: world.reportedDeliveryStatuses,
    signInRequests: world.signInRequests,
    signInLinks: world.signInLinks
  };

  if (options.memberName) {
    harnessWorld.memberName = options.memberName;
  }

  try {
    await action(harnessWorld);
    copyHarnessState(world, harnessWorld);
  } finally {
    await context.close();
  }
}

function ensureHarnessState(world) {
  ensureState(world);
  world.signInRequests = world.signInRequests || {};
  world.signInLinks = world.signInLinks || {};

  return world;
}

function copyHarnessState(world, harnessWorld) {
  for (const key of [
    "addressedMemberIds",
    "addressedMemberNames",
    "currentOperatorDelivery",
    "lastMessageSubject",
    "mailboxEmailsBeforeSend"
  ]) {
    if (Object.prototype.hasOwnProperty.call(harnessWorld, key)) {
      world[key] = harnessWorld[key];
    }
  }
}

async function signInStaff(world) {
  await signInByMagicLink(world, staffEmail, "staff harness");
  await playwrightExpect(world.page.locator("#admin-layout[data-surface='admin']")).toBeVisible();
}

async function signInMember(world, memberName) {
  const person = personFromWorld(world, memberName);

  await signInByMagicLink(world, person.email, memberName);
  assertMemberPageIsNotAdmin(world, `signing in ${memberName} as a member`);
}

async function signInByMagicLink(world, email, label) {
  const previousEmails = await testMailboxEmails(world);

  await world.page.goto(appUrl(world.baseUrl, "/auth"));
  await world.page.getByLabel("Email address").fill(email);
  await world.page.getByRole("button", { name: "Email me a sign-in link" }).click();

  const emails = await waitForMailboxEmails(
    world,
    previousEmails.length + 1,
    `sign-in email for ${label} <${email}>`
  );
  const previousIds = previousEmails.map(mailboxMessageId).filter(Boolean);
  const signInEmail = emails
    .filter((mailboxEmail) => !previousIds.includes(mailboxMessageId(mailboxEmail)))
    .find((mailboxEmail) => signInEmailMatches(mailboxEmail, email));

  assert.ok(
    signInEmail,
    `Expected ${label} <${email}> to receive a sign-in email; saw ${JSON.stringify(emails.map(emailSummary))}`
  );

  const signInLink = signInLinkFromTextBody(signInEmail.text_body);
  assert.ok(signInLink, `Expected sign-in email to contain a sign-in link; saw ${signInEmail.text_body}`);

  await world.page.goto(signInLink);
}

function guardPageAgainstAdminRoutes(world, memberName) {
  const page = world.page;

  if (!page || typeof page.goto !== "function" || page.__membaMemberAdminGuard) {
    return page;
  }

  const originalGoto = page.goto.bind(page);

  page.goto = async (targetUrl, ...args) => {
    if (isAdminRoute(targetUrl, world.baseUrl)) {
      throw new Error(
        `Member browser helper attempted to navigate to staff/admin route for ${memberName}: ${targetUrl}`
      );
    }

    const result = await originalGoto(targetUrl, ...args);
    assertMemberPageIsNotAdmin(world, `navigation for ${memberName}`);

    return result;
  };

  page.__membaMemberAdminGuard = true;

  return page;
}

function isAdminRoute(url, baseUrl) {
  const pathname = pathForUrl(url, baseUrl);

  return pathname === "/admin" || pathname.startsWith("/admin/");
}

function pathForUrl(url, baseUrl) {
  try {
    return new URL(url, `${baseUrl || "http://memba.test"}/`).pathname;
  } catch (_error) {
    return "";
  }
}

function currentPageUrl(page) {
  if (!page) {
    return null;
  }

  if (typeof page.url === "function") {
    return page.url();
  }

  return page.currentUrl || null;
}

function personFromWorld(world, memberName) {
  ensureHarnessState(world);
  const person = world.people[memberName];

  assert.ok(person, `Expected ${memberName} to be known in the scenario`);
  assert.ok(person.email, `Expected ${memberName} to have an email address for member sign-in`);

  return person;
}

function signInEmailMatches(email, recipientEmail) {
  return (
    email.subject === signInSubject &&
    Array.isArray(email.to) &&
    email.to.some((recipient) => String(recipient).includes(recipientEmail))
  );
}

function signInLinkFromTextBody(textBody) {
  const match = String(textBody || "").match(/https?:\/\/\S+\/auth\/magic\/\S+/);
  return match && match[0];
}

function mailboxMessageId(email) {
  return email && email.headers && email.headers["Message-ID"];
}

function emailSummary(email) {
  return { subject: email.subject, to: email.to, text_body: email.text_body };
}

module.exports = {
  assertMemberPageIsNotAdmin,
  memberBrowserAction,
  signInMember,
  withMemberHarness,
  withStaffHarness
};
