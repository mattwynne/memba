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
  await browserInteraction("visit /clubs", () => world.page.goto(appUrl(world.baseUrl, "/clubs")));
}

async function openClub(world, clubName, { expect = playwrightExpect, timeoutMs } = {}) {
  ensureState(world);

  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to have been created before opening it`);

  await browserInteraction(`visit club page for ${clubName}`, () =>
    world.page.goto(appUrl(world.baseUrl, `/clubs/${club.clubId}`))
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
    world.page.goto(appUrl(world.baseUrl, `/messages/${message.messageId}`))
  );
  await waitForProjectedVisible(
    world,
    world.page.getByRole("heading", { name: subject }),
    `message heading for ${JSON.stringify(subject)}`,
    { expect, timeoutMs }
  );
}

async function openDeliveriesOverview(world, { expect = playwrightExpect, timeoutMs } = {}) {
  await browserInteraction("visit /deliveries", () =>
    world.page.goto(appUrl(world.baseUrl, "/deliveries"))
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

async function createPersonOnCurrentClubPage(world, name, { expect = playwrightExpect } = {}) {
  const personRows = rowsByData(world.page, "person-row", "data-person-name", name);
  const previousPersonIds = await rowAttributeValues(personRows, "data-person-id");
  const email = emailFor(name);

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
  world.lastMessageSubject = subject;

  await openMessage(world, subject, { expect });

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

  const delivery = await deliveryForRecipient(world, recipientName, subject, { expect });
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

  const key = `${subject}:${recipientName}`;
  world.reportedDeliveryStatuses[key] = {
    eventType,
    payload,
    reason,
    recipientName,
    subject
  };

  return world;
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
  assertEachAddressedMemberHasSeparateDeliveryRecord,
  assertEachDeliverySentThroughEmailProvider,
  assertLastMessageAddressedTo,
  assertLastMessageNotAddressedTo,
  assertOperatorDeliveryReason,
  assertOperatorDeliveryStatus,
  assertReceiptStatus,
  createClub,
  createPeople,
  cssString,
  deliveryForRecipient,
  emailFor,
  ensureState,
  kootenayClubName,
  memberReceiptStatusForEventType,
  nelsonClubName,
  postmarkPayloadForStatus,
  postPostmarkWebhook,
  projectionPollIntervalMs,
  projectionTimeoutMs,
  reportRecipientEmailStatus,
  rowAttributeValues,
  openDeliveriesOverview,
  openClub,
  openMessage,
  sendMessageToKootenayMembers,
  visitClubsIndex
};
