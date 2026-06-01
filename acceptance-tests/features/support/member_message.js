const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { expect: playwrightExpect } = require("@playwright/test");

const kootenayClubName = "Kootenay Mountaineering Club";
const nelsonClubName = "Nelson Paddling Club";
const defaultProjectionPollIntervalMs = 250;
const defaultProjectionTimeoutMs = 10000;

function appUrl(baseUrl, path) {
  return new URL(path, `${baseUrl}/`).toString();
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

function ensureState(world) {
  world.clubs = world.clubs || {};
  world.people = world.people || {};
  world.memberships = world.memberships || {};
  world.messages = world.messages || {};
  world.deliveries = world.deliveries || {};
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

function clubHomePath(clubId) {
  return `/?club_id=${encodeURIComponent(clubId)}`;
}

function memberMessagePath(message) {
  return `/messages/${encodeURIComponent(message.messageId)}?club_id=${encodeURIComponent(message.clubId)}`;
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

async function visitClubsIndex(world) {
  await browserInteraction("visit /admin/clubs", () =>
    world.page.goto(appUrl(world.baseUrl, "/admin/clubs"))
  );
}

async function openClub(world, clubName, { expect = playwrightExpect, timeoutMs } = {}) {
  ensureState(world);

  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to have been created before opening it`);

  await browserInteraction(`visit club page for ${clubName}`, () =>
    world.page.goto(appUrl(world.baseUrl, `/admin/clubs/${club.clubId}`))
  );
  await waitForProjectedVisible(
    world,
    world.page.getByRole("heading", { name: clubName }),
    `club heading for ${clubName}`,
    { expect, timeoutMs }
  );
}

async function openMessage(world, subject, { expect = playwrightExpect, timeoutMs } = {}) {
  ensureState(world);

  const message = world.messages[subject];
  assert.ok(message, `Expected message ${JSON.stringify(subject)} to have been sent`);

  await browserInteraction(`visit message page for ${JSON.stringify(subject)}`, () =>
    world.page.goto(appUrl(world.baseUrl, `/admin/messages/${message.messageId}`))
  );
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

  await browserInteraction(`visit member club home for ${clubName}`, () =>
    world.page.goto(appUrl(world.baseUrl, clubHomePath(club.clubId)))
  );
  await waitForProjectedVisible(
    world,
    world.page.locator(`#member-club-home[data-club-id=${cssString(club.clubId)}]`),
    `member club home for ${clubName}`,
    { expect, timeoutMs }
  );
}

async function openMemberMessage(world, subject, { expect = playwrightExpect, timeoutMs } = {}) {
  ensureState(world);

  const message = world.messages[subject];
  assert.ok(message, `Expected message ${JSON.stringify(subject)} to have been sent`);
  assert.ok(message.clubId, `Expected message ${JSON.stringify(subject)} to have a club id`);

  await browserInteraction(`visit member message page for ${JSON.stringify(subject)}`, () =>
    world.page.goto(appUrl(world.baseUrl, memberMessagePath(message)))
  );
  await waitForProjectedVisible(
    world,
    world.page.getByRole("heading", { name: subject }),
    `member message heading for ${JSON.stringify(subject)}`,
    { expect, timeoutMs }
  );
}

async function openDeliveriesOverview(world, { expect = playwrightExpect, timeoutMs } = {}) {
  await browserInteraction("visit /admin/deliveries", () =>
    world.page.goto(appUrl(world.baseUrl, "/admin/deliveries"))
  );
  await waitForProjectedVisible(
    world,
    world.page.getByRole("heading", { name: "Deliveries" }),
    "deliveries overview heading",
    { expect, timeoutMs }
  );
}

async function createClub(world, clubName, { expect = playwrightExpect } = {}) {
  ensureState(world);

  await visitClubsIndex(world);

  const clubRows = rowsByData(world.page, "club-row", "data-club-name", clubName);
  const previousClubIds = await rowAttributeValues(clubRows, "data-club-id");

  await browserInteraction(`submit club creation form for ${clubName}`, async () => {
    await world.page.getByLabel("Club name").fill(clubName);
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

  world.clubs[clubName] = { clubId, name: clubName };

  return world;
}

async function createPeople(world, names, { expect = playwrightExpect } = {}) {
  ensureState(world);

  await openClub(world, kootenayClubName, { expect });

  for (const name of names) {
    await createPersonOnCurrentClubPage(world, name, { expect });
  }

  return world;
}

async function createPerson(world, name, clubName = kootenayClubName, { email, expect = playwrightExpect } = {}) {
  ensureState(world);

  await openClub(world, clubName, { expect });
  await createPersonOnCurrentClubPage(world, name, { email, expect });

  return world;
}

async function createPersonOnCurrentClubPage(world, name, { email = emailFor(name), expect = playwrightExpect } = {}) {
  const personRows = rowsByData(world.page, "person-row", "data-person-name", name);
  const previousPersonIds = await rowAttributeValues(personRows, "data-person-id");

  await browserInteraction(`submit person creation form for ${name}`, async () => {
    await world.page.getByLabel("Person name").fill(name);
    await world.page.getByLabel("Person email").fill(email);
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

  world.people[name] = { email, name, personId };
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
  const sender = world.people[senderName];
  assert.ok(sender, `Expected ${senderName} to have been created before sending a message`);

  await openMemberClubHome(world, kootenayClubName, { expect });

  const messageRows = rowsByData(world.page, "club-message-row", "data-message-subject", subject);
  const previousMessageIds = await rowAttributeValues(messageRows, "data-message-id");
  const mailboxEmailsBeforeSend = await testMailboxEmails(world);

  await browserInteraction(`submit member message form for ${JSON.stringify(subject)}`, async () => {
    await world.page.getByLabel("Message sender").selectOption(sender.personId);
    await world.page.getByLabel("Message subject").fill(subject);
    await world.page.getByLabel("Message body").fill(body);
    await world.page.getByRole("button", { name: "Send club message" }).click();
  });
  await waitForProjectedCount(
    world,
    messageRows,
    previousMessageIds.length + 1,
    `new member club message row for ${JSON.stringify(subject)}`,
    { expect }
  );

  const messageId = await newRowAttributeValue(
    messageRows,
    "data-message-id",
    previousMessageIds,
    `member club message row for ${subject}`
  );
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

  return world;
}

async function assertMemberMessageAddressedTo(
  world,
  expectedNames,
  subject = world.lastMessageSubject,
  { expect = playwrightExpect } = {}
) {
  await openMemberMessage(world, subject, { expect });

  const rows = allRows(world.page, "member-receipts", "member-receipt");
  await waitForProjectedCount(
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
    "Expected addressed members to be asserted before checking delivery records"
  );

  const rows = allRows(world.page, "delivery-records", "delivery-record");
  await waitForProjectedCount(
    world,
    rows,
    expectedIds.length,
    `delivery records for ${JSON.stringify(world.lastMessageSubject)}`,
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
    "Expected delivery records to be asserted before checking email-provider delivery"
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

async function assertEachAddressedMemberReceivedEmailInTestMailbox(world) {
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

    const matchingEmail = newEmails.find(
      (email) =>
        email.subject === subject &&
        email.text_body === message.body &&
        email.to.some((recipient) => recipient.includes(person.email))
    );

    assertFinalBrowserState(`test mailbox email for ${recipientName}`, () =>
      assert.ok(
        matchingEmail,
        `Expected a mailbox email for ${recipientName} <${person.email}> with subject ${JSON.stringify(
          subject
        )}; saw ${JSON.stringify(newEmails.map(mailboxEmailSummary))}`
      )
    );
  }

  return world;
}

async function assertEveryAddressedMemberReceiptStatus(
  world,
  subject,
  expectedLabel,
  { expect = playwrightExpect } = {}
) {
  ensureState(world);

  const addressedMemberNames = world.addressedMemberNames || [];
  assert.ok(
    addressedMemberNames.length > 0,
    "Expected addressed members to be asserted before checking every member receipt status"
  );

  await openMemberMessage(world, subject, { expect });

  for (const recipientName of addressedMemberNames) {
    await assertMemberReceiptStatusOnCurrentPage(world, recipientName, subject, expectedLabel, { expect });
  }

  return world;
}

async function assertMemberReceiptStatus(
  world,
  recipientName,
  subject,
  expectedLabel,
  { expect = playwrightExpect } = {}
) {
  await openMemberMessage(world, subject, { expect });
  await assertMemberReceiptStatusOnCurrentPage(world, recipientName, subject, expectedLabel, { expect });

  return world;
}

async function assertMemberReceiptStatusOnCurrentPage(
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
    `${recipientName}'s member-facing receipt row for ${JSON.stringify(subject)}`,
    { expect }
  );
  await waitForProjectedText(
    world,
    row.locator("[data-testid=\"receipt-status\"]"),
    expectedLabel,
    `${recipientName}'s member-facing receipt status label for ${JSON.stringify(subject)}`,
    { expect }
  );

  const expectedIcon = memberReceiptIconForLabel(expectedLabel);
  const icon = row.locator("[data-testid=\"receipt-status-icon\"]");
  await waitForProjectedVisible(
    world,
    icon,
    `${recipientName}'s member-facing receipt status icon for ${JSON.stringify(subject)}`,
    { expect }
  );

  const actualIcon = await icon.getAttribute("data-icon-name");
  assertFinalBrowserState(`${recipientName}'s member-facing receipt icon for ${JSON.stringify(subject)}`, () =>
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
    `${recipientName}'s receipt status for ${JSON.stringify(subject)}`,
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
    `${recipientName}'s operator delivery row for ${JSON.stringify(subject)}`,
    { expect }
  );
  await waitForProjectedText(
    world,
    row.locator("[data-test-id=\"delivery-status\"]"),
    expectedStatus,
    `${recipientName}'s operator delivery status for ${JSON.stringify(subject)}`,
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
    "Expected an operator delivery status assertion before checking its reason"
  );
  assert.equal(
    currentDelivery.recipientName,
    recipientName,
    `Expected current operator delivery to belong to ${recipientName}`
  );

  await openDeliveriesOverview(world, { expect });

  const row = operatorDeliveryRow(world, recipientName, currentDelivery.subject);
  await waitForProjectedVisible(
    world,
    row,
    `${recipientName}'s operator delivery row for ${JSON.stringify(currentDelivery.subject)}`,
    { expect }
  );
  await waitForProjectedText(
    world,
    row.locator("[data-test-id=\"delivery-reason\"]"),
    expectedReason,
    `${recipientName}'s operator delivery reason for ${JSON.stringify(currentDelivery.subject)}`,
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
      throw new Error(`Unsupported browser receipt projection status event: ${eventType}`);
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
      throw new Error(`Unsupported member-facing receipt label: ${label}`);
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
      await openMessage(world, subject, { expect, timeoutMs: assertionTimeoutMs });

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
        `${recipientName}'s projected receipt status for ${JSON.stringify(subject)}`,
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
    `Projection timing timeout: timed out after ${timeoutMs}ms waiting for projected receipt status: ` +
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
    `${recipientName}'s delivery record for ${JSON.stringify(subject)}`,
    { expect }
  );

  const deliveryId = await row.getAttribute("data-delivery-id");
  assert.ok(
    deliveryId,
    `Expected delivery record for ${recipientName} and ${JSON.stringify(subject)} to expose data-delivery-id`
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

function mailboxEmailSummary(email) {
  return {
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

async function rowDatasetValues(rows, datasetName) {
  return rows.evaluateAll((elements, key) => elements.map((element) => element.dataset[key]), datasetName);
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
  assertEveryAddressedMemberReceiptStatus,
  assertEachAddressedMemberHasSeparateDeliveryRecord,
  assertEachAddressedMemberReceivedEmailInTestMailbox,
  assertEachDeliverySentThroughEmailProvider,
  assertLastMessageAddressedTo,
  assertLastMessageNotAddressedTo,
  assertMemberMessageAddressedTo,
  assertMemberMessageNotAddressedTo,
  assertMemberReceiptStatus,
  assertMemberSeesMessageInClub,
  assertOperatorDeliveryReason,
  assertOperatorDeliveryStatus,
  assertReceiptStatus,
  createClub,
  createPeople,
  createPerson,
  cssString,
  deliveryForRecipient,
  emailFor,
  ensureState,
  kootenayClubName,
  memberReceiptIconForLabel,
  memberReceiptStatusForEventType,
  nelsonClubName,
  openMemberClubHome,
  openMemberMessage,
  postmarkPayloadForStatus,
  postPostmarkWebhook,
  projectionPollIntervalMs,
  projectionTimeoutMs,
  reportRecipientEmailStatus,
  rowAttributeValues,
  openDeliveriesOverview,
  openClub,
  openMessage,
  sendMemberMessageToKootenayMembers,
  sendMessageToKootenayMembers,
  testMailboxEmails,
  visitClubsIndex,
  waitForMailboxEmails
};
