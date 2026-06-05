const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { expect: playwrightExpect } = require("@playwright/test");

const kootenayClubName = "Kootenay Mountaineering Club";
const nelsonClubName = "Nelson Paddling Club";
const maxClubSlugLength = 32;
const defaultProjectionPollIntervalMs = 250;
const defaultProjectionTimeoutMs = 10000;

function appUrl(baseUrl, path) {
  return new URL(path, `${baseUrl}/`).toString();
}

function clubSiteBaseDomain() {
  return process.env.MEMBA_CLUB_SITE_BASE_DOMAIN || "lvh.me";
}

function clubSiteUrl(baseUrl, club, path = "/") {
  assert.ok(club && club.slug, "Expected club to have a slug for club-site URL generation");

  const url = new URL(path, `${baseUrl}/`);
  url.hostname = `${club.slug}.${clubSiteBaseDomain()}`;
  return url.toString();
}

function cssString(value) {
  return `"${String(value)
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\n/g, "\\a ")}"`;
}

function emailFor(name) {
  const normalizedName = name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ".")
    .replace(/^\.+|\.+$/g, "");

  return `${normalizedName}@example.test`;
}

function defaultClubSlug(clubName) {
  return String(clubName || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, maxClubSlugLength)
    .replace(/^-+|-+$/g, "");
}

function clubSlugForOccurrence(clubName, occurrence) {
  const base = defaultClubSlug(clubName) || "club";

  if (occurrence <= 1) {
    return base;
  }

  const suffix = `-${occurrence}`;
  const trimmedBase = base
    .slice(0, maxClubSlugLength - suffix.length)
    .replace(/^-+|-+$/g, "");

  return `${trimmedBase || "club"}${suffix}`;
}

function postmarkPayloadForStatus({
  deliveryId,
  eventType,
  messageId,
  reason,
  recipientEmail
}) {
  const payload = {
    MessageID: randomUUID(),
    Metadata: {
      delivery_id: deliveryId,
      message_id: messageId
    },
    Recipient: recipientEmail
  };

  switch (eventType) {
    case "delivered":
      return { ...payload, RecordType: "Delivery" };

    case "opened":
      return { ...payload, RecordType: "Open" };

    case "delayed":
      return {
        ...payload,
        Details: reason,
        RecordType: "Bounce",
        Type: "Transient"
      };

    case "bounced":
      return {
        ...payload,
        Description: reason,
        RecordType: "Bounce",
        Type: "HardBounce"
      };

    case "spam_complaint":
      return {
        ...payload,
        Details: reason,
        RecordType: "SpamComplaint"
      };

    default:
      throw new Error(`Unsupported browser Postmark status event: ${eventType}`);
  }
}

function resendInboundEmailPayload({
  attachments,
  eventId = randomUUID(),
  fromAddress,
  htmlBody,
  providerMessageId = randomUUID(),
  subject,
  textBody,
  toAddress
}) {
  const data = {
    email_id: providerMessageId,
    from: fromAddress,
    to: [toAddress],
    subject,
    text: textBody
  };

  if (htmlBody !== undefined) {
    data.html = htmlBody;
  }

  if (attachments !== undefined) {
    data.attachments = attachments;
  }

  return {
    id: eventId,
    type: "email.received",
    data
  };
}

function ensureState(world) {
  world.clubs = world.clubs || {};
  world.people = world.people || {};
  world.memberships = world.memberships || {};
  world.messages = world.messages || {};
  world.deliveries = world.deliveries || {};
  world.inboundEmails = world.inboundEmails || {};
  world.inboundEmailSenders = world.inboundEmailSenders || {};
  world.inboundRejectionEmails = world.inboundRejectionEmails || {};
  world.reportedDeliveryStatuses = world.reportedDeliveryStatuses || {};

  return world;
}

function rowByData(page, testId, dataName, value) {
  return page
    .locator(`[data-testid=${cssString(testId)}][${dataName}=${cssString(value)}]`)
    .last();
}

function rowsByData(page, testId, dataName, value) {
  return page.locator(`[data-testid=${cssString(testId)}][${dataName}=${cssString(value)}]`);
}

function allRows(page, containerId, testId) {
  return page.locator(`#${containerId} [data-testid=${cssString(testId)}]`);
}

async function expandCollapsedMemberEmailDeliveryGroups(
  world,
  { expect = playwrightExpect, timeoutMs } = {}
) {
  ensureState(world);

  const maxVisibleReceiptGroups = 4;

  for (let expandedCount = 0; expandedCount <= maxVisibleReceiptGroups; expandedCount += 1) {
    const collapsedToggles = world.page.locator(
      '[id^="member-receipt-group-toggle-"][aria-expanded="false"]'
    );
    const collapsedCount = await collapsedToggles.count();

    if (collapsedCount === 0) {
      return;
    }

    if (expandedCount === maxVisibleReceiptGroups) {
      break;
    }

    const toggle = collapsedToggles.first();
    const toggleId = await toggle.getAttribute("id");

    await browserInteraction("expand collapsed member email delivery group", () => toggle.click());

    if (toggleId) {
      await waitForProjectedVisible(
        world,
        world.page.locator(`[id=${cssString(toggleId)}][aria-expanded="true"]`),
        `expanded member email delivery group ${toggleId}`,
        { expect, timeoutMs }
      );
    }
  }

  throw new Error("Expected no more than four member email delivery groups to require expansion");
}

function clubById(world, clubId) {
  return Object.values(world.clubs || {}).find((club) => club.clubId === clubId);
}

function memberMessageUrl(world, message) {
  const club = clubById(world, message.clubId) || { slug: message.clubSlug || "kootenay-mountaineering-club" };
  return clubSiteUrl(world.baseUrl, club, `/messages/${encodeURIComponent(message.messageId)}`);
}

async function rowAttributeValues(rows, attributeName) {
  return rows.evaluateAll(
    (elements, attr) =>
      elements.map((element) => element.getAttribute(attr)).filter((value) => value),
    attributeName
  );
}

function numericWaitConfig(world, worldKey, envKey, defaultValue) {
  const configuredValue =
    world && world[worldKey] !== undefined ? world[worldKey] : process.env[envKey];
  const parsedValue = Number(configuredValue);

  return Number.isFinite(parsedValue) && parsedValue >= 0 ? parsedValue : defaultValue;
}

function projectionTimeoutMs(world) {
  return numericWaitConfig(
    world,
    "projectionTimeoutMs",
    "ACCEPTANCE_PROJECTION_TIMEOUT_MS",
    defaultProjectionTimeoutMs
  );
}

function projectionPollIntervalMs(world) {
  return numericWaitConfig(
    world,
    "projectionPollIntervalMs",
    "ACCEPTANCE_PROJECTION_POLL_INTERVAL_MS",
    defaultProjectionPollIntervalMs
  );
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function errorMessage(error) {
  return error && error.message ? error.message : String(error);
}

async function browserInteraction(description, action) {
  try {
    return await action();
  } catch (error) {
    throw new Error(`Browser interaction failed: ${description}.\nCause: ${errorMessage(error)}`, {
      cause: error
    });
  }
}

function assertFinalBrowserState(description, assertion) {
  try {
    return assertion();
  } catch (error) {
    throw new Error(`Assertion mismatch: ${description}.\nCause: ${errorMessage(error)}`, {
      cause: error
    });
  }
}

async function withProjectionWait(description, assertion) {
  try {
    return await assertion();
  } catch (error) {
    throw new Error(
      `Projection timing timeout: timed out waiting for projected browser UI: ${description}.\n` +
        `Last assertion error: ${errorMessage(error)}`,
      { cause: error }
    );
  }
}

async function waitForProjectedCount(
  world,
  locator,
  expectedCount,
  description,
  { expect = playwrightExpect, timeoutMs = projectionTimeoutMs(world) } = {}
) {
  await withProjectionWait(description, () =>
    expect(locator, description).toHaveCount(expectedCount, { timeout: timeoutMs })
  );
}

async function waitForExpandedMemberEmailDeliveryCount(
  world,
  locator,
  expectedCount,
  description,
  { expect = playwrightExpect, timeoutMs = projectionTimeoutMs(world) } = {}
) {
  const deadline = Date.now() + timeoutMs;
  let lastError = null;

  do {
    const assertionTimeoutMs = Math.max(1, Math.min(1000, deadline - Date.now()));

    try {
      await expandCollapsedMemberEmailDeliveryGroups(world, {
        expect,
        timeoutMs: assertionTimeoutMs
      });
      await waitForProjectedCount(world, locator, expectedCount, description, {
        expect,
        timeoutMs: assertionTimeoutMs
      });

      return;
    } catch (error) {
      lastError = error;
    }

    const remainingMs = deadline - Date.now();

    if (remainingMs > 0) {
      await delay(Math.min(projectionPollIntervalMs(world), remainingMs));
    }
  } while (Date.now() <= deadline);

  throw new Error(
    `Projection timing timeout: timed out after ${timeoutMs}ms waiting for expanded member email delivery rows: ` +
      `${description} should have count ${expectedCount}.\nLast projection error: ${
        lastError ? errorMessage(lastError) : "(none)"
      }`
  );
}

async function waitForProjectedText(
  world,
  locator,
  expectedText,
  description,
  { expect = playwrightExpect, timeoutMs = projectionTimeoutMs(world) } = {}
) {
  await withProjectionWait(description, () =>
    expect(locator, description).toHaveText(expectedText, { timeout: timeoutMs })
  );
}

async function waitForProjectedVisible(
  world,
  locator,
  description,
  { expect = playwrightExpect, timeoutMs = projectionTimeoutMs(world) } = {}
) {
  await withProjectionWait(description, () =>
    expect(locator, description).toBeVisible({ timeout: timeoutMs })
  );
}

function currentPageMatches(page, targetUrl) {
  if (!page || typeof page.url !== "function") {
    return false;
  }

  try {
    return new URL(page.url()).href === new URL(targetUrl).href;
  } catch (_error) {
    return false;
  }
}

async function gotoUnlessCurrent(world, targetUrl, description) {
  if (currentPageMatches(world.page, targetUrl)) {
    return;
  }

  await browserInteraction(description, () => world.page.goto(targetUrl));
}

async function newRowAttributeValue(rows, attributeName, previousValues, description) {
  const currentValues = await rowAttributeValues(rows, attributeName);
  const newValues = currentValues.filter((value) => !previousValues.includes(value));

  assert.equal(
    newValues.length,
    1,
    `Expected exactly one new ${description}; previous=${previousValues.join(", ")} current=${currentValues.join(", ")}`
  );

  return newValues[0];
}

async function visitClubsIndex(world, { expect = playwrightExpect, timeoutMs = projectionTimeoutMs(world) } = {}) {
  await browserInteraction("visit /admin/clubs", async () => {
    const targetUrl = appUrl(world.baseUrl, "/admin/clubs");
    if (!currentPageMatches(world.page, targetUrl)) {
      await world.page.goto(targetUrl);
    }
    if (expect === playwrightExpect) {
      await expect(world.page.getByRole("heading", { name: "Clubs", exact: true })).toBeVisible({
        timeout: timeoutMs
      });
    }
  });
}

async function openClub(world, clubName, { expect = playwrightExpect, timeoutMs } = {}) {
  ensureState(world);

  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to have been created before opening it`);

  await gotoUnlessCurrent(
    world,
    appUrl(world.baseUrl, `/admin/clubs/${club.clubId}`),
    `visit club page for ${clubName}`
  );
  await waitForProjectedVisible(
    world,
    world.page.getByRole("heading", { name: clubName }),
    `club heading for ${clubName}`,
    { expect, timeoutMs }
  );
}

async function openMessage(world, subject, { expect = playwrightExpect, force = false, timeoutMs } = {}) {
  ensureState(world);

  const message = world.messages[subject];
  assert.ok(message, `Expected message ${JSON.stringify(subject)} to have been sent`);

  const targetUrl = appUrl(world.baseUrl, `/admin/messages/${message.messageId}`);

  if (force) {
    await browserInteraction(`visit message page for ${JSON.stringify(subject)}`, () => world.page.goto(targetUrl));
  } else {
    await gotoUnlessCurrent(
      world,
      targetUrl,
      `visit message page for ${JSON.stringify(subject)}`
    );
  }
  await waitForProjectedVisible(
    world,
    world.page.getByRole("heading", { name: subject }),
    `message heading for ${JSON.stringify(subject)}`,
    { expect, timeoutMs }
  );
}

async function openMemberClubHome(world, clubName, { expect = playwrightExpect, timeoutMs } = {}) {
  ensureState(world);

  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to have been created before opening the member club home`);

  await gotoUnlessCurrent(
    world,
    clubSiteUrl(world.baseUrl, club),
    `visit member club home for ${clubName}`
  );
  await waitForProjectedVisible(
    world,
    world.page.locator(`#member-club-home[data-club-id=${cssString(club.clubId)}]`),
    `member club home for ${clubName}`,
    { expect, timeoutMs }
  );
}

async function openMemberComposeFromClubHome(world, clubName, { expect = playwrightExpect, timeoutMs } = {}) {
  await openMemberClubHome(world, clubName, { expect, timeoutMs });

  const composeLink = world.page.locator("#member-send-message-link");
  await waitForProjectedVisible(world, composeLink, `member compose link for ${clubName}`, {
    expect,
    timeoutMs
  });

  await browserInteraction(`open member compose flow for ${clubName}`, () => composeLink.click());

  await waitForProjectedVisible(
    world,
    world.page.locator("#member-message-compose[data-compose-state=\"composing\"]"),
    `member compose form for ${clubName}`,
    { expect, timeoutMs }
  );
}

async function openMemberMessage(world, subject, { expect = playwrightExpect, timeoutMs } = {}) {
  ensureState(world);

  const message = world.messages[subject];
  assert.ok(message, `Expected message ${JSON.stringify(subject)} to have been sent`);
  assert.ok(message.clubId, `Expected message ${JSON.stringify(subject)} to have a club id`);

  await gotoUnlessCurrent(
    world,
    memberMessageUrl(world, message),
    `visit member message page for ${JSON.stringify(subject)}`
  );
  await waitForProjectedVisible(
    world,
    world.page.getByRole("heading", { name: subject }),
    `member message heading for ${JSON.stringify(subject)}`,
    { expect, timeoutMs }
  );
}

async function openDeliveriesOverview(world, { expect = playwrightExpect, timeoutMs } = {}) {
  await gotoUnlessCurrent(world, appUrl(world.baseUrl, "/admin/deliveries"), "visit /admin/deliveries");
  await waitForProjectedVisible(
    world,
    world.page.getByRole("heading", { name: "Deliveries", exact: true }),
    "deliveries overview heading",
    { expect, timeoutMs }
  );
}

async function createClub(world, clubName, { expect = playwrightExpect, slug } = {}) {
  ensureState(world);

  await visitClubsIndex(world, { expect });

  const clubRows = rowsByData(world.page, "club-row", "data-club-name", clubName);
  const previousClubIds = await rowAttributeValues(clubRows, "data-club-id");
  const requestedSlug = slug || clubSlugForOccurrence(clubName, previousClubIds.length + 1);

  await browserInteraction(`submit club creation form for ${clubName}`, async () => {
    await world.page.getByLabel("Club name").fill(clubName);
    await world.page.getByLabel("Club slug").fill(requestedSlug);
    await world.page.getByRole("button", { name: "Create club" }).click();
  });
  await waitForProjectedCount(
    world,
    clubRows,
    previousClubIds.length + 1,
    `new club row for ${clubName}`,
    { expect }
  );

  const clubId = await newRowAttributeValue(
    clubRows,
    "data-club-id",
    previousClubIds,
    `club row for ${clubName}`
  );
  await waitForProjectedVisible(
    world,
    rowByData(world.page, "club-row", "data-club-id", clubId),
    `projected club row ${clubId}`,
    { expect }
  );
  const clubSlug =
    (await rowByData(world.page, "club-row", "data-club-id", clubId).getAttribute("data-club-slug")) ||
    requestedSlug;

  world.clubs[clubName] = { clubId, name: clubName, slug: clubSlug };

  return world;
}

async function updateClubSlug(world, clubName, slug, { expect = playwrightExpect, timeoutMs } = {}) {
  ensureState(world);

  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to have been created before updating its slug`);

  if (club.slug === slug) {
    return world;
  }

  await openClub(world, clubName, { expect, timeoutMs });

  await browserInteraction(`update club slug for ${clubName} to ${slug}`, async () => {
    await world.page.getByLabel("Club slug").fill(slug);
    await world.page.getByRole("button", { name: "Save club" }).click();
  });

  await waitForProjectedText(
    world,
    world.page.locator("#club-slug-display"),
    `Slug: ${slug}`,
    `updated club slug display for ${clubName}`,
    { expect, timeoutMs }
  );

  club.slug = slug;

  return world;
}

async function ensureClubSlugMatchesInboundAddress(
  world,
  clubName,
  inboundAddress,
  { expect = playwrightExpect, timeoutMs } = {}
) {
  ensureState(world);

  const slug = slugFromInboundAddress(inboundAddress);
  assert.ok(slug, `Expected inbound address ${JSON.stringify(inboundAddress)} to include a local-part slug`);

  return updateClubSlug(world, clubName, slug, { expect, timeoutMs });
}

async function createPeople(world, names, { expect = playwrightExpect } = {}) {
  ensureState(world);

  await openClub(world, kootenayClubName, { expect });

  for (const name of names) {
    await createPersonOnCurrentClubPage(world, name, kootenayClubName, { expect });
  }

  return world;
}

async function createPerson(
  world,
  name,
  clubName = kootenayClubName,
  { email, emailAddresses, expect = playwrightExpect } = {}
) {
  ensureState(world);

  await openClub(world, clubName, { expect });
  await createPersonOnCurrentClubPage(world, name, clubName, { email, emailAddresses, expect });

  return world;
}

async function createPersonOnCurrentClubPage(
  world,
  name,
  clubName,
  { email, emailAddresses, expect = playwrightExpect, timeoutMs } = {}
) {
  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to have been created before creating ${name}`);
  const normalizedEmailAddresses = personEmailAddressSet(name, { email, emailAddresses });

  const personRows = rowsByData(world.page, "person-row", "data-person-name", name);
  const previousPersonIds = await rowAttributeValues(personRows, "data-person-id");

  await browserInteraction(`visit create-person page for ${name}`, () =>
    world.page.goto(appUrl(world.baseUrl, `/admin/clubs/${club.clubId}/people/new`))
  );
  await waitForProjectedVisible(
    world,
    world.page.getByRole("heading", { name: "New person" }),
    `new person heading for ${clubName}`,
    { expect, timeoutMs }
  );

  await browserInteraction(`submit person creation form for ${name}`, async () => {
    await world.page.getByLabel("Person name").fill(name);
    await fillPersonEmailAddressRows(world, normalizedEmailAddresses, { expect, timeoutMs });
    await world.page.getByRole("button", { name: "Create person" }).click();
  });
  await waitForProjectedCount(
    world,
    personRows,
    previousPersonIds.length + 1,
    `new person row for ${name}`,
    { expect }
  );

  const personId = await newRowAttributeValue(
    personRows,
    "data-person-id",
    previousPersonIds,
    `person row for ${name}`
  );
  await waitForProjectedVisible(
    world,
    rowByData(world.page, "person-row", "data-person-id", personId),
    `projected person row ${personId}`,
    { expect }
  );

  world.people[name] = personState({ emailAddresses: normalizedEmailAddresses, name, personId });
}

async function updatePersonEmailAddresses(
  world,
  name,
  clubName = kootenayClubName,
  emailAddresses,
  { expect = playwrightExpect, timeoutMs } = {}
) {
  ensureState(world);

  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to have been created before editing ${name}`);

  const person = world.people[name];
  assert.ok(person && person.personId, `Expected ${name} to have been created before editing email addresses`);

  const normalizedEmailAddresses = personEmailAddressSet(name, { emailAddresses });

  await browserInteraction(`visit edit-person page for ${name}`, () =>
    world.page.goto(appUrl(world.baseUrl, `/admin/clubs/${club.clubId}/people/${person.personId}/edit`))
  );
  await waitForProjectedVisible(
    world,
    world.page.getByRole("heading", { name: `Edit ${name}` }),
    `edit person heading for ${name}`,
    { expect, timeoutMs }
  );

  await browserInteraction(`submit person email-address edit form for ${name}`, async () => {
    await fillPersonEmailAddressRows(world, normalizedEmailAddresses, { expect, timeoutMs });
    await world.page.getByRole("button", { name: "Save person" }).click();
  });
  await waitForProjectedVisible(
    world,
    rowByData(world.page, "person-row", "data-person-id", person.personId),
    `projected edited person row ${person.personId}`,
    { expect }
  );

  world.people[name] = personState({
    emailAddresses: normalizedEmailAddresses,
    name,
    personId: person.personId
  });

  return world;
}

async function fillPersonEmailAddressRows(
  world,
  emailAddresses,
  { expect = playwrightExpect, timeoutMs } = {}
) {
  const existingRows = world.page.locator('[data-testid="person-email-row"]');
  const existingRowCount = await existingRows.count();

  for (const [index, emailAddress] of emailAddresses.entries()) {
    if (index >= existingRowCount) {
      await world.page.getByRole("button", { name: "Add email address" }).click();
      await waitForProjectedVisible(
        world,
        world.page.getByLabel(`Email address ${index}`, { exact: true }),
        `email address row ${index}`,
        { expect, timeoutMs }
      );
    }

    await world.page.getByLabel(`Email address ${index}`, { exact: true }).fill(emailAddress.email);

    if (emailAddress.isPrimary) {
      await world.page.locator(`#person-primary-radio-${index}`).click();
    }
  }
}

function personEmailAddressSet(name, { email, emailAddresses } = {}) {
  const rawEmailAddresses = emailAddresses || [{ email: email || emailFor(name), isPrimary: true }];
  const normalizedEmailAddresses = rawEmailAddresses.map((emailAddress) => {
    const normalizedEmail = String(emailAddress.email || "").trim();
    const isPrimary = Boolean(
      emailAddress.isPrimary ?? emailAddress.is_primary ?? emailAddress.primary ?? emailAddress["primary?"]
    );

    assert.ok(normalizedEmail, `Expected ${name} email-address entries to include a non-blank email`);

    return { email: normalizedEmail, isPrimary };
  });

  assert.equal(
    normalizedEmailAddresses.filter((emailAddress) => emailAddress.isPrimary).length,
    1,
    `Expected exactly one primary email address for ${name}`
  );

  return normalizedEmailAddresses;
}

function personState({ emailAddresses, name, personId }) {
  const primaryEmailAddress = emailAddresses.find((emailAddress) => emailAddress.isPrimary);
  assert.ok(primaryEmailAddress, `Expected ${name} to have one primary email address`);
  const alternateEmails = emailAddresses
    .filter((emailAddress) => !emailAddress.isPrimary)
    .map((emailAddress) => emailAddress.email);

  return {
    alternateEmails,
    email: primaryEmailAddress.email,
    emailAddresses,
    name,
    personId,
    primaryEmail: primaryEmailAddress.email
  };
}

async function addMembers(world, personNames, clubName, { expect = playwrightExpect } = {}) {
  ensureState(world);

  await openClub(world, clubName, { expect });

  for (const personName of personNames) {
    await addMemberOnCurrentClubPage(world, personName, clubName, { expect });
  }

  return world;
}

async function addMemberOnCurrentClubPage(
  world,
  personName,
  clubName,
  { expect = playwrightExpect } = {}
) {
  const person = world.people[personName];
  assert.ok(person, `Expected ${personName} to have been created before adding them as a member`);

  const memberRows = rowsByData(world.page, "member-row", "data-member-name", personName);
  const previousMemberIds = await rowAttributeValues(memberRows, "data-member-id");

  await browserInteraction(`submit add-member form for ${personName} in ${clubName}`, async () => {
    await world.page.getByLabel("Person to add as member").selectOption(person.personId);
    await world.page.getByRole("button", { name: "Add selected person as member" }).click();
  });
  await waitForProjectedCount(
    world,
    memberRows,
    previousMemberIds.length + 1,
    `new member row for ${personName} in ${clubName}`,
    { expect }
  );

  const memberId = await newRowAttributeValue(
    memberRows,
    "data-member-id",
    previousMemberIds,
    `member row for ${personName} in ${clubName}`
  );
  await waitForProjectedVisible(
    world,
    rowByData(world.page, "member-row", "data-member-id", memberId),
    `projected member row ${memberId}`,
    { expect }
  );

  world.memberships[`${clubName}:${personName}`] = {
    clubName,
    memberId,
    personName
  };
}

async function sendMemberMessageToKootenayMembers(
  world,
  senderName,
  subject,
  { expect = playwrightExpect } = {}
) {
  ensureState(world);

  const body = `${subject} details.`;

  const mailboxEmailsBeforeSend = await testMailboxEmails(world);

  await openMemberComposeFromClubHome(world, kootenayClubName, { expect });

  await browserInteraction(`submit member compose form for ${JSON.stringify(subject)}`, async () => {
    await world.page.getByLabel("Subject").fill(subject);
    await world.page.getByLabel("Message").fill(body);
    await world.page.getByRole("button", { name: "Send to all members" }).click();
  });

  const sentState = world.page.locator("#member-message-compose[data-compose-state=\"sent\"]");
  await waitForProjectedVisible(world, sentState, `member compose success for ${JSON.stringify(subject)}`, {
    expect
  });

  const messageId = await sentState.getAttribute("data-sent-message-id");
  assert.ok(messageId, `Expected compose success state to expose a message id for ${JSON.stringify(subject)}`);

  await openMemberClubHome(world, kootenayClubName, { expect });

  await waitForProjectedVisible(
    world,
    rowByData(world.page, "club-message-row", "data-message-id", messageId),
    `projected member club message row ${messageId}`,
    { expect }
  );

  world.messages[subject] = {
    body,
    clubId: world.clubs[kootenayClubName].clubId,
    messageId,
    senderName,
    subject
  };
  world.mailboxEmailsBeforeSend = mailboxEmailsBeforeSend;
  world.lastMessageSubject = subject;

  return world;
}

async function sendInboundClubEmail(
  world,
  senderName,
  subject,
  toAddress,
  {
    attachments,
    fromAddress,
    htmlBody,
    htmlOnly = false,
    providerMessageId,
    textBody,
    expect = playwrightExpect
  } = {}
) {
  ensureState(world);

  const senderEmail = fromAddress || emailAddressForSender(world, senderName);
  const messageTextBody = htmlOnly ? "" : textBody ?? `${subject} details.`;
  const messageHtmlBody = htmlOnly ? htmlBody || `<p>${subject} details.</p>` : htmlBody;
  const mailboxEmailsBeforeSend = await testMailboxEmails(world);

  const payload = resendInboundEmailPayload({
    attachments,
    fromAddress: senderEmail,
    htmlBody: messageHtmlBody,
    providerMessageId,
    subject,
    textBody: messageTextBody,
    toAddress
  });

  await postResendInboundWebhook(world, payload);

  const inboundEmail = {
    attachments: attachments || [],
    fromAddress: senderEmail,
    htmlBody: messageHtmlBody,
    payload,
    providerMessageId: payload.data.email_id,
    senderName,
    subject,
    textBody: messageTextBody,
    toAddress
  };

  world.inboundEmails[subject] = inboundEmail;
  world.inboundEmailSenders[senderName] = inboundEmail;
  world.mailboxEmailsBeforeSend = mailboxEmailsBeforeSend;
  world.lastInboundEmail = inboundEmail;
  world.lastMessageSubject = subject;
  world.addressedMemberNames = memberNamesForClub(world, kootenayClubName);

  if (expect !== false) {
    await waitForInboundWebhookAccepted(world, payload);
  }

  return world;
}

async function trySendMemberMessageToKootenayMembers(
  world,
  _senderName,
  subject,
  { expect = playwrightExpect } = {}
) {
  ensureState(world);

  const body = `${subject} details.`;

  await openMemberComposeFromClubHome(world, kootenayClubName, { expect });

  await browserInteraction(`submit unavailable member compose form for ${JSON.stringify(subject)}`, async () => {
    await world.page.getByLabel("Subject").fill(subject);
    await world.page.getByLabel("Message").fill(body);
    await world.page.getByRole("button", { name: "Send to all members" }).click();
  });

  await waitForProjectedVisible(
    world,
    world.page.locator("#member-message-compose[data-compose-state=\"send_failed\"]"),
    `member compose send failure for ${JSON.stringify(subject)}`,
    { expect }
  );

  world.failedMessageSubject = subject;

  return world;
}

async function configureMessagingEmailDeliveryProvider(world, provider) {
  const request = world.request || (world.context && world.context.request) || (world.page && world.page.request);
  assert.ok(
    request && typeof request.post === "function",
    "Expected Playwright request context to be available for acceptance test support configuration"
  );

  let response;

  try {
    response = await request.post(appUrl(world.baseUrl, "/dev/test-support/messaging-delivery-provider"), {
      data: { provider },
      headers: {
        "content-type": "application/json"
      }
    });
  } catch (error) {
    throw new Error(
      `Acceptance test support configuration failed: POST /dev/test-support/messaging-delivery-provider request error.\n` +
        `Provider: ${provider}\nCause: ${errorMessage(error)}`,
      { cause: error }
    );
  }

  const status = response.status();

  if (status !== 204) {
    const body = typeof response.text === "function" ? await response.text() : "(response body unavailable)";

    throw new Error(
      `Acceptance test support configuration failed: expected HTTP 204 from ` +
        `POST /dev/test-support/messaging-delivery-provider, got HTTP ${status}.\n` +
        `Provider: ${provider}\nResponse body: ${body}`
    );
  }

  return world;
}

async function makeClubMessageSendingUnavailable(world) {
  await configureMessagingEmailDeliveryProvider(world, "unavailable");
  world.clubMessageSendingWasConfigured = true;

  return world;
}

async function restoreClubMessageSending(world) {
  if (!world.clubMessageSendingWasConfigured) {
    return world;
  }

  await configureMessagingEmailDeliveryProvider(world, "local");
  world.clubMessageSendingWasConfigured = false;

  return world;
}

async function assertMemberWasToldMessageWasNotSent(world, { expect = playwrightExpect } = {}) {
  await waitForProjectedText(
    world,
    world.page.locator("#member-compose-error-summary"),
    "Your message was not sent to anyone. Please contact support so we can investigate before you try again.",
    "member compose failure not-sent copy",
    { expect }
  );

  return world;
}

async function assertMemberWasToldToContactSupport(world, { expect = playwrightExpect } = {}) {
  await waitForProjectedText(
    world,
    world.page.locator("#member-compose-error-summary"),
    "Your message was not sent to anyone. Please contact support so we can investigate before you try again.",
    "member compose failure support copy",
    { expect }
  );

  return world;
}

async function sendMessageToKootenayMembers(
  world,
  senderName,
  subject,
  { expect = playwrightExpect } = {}
) {
  ensureState(world);

  const body = `${subject} details.`;

  await openClub(world, kootenayClubName, { expect });

  const messageRows = rowsByData(world.page, "message-row", "data-message-subject", subject);
  const previousMessageIds = await rowAttributeValues(messageRows, "data-message-id");

  const sender = world.people[senderName];
  assert.ok(sender, `Expected ${senderName} to have been created before sending a message`);

  const mailboxEmailsBeforeSend = await testMailboxEmails(world);

  await browserInteraction(`submit message form for ${JSON.stringify(subject)}`, async () => {
    await world.page.getByLabel("Message sender").selectOption(sender.personId);
    await world.page.getByLabel("Message subject").fill(subject);
    await world.page.getByLabel("Message body").fill(body);
    await world.page.getByRole("button", { name: "Send club message" }).click();
  });
  await waitForProjectedCount(
    world,
    messageRows,
    previousMessageIds.length + 1,
    `new message row for ${JSON.stringify(subject)}`,
    { expect }
  );

  const messageId = await newRowAttributeValue(
    messageRows,
    "data-message-id",
    previousMessageIds,
    `message row for ${subject}`
  );
  await waitForProjectedVisible(
    world,
    rowByData(world.page, "message-row", "data-message-id", messageId),
    `projected message row ${messageId}`,
    { expect }
  );

  world.messages[subject] = {
    body,
    clubId: world.clubs[kootenayClubName].clubId,
    messageId,
    senderName,
    subject
  };
  world.mailboxEmailsBeforeSend = mailboxEmailsBeforeSend;
  world.lastMessageSubject = subject;

  await openMessage(world, subject, { expect });

  return world;
}

async function assertMemberSeesMessageInClub(
  world,
  subject,
  clubName,
  { expect = playwrightExpect } = {}
) {
  await openMemberClubHome(world, clubName, { expect });

  const row = rowByData(world.page, "club-message-row", "data-message-subject", subject);
  await waitForProjectedVisible(
    world,
    row,
    `member club message row for ${JSON.stringify(subject)} in ${clubName}`,
    { expect }
  );

  const messageId = await row.getAttribute("data-message-id");

  if (messageId && !world.messages[subject]) {
    const inboundEmail = world.inboundEmails[subject] || {};

    world.messages[subject] = {
      body: inboundEmail.textBody || `${subject} details.`,
      clubId: world.clubs[clubName].clubId,
      messageId,
      senderName: inboundEmail.senderName,
      subject
    };
  }

  world.lastMessageSubject = subject;

  return world;
}

async function assertNoMemberMessageCreated(
  world,
  clubName,
  subject,
  { expect = playwrightExpect } = {}
) {
  await openMemberClubHome(world, clubName, { expect });

  const rows = rowsByData(world.page, "club-message-row", "data-message-subject", subject);
  await waitForProjectedCount(
    world,
    rows,
    0,
    `no member club message row for ${JSON.stringify(subject)} in ${clubName}`,
    { expect }
  );

  assertFinalBrowserState(`message ${JSON.stringify(subject)} should not be recorded in scenario state`, () =>
    assert.equal(world.messages[subject], undefined)
  );

  return world;
}

async function assertMemberMessageBody(world, expectedBody, { expect = playwrightExpect } = {}) {
  const subject = world.lastMessageSubject;
  assert.ok(subject, "Expected a current message subject before checking the message body");

  await openMemberMessage(world, subject, { expect });
  await waitForProjectedText(
    world,
    world.page.locator("#member-message-body"),
    normalizeDocString(expectedBody),
    `member message body for ${JSON.stringify(subject)}`,
    { expect }
  );

  return world;
}

async function assertMemberMessageAddressedTo(
  world,
  expectedNames,
  subject = world.lastMessageSubject,
  { expect = playwrightExpect } = {}
) {
  await openMemberMessage(world, subject, { expect });
  await expandCollapsedMemberEmailDeliveryGroups(world, { expect });

  const rows = allRows(world.page, "member-receipts", "member-receipt");
  await waitForExpandedMemberEmailDeliveryCount(
    world,
    rows,
    expectedNames.length,
    `member-facing recipient rows for ${JSON.stringify(subject)}`,
    { expect }
  );

  const actualNames = await rowDatasetValues(rows, "recipientName");
  assertFinalBrowserState(`member-facing recipients for ${JSON.stringify(subject)}`, () =>
    assert.deepEqual(actualNames, expectedNames)
  );

  world.addressedMemberNames = expectedNames;
  world.addressedMemberIds = expectedNames.map((name) => {
    const person = world.people[name];
    assert.ok(person, `Expected ${name} to have been created`);
    return person.personId;
  });

  return world;
}

async function assertMemberMessageNotAddressedTo(
  world,
  excludedName,
  subject = world.lastMessageSubject,
  { expect = playwrightExpect } = {}
) {
  await openMemberMessage(world, subject, { expect });
  await expandCollapsedMemberEmailDeliveryGroups(world, { expect });

  const rows = allRows(world.page, "member-receipts", "member-receipt");
  const actualNames = await rowDatasetValues(rows, "recipientName");
  assertFinalBrowserState(`member-facing recipients should not include ${excludedName}`, () =>
    assert.ok(
      !actualNames.includes(excludedName),
      `Expected member-facing recipients not to include ${excludedName}; saw ${actualNames.join(", ")}`
    )
  );

  return world;
}

async function assertLastMessageAddressedTo(
  world,
  expectedNames,
  { expect = playwrightExpect } = {}
) {
  await openMessage(world, world.lastMessageSubject, { expect });

  const rows = allRows(world.page, "addressed-recipients", "addressed-recipient");
  await waitForProjectedCount(
    world,
    rows,
    expectedNames.length,
    `addressed recipients for ${JSON.stringify(world.lastMessageSubject)}`,
    { expect }
  );

  const actualNames = await rowDatasetValues(rows, "recipientName");
  assertFinalBrowserState(
    `addressed recipients for ${JSON.stringify(world.lastMessageSubject)}`,
    () => assert.deepEqual(actualNames, expectedNames)
  );

  world.addressedMemberNames = expectedNames;
  world.addressedMemberIds = expectedNames.map((name) => {
    const person = world.people[name];
    assert.ok(person, `Expected ${name} to have been created`);
    return person.personId;
  });

  return world;
}

async function assertLastMessageNotAddressedTo(
  world,
  excludedName,
  { expect = playwrightExpect } = {}
) {
  await openMessage(world, world.lastMessageSubject, { expect });

  const rows = allRows(world.page, "addressed-recipients", "addressed-recipient");
  const actualNames = await rowDatasetValues(rows, "recipientName");
  assertFinalBrowserState(
    `addressed recipients should not include ${excludedName}`,
    () =>
      assert.ok(
        !actualNames.includes(excludedName),
        `Expected addressed recipients not to include ${excludedName}; saw ${actualNames.join(", ")}`
      )
  );

  return world;
}

async function assertEachAddressedMemberHasSeparateDeliveryRecord(
  world,
  { expect = playwrightExpect } = {}
) {
  await openMessage(world, world.lastMessageSubject, { expect });

  const expectedIds = world.addressedMemberIds || [];
  assert.ok(
    expectedIds.length > 0,
    "Expected addressed members to be asserted before checking email deliveries"
  );

  const rows = allRows(world.page, "delivery-records", "delivery-record");
  await waitForProjectedCount(
    world,
    rows,
    expectedIds.length,
    `email deliveries for ${JSON.stringify(world.lastMessageSubject)}`,
    { expect }
  );

  const recipientIds = await rowDatasetValues(rows, "recipientId");
  const deliveryIds = await rowDatasetValues(rows, "deliveryId");
  const recipientNames = await rowDatasetValues(rows, "recipientName");

  assertFinalBrowserState(`delivery recipient IDs for ${JSON.stringify(world.lastMessageSubject)}`, () =>
    assert.deepEqual(recipientIds, expectedIds)
  );
  assertUnique(deliveryIds, "delivery IDs");
  assertUnique(recipientIds, "recipient IDs");

  const subject = world.lastMessageSubject;
  world.deliveries[subject] = {};

  recipientNames.forEach((recipientName, index) => {
    world.deliveries[subject][recipientName] = {
      deliveryId: deliveryIds[index],
      recipientId: recipientIds[index],
      recipientName
    };
  });

  return world;
}

async function assertEachDeliverySentThroughEmailProvider(
  world,
  { expect = playwrightExpect } = {}
) {
  await openMessage(world, world.lastMessageSubject, { expect });

  const deliveryNames = Object.keys(world.deliveries[world.lastMessageSubject] || {});
  assert.ok(
    deliveryNames.length > 0,
    "Expected email deliveries to be asserted before checking email-provider delivery"
  );

  for (const recipientName of deliveryNames) {
    const row = rowByData(world.page, "delivery-record", "data-recipient-name", recipientName);
    await waitForProjectedVisible(
      world,
      row.getByText(/^email$/),
      `email channel for ${recipientName}'s delivery`,
      { expect }
    );
    await waitForProjectedText(
      world,
      row.locator("[data-testid=\"delivery-status\"]"),
      "sent",
      `sent delivery status for ${recipientName}`,
      { expect }
    );
  }

  return world;
}

async function assertEachAddressedMemberReceivedEmailInTestMailbox(world, { senderName } = {}) {
  ensureState(world);

  const subject = world.lastMessageSubject;
  const message = world.messages[subject];
  assert.ok(message, "Expected a message to have been sent before checking the mailbox");

  const addressedMemberNames = world.addressedMemberNames || [];
  assert.ok(
    addressedMemberNames.length > 0,
    "Expected addressed members to be asserted before checking the mailbox"
  );

  const previousEmails = world.mailboxEmailsBeforeSend || [];
  const emails = await waitForMailboxEmails(
    world,
    previousEmails.length + addressedMemberNames.length,
    `Swoosh test mailbox emails for ${JSON.stringify(subject)}`
  );
  const previousMessageIds = previousEmails.map(mailboxMessageId).filter(Boolean);
  const newEmails = emails.filter((email) => !previousMessageIds.includes(mailboxMessageId(email)));

  for (const recipientName of addressedMemberNames) {
    const person = world.people[recipientName];
    assert.ok(person, `Expected ${recipientName} to have been created`);

    const sender = senderName ? world.people[senderName] : null;

    if (senderName) {
      assert.ok(sender, `Expected ${senderName} to have been created`);
    }

    const matchingEmail = newEmails.find(
      (email) =>
        email.subject === subject &&
        email.text_body === message.body &&
        email.to.some((recipient) => recipient.includes(person.email)) &&
        (!sender || mailboxEmailFrom(email).includes(`${senderName} via Memba`))
    );

    assertFinalBrowserState(`test mailbox email for ${recipientName}`, () =>
      assert.ok(
        matchingEmail,
        `Expected a mailbox email for ${recipientName} <${person.email}> with subject ${JSON.stringify(
          subject
        )}${sender ? ` from ${senderName} via Memba` : ""}; saw ${JSON.stringify(newEmails.map(mailboxEmailSummary))}`
      )
    );
  }

  return world;
}

async function assertInboundRejectionEmail(world, senderName, expectedText) {
  ensureState(world);

  const senderEmail = inboundSenderEmail(world, senderName);
  const previousEmails = world.mailboxEmailsBeforeSend || [];
  const emails = await waitForMailboxEmails(
    world,
    previousEmails.length + 1,
    `inbound rejection email for ${senderName} <${senderEmail}>`
  );
  const previousMessageIds = previousEmails.map(mailboxMessageId).filter(Boolean);
  const newEmails = emails.filter((email) => !previousMessageIds.includes(mailboxMessageId(email)));

  const rejectionEmail = newEmails.find(
    (email) =>
      email.subject === "Your email was not posted" &&
      mailboxEmailTo(email).includes(senderEmail) &&
      mailboxEmailText(email).includes(expectedText)
  );

  assertFinalBrowserState(`inbound rejection email for ${senderName}`, () =>
    assert.ok(
      rejectionEmail,
      `Expected a rejection email to ${senderEmail} containing ${JSON.stringify(
        expectedText
      )}; saw ${JSON.stringify(newEmails.map(mailboxEmailSummary))}`
    )
  );

  world.inboundRejectionEmails[senderName] = rejectionEmail;

  return world;
}

async function assertInboundRejectionEmailSupportGuidance(world, senderName) {
  ensureState(world);

  const rejectionEmail = world.inboundRejectionEmails[senderName];
  assert.ok(
    rejectionEmail,
    `Expected ${senderName}'s rejection email to have been asserted before checking support guidance`
  );

  assertFinalBrowserState(`inbound rejection support guidance for ${senderName}`, () =>
    assert.match(mailboxEmailText(rejectionEmail), /contact Memba support|reply to this email/i)
  );

  return world;
}

async function assertEveryAddressedMemberEmailDeliveryStatus(
  world,
  subject,
  expectedLabel,
  { expect = playwrightExpect } = {}
) {
  ensureState(world);

  const addressedMemberNames = world.addressedMemberNames || [];
  assert.ok(
    addressedMemberNames.length > 0,
    "Expected addressed members to be asserted before checking every member email delivery status"
  );

  await openMemberMessage(world, subject, { expect });
  await expandCollapsedMemberEmailDeliveryGroups(world, { expect });

  for (const recipientName of addressedMemberNames) {
    await assertMemberEmailDeliveryStatusOnCurrentPage(world, recipientName, subject, expectedLabel, { expect });
  }

  return world;
}

async function assertMemberEmailDeliveryStatus(
  world,
  recipientName,
  subject,
  expectedLabel,
  { expect = playwrightExpect } = {}
) {
  await openMemberMessage(world, subject, { expect });
  await expandCollapsedMemberEmailDeliveryGroups(world, { expect });
  await assertMemberEmailDeliveryStatusOnCurrentPage(world, recipientName, subject, expectedLabel, { expect });

  return world;
}

async function assertMemberEmailDeliveryStatusOnCurrentPage(
  world,
  recipientName,
  subject,
  expectedLabel,
  { expect = playwrightExpect } = {}
) {
  const row = rowByData(world.page, "member-receipt", "data-recipient-name", recipientName);
  await waitForProjectedVisible(
    world,
    row,
    `${recipientName}'s member-facing email delivery row for ${JSON.stringify(subject)}`,
    { expect }
  );
  await waitForProjectedText(
    world,
    row.locator("[data-testid=\"receipt-status\"]"),
    expectedLabel,
    `${recipientName}'s member-facing status label for ${JSON.stringify(subject)}`,
    { expect }
  );

  const expectedIcon = memberReceiptIconForLabel(expectedLabel);
  const icon = row.locator("[data-testid=\"receipt-status-icon\"]");
  await waitForProjectedVisible(
    world,
    icon,
    `${recipientName}'s member-facing status icon for ${JSON.stringify(subject)}`,
    { expect }
  );

  const actualIcon = await icon.getAttribute("data-icon-name");
  assertFinalBrowserState(`${recipientName}'s member-facing email delivery icon for ${JSON.stringify(subject)}`, () =>
    assert.equal(actualIcon, expectedIcon)
  );

  return world;
}

async function assertReceiptStatus(world, recipientName, subject, expectedStatus, { expect = playwrightExpect } = {}) {
  await openMessage(world, subject, { expect });

  const row = rowByData(world.page, "member-receipt", "data-recipient-name", recipientName);
  await waitForProjectedVisible(
    world,
    row,
    `${recipientName}'s receipt row for ${JSON.stringify(subject)}`,
    { expect }
  );
  await waitForProjectedText(
    world,
    row.locator("[data-testid=\"receipt-status\"]"),
    expectedStatus,
    `${recipientName}'s status for ${JSON.stringify(subject)}`,
    { expect }
  );

  return world;
}

async function assertOperatorDeliveryStatus(
  world,
  recipientName,
  subject,
  expectedStatus,
  { expect = playwrightExpect } = {}
) {
  await openDeliveriesOverview(world, { expect });

  const row = operatorDeliveryRow(world, recipientName, subject);
  await waitForProjectedVisible(
    world,
    row,
    `${recipientName}'s Memba staff email delivery row for ${JSON.stringify(subject)}`,
    { expect }
  );
  await waitForProjectedText(
    world,
    row.locator("[data-test-id=\"delivery-status\"]"),
    expectedStatus,
    `${recipientName}'s Memba staff email delivery status for ${JSON.stringify(subject)}`,
    { expect }
  );

  world.currentOperatorDelivery = { recipientName, subject };

  return world;
}

async function assertOperatorDeliveryReason(
  world,
  recipientName,
  expectedReason,
  { expect = playwrightExpect } = {}
) {
  ensureState(world);

  const currentDelivery = world.currentOperatorDelivery;
  assert.ok(
    currentDelivery,
    "Expected an Memba staff email delivery status assertion before checking its reason"
  );
  assert.equal(
    currentDelivery.recipientName,
    recipientName,
    `Expected current Memba staff email delivery to belong to ${recipientName}`
  );

  await openDeliveriesOverview(world, { expect });

  const row = operatorDeliveryRow(world, recipientName, currentDelivery.subject);
  await waitForProjectedVisible(
    world,
    row,
    `${recipientName}'s Memba staff email delivery row for ${JSON.stringify(currentDelivery.subject)}`,
    { expect }
  );
  await waitForProjectedText(
    world,
    row.locator("[data-test-id=\"delivery-reason\"]"),
    expectedReason,
    `${recipientName}'s Memba staff email delivery reason for ${JSON.stringify(currentDelivery.subject)}`,
    { expect }
  );

  return world;
}

function operatorDeliveryRow(world, recipientName, subject) {
  ensureState(world);

  const message = world.messages[subject];
  assert.ok(message, `Expected message ${JSON.stringify(subject)} to have been sent`);

  const recipient = world.people[recipientName];
  assert.ok(recipient, `Expected ${recipientName} to have been created`);

  return world.page
    .locator(
      `[data-test-id^="delivery-row-"][data-message-id=${cssString(
        message.messageId
      )}][data-recipient-id=${cssString(recipient.personId)}]`
    )
    .last();
}

function memberReceiptStatusForEventType(eventType) {
  switch (eventType) {
    case "delivered":
      return "delivered";

    case "opened":
      return "opened";

    case "delayed":
    case "bounced":
    case "spam_complaint":
      return "delivery problem";

    default:
      throw new Error(`Unsupported browser member email delivery projection status event: ${eventType}`);
  }
}

function memberReceiptIconForLabel(label) {
  switch (label) {
    case "Sending":
      return "hero-clock";

    case "Delivered":
      return "hero-check-circle";

    case "Delivery problem":
      return "hero-exclamation-triangle";

    case "Opened":
      return "hero-envelope-open";

    default:
      throw new Error(`Unsupported member-facing email delivery label: ${label}`);
  }
}

async function waitForProjectedReceiptStatus(
  world,
  recipientName,
  subject,
  expectedStatus,
  { expect = playwrightExpect } = {}
) {
  const timeoutMs = projectionTimeoutMs(world);
  const deadline = Date.now() + timeoutMs;
  let lastError = null;

  do {
    const assertionTimeoutMs = Math.max(1, Math.min(1000, deadline - Date.now()));

    try {
      await openMessage(world, subject, { expect, force: true, timeoutMs: assertionTimeoutMs });

      const row = rowByData(world.page, "member-receipt", "data-recipient-name", recipientName);
      await waitForProjectedVisible(
        world,
        row,
        `${recipientName}'s projected receipt row for ${JSON.stringify(subject)}`,
        { expect, timeoutMs: assertionTimeoutMs }
      );
      await waitForProjectedText(
        world,
        row.locator("[data-testid=\"receipt-status\"]"),
        expectedStatus,
        `${recipientName}'s projected status for ${JSON.stringify(subject)}`,
        { expect, timeoutMs: assertionTimeoutMs }
      );

      return world;
    } catch (error) {
      lastError = error;
    }

    const remainingMs = deadline - Date.now();

    if (remainingMs > 0) {
      await delay(Math.min(projectionPollIntervalMs(world), remainingMs));
    }
  } while (Date.now() <= deadline);

  throw new Error(
    `Projection timing timeout: timed out after ${timeoutMs}ms waiting for projected status: ` +
      `${recipientName}'s receipt for ${JSON.stringify(subject)} should become ${JSON.stringify(
        expectedStatus
      )}.\nLast projection error: ${lastError ? errorMessage(lastError) : "(none)"}`
  );
}

async function reportRecipientEmailStatus(
  world,
  recipientName,
  subject,
  eventType,
  { expect = playwrightExpect, reason } = {}
) {
  ensureState(world);

  const key = `${subject}:${recipientName}`;
  const delivery = await deliveryForRecipient(world, recipientName, subject, { expect });

  if (eventType === "opened" && !hasSuccessfulDeliveryReport(world, key)) {
    const deliveredPayload = postmarkPayloadForStatus({
      deliveryId: delivery.deliveryId,
      eventType: "delivered",
      messageId: delivery.messageId,
      recipientEmail: delivery.recipientEmail
    });

    await postPostmarkWebhook(world, deliveredPayload);
    await waitForProjectedReceiptStatus(
      world,
      recipientName,
      subject,
      memberReceiptStatusForEventType("delivered"),
      { expect }
    );
  }

  const payload = postmarkPayloadForStatus({
    deliveryId: delivery.deliveryId,
    eventType,
    messageId: delivery.messageId,
    reason,
    recipientEmail: delivery.recipientEmail
  });

  await postPostmarkWebhook(world, payload);
  await waitForProjectedReceiptStatus(
    world,
    recipientName,
    subject,
    memberReceiptStatusForEventType(eventType),
    { expect }
  );

  world.reportedDeliveryStatuses[key] = {
    eventType,
    payload,
    reason,
    recipientName,
    subject
  };

  return world;
}

function hasSuccessfulDeliveryReport(world, key) {
  const report = world.reportedDeliveryStatuses[key];

  return report && ["delivered", "opened"].includes(report.eventType);
}

async function deliveryForRecipient(
  world,
  recipientName,
  subject,
  { expect = playwrightExpect } = {}
) {
  ensureState(world);

  const message = world.messages[subject];
  assert.ok(message, `Expected message ${JSON.stringify(subject)} to have been sent`);

  const recipient = world.people[recipientName];
  assert.ok(recipient, `Expected ${recipientName} to have been created`);

  await openMessage(world, subject, { expect });

  const row = rowByData(world.page, "delivery-record", "data-recipient-name", recipientName);
  await waitForProjectedVisible(
    world,
    row,
    `${recipientName}'s email delivery for ${JSON.stringify(subject)}`,
    { expect }
  );

  const deliveryId = await row.getAttribute("data-delivery-id");
  assert.ok(
    deliveryId,
    `Expected email delivery for ${recipientName} and ${JSON.stringify(subject)} to expose data-delivery-id`
  );

  const recipientId = await row.getAttribute("data-recipient-id");

  world.deliveries[subject] = world.deliveries[subject] || {};
  world.deliveries[subject][recipientName] = {
    deliveryId,
    recipientEmail: recipient.email,
    recipientId,
    recipientName
  };

  return {
    deliveryId,
    messageId: message.messageId,
    recipientEmail: recipient.email,
    recipientId,
    recipientName
  };
}

async function testMailboxEmails(world) {
  const request = world.request || (world.context && world.context.request) || (world.page && world.page.request);
  if (!request || typeof request.get !== "function") {
    return [];
  }

  let response;

  try {
    response = await request.get(appUrl(world.baseUrl, "/dev/mailbox/json"));
  } catch (error) {
    throw new Error(
      `Swoosh mailbox inspection failed: GET /dev/mailbox/json request error.\nCause: ${errorMessage(
        error
      )}`,
      { cause: error }
    );
  }

  const status = response.status();

  if (status !== 200) {
    const body = typeof response.text === "function" ? await response.text() : "(response body unavailable)";

    throw new Error(
      `Swoosh mailbox inspection failed: expected HTTP 200 from GET /dev/mailbox/json, got HTTP ${status}.\n` +
        `Response body: ${body}`
    );
  }

  const payload = await response.json();
  return payload.data || [];
}

async function waitForMailboxEmails(world, expectedCount, description) {
  const timeoutMs = projectionTimeoutMs(world);
  const deadline = Date.now() + timeoutMs;
  let emails = [];
  let lastError = null;

  do {
    try {
      emails = await testMailboxEmails(world);

      if (emails.length >= expectedCount) {
        return emails;
      }
    } catch (error) {
      lastError = error;
    }

    const remainingMs = deadline - Date.now();

    if (remainingMs > 0) {
      await delay(Math.min(projectionPollIntervalMs(world), remainingMs));
    }
  } while (Date.now() <= deadline);

  throw new Error(
    `Projection timing timeout: timed out after ${timeoutMs}ms waiting for ${description}. ` +
      `Expected at least ${expectedCount} emails; saw ${emails.length}.\n` +
      `Last mailbox error: ${lastError ? errorMessage(lastError) : "(none)"}`
  );
}

function mailboxMessageId(email) {
  return email && email.headers && email.headers["Message-ID"];
}

function mailboxEmailTo(email) {
  const to = email && email.to;

  if (Array.isArray(to)) {
    return to.join(" ");
  }

  return String(to || "");
}

function mailboxEmailText(email) {
  return String((email && (email.text_body || email.textBody || email.text)) || "");
}

function mailboxEmailFrom(email) {
  const from = email && email.from;

  if (Array.isArray(from)) {
    return from.join(" ");
  }

  return String(from || "");
}

function mailboxEmailSummary(email) {
  return {
    from: email.from,
    subject: email.subject,
    to: email.to,
    text_body: email.text_body
  };
}

async function postPostmarkWebhook(world, payload) {
  const request = world.request || (world.context && world.context.request) || (world.page && world.page.request);
  assert.ok(
    request && typeof request.post === "function",
    "Expected Playwright request context to be available for Postmark webhook submission"
  );

  let response;

  try {
    response = await request.post(appUrl(world.baseUrl, "/webhooks/postmark"), {
      data: payload,
      headers: {
        "content-type": "application/json"
      }
    });
  } catch (error) {
    throw new Error(
      `Postmark webhook submission failed: POST /webhooks/postmark request error.\n` +
        `Payload: ${JSON.stringify(payload)}\nCause: ${errorMessage(error)}`,
      { cause: error }
    );
  }
  const status = response.status();

  if (status !== 202) {
    const body = typeof response.text === "function" ? await response.text() : "(response body unavailable)";

    throw new Error(
      `Postmark webhook submission failed: expected HTTP 202 from POST /webhooks/postmark, got HTTP ${status}.\n` +
        `Payload: ${JSON.stringify(payload)}\nResponse body: ${body}`
    );
  }

  return response;
}

async function postResendInboundWebhook(world, payload) {
  const request = world.request || (world.context && world.context.request) || (world.page && world.page.request);
  assert.ok(
    request && typeof request.post === "function",
    "Expected Playwright request context to be available for Resend inbound webhook submission"
  );

  let response;

  try {
    response = await request.post(appUrl(world.baseUrl, "/webhooks/resend/inbound"), {
      data: payload,
      headers: {
        "content-type": "application/json"
      }
    });
  } catch (error) {
    throw new Error(
      `Resend inbound webhook submission failed: POST /webhooks/resend/inbound request error.\n` +
        `Payload: ${JSON.stringify(payload)}\nCause: ${errorMessage(error)}`,
      { cause: error }
    );
  }
  const status = response.status();

  if (status !== 202) {
    const body = typeof response.text === "function" ? await response.text() : "(response body unavailable)";

    throw new Error(
      `Resend inbound webhook submission failed: expected HTTP 202 from POST /webhooks/resend/inbound, got HTTP ${status}.\n` +
        `Payload: ${JSON.stringify(payload)}\nResponse body: ${body}`
    );
  }

  return response;
}

async function waitForInboundWebhookAccepted(world, payload) {
  assert.ok(
    payload && payload.type === "email.received",
    `Expected an email.received Resend inbound payload; got ${JSON.stringify(payload)}`
  );

  return world;
}

async function rowDatasetValues(rows, datasetName) {
  return rows.evaluateAll((elements, key) => elements.map((element) => element.dataset[key]), datasetName);
}

function emailAddressForSender(world, senderName) {
  const person = world.people[senderName];

  if (person && (person.email || person.primaryEmail)) {
    return person.email || person.primaryEmail;
  }

  return emailFor(senderName);
}

function inboundSenderEmail(world, senderName) {
  const inboundEmail = world.inboundEmailSenders[senderName];

  if (inboundEmail && inboundEmail.fromAddress) {
    return inboundEmail.fromAddress;
  }

  return emailAddressForSender(world, senderName);
}

function memberNamesForClub(world, clubName) {
  const prefix = `${clubName}:`;

  return Object.keys(world.memberships || {})
    .filter((membershipKey) => membershipKey.startsWith(prefix))
    .map((membershipKey) => membershipKey.slice(prefix.length));
}

function slugFromInboundAddress(inboundAddress) {
  const match = String(inboundAddress || "").match(/<?([^<>\s@]+)@[^<>\s@]+>?/);

  return match && match[1];
}

function normalizeDocString(text) {
  return String(text || "").replace(/\r\n/g, "\n").replace(/\n+$/g, "");
}

function assertUnique(values, label) {
  assertFinalBrowserState(`${label} should be unique`, () =>
    assert.deepEqual(
      [...new Set(values)],
      values,
      `Expected ${label} to be unique; saw ${values.join(", ")}`
    )
  );
}

module.exports = {
  addMembers,
  appUrl,
  clubSiteUrl,
  assertEveryAddressedMemberEmailDeliveryStatus,
  assertEveryAddressedMemberReceiptStatus: assertEveryAddressedMemberEmailDeliveryStatus,
  assertEachAddressedMemberHasSeparateDeliveryRecord,
  assertEachAddressedMemberReceivedEmailInTestMailbox,
  assertEachDeliverySentThroughEmailProvider,
  assertInboundRejectionEmail,
  assertInboundRejectionEmailSupportGuidance,
  assertLastMessageAddressedTo,
  assertLastMessageNotAddressedTo,
  assertMemberMessageAddressedTo,
  assertMemberMessageBody,
  assertMemberMessageNotAddressedTo,
  assertMemberEmailDeliveryStatus,
  assertMemberReceiptStatus: assertMemberEmailDeliveryStatus,
  assertMemberSeesMessageInClub,
  assertMemberWasToldMessageWasNotSent,
  assertMemberWasToldToContactSupport,
  assertNoMemberMessageCreated,
  assertOperatorDeliveryReason,
  assertOperatorDeliveryStatus,
  assertReceiptStatus,
  createClub,
  createPeople,
  createPerson,
  cssString,
  deliveryForRecipient,
  emailFor,
  ensureClubSlugMatchesInboundAddress,
  ensureState,
  kootenayClubName,
  makeClubMessageSendingUnavailable,
  memberReceiptIconForLabel,
  memberReceiptStatusForEventType,
  nelsonClubName,
  openMemberComposeFromClubHome,
  openMemberClubHome,
  openMemberMessage,
  postmarkPayloadForStatus,
  postPostmarkWebhook,
  postResendInboundWebhook,
  projectionPollIntervalMs,
  projectionTimeoutMs,
  reportRecipientEmailStatus,
  resendInboundEmailPayload,
  rowAttributeValues,
  openDeliveriesOverview,
  openClub,
  openMessage,
  restoreClubMessageSending,
  sendInboundClubEmail,
  sendMemberMessageToKootenayMembers,
  sendMessageToKootenayMembers,
  testMailboxEmails,
  trySendMemberMessageToKootenayMembers,
  updateClubSlug,
  updatePersonEmailAddresses,
  visitClubsIndex,
  waitForMailboxEmails
};
