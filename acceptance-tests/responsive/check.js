#!/usr/bin/env node

const fs = require("node:fs/promises");
const path = require("node:path");
const { chromium } = require("playwright");
const { expect } = require("@playwright/test");
const { collectChangedFiles } = require("./change_detector");
const { configureBrowserEnvironment } = require("../features/support/browser_environment");
const { createBrowserAcceptanceLifecycle } = require("../features/support/lifecycle");
const { scenes } = require("../gallery/scenes");

const repoRoot = path.resolve(__dirname, "../..");
const outputDir = path.join(repoRoot, "tmp", "responsive-check");
const memberEmail = "alice@example.com";
const staffEmail = "gallery-staff@memba.io";
const overflowTolerancePx = 2;

const viewports = {
  phone: { width: 390, height: 844 },
  belowMemberRailBreakpoint: { width: 680, height: 844 },
  aboveMemberRailBreakpoint: { width: 720, height: 844 }
};

function hasFlag(name) {
  return process.argv.includes(name);
}

function appUrl(baseUrl, route) {
  return new URL(route, `${baseUrl}/`).toString();
}

function clubSiteBaseDomain(env = process.env) {
  return env.MEMBA_CLUB_SITE_BASE_DOMAIN || "lvh.me";
}

function sceneById(id) {
  const scene = scenes.find((candidate) => candidate.id === id);

  if (!scene) {
    throw new Error(`Responsive check scene not found: ${id}`);
  }

  return scene;
}

async function postNoContent(request, url, data) {
  const response = await request.post(url, data === undefined ? {} : {
    data,
    headers: { "content-type": "application/json" }
  });

  if (response.status() !== 204) {
    throw new Error(`Expected POST ${url} to return 204, got ${response.status()}: ${await response.text()}`);
  }
}

async function resetAndSeed(request, baseUrl) {
  await postNoContent(request, appUrl(baseUrl, "/dev/test-support/reset"));
  await postNoContent(request, appUrl(baseUrl, "/dev/test-support/seed"));
}

async function signIn(context, baseUrl, auth) {
  if (auth === "member") {
    await postNoContent(context.request, appUrl(baseUrl, "/dev/test-support/sign-in"), {
      email: memberEmail
    });
  } else if (auth === "staff") {
    await postNoContent(context.request, appUrl(baseUrl, "/dev/test-support/sign-in"), {
      email: staffEmail
    });
  }
}

function attachPageErrorChecks(page, label) {
  const errors = [];

  page.on("pageerror", (error) => {
    errors.push(error.stack || error.message);
  });
  page.on("console", (message) => {
    if (message.type() === "error") {
      errors.push(`[console:error] ${message.text()}`);
    }
  });

  return () => {
    if (errors.length > 0) {
      throw new Error(`${label} emitted browser errors:\n${errors.join("\n")}`);
    }
  };
}

async function assertNoOuterDocumentOverflow(page, label) {
  const overflow = await page.evaluate(() => {
    const body = document.body;
    const doc = document.documentElement;

    return {
      bodyScrollWidth: body ? body.scrollWidth : 0,
      documentScrollWidth: doc.scrollWidth,
      viewportWidth: doc.clientWidth,
      windowInnerWidth: window.innerWidth
    };
  });
  const maxScrollWidth = Math.max(overflow.bodyScrollWidth, overflow.documentScrollWidth);
  const viewportWidth = overflow.viewportWidth || overflow.windowInnerWidth;

  if (maxScrollWidth > viewportWidth + overflowTolerancePx) {
    throw new Error(
      `${label} has outer-document horizontal overflow: scrollWidth=${maxScrollWidth}, viewport=${viewportWidth}, tolerance=${overflowTolerancePx}`
    );
  }
}

async function assertWithinViewport(locator, label, options = {}) {
  await expect(locator, `${label} is visible`).toBeVisible();
  await locator.scrollIntoViewIfNeeded();

  const box = await locator.boundingBox();

  if (!box) {
    throw new Error(`${label} has no rendered bounding box`);
  }

  const page = locator.page();
  const viewport = page.viewportSize();

  if (!viewport) {
    return;
  }

  const tolerance = options.tolerance ?? overflowTolerancePx;
  const left = box.x;
  const right = box.x + box.width;
  const top = box.y;
  const bottom = box.y + box.height;

  if (left < -tolerance || right > viewport.width + tolerance) {
    throw new Error(
      `${label} is outside viewport horizontally: left=${left}, right=${right}, viewportWidth=${viewport.width}`
    );
  }

  if (options.vertical !== false && (top < -tolerance || bottom > viewport.height + tolerance)) {
    throw new Error(
      `${label} is outside viewport vertically after scrollIntoViewIfNeeded: top=${top}, bottom=${bottom}, viewportHeight=${viewport.height}`
    );
  }
}

async function assertMemberRailResponsive(page, width, label) {
  const rail = page.locator("#member-group-rail");
  const content = page.locator("#member-group-content");
  await assertWithinViewport(rail, `${label} group rail`, { vertical: false });
  await expect(page.locator('[data-testid="member-group-link"]').first()).toBeVisible();

  const geometry = await page.evaluate(() => {
    const rail = document.querySelector("#member-group-rail");
    const content = document.querySelector("#member-group-content");

    if (!rail || !content) {
      return null;
    }

    const railBox = rail.getBoundingClientRect();
    const contentBox = content.getBoundingClientRect();
    const railStyle = getComputedStyle(rail);
    const splitStyle = getComputedStyle(document.querySelector(".app-split"));

    return {
      rail: {
        left: railBox.left,
        right: railBox.right,
        top: railBox.top,
        bottom: railBox.bottom,
        width: railBox.width,
        scrollWidth: rail.scrollWidth,
        clientWidth: rail.clientWidth,
        overflowX: railStyle.overflowX,
        display: railStyle.display
      },
      content: {
        left: contentBox.left,
        top: contentBox.top
      },
      splitDisplay: splitStyle.display
    };
  });

  if (!geometry) {
    throw new Error(`${label} missing member rail/content geometry`);
  }

  if (width <= 700) {
    if (geometry.splitDisplay !== "block") {
      throw new Error(`${label} expected stacked member shell at ${width}px, got ${geometry.splitDisplay}`);
    }

    if (!/auto|scroll/.test(geometry.rail.overflowX)) {
      throw new Error(`${label} expected horizontal rail overflow containment at ${width}px, got ${geometry.rail.overflowX}`);
    }

    if (geometry.rail.bottom > geometry.content.top + overflowTolerancePx) {
      throw new Error(
        `${label} expected content below mobile rail: rail.bottom=${geometry.rail.bottom}, content.top=${geometry.content.top}`
      );
    }
  } else {
    if (geometry.splitDisplay !== "grid") {
      throw new Error(`${label} expected grid member shell above 700px, got ${geometry.splitDisplay}`);
    }

    if (geometry.content.left < geometry.rail.right - overflowTolerancePx) {
      throw new Error(
        `${label} expected content beside desktop rail: rail.right=${geometry.rail.right}, content.left=${geometry.content.left}`
      );
    }
  }
}

async function assertHomepage(page, label) {
  await expect(page.getByRole("heading", { name: /^Volunteering shouldn[’']t feel like work\.$/ })).toBeVisible();
  await assertWithinViewport(page.getByRole("link", { name: "Request access for your group" }), `${label} hero request-access CTA`);
  await assertWithinViewport(page.locator("header").getByRole("link", { name: "Request access", exact: true }), `${label} header request-access CTA`);
}

async function assertMemberClubHome(page, width, section, label) {
  await assertMemberRailResponsive(page, width, label);
  await assertWithinViewport(page.locator("#member-section-tabs"), `${label} section tabs`, { vertical: false });

  if (section === "conversations") {
    await assertWithinViewport(page.locator("#member-section-tab-conversations"), `${label} Conversations tab`);
    await assertWithinViewport(page.locator("#member-section-action-new-message"), `${label} New message action`);
    await expect(page.locator("#member-section-panel-conversations")).toBeVisible();
  } else {
    await assertWithinViewport(page.locator("#member-section-tab-members"), `${label} Members tab`);
    await expect(page.locator("#member-section-panel-members")).toBeVisible();
    const memberAction = page.locator("#member-section-action-add-group-member, #member-section-action-invite-member").first();

    if (await memberAction.count()) {
      await assertWithinViewport(memberAction, `${label} member-section action`);
    }
  }
}

async function assertMemberMessageRead(page, label) {
  await assertWithinViewport(page.locator("#back-to-club-home-link"), `${label} back to conversations link`);
  await assertWithinViewport(page.locator("#member-message-heading-row"), `${label} message heading row`, { vertical: false });
  await assertWithinViewport(page.locator("#member-message-reply-submit-button"), `${label} post reply button`);
}

async function assertMemberMessageDelivery(page, label) {
  await assertWithinViewport(page.locator("#member-delivery-back-to-conversation-link"), `${label} back to conversation link`);
  await assertWithinViewport(page.locator("#member-delivery-summary"), `${label} delivery summary`, { vertical: false });
  await assertWithinViewport(page.locator('[data-testid="member-delivery-group"]').first(), `${label} delivery group`, { vertical: false });
}

async function assertStaffPeopleTable(page, label) {
  await assertWithinViewport(page.locator("#admin-people-toolbar"), `${label} people toolbar`, { vertical: false });
  await expect(page.locator('[data-testid="admin-person-row"]').first()).toBeVisible();
  await assertWithinViewport(page.locator("#admin-people-table-card"), `${label} people table card`, { vertical: false });

  const tableOverflow = await page.evaluate(() => {
    const table = document.querySelector("#admin-people-table");
    const scroller = table && table.closest(".overflow-x-auto");

    if (!table || !scroller) {
      return null;
    }

    const box = scroller.getBoundingClientRect();
    const style = getComputedStyle(scroller);

    return {
      overflowX: style.overflowX,
      scrollWidth: scroller.scrollWidth,
      clientWidth: scroller.clientWidth,
      left: box.left,
      right: box.right,
      viewportWidth: document.documentElement.clientWidth
    };
  });

  if (!tableOverflow) {
    throw new Error(`${label} could not find staff table internal scroller`);
  }

  if (!/auto|scroll/.test(tableOverflow.overflowX)) {
    throw new Error(`${label} expected staff table internal horizontal scrolling, got ${tableOverflow.overflowX}`);
  }

  if (tableOverflow.left < -overflowTolerancePx || tableOverflow.right > tableOverflow.viewportWidth + overflowTolerancePx) {
    throw new Error(
      `${label} table scroller escapes viewport: left=${tableOverflow.left}, right=${tableOverflow.right}, viewport=${tableOverflow.viewportWidth}`
    );
  }
}

const checks = [
  {
    label: "homepage at 390px",
    sceneId: "marketing-home",
    viewport: viewports.phone,
    auth: null,
    assert: (page) => assertHomepage(page, "homepage at 390px")
  },
  ...[viewports.phone, viewports.belowMemberRailBreakpoint, viewports.aboveMemberRailBreakpoint].flatMap((viewport) => [
    {
      label: `member club home Conversations at ${viewport.width}px`,
      sceneId: "member-club-home",
      viewport,
      auth: "member",
      assert: (page) => assertMemberClubHome(page, viewport.width, "conversations", `member club home Conversations at ${viewport.width}px`)
    },
    {
      label: `member club home Members at ${viewport.width}px`,
      sceneId: "member-club-home-members-tab",
      viewport,
      auth: "member",
      assert: (page) => assertMemberClubHome(page, viewport.width, "members", `member club home Members at ${viewport.width}px`)
    }
  ]),
  {
    label: "member message read at 390px",
    sceneId: "member-message-read",
    viewport: viewports.phone,
    auth: "member",
    assert: (page) => assertMemberMessageRead(page, "member message read at 390px")
  },
  {
    label: "member message delivery at 390px",
    sceneId: "member-message-delivery",
    viewport: viewports.phone,
    auth: "member",
    assert: (page) => assertMemberMessageDelivery(page, "member message delivery at 390px")
  },
  {
    label: "populated staff people table at 390px",
    sceneId: "staff-people-index",
    viewport: viewports.phone,
    auth: "staff",
    assert: (page) => assertStaffPeopleTable(page, "populated staff people table at 390px")
  }
];

async function runCheckCase(browser, baseUrl, check) {
  const context = await browser.newContext({ viewport: check.viewport });
  let page;

  try {
    await signIn(context, baseUrl, check.auth);
    page = await context.newPage();
    const assertNoPageErrors = attachPageErrorChecks(page, check.label);
    const scene = sceneById(check.sceneId);

    await scene.navigate(page, {
      baseUrl,
      clubSiteBaseDomain: clubSiteBaseDomain()
    });
    await assertNoOuterDocumentOverflow(page, check.label);
    await check.assert(page);
    await assertNoOuterDocumentOverflow(page, check.label);
    assertNoPageErrors();
  } catch (error) {
    if (page) {
      await fs.mkdir(outputDir, { recursive: true });
      const screenshotPath = path.join(outputDir, `${check.label.replace(/[^a-z0-9]+/gi, "-").replace(/^-|-$/g, "").toLowerCase()}.png`);
      await page.screenshot({ path: screenshotPath, fullPage: true }).catch(() => {});
      error.message = `${error.message}\nFailure screenshot: ${path.relative(repoRoot, screenshotPath)}`;
    }

    throw error;
  } finally {
    await context.close();
  }
}

async function runResponsiveChecks() {
  configureBrowserEnvironment();

  const lifecycle = createBrowserAcceptanceLifecycle();
  let browser;

  try {
    await lifecycle.start();
    const baseUrl = lifecycle.baseUrl;
    browser = await chromium.launch({ headless: process.env.HEADLESS !== "false" });

    const requestContext = await browser.newContext();
    try {
      await resetAndSeed(requestContext.request, baseUrl);
    } finally {
      await requestContext.close();
    }

    const failures = [];

    for (const check of checks) {
      process.stdout.write(`responsive check: ${check.label}\n`);
      try {
        await runCheckCase(browser, baseUrl, check);
      } catch (error) {
        failures.push({ label: check.label, error });
        process.stderr.write(`responsive check failed: ${check.label}\n${error.stack || error.message}\n`);
      }
    }

    if (failures.length > 0) {
      throw new Error(`${failures.length} responsive check(s) failed: ${failures.map(({ label }) => label).join(", ")}`);
    }

    process.stdout.write(`responsive check: passed ${checks.length} viewport/page checks\n`);
  } finally {
    if (browser) {
      await browser.close();
    }
    await lifecycle.stop();
  }
}

async function main() {
  const force = hasFlag("--force");
  const changes = collectChangedFiles(repoRoot, process.env);

  const triggerReason = changes.sources.committed.explanation || "Checked staged, unstaged, untracked, and configured committed changes.";

  if (!force && !changes.shouldRun) {
    process.stdout.write("responsive check: skipped; no relevant style/layout changes detected.\n");
    process.stdout.write(`responsive check: ${triggerReason}\n`);
    return;
  }

  if (force) {
    process.stdout.write("responsive check: forced by --force.\n");
  } else if (changes.failOpen) {
    process.stdout.write(`responsive check: ${triggerReason}\n`);
  } else {
    process.stdout.write("responsive check: relevant changes detected:\n");
    for (const file of changes.relevant) {
      process.stdout.write(`  - ${file}\n`);
    }
    process.stdout.write(`responsive check: ${triggerReason}\n`);
  }

  await runResponsiveChecks();
}

main().catch((error) => {
  process.stderr.write(`${error.stack || error.message}\n`);
  process.exitCode = 1;
});
