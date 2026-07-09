#!/usr/bin/env node

const fs = require("node:fs/promises");
const path = require("node:path");
const { chromium } = require("playwright");
const { configureBrowserEnvironment } = require("../features/support/browser_environment");
const { scenes } = require("./scenes");

const repoRoot = path.resolve(__dirname, "../..");
const outputDir = path.join(repoRoot, "tmp", "gallery");
const memberEmail = "alice@example.com";
const staffEmail = "gallery-staff@memba.io";

const viewports = [
  { name: "desktop", width: 1280, height: 800 },
  { name: "mobile", width: 390, height: 844 }
];

function galleryBaseUrl(env = process.env) {
  if (env.GALLERY_BASE_URL) {
    return env.GALLERY_BASE_URL;
  }

  if (env.BASE_URL) {
    return env.BASE_URL;
  }

  return `http://lvh.me:${env.ACCEPTANCE_PORT || env.PORT || "4000"}`;
}

function appUrl(baseUrl, route) {
  return new URL(route, `${baseUrl}/`).toString();
}

function clubSiteBaseDomain(env = process.env) {
  return env.MEMBA_CLUB_SITE_BASE_DOMAIN || "lvh.me";
}

function slugify(value) {
  const slug = String(value || "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 64)
    .replace(/^-+|-+$/g, "");

  return slug || "email";
}

async function postNoContent(request, url, data) {
  const options =
    data === undefined
      ? {}
      : {
          data,
          headers: { "content-type": "application/json" }
        };
  const response = await request.post(url, options);

  if (response.status() !== 204) {
    throw new Error(`Expected POST ${url} to return 204, got ${response.status()}: ${await response.text()}`);
  }
}

async function resetAndSeed(request, baseUrl) {
  await postNoContent(request, appUrl(baseUrl, "/dev/test-support/reset"));
  await postNoContent(request, appUrl(baseUrl, "/dev/test-support/seed"));
}

async function signInMember(context, baseUrl) {
  await postNoContent(context.request, appUrl(baseUrl, "/dev/test-support/sign-in"), {
    email: memberEmail
  });
}

async function signInStaff(context, baseUrl) {
  await postNoContent(context.request, appUrl(baseUrl, "/dev/test-support/sign-in"), {
    email: staffEmail
  });
}

function attachPageErrorChecks(page, label) {
  const errors = [];

  page.on("pageerror", (error) => {
    errors.push(error.stack || error.message);
  });

  return () => {
    if (errors.length > 0) {
      throw new Error(`${label} emitted browser errors:\n${errors.join("\n")}`);
    }
  };
}

async function captureScene(browser, baseUrl, scene, viewport, manifest) {
  const context = await browser.newContext({
    viewport: { width: viewport.width, height: viewport.height }
  });

  try {
    if (scene.auth === "member") {
      await signInMember(context, baseUrl);
    } else if (scene.auth === "staff") {
      await signInStaff(context, baseUrl);
    }

    const page = await context.newPage();
    const assertNoPageErrors = attachPageErrorChecks(page, `${scene.id}/${viewport.name}`);
    await scene.navigate(page, {
      baseUrl,
      clubSiteBaseDomain: clubSiteBaseDomain()
    });
    assertNoPageErrors();

    const file = `${scene.area}__${scene.id}__${viewport.name}.png`;
    await page.screenshot({ path: path.join(outputDir, file), fullPage: true });

    manifest.push({
      area: scene.area,
      id: scene.id,
      label: scene.label,
      viewport: viewport.name,
      file
    });
  } finally {
    await context.close();
  }
}

async function fetchMailboxEmails(request, baseUrl) {
  const response = await request.get(appUrl(baseUrl, "/dev/mailbox/json"));

  if (response.status() !== 200) {
    throw new Error(`Expected GET /dev/mailbox/json to return 200, got ${response.status()}: ${await response.text()}`);
  }

  const payload = await response.json();
  const emails = Array.isArray(payload.data) ? payload.data : [];

  if (emails.length === 0) {
    throw new Error("No emails found in /dev/mailbox after seeding.");
  }

  return emails;
}

async function captureEmails(browser, baseUrl, emails, manifest) {
  const context = await browser.newContext({
    viewport: { width: 1280, height: 800 }
  });

  try {
    const page = await context.newPage();

    for (const [index, email] of emails.entries()) {
      const number = index + 1;
      const messageId = email.headers && email.headers["Message-ID"];

      if (!messageId) {
        throw new Error(`Mailbox email ${number} did not include a Message-ID header.`);
      }

      const subject = email.subject || `Email ${number}`;
      const id = `${number}-${slugify(subject)}`;
      const file = `emails__${id}__desktop.png`;
      const assertNoPageErrors = attachPageErrorChecks(page, `email/${id}`);

      await page.goto(appUrl(baseUrl, `/dev/mailbox/${encodeURIComponent(messageId)}`), {
        waitUntil: "domcontentloaded"
      });
      await page.waitForLoadState("networkidle").catch(() => {});
      assertNoPageErrors();
      await page.screenshot({ path: path.join(outputDir, file), fullPage: true });

      manifest.push({
        area: "emails",
        id,
        label: subject,
        viewport: "desktop",
        file
      });
    }
  } finally {
    await context.close();
  }
}

async function main() {
  configureBrowserEnvironment();

  const baseUrl = galleryBaseUrl();
  await fs.rm(outputDir, { recursive: true, force: true });
  await fs.mkdir(outputDir, { recursive: true });

  const browser = await chromium.launch({ headless: process.env.HEADLESS !== "false" });
  const manifest = [];

  try {
    const requestContext = await browser.newContext();

    try {
      await resetAndSeed(requestContext.request, baseUrl);
      for (const scene of scenes) {
        for (const viewport of viewports) {
          await captureScene(browser, baseUrl, scene, viewport, manifest);
        }
      }

      const emails = await fetchMailboxEmails(requestContext.request, baseUrl);
      await captureEmails(browser, baseUrl, emails, manifest);
    } finally {
      await requestContext.close();
    }
  } finally {
    await browser.close();
  }

  await fs.writeFile(
    path.join(outputDir, "manifest.json"),
    `${JSON.stringify(manifest, null, 2)}\n`
  );

  process.stdout.write(`Captured ${manifest.length} gallery screenshots in ${path.relative(repoRoot, outputDir)}\n`);
}

main().catch((error) => {
  process.stderr.write(`${error.stack || error.message}\n`);
  process.exitCode = 1;
});
