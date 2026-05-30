const assert = require("assert");
const { Given, When, Then } = require("@cucumber/cucumber");
const { expect } = require("@playwright/test");

Given("Kootenay Mountaineering Club is a club", async function () {
  await createClub(this, "Kootenay Mountaineering Club");
});

Given("Nelson Paddling Club is a club", async function () {
  await createClub(this, "Nelson Paddling Club");
});

Given("Alice, Bob, and Carol are people", async function () {
  await createPeople(this, ["Alice", "Bob", "Carol"]);
});

Given("Pat is a person", async function () {
  await createPeople(this, ["Pat"]);
});

Given(
  "Alice, Bob, and Carol are members of Kootenay Mountaineering Club",
  async function () {
    await addMembers(this, ["Alice", "Bob", "Carol"], "Kootenay Mountaineering Club");
  }
);

Given("Pat is a member of Nelson Paddling Club", async function () {
  await addMembers(this, ["Pat"], "Nelson Paddling Club");
});

When(
  /^(.+) sends the message "([^"]+)" to Kootenay Mountaineering Club members$/,
  async function (senderName, subject) {
    await sendClubMessage(this, senderName, subject, "Bring route ideas.");
  }
);

Given(
  /^(.+) has sent the message "([^"]+)" to Kootenay Mountaineering Club members$/,
  async function (senderName, subject) {
    await sendClubMessage(this, senderName, subject, "Bring route ideas.");
  }
);

When(
  /^(.+)'s email for "([^"]+)" is reported as delivered$/,
  async function (recipientName, subject) {
    await reportDeliveryStatus(this, recipientName, subject, "Delivery");
  }
);

Given(
  /^(.+)'s email for "([^"]+)" has been reported as delivered$/,
  async function (recipientName, subject) {
    await reportDeliveryStatus(this, recipientName, subject, "Delivery");
  }
);

When(
  /^(.+)'s email for "([^"]+)" is reported as delayed because "([^"]+)"$/,
  async function (recipientName, subject, reason) {
    await reportDeliveryStatus(this, recipientName, subject, "Bounce", {
      Type: "Transient",
      Details: reason
    });
  }
);

When(
  /^(.+)'s email for "([^"]+)" is reported as bounced because "([^"]+)"$/,
  async function (recipientName, subject, reason) {
    await reportDeliveryStatus(this, recipientName, subject, "Bounce", {
      Type: "HardBounce",
      Description: reason
    });
  }
);

When(
  /^(.+)'s email for "([^"]+)" is reported as a spam complaint because "([^"]+)"$/,
  async function (recipientName, subject, reason) {
    await reportDeliveryStatus(this, recipientName, subject, "SpamComplaint", {
      Details: reason
    });
  }
);

When(/^(.+) opens the email for "([^"]+)"$/, async function (recipientName, subject) {
  await reportDeliveryStatus(this, recipientName, subject, "Open");
});

Then("the message should be addressed to Alice, Bob, and Carol", async function () {
  const expectedNames = ["Alice", "Bob", "Carol"];

  for (const name of expectedNames) {
    await expect(addressedRecipientRow(this.page, name)).toBeVisible();
  }

  this.addressedMemberNames = expectedNames;
});

Then("the message should not be addressed to {word}", async function (personName) {
  await expect(addressedRecipientRow(this.page, personName)).toHaveCount(0);
});

Then("each addressed member should have a separate delivery record", async function () {
  const deliveryIds = [];

  for (const name of this.addressedMemberNames) {
    const row = deliveryRecordRow(this.page, name);
    await expect(row).toBeVisible();
    deliveryIds.push(await row.getAttribute("data-delivery-id"));
  }

  assert.strictEqual(deliveryIds.length, this.addressedMemberNames.length);
  assert.deepStrictEqual(new Set(deliveryIds).size, deliveryIds.length);
});

Then("each delivery should be sent through the email provider", async function () {
  for (const name of this.addressedMemberNames) {
    const row = deliveryRecordRow(this.page, name);
    await expect(row).toContainText("email");
    await expect(row.getByTestId("delivery-status")).toHaveText("sent");
  }
});

Then(
  /^(.+)'s receipt status for "([^"]+)" should be "([^"]+)"$/,
  async function (recipientName, subject, expectedStatus) {
    await openMessage(this, subject);
    await expect(receiptStatus(this.page, normalizePersonName(recipientName))).toHaveText(
      expectedStatus
    );
  }
);

async function createClub(world, name) {
  const page = world.page;
  await page.goto(`${world.baseUrl}/clubs`);
  await expect(page.locator("#clubs-index")).toBeVisible();
  await waitForLiveView(page);

  const beforeIds = new Set(
    await rowIdsForName(page, "club-row", "data-club-name", name, "data-club-id")
  );

  await page.getByLabel("Club name").fill(name);
  await submitForm(page, "#new-club-form");

  const clubId = await waitForNewRowId(
    page,
    "club-row",
    "data-club-name",
    name,
    "data-club-id",
    beforeIds,
    async () => {
      await page.reload();
      await waitForLiveView(page);
    }
  );
  world.clubs[name] = clubId;
}

async function createPeople(world, names) {
  const clubId = firstClubId(world);
  await openClub(world, clubId);

  for (const name of names) {
    await createPerson(world, name);
  }
}

async function createPerson(world, name) {
  const page = world.page;
  const email = emailFor(world, name);
  const beforeIds = new Set(
    await rowIdsForName(page, "person-row", "data-person-name", name, "data-person-id")
  );

  await page.getByLabel("Person name").fill(name);
  await page.getByLabel("Person email").fill(email);
  await submitForm(page, "#new-person-form");

  const personId = await waitForNewRowId(
    page,
    "person-row",
    "data-person-name",
    name,
    "data-person-id",
    beforeIds,
    async () => {
      await page.reload();
      await waitForLiveView(page);
    }
  );
  const row = rowByAttribute(page, "person-row", "data-person-id", personId);
  await expect(row).toContainText(email);

  world.people[name] = { id: personId, email };
}

async function addMembers(world, names, clubName) {
  await openClub(world, clubIdFor(world, clubName));

  for (const name of names) {
    await addMember(world, name);
  }
}

async function addMember(world, name) {
  const page = world.page;
  const person = personFor(world, name);
  const row = rowByAttribute(page, "member-row", "data-member-id", person.id);

  if ((await row.count()) > 0) {
    return;
  }

  await page.locator("#member-person-select").selectOption(person.id);
  await submitForm(page, "#add-member-form");

  await waitForVisible(row, async () => {
    await page.reload();
    await waitForLiveView(page);
  });
}

async function sendClubMessage(world, senderName, subject, body) {
  const page = world.page;
  const clubId = clubIdFor(world, "Kootenay Mountaineering Club");
  const sender = personFor(world, normalizePersonName(senderName));

  await openClub(world, clubId);

  const beforeIds = new Set(
    await rowIdsForName(page, "message-row", "data-message-subject", subject, "data-message-id")
  );

  await page.locator("#message-sender-select").selectOption(sender.id);
  await page.getByLabel("Message subject").fill(subject);
  await page.getByLabel("Message body").fill(body);
  await submitForm(page, "#new-message-form");

  const messageId = await waitForNewRowId(
    page,
    "message-row",
    "data-message-subject",
    subject,
    "data-message-id",
    beforeIds,
    async () => {
      await page.reload();
      await waitForLiveView(page);
    }
  );

  world.messages[subject] = { id: messageId, clubId, subject };

  await openMessage(world, subject);
}

async function reportDeliveryStatus(world, recipientName, subject, recordType, overrides = {}) {
  const message = messageFor(world, subject);
  await openMessage(world, subject);

  const recipient = normalizePersonName(recipientName);
  const deliveryId = await deliveryRecordRow(world.page, recipient).getAttribute("data-delivery-id");

  assert.ok(deliveryId, `Expected a delivery id for ${recipient} and ${subject}`);

  const response = await world.page.request.post(`${world.baseUrl}/webhooks/postmark`, {
    data: {
      RecordType: recordType,
      Metadata: {
        message_id: message.id,
        delivery_id: deliveryId
      },
      ...overrides
    }
  });

  assert.strictEqual(
    response.status(),
    202,
    `Expected Postmark webhook to accept ${recordType}; response was ${response.status()} ${await response.text()}`
  );

  await openMessage(world, subject);
}

async function openClub(world, clubId) {
  await world.page.goto(`${world.baseUrl}/clubs/${clubId}`);
  await expect(world.page.locator("#club-show")).toBeVisible();
  await waitForLiveView(world.page);
}

async function openMessage(world, subject) {
  const message = messageFor(world, subject);
  await world.page.goto(`${world.baseUrl}/messages/${message.id}`);
  await expect(world.page.locator("#message-show")).toContainText(subject);
  await waitForLiveView(world.page);
}

async function rowIdsForName(page, testId, nameAttribute, name, idAttribute) {
  return page.getByTestId(testId).evaluateAll(
    (rows, args) =>
      rows
        .filter((row) => row.getAttribute(args.nameAttribute) === args.name)
        .map((row) => row.getAttribute(args.idAttribute))
        .filter(Boolean),
    { nameAttribute, name, idAttribute }
  );
}

async function waitForNewRowId(
  page,
  testId,
  nameAttribute,
  name,
  idAttribute,
  beforeIds,
  refresh
) {
  const deadline = Date.now() + 20000;
  let lastRefreshAt = Date.now();

  while (Date.now() < deadline) {
    const rows = rowByAttribute(page, testId, nameAttribute, name);
    const rowCount = await rows.count();
    const ids = [];

    for (let index = 0; index < rowCount; index++) {
      const id = await rows.nth(index).getAttribute(idAttribute);

      if (id) {
        ids.push(id);
      }
    }

    const id = ids.find((candidate) => !beforeIds.has(candidate));

    if (id) {
      return id;
    }

    if (refresh && Date.now() - lastRefreshAt > 1000) {
      lastRefreshAt = Date.now();
      await refresh();
    } else {
      await page.waitForTimeout(250);
    }
  }

  throw new Error(`Expected a new ${testId} row named ${name}`);
}

async function waitForVisible(locator, refresh) {
  const deadline = Date.now() + 20000;
  let lastRefreshAt = Date.now();

  while (Date.now() < deadline) {
    if ((await locator.count()) > 0 && (await locator.first().isVisible())) {
      return;
    }

    if (refresh && Date.now() - lastRefreshAt > 1000) {
      lastRefreshAt = Date.now();
      await refresh();
    } else {
      await locator.page().waitForTimeout(250);
    }
  }

  await expect(locator).toBeVisible();
}

async function waitForLiveView(page) {
  await page.waitForFunction(
    () => window.liveSocket && typeof window.liveSocket.isConnected === "function" && window.liveSocket.isConnected(),
    null,
    { timeout: 10000 }
  );
}

async function submitForm(page, selector) {
  await page.locator(selector).evaluate((form) => form.requestSubmit());
}

function rowByAttribute(page, testId, attribute, value) {
  return page.locator(`[data-testid="${testId}"][${attribute}="${cssString(value)}"]`);
}

function addressedRecipientRow(page, name) {
  return page.locator(
    `#addressed-recipients [data-testid="addressed-recipient"][data-recipient-name="${cssString(normalizePersonName(name))}"]`
  );
}

function deliveryRecordRow(page, name) {
  return page.locator(
    `#delivery-records [data-testid="delivery-record"][data-recipient-name="${cssString(normalizePersonName(name))}"]`
  );
}

function receiptStatus(page, name) {
  return page
    .locator(
      `#member-receipts [data-testid="member-receipt"][data-recipient-name="${cssString(normalizePersonName(name))}"]`
    )
    .getByTestId("receipt-status");
}

function clubIdFor(world, name) {
  const clubId = world.clubs[name];
  assert.ok(clubId, `Expected club ${name} to have been created`);
  return clubId;
}

function firstClubId(world) {
  const clubId = Object.values(world.clubs)[0];
  assert.ok(clubId, "Expected at least one club to have been created");
  return clubId;
}

function personFor(world, name) {
  const person = world.people[name];
  assert.ok(person, `Expected person ${name} to have been created`);
  return person;
}

function messageFor(world, subject) {
  const message = world.messages[subject];
  assert.ok(message, `Expected message ${subject} to have been sent`);
  return message;
}

function emailFor(world, name) {
  const normalizedName = name.toLowerCase().replace(/[^a-z0-9]+/g, ".").replace(/^\.+|\.+$/g, "");
  return `${normalizedName}+${world.scenarioId}@example.test`;
}

function normalizePersonName(name) {
  return name.replace(/'s$/, "");
}

function cssString(value) {
  return String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}
