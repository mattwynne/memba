const clubs = {
  kootenay: {
    clubId: "clb_11111111-1111-1111-1111-111111111111",
    name: "Kootenay Alpine Club",
    slug: "kootenay-alpine"
  },
  wessex: {
    clubId: "clb_22222222-2222-2222-2222-222222222222",
    name: "Wessex Chamber Choir",
    slug: "wessex-choir"
  }
};

const messages = {
  saturdayRidgeWalk: {
    messageId: "msg_30000000-0000-0000-0000-000000000001",
    subject: "Saturday ridge walk"
  }
};

function rootUrl(ctx, path = "/") {
  return new URL(path, `${ctx.baseUrl}/`).toString();
}

function clubUrl(ctx, club, path = "/") {
  const url = new URL(path, `${ctx.baseUrl}/`);
  url.hostname = `${club.slug}.${ctx.clubSiteBaseDomain}`;
  return url.toString();
}

async function waitForLoaded(page) {
  await page.waitForLoadState("domcontentloaded");
  await page.waitForLoadState("networkidle").catch(() => {});
}

const scenes = [
  {
    id: "marketing-home",
    area: "app",
    label: "Marketing home",
    auth: null,
    async navigate(page, ctx) {
      await page.goto(rootUrl(ctx, "/"), { waitUntil: "domcontentloaded" });
      await page.getByText("Private member websites for volunteer-run groups").waitFor();
      await waitForLoaded(page);
    }
  },
  {
    id: "member-club-home",
    area: "app",
    label: "Member club home",
    auth: "member",
    async navigate(page, ctx) {
      await page.goto(clubUrl(ctx, clubs.kootenay), { waitUntil: "domcontentloaded" });
      await page.locator(`#member-club-home[data-club-id="${clubs.kootenay.clubId}"]`).waitFor();
      await waitForLoaded(page);
    }
  },
  {
    id: "member-message-read",
    area: "app",
    label: "Member message read",
    auth: "member",
    async navigate(page, ctx) {
      await page.goto(
        clubUrl(ctx, clubs.kootenay, `/messages/${encodeURIComponent(messages.saturdayRidgeWalk.messageId)}`),
        { waitUntil: "domcontentloaded" }
      );
      await page.locator(`#member-message-detail[data-message-id="${messages.saturdayRidgeWalk.messageId}"]`).waitFor();
      await page.getByRole("heading", { name: messages.saturdayRidgeWalk.subject }).waitFor();
      await waitForLoaded(page);
    }
  },
  {
    id: "member-message-compose",
    area: "app",
    label: "Member message compose",
    auth: "member",
    async navigate(page, ctx) {
      await page.goto(clubUrl(ctx, clubs.kootenay, "/messages/new"), { waitUntil: "domcontentloaded" });
      await page.locator("#member-message-compose[data-compose-state=\"composing\"]").waitFor();
      await waitForLoaded(page);
    }
  },
  {
    id: "public-club-page",
    area: "app",
    label: "Public club page",
    auth: null,
    async navigate(page, ctx) {
      await page.goto(clubUrl(ctx, clubs.wessex), { waitUntil: "domcontentloaded" });
      await page.locator(`#public-club-page-page[data-club-id="${clubs.wessex.clubId}"]`).waitFor();
      await waitForLoaded(page);
    }
  }
];

module.exports = {
  clubs,
  messages,
  scenes
};
