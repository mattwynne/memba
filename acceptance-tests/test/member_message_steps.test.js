const assert = require("node:assert/strict");
const test = require("node:test");

const {
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
  kootenayClubName,
  memberReceiptStatusForEventType,
  postmarkPayloadForStatus,
  postPostmarkWebhook,
  projectionPollIntervalMs,
  projectionTimeoutMs,
  reportRecipientEmailStatus,
  sendMessageToKootenayMembers
} = require("../features/support/member_message");

class FakeLocator {
  constructor(page, selector, options = {}) {
    this.page = page;
    this.selector = selector;
    this.kind = options.kind || "locator";
    this.value = options.value;
    this.attrs = options.attrs || {};
    this.text = options.text;
    this.rows = options.rows || null;
  }

  currentRows() {
    return this.rows || rowsForSelector(this.page.rows, this.selector);
  }

  async count() {
    return this.currentRows().length;
  }

  last() {
    const rows = this.currentRows();
    const row = rows[rows.length - 1] || { attrs: {}, text: undefined };

    return new FakeLocator(this.page, `${this.selector} >> last`, {
      attrs: row.attrs,
      kind: "row",
      text: row.text
    });
  }

  locator(selector) {
    const childText =
      selector.includes('data-test-id="delivery-reason"')
        ? this.attrs.deliveryReason
        : this.attrs.deliveryStatus || this.attrs.receiptStatus;

    return new FakeLocator(this.page, `${this.selector} ${selector}`, {
      kind: "child",
      value: selector,
      text: childText
    });
  }

  getByText(text) {
    return new FakeLocator(this.page, `${this.selector} text=${text}`, {
      kind: "text",
      value: text
    });
  }

  async getAttribute(attributeName) {
    return this.attrs[attributeName];
  }

  async evaluateAll(callback, key) {
    const elements = this.currentRows().map((row) => ({
      dataset: row.dataset,
      getAttribute(attributeName) {
        return row.attrs ? row.attrs[attributeName] : undefined;
      }
    }));

    return callback(elements, key);
  }
}

class FakePage {
  constructor() {
    this.actions = [];
    this.fields = {};
    this.rows = {
      clubs: [],
      people: [],
      members: [],
      messages: [],
      addressedRecipients: [],
      deliveryRecords: [],
      operatorDeliveries: [],
      memberReceipts: []
    };
  }

  async goto(url) {
    this.actions.push(["goto", url]);
  }

  getByLabel(name) {
    return {
      fill: async (value) => {
        this.fields[name] = value;
        this.actions.push(["fill", name, value]);
      },
      selectOption: async (value) => {
        this.fields[name] = value;
        this.actions.push(["select", name, value]);
      }
    };
  }

  getByRole(role, options) {
    return {
      role,
      options,
      click: async () => {
        this.actions.push(["click", role, options]);
        this.applyClickSideEffect(options.name);
      }
    };
  }

  locator(selector) {
    return new FakeLocator(this, selector);
  }

  applyClickSideEffect(name) {
    if (name === "Create club") {
      const clubName = this.fields["Club name"];
      const clubId = idFor("club", clubName, this.rows.clubs.length + 1);
      this.rows.clubs.push(rowWithAttrs({
        "data-club-id": clubId,
        "data-club-name": clubName
      }));
    }

    if (name === "Create person") {
      const personName = this.fields["Person name"];
      const personId = idFor("person", personName, this.rows.people.length + 1);
      this.rows.people.push(rowWithAttrs({
        "data-person-id": personId,
        "data-person-name": personName
      }));
    }

    if (name === "Add selected person as member") {
      const personId = this.fields["Person to add as member"];
      const personRow = this.rows.people.find((row) => row.attrs["data-person-id"] === personId);
      const personName = personRow.attrs["data-person-name"];
      const memberId = idFor("member", personName, this.rows.members.length + 1);

      this.rows.members.push(rowWithAttrs({
        "data-member-id": memberId,
        "data-member-name": personName
      }));
    }

    if (name === "Send club message") {
      const subject = this.fields["Message subject"];
      const messageId = idFor("message", subject, this.rows.messages.length + 1);

      this.rows.messages.push(rowWithAttrs({
        "data-message-id": messageId,
        "data-message-subject": subject
      }));
    }
  }
}

class FakeResponse {
  constructor(status, body = "") {
    this.responseStatus = status;
    this.body = body;
  }

  status() {
    return this.responseStatus;
  }

  async text() {
    return typeof this.body === "string" ? this.body : JSON.stringify(this.body);
  }
}

class FakeRequestContext {
  constructor(response = new FakeResponse(202, { status: "accepted" })) {
    this.posts = [];
    this.response = response;
  }

  async post(url, options) {
    this.posts.push({ options, url });

    return this.response;
  }
}

function rowsForSelector(rows, selector) {
  if (selector.includes('data-testid="club-row"')) return filterRows(rows.clubs, selector);
  if (selector.includes('data-testid="person-row"')) return filterRows(rows.people, selector);
  if (selector.includes('data-testid="member-row"')) return filterRows(rows.members, selector);
  if (selector.includes('data-testid="message-row"')) return filterRows(rows.messages, selector);
  if (selector.includes("#addressed-recipients")) return rows.addressedRecipients;
  if (selector.includes("#delivery-records")) return rows.deliveryRecords;
  if (selector.includes("#member-receipts")) return rows.memberReceipts;
  if (selector.includes('data-testid="delivery-record"')) return filterRows(rows.deliveryRecords, selector);
  if (selector.includes('data-test-id^="delivery-row-"')) {
    return filterRows(rows.operatorDeliveries, selector);
  }
  if (selector.includes('data-testid="member-receipt"')) return filterRows(rows.memberReceipts, selector);

  return [];
}

function filterRows(rows, selector) {
  return rows.filter((row) => {
    for (const [attributeName, value] of Object.entries(row.attrs || {})) {
      if (selector.includes(`[${attributeName}=`) && !selector.includes(`[${attributeName}="${value}"]`)) {
        return false;
      }
    }

    return true;
  });
}

function idFor(prefix, value, count) {
  return `${prefix}-${String(value).toLowerCase().replace(/[^a-z0-9]+/g, "-")}-${count}`;
}

function rowWithAttrs(attrs) {
  const dataset = {};

  for (const [name, value] of Object.entries(attrs)) {
    if (name.startsWith("data-")) {
      dataset[name.slice(5).replace(/-([a-z])/g, (_match, letter) => letter.toUpperCase())] = value;
    }
  }

  return { attrs, dataset };
}

function fakeExpect(expectations) {
  return (target) => ({
    async toBeVisible(options) {
      expectations.push(["visible", target.selector || target, options]);
    },
    async toHaveCount(count, options) {
      expectations.push(["count", target.selector, count, options]);
    },
    async toHaveText(text, options) {
      expectations.push(["text", target.selector, text, options]);
    }
  });
}

function flakyReceiptTextExpect(expectations, failuresBeforeSuccess) {
  let receiptTextAttempts = 0;

  return (target) => ({
    async toBeVisible(options) {
      expectations.push(["visible", target.selector || target, options]);
    },
    async toHaveCount(count, options) {
      expectations.push(["count", target.selector, count, options]);
    },
    async toHaveText(text, options) {
      expectations.push(["text", target.selector, text, options]);

      if (String(target.selector).includes('data-testid="receipt-status"')) {
        receiptTextAttempts += 1;

        if (receiptTextAttempts <= failuresBeforeSuccess) {
          throw new Error(`projection not ready on attempt ${receiptTextAttempts}`);
        }
      }
    }
  });
}

function worldWithPage(page = new FakePage()) {
  return {
    baseUrl: "http://127.0.0.1:4444",
    page
  };
}

test("member-message route URL and generated emails match the browser app surface", () => {
  assert.equal(
    appUrl("http://127.0.0.1:4444", "/admin/clubs"),
    "http://127.0.0.1:4444/admin/clubs"
  );
  assert.equal(
    appUrl("http://127.0.0.1:4444/", "/admin/messages/message-1"),
    "http://127.0.0.1:4444/admin/messages/message-1"
  );
  assert.equal(emailFor("Alice"), "alice@example.test");
  assert.equal(emailFor("Kootenay Mountaineering Club"), "kootenay.mountaineering.club@example.test");
  assert.equal(cssString('Bob "The Sender"'), '"Bob \\"The Sender\\""');
});

test("creating a club drives /admin/clubs and stores the generated club id from the UI", async () => {
  const page = new FakePage();
  page.rows.clubs.push(rowWithAttrs({
    "data-club-id": "club-existing-1",
    "data-club-name": kootenayClubName
  }));
  const expectations = [];
  const world = worldWithPage(page);

  await createClub(world, kootenayClubName, { expect: fakeExpect(expectations) });

  assert.deepEqual(page.actions, [
    ["goto", "http://127.0.0.1:4444/admin/clubs"],
    ["fill", "Club name", kootenayClubName],
    ["click", "button", { name: "Create club" }]
  ]);
  assert.deepEqual(world.clubs[kootenayClubName], {
    clubId: "club-kootenay-mountaineering-club-2",
    name: kootenayClubName
  });
  assert.deepEqual(expectations.map((expectation) => expectation[0]), ["count", "visible"]);
});

test("browser command projection waits use bounded Playwright assertion timeouts", async () => {
  const page = new FakePage();
  const expectations = [];
  const world = worldWithPage(page);
  world.projectionTimeoutMs = 1234;

  assert.equal(projectionTimeoutMs(world), 1234);

  await createClub(world, kootenayClubName, { expect: fakeExpect(expectations) });

  assert.ok(
    expectations.some(
      (expectation) =>
        expectation[0] === "count" &&
        expectation[1].includes('data-testid="club-row"') &&
        expectation[3].timeout === 1234
    )
  );
  assert.ok(
    expectations.some(
      (expectation) =>
        expectation[0] === "visible" &&
        expectation[1].includes('data-testid="club-row"') &&
        expectation[2].timeout === 1234
    )
  );
});

test("browser interaction failures are reported separately from projection waits", async () => {
  const page = new FakePage();
  page.goto = async (url) => {
    page.actions.push(["goto", url]);
    throw new Error("browser context closed");
  };
  const world = worldWithPage(page);

  await assert.rejects(
    () => createClub(world, kootenayClubName, { expect: fakeExpect([]) }),
    /Browser interaction failed: visit \/admin\/clubs\.\nCause: browser context closed/
  );
});

test("creating people and members uses accessible form labels and keeps browser ids in scenario state", async () => {
  const page = new FakePage();
  const expectations = [];
  const world = worldWithPage(page);
  world.clubs = { [kootenayClubName]: { clubId: "club-1", name: kootenayClubName } };

  await createPeople(world, ["Alice", "Bob"], { expect: fakeExpect(expectations) });
  await addMembers(world, ["Alice", "Bob"], kootenayClubName, { expect: fakeExpect(expectations) });

  assert.deepEqual(world.people.Alice, {
    email: "alice@example.test",
    name: "Alice",
    personId: "person-alice-1"
  });
  assert.deepEqual(world.memberships[`${kootenayClubName}:Bob`], {
    clubName: kootenayClubName,
    memberId: "member-bob-2",
    personName: "Bob"
  });
  assert.ok(
    page.actions.some(
      (action) =>
        action[0] === "select" &&
        action[1] === "Person to add as member" &&
        action[2] === "person-alice-1"
    )
  );
  assert.ok(
    page.actions.some(
      (action) =>
        action[0] === "click" &&
        action[1] === "button" &&
        action[2].name === "Add selected person as member"
    )
  );
});

test("sending a Kootenay member message drives the club form and opens the real message route", async () => {
  const page = new FakePage();
  const expectations = [];
  const world = worldWithPage(page);
  world.clubs = { [kootenayClubName]: { clubId: "club-1", name: kootenayClubName } };
  world.people = { Alice: { personId: "person-alice-1" } };

  await sendMessageToKootenayMembers(world, "Alice", "Trip planning night", {
    expect: fakeExpect(expectations)
  });

  assert.deepEqual(world.messages["Trip planning night"], {
    body: "Trip planning night details.",
    clubId: "club-1",
    messageId: "message-trip-planning-night-1",
    senderName: "Alice",
    subject: "Trip planning night"
  });
  assert.deepEqual(page.actions.slice(-5), [
    ["select", "Message sender", "person-alice-1"],
    ["fill", "Message subject", "Trip planning night"],
    ["fill", "Message body", "Trip planning night details."],
    ["click", "button", { name: "Send club message" }],
    ["goto", "http://127.0.0.1:4444/admin/messages/message-trip-planning-night-1"]
  ]);
});

test("message assertions read addressed recipients, delivery records, email channel, and receipts from UI rows", async () => {
  const page = new FakePage();
  page.rows.addressedRecipients.push(
    { dataset: { recipientName: "Alice", recipientId: "person-alice" } },
    { dataset: { recipientName: "Bob", recipientId: "person-bob" } },
    { dataset: { recipientName: "Carol", recipientId: "person-carol" } }
  );
  page.rows.deliveryRecords.push(
    {
      attrs: {
        "data-delivery-id": "delivery-alice",
        "data-recipient-id": "person-alice",
        "data-recipient-name": "Alice",
        deliveryStatus: "sent"
      },
      dataset: { deliveryId: "delivery-alice", recipientId: "person-alice", recipientName: "Alice" }
    },
    {
      attrs: {
        "data-delivery-id": "delivery-bob",
        "data-recipient-id": "person-bob",
        "data-recipient-name": "Bob",
        deliveryStatus: "sent"
      },
      dataset: { deliveryId: "delivery-bob", recipientId: "person-bob", recipientName: "Bob" }
    },
    {
      attrs: {
        "data-delivery-id": "delivery-carol",
        "data-recipient-id": "person-carol",
        "data-recipient-name": "Carol",
        deliveryStatus: "sent"
      },
      dataset: { deliveryId: "delivery-carol", recipientId: "person-carol", recipientName: "Carol" }
    }
  );
  page.rows.memberReceipts.push({
    attrs: { "data-recipient-name": "Bob", receiptStatus: "sent" },
    dataset: { recipientName: "Bob" }
  });
  const expectations = [];
  const world = worldWithPage(page);
  world.lastMessageSubject = "Trip planning night";
  world.messages = { "Trip planning night": { messageId: "message-1", subject: "Trip planning night" } };
  world.people = {
    Alice: { personId: "person-alice" },
    Bob: { personId: "person-bob" },
    Carol: { personId: "person-carol" },
    Pat: { personId: "person-pat" }
  };

  await assertLastMessageAddressedTo(world, ["Alice", "Bob", "Carol"], {
    expect: fakeExpect(expectations)
  });
  await assertLastMessageNotAddressedTo(world, "Pat", { expect: fakeExpect(expectations) });
  await assertEachAddressedMemberHasSeparateDeliveryRecord(world, { expect: fakeExpect(expectations) });
  await assertEachDeliverySentThroughEmailProvider(world, { expect: fakeExpect(expectations) });
  await assertReceiptStatus(world, "Bob", "Trip planning night", "sent", {
    expect: fakeExpect(expectations)
  });

  assert.deepEqual(world.deliveries["Trip planning night"].Bob, {
    deliveryId: "delivery-bob",
    recipientId: "person-bob",
    recipientName: "Bob"
  });
  assert.ok(expectations.some((expectation) => expectation[0] === "text" && expectation[2] === "sent"));
});

test("operator delivery assertions inspect the /admin/deliveries overview by message and recipient", async () => {
  const page = new FakePage();
  page.rows.operatorDeliveries.push(
    rowWithAttrs({
      "data-test-id": "delivery-row-delivery-other",
      "data-message-id": "message-2",
      "data-recipient-id": "person-bob",
      "data-recipient-name": "Bob",
      deliveryReason: "mailbox does not exist",
      deliveryStatus: "bounced"
    }),
    rowWithAttrs({
      "data-test-id": "delivery-row-delivery-bob",
      "data-message-id": "message-1",
      "data-recipient-id": "person-bob",
      "data-recipient-name": "Bob",
      deliveryReason: "recipient server is temporarily unavailable",
      deliveryStatus: "delayed"
    })
  );
  const expectations = [];
  const world = worldWithPage(page);
  world.messages = {
    "Avalanche bulletin": { messageId: "message-2", subject: "Avalanche bulletin" },
    "Trip planning night": { messageId: "message-1", subject: "Trip planning night" }
  };
  world.people = { Bob: { personId: "person-bob" } };

  await assertOperatorDeliveryStatus(world, "Bob", "Trip planning night", "delayed", {
    expect: fakeExpect(expectations)
  });
  await assertOperatorDeliveryReason(world, "Bob", "recipient server is temporarily unavailable", {
    expect: fakeExpect(expectations)
  });

  assert.deepEqual(
    page.actions.filter((action) => action[0] === "goto").map((action) => action[1]),
    [
      "http://127.0.0.1:4444/admin/deliveries",
      "http://127.0.0.1:4444/admin/deliveries"
    ]
  );
  assert.deepEqual(world.currentOperatorDelivery, {
    recipientName: "Bob",
    subject: "Trip planning night"
  });
  assert.ok(
    expectations.some(
      (expectation) =>
        expectation[0] === "text" &&
        expectation[1].includes('data-message-id="message-1"') &&
        expectation[1].includes('data-test-id="delivery-status"') &&
        expectation[2] === "delayed"
    )
  );
  assert.ok(
    expectations.some(
      (expectation) =>
        expectation[0] === "text" &&
        expectation[1].includes('data-message-id="message-1"') &&
        expectation[1].includes('data-test-id="delivery-reason"') &&
        expectation[2] === "recipient server is temporarily unavailable"
    )
  );
});

test("final assertion mismatches are reported separately from projection timing", async () => {
  const page = new FakePage();
  page.rows.addressedRecipients.push(
    { dataset: { recipientName: "Alice", recipientId: "person-alice" } },
    { dataset: { recipientName: "Bob", recipientId: "person-bob" } }
  );
  const world = worldWithPage(page);
  world.lastMessageSubject = "Trip planning night";
  world.messages = { "Trip planning night": { messageId: "message-1", subject: "Trip planning night" } };
  world.people = {
    Alice: { personId: "person-alice" },
    Bob: { personId: "person-bob" }
  };

  await assert.rejects(
    () =>
      assertLastMessageAddressedTo(world, ["Alice", "Carol"], {
        expect: fakeExpect([])
      }),
    /Assertion mismatch: addressed recipients for "Trip planning night"\.\nCause:/
  );
});

test("Postmark webhook payloads map member-facing status events onto the app endpoint shape", () => {
  const base = {
    deliveryId: "delivery-bob",
    messageId: "message-1",
    recipientEmail: "bob@example.test"
  };

  assert.deepEqual(
    redactGeneratedMessageId(postmarkPayloadForStatus({ ...base, eventType: "delivered" })),
    {
      MessageID: "<generated>",
      Metadata: { delivery_id: "delivery-bob", message_id: "message-1" },
      Recipient: "bob@example.test",
      RecordType: "Delivery"
    }
  );

  assert.deepEqual(redactGeneratedMessageId(postmarkPayloadForStatus({ ...base, eventType: "opened" })), {
    MessageID: "<generated>",
    Metadata: { delivery_id: "delivery-bob", message_id: "message-1" },
    Recipient: "bob@example.test",
    RecordType: "Open"
  });

  assert.deepEqual(
    redactGeneratedMessageId(
      postmarkPayloadForStatus({
        ...base,
        eventType: "delayed",
        reason: "recipient server is temporarily unavailable"
      })
    ),
    {
      Details: "recipient server is temporarily unavailable",
      MessageID: "<generated>",
      Metadata: { delivery_id: "delivery-bob", message_id: "message-1" },
      Recipient: "bob@example.test",
      RecordType: "Bounce",
      Type: "Transient"
    }
  );

  assert.deepEqual(
    redactGeneratedMessageId(
      postmarkPayloadForStatus({
        ...base,
        eventType: "bounced",
        reason: "mailbox does not exist"
      })
    ),
    {
      Description: "mailbox does not exist",
      MessageID: "<generated>",
      Metadata: { delivery_id: "delivery-bob", message_id: "message-1" },
      Recipient: "bob@example.test",
      RecordType: "Bounce",
      Type: "HardBounce"
    }
  );

  assert.deepEqual(
    redactGeneratedMessageId(
      postmarkPayloadForStatus({
        ...base,
        eventType: "spam_complaint",
        reason: "recipient marked the message as spam"
      })
    ),
    {
      Details: "recipient marked the message as spam",
      MessageID: "<generated>",
      Metadata: { delivery_id: "delivery-bob", message_id: "message-1" },
      Recipient: "bob@example.test",
      RecordType: "SpamComplaint"
    }
  );

  assert.equal(memberReceiptStatusForEventType("delivered"), "delivered");
  assert.equal(memberReceiptStatusForEventType("opened"), "opened");
  assert.equal(memberReceiptStatusForEventType("delayed"), "delivery problem");
  assert.equal(memberReceiptStatusForEventType("bounced"), "delivery problem");
  assert.equal(memberReceiptStatusForEventType("spam_complaint"), "delivery problem");
});

test("reporting a recipient email status posts to POST /webhooks/postmark using browser-visible ids", async () => {
  const page = new FakePage();
  page.rows.deliveryRecords.push({
    attrs: {
      "data-delivery-id": "delivery-bob",
      "data-recipient-id": "person-bob",
      "data-recipient-name": "Bob"
    },
    dataset: { deliveryId: "delivery-bob", recipientId: "person-bob", recipientName: "Bob" }
  });
  const request = new FakeRequestContext();
  const expectations = [];
  const world = worldWithPage(page);
  world.request = request;
  world.messages = { "Trip planning night": { messageId: "message-1", subject: "Trip planning night" } };
  world.people = { Bob: { email: "bob@example.test", personId: "person-bob" } };

  await reportRecipientEmailStatus(world, "Bob", "Trip planning night", "delivered", {
    expect: fakeExpect(expectations)
  });

  assert.deepEqual(request.posts.map((post) => post.url), [
    "http://127.0.0.1:4444/webhooks/postmark"
  ]);
  assert.deepEqual(redactGeneratedMessageId(request.posts[0].options.data), {
    MessageID: "<generated>",
    Metadata: { delivery_id: "delivery-bob", message_id: "message-1" },
    Recipient: "bob@example.test",
    RecordType: "Delivery"
  });
  assert.equal(request.posts[0].options.headers["content-type"], "application/json");
  assert.deepEqual(world.deliveries["Trip planning night"].Bob, {
    deliveryId: "delivery-bob",
    recipientEmail: "bob@example.test",
    recipientId: "person-bob",
    recipientName: "Bob"
  });
  assert.equal(world.reportedDeliveryStatuses["Trip planning night:Bob"].eventType, "delivered");
  assert.ok(expectations.some((expectation) => expectation[0] === "visible"));
});

test("reporting a recipient email status polls the browser-visible receipt projection", async () => {
  const page = new FakePage();
  page.rows.deliveryRecords.push({
    attrs: {
      "data-delivery-id": "delivery-bob",
      "data-recipient-id": "person-bob",
      "data-recipient-name": "Bob"
    },
    dataset: { deliveryId: "delivery-bob", recipientId: "person-bob", recipientName: "Bob" }
  });
  page.rows.memberReceipts.push({
    attrs: { "data-recipient-name": "Bob", receiptStatus: "delivered" },
    dataset: { recipientName: "Bob" }
  });
  const request = new FakeRequestContext();
  const expectations = [];
  const world = worldWithPage(page);
  world.projectionPollIntervalMs = 0;
  world.projectionTimeoutMs = 1000;
  world.request = request;
  world.messages = { "Trip planning night": { messageId: "message-1", subject: "Trip planning night" } };
  world.people = { Bob: { email: "bob@example.test", personId: "person-bob" } };

  assert.equal(projectionPollIntervalMs(world), 0);

  await reportRecipientEmailStatus(world, "Bob", "Trip planning night", "delivered", {
    expect: flakyReceiptTextExpect(expectations, 2)
  });

  const receiptTextAssertions = expectations.filter(
    (expectation) =>
      expectation[0] === "text" && expectation[1].includes('data-testid="receipt-status"')
  );

  assert.equal(request.posts.length, 1);
  assert.equal(receiptTextAssertions.length, 3);
  assert.ok(
    receiptTextAssertions.every((expectation) => expectation[3].timeout > 0 && expectation[3].timeout <= 1000)
  );
});

test("Postmark webhook submission failures report the endpoint and response details", async () => {
  const request = new FakeRequestContext(new FakeResponse(422, { errors: { detail: "Unsupported" } }));
  const world = {
    baseUrl: "http://127.0.0.1:4444",
    request
  };

  await assert.rejects(
    () => postPostmarkWebhook(world, { RecordType: "SubscriptionChange" }),
    /Postmark webhook submission failed: expected HTTP 202 from POST \/webhooks\/postmark, got HTTP 422/
  );
});

test("projection timing failures are reported separately from final assertion mismatches", async () => {
  const page = new FakePage();
  const world = worldWithPage(page);
  world.projectionTimeoutMs = 1;
  world.messages = { "Trip planning night": { messageId: "message-1", subject: "Trip planning night" } };

  await assert.rejects(
    () =>
      assertReceiptStatus(world, "Bob", "Trip planning night", "delivered", {
        expect: flakyReceiptTextExpect([], 100)
      }),
    /Projection timing timeout: timed out waiting for projected browser UI:/
  );
});

test("delivery lookup reads the delivery id needed for webhook metadata from the message UI", async () => {
  const page = new FakePage();
  page.rows.deliveryRecords.push({
    attrs: {
      "data-delivery-id": "delivery-bob",
      "data-recipient-id": "person-bob",
      "data-recipient-name": "Bob"
    },
    dataset: { deliveryId: "delivery-bob", recipientId: "person-bob", recipientName: "Bob" }
  });
  const expectations = [];
  const world = worldWithPage(page);
  world.messages = { "Trip planning night": { messageId: "message-1", subject: "Trip planning night" } };
  world.people = { Bob: { email: "bob@example.test", personId: "person-bob" } };

  assert.deepEqual(
    await deliveryForRecipient(world, "Bob", "Trip planning night", { expect: fakeExpect(expectations) }),
    {
      deliveryId: "delivery-bob",
      messageId: "message-1",
      recipientEmail: "bob@example.test",
      recipientId: "person-bob",
      recipientName: "Bob"
    }
  );
});

function redactGeneratedMessageId(payload) {
  return {
    ...payload,
    MessageID: "<generated>"
  };
}
