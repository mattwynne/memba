const assert = require("node:assert/strict");
const { When, Then } = require("@cucumber/cucumber");
const { expect: playwrightExpect } = require("@playwright/test");
const {
  appUrl,
  cssString,
  kootenayClubName,
  projectionTimeoutMs
} = require("../support/member_message");

const staffPages = {
  Clubs: { navItem: "clubs", path: "/admin/clubs", pageSelector: "#clubs-index" },
  Requests: { navItem: "requests", path: "/admin/requests", pageSelector: "#admin-requests-index" },
  People: { navItem: "people", path: "/admin/people", pageSelector: "#admin-people-index" },
  Messages: { navItem: "messages", path: "/admin/messages", pageSelector: "#admin-messages-index" },
  Deliveries: { navItem: "deliveries", path: "/admin/deliveries", pageSelector: "#deliveries-overview" }
};

When("{word} opens the Memba staff area", async function (_staffName) {
  await openStaffPage(this, staffPages.Clubs);
});

When("{word} opens the staff People page", async function (_staffName) {
  await openStaffPage(this, staffPages.People);
});

When("{word} opens the staff Messages page", async function (_staffName) {
  await openStaffPage(this, staffPages.Messages);
});

When("{word} opens the message diagnostics for {string}", async function (_staffName, subject) {
  const row = await messageRow(this, subject);
  await row.getByRole("link", { name: "Open diagnostics" }).click();
  await playwrightExpect(this.page).toHaveURL(appUrl(this.baseUrl, `/admin/messages/${messageIdFor(this, subject)}`));
  await playwrightExpect(this.page.locator("#message-show")).toBeVisible({
    timeout: projectionTimeoutMs(this)
  });
});

When("{word} opens Kootenay Mountaineering Club in the staff area", async function (_staffName) {
  const club = clubFor(this, kootenayClubName);

  await this.page.goto(appUrl(this.baseUrl, `/admin/clubs/${club.clubId}`));
  await playwrightExpect(this.page.locator("#club-show")).toBeVisible({
    timeout: projectionTimeoutMs(this)
  });
  await playwrightExpect(this.page.getByRole("heading", { name: kootenayClubName })).toBeVisible();
});

Then("{word} should be able to navigate to {word}", async function (_staffName, pageName) {
  const staffPage = staffPageFor(pageName);
  const link = this.page.locator(
    `nav[aria-label="Memba staff navigation"] [data-admin-nav-item=${cssString(staffPage.navItem)}]`
  );

  await playwrightExpect(link).toBeVisible();
  await playwrightExpect(link).toHaveAttribute("href", staffPage.path);

  await link.click();
  await playwrightExpect(this.page).toHaveURL(appUrl(this.baseUrl, staffPage.path));
  await playwrightExpect(this.page.locator(staffPage.pageSelector)).toBeVisible({
    timeout: projectionTimeoutMs(this)
  });
});

Then(
  "{word} should not be offered unavailable staff pages such as Incoming or Roles",
  async function (_staffName) {
    const nav = this.page.locator('nav[aria-label="Memba staff navigation"]');

    await playwrightExpect(nav.getByText("Incoming")).toHaveCount(0);
    await playwrightExpect(nav.getByText("Roles")).toHaveCount(0);
    await playwrightExpect(nav.locator("[data-admin-nav-item]")).toHaveCount(Object.keys(staffPages).length);
  }
);

Then("{word} should see Alice as one person", async function (_staffName) {
  await playwrightExpect(personRows(this, "Alice")).toHaveCount(1, {
    timeout: projectionTimeoutMs(this)
  });
});

Then(
  "{word} should see that {word} is a member of Kootenay Mountaineering Club",
  async function (_staffName, personName) {
    await assertPersonMembership(this, personName, kootenayClubName);
  }
);

Then(
  "{word} should see that {word} is a member of Nelson Paddling Club",
  async function (_staffName, personName) {
    await assertPersonMembership(this, personName, "Nelson Paddling Club");
  }
);

Then("{word} should see {string} for Kootenay Mountaineering Club", async function (_staffName, subject) {
  const row = await messageRow(this, subject);

  await playwrightExpect(row.locator('[data-testid="admin-message-subject"]')).toContainText(subject);
  await playwrightExpect(row.locator('[data-testid="admin-message-club"]')).toContainText(kootenayClubName);
});

Then(
  "{word} should see the staff delivery diagnostics for {string}",
  async function (_staffName, subject) {
    await playwrightExpect(this.page.locator("#message-show")).toBeVisible({
      timeout: projectionTimeoutMs(this)
    });
    await playwrightExpect(this.page.getByRole("heading", { name: subject })).toBeVisible();
    await playwrightExpect(this.page.locator("#addressed-recipients")).toBeVisible();
    await playwrightExpect(this.page.locator("#delivery-records")).toBeVisible();
    await playwrightExpect(this.page.locator("#member-receipts")).toBeVisible();
  }
);

Then(
  "{word} should not be offered a way to send a club message as a member",
  async function (_staffName) {
    await playwrightExpect(this.page.locator("#club-show")).toBeVisible();
    await playwrightExpect(this.page.locator("#new-message-form")).toHaveCount(0);
    await playwrightExpect(this.page.locator("#message-sender-select")).toHaveCount(0);
    await playwrightExpect(this.page.locator("#message-subject-input")).toHaveCount(0);
    await playwrightExpect(this.page.locator("#message-body-input")).toHaveCount(0);
    await playwrightExpect(this.page.locator("#send-message-button")).toHaveCount(0);
    await playwrightExpect(this.page.getByRole("button", { name: "Send club message" })).toHaveCount(0);
    await playwrightExpect(this.page.getByRole("link", { name: "Send club message" })).toHaveCount(0);
  }
);

async function openStaffPage(world, staffPage) {
  await world.page.goto(appUrl(world.baseUrl, staffPage.path));
  await playwrightExpect(world.page.locator("#admin-layout[data-surface='admin']")).toBeVisible({
    timeout: projectionTimeoutMs(world)
  });
  await playwrightExpect(world.page.locator(staffPage.pageSelector)).toBeVisible();
}

function staffPageFor(pageName) {
  const staffPage = staffPages[pageName];
  assert.ok(staffPage, `Expected ${pageName} to name a staff operations page`);
  return staffPage;
}

function clubFor(world, clubName) {
  const club = world.clubs && world.clubs[clubName];
  assert.ok(club && club.clubId, `Expected ${clubName} to be known in the scenario`);
  return club;
}

function personRows(world, personName) {
  return world.page.locator(
    `[data-testid="admin-person-row"][data-person-name=${cssString(personName)}]`
  );
}

async function assertPersonMembership(world, personName, clubName) {
  const rows = personRows(world, personName);
  await playwrightExpect(rows).toHaveCount(1, { timeout: projectionTimeoutMs(world) });
  await playwrightExpect(rows.first().locator('[data-testid="admin-person-memberships"]')).toContainText(clubName);
}

async function messageRow(world, subject) {
  const row = world.page.locator(
    `[data-testid="admin-message-row"][data-message-subject=${cssString(subject)}]`
  );

  await playwrightExpect(row).toHaveCount(1, { timeout: projectionTimeoutMs(world) });
  return row.first();
}

function messageIdFor(world, subject) {
  const message = world.messages && world.messages[subject];
  assert.ok(message && message.messageId, `Expected message ${JSON.stringify(subject)} to have been sent`);
  return encodeURIComponent(message.messageId);
}
