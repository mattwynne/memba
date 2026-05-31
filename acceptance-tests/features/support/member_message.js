const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { expect: playwrightExpect } = require("@playwright/test");

const kootenayClubName = "Kootenay Mountaineering Club";
const nelsonClubName = "Nelson Paddling Club";

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
  await world.page.goto(appUrl(world.baseUrl, "/clubs"));
}

async function openClub(world, clubName, { expect = playwrightExpect } = {}) {
  ensureState(world);

  const club = world.clubs[clubName];
  assert.ok(club, `Expected ${clubName} to have been created before opening it`);

  await world.page.goto(appUrl(world.baseUrl, `/clubs/${club.clubId}`));
  await expect(world.page.getByRole("heading", { name: clubName })).toBeVisible();
}

async function openMessage(world, subject, { expect = playwrightExpect } = {}) {
  ensureState(world);

  const message = world.messages[subject];
  assert.ok(message, `Expected message ${JSON.stringify(subject)} to have been sent`);

  await world.page.goto(appUrl(world.baseUrl, `/messages/${message.messageId}`));
  await expect(world.page.getByRole("heading", { name: subject })).toBeVisible();
}

async function createClub(world, clubName, { expect = playwrightExpect } = {}) {
  ensureState(world);

  await visitClubsIndex(world);

  const clubRows = rowsByData(world.page, "club-row", "data-club-name", clubName);
  const previousClubIds = await rowAttributeValues(clubRows, "data-club-id");

  await world.page.getByLabel("Club name").fill(clubName);
  await world.page.getByRole("button", { name: "Create club" }).click();
  await expect(clubRows).toHaveCount(previousClubIds.length + 1);

  const clubId = await newRowAttributeValue(
    clubRows,
    "data-club-id",
    previousClubIds,
    `club row for ${clubName}`
  );
  await expect(rowByData(world.page, "club-row", "data-club-id", clubId)).toBeVisible();

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

  await world.page.getByLabel("Person name").fill(name);
  await world.page.getByLabel("Person email").fill(email);
  await world.page.getByRole("button", { name: "Create person" }).click();
  await expect(personRows).toHaveCount(previousPersonIds.length + 1);

  const personId = await newRowAttributeValue(
    personRows,
    "data-person-id",
    previousPersonIds,
    `person row for ${name}`
  );
  await expect(rowByData(world.page, "person-row", "data-person-id", personId)).toBeVisible();

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

  await world.page.getByLabel("Person to add as member").selectOption(person.personId);
  await world.page.getByRole("button", { name: "Add member" }).click();
  await expect(memberRows).toHaveCount(previousMemberIds.length + 1);

  const memberId = await newRowAttributeValue(
    memberRows,
    "data-member-id",
    previousMemberIds,
    `member row for ${personName} in ${clubName}`
  );
  await expect(rowByData(world.page, "member-row", "data-member-id", memberId)).toBeVisible();

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

  await world.page.getByLabel("Message sender").selectOption(sender.personId);
  await world.page.getByLabel("Message subject").fill(subject);
  await world.page.getByLabel("Message body").fill(body);
  await world.page.getByRole("button", { name: "Send club message" }).click();
  await expect(messageRows).toHaveCount(previousMessageIds.length + 1);

  const messageId = await newRowAttributeValue(
    messageRows,
    "data-message-id",
    previousMessageIds,
    `message row for ${subject}`
  );
  await expect(rowByData(world.page, "message-row", "data-message-id", messageId)).toBeVisible();

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
  await expect(rows).toHaveCount(expectedNames.length);

  const actualNames = await rowDatasetValues(rows, "recipientName");
  assert.deepEqual(actualNames, expectedNames);

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
  assert.ok(
    !actualNames.includes(excludedName),
    `Expected addressed recipients not to include ${excludedName}; saw ${actualNames.join(", ")}`
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
  await expect(rows).toHaveCount(expectedIds.length);

  const recipientIds = await rowDatasetValues(rows, "recipientId");
  const deliveryIds = await rowDatasetValues(rows, "deliveryId");
  const recipientNames = await rowDatasetValues(rows, "recipientName");

  assert.deepEqual(recipientIds, expectedIds);
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
    await expect(row.getByText(/^email$/)).toBeVisible();
    await expect(row.locator("[data-testid=\"delivery-status\"]")).toHaveText("sent");
  }

  return world;
}

async function assertReceiptStatus(world, recipientName, subject, expectedStatus, { expect = playwrightExpect } = {}) {
  await openMessage(world, subject, { expect });

  const row = rowByData(world.page, "member-receipt", "data-recipient-name", recipientName);
  await expect(row).toBeVisible();
  await expect(row.locator("[data-testid=\"receipt-status\"]")).toHaveText(expectedStatus);

  return world;
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
  await expect(row).toBeVisible();

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

  const response = await request.post(appUrl(world.baseUrl, "/webhooks/postmark"), {
    data: payload,
    headers: {
      "content-type": "application/json"
    }
  });
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
  assert.deepEqual(
    [...new Set(values)],
    values,
    `Expected ${label} to be unique; saw ${values.join(", ")}`
  );
}

module.exports = {
  addMembers,
  appUrl,
  assertEachAddressedMemberHasSeparateDeliveryRecord,
  assertEachDeliverySentThroughEmailProvider,
  assertLastMessageAddressedTo,
  assertLastMessageNotAddressedTo,
  assertReceiptStatus,
  createClub,
  createPeople,
  cssString,
  deliveryForRecipient,
  emailFor,
  ensureState,
  kootenayClubName,
  nelsonClubName,
  postmarkPayloadForStatus,
  postPostmarkWebhook,
  reportRecipientEmailStatus,
  rowAttributeValues,
  openClub,
  openMessage,
  sendMessageToKootenayMembers,
  visitClubsIndex
};
