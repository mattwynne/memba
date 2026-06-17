const { expect: playwrightExpect } = require("@playwright/test");

const HOMEPAGE_VOLUNTEERING_PROMISE = /^Volunteering shouldn[’']t feel like work\.$/;

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function homepageUrl(baseUrl) {
  return new URL("/", `${baseUrl}/`).toString();
}

function homepageUrlPattern(baseUrl) {
  const withoutTrailingSlash = homepageUrl(baseUrl).replace(/\/$/, "");

  return new RegExp(`^${escapeRegExp(withoutTrailingSlash)}/?$`);
}

async function visitHomepage({ baseUrl, page }) {
  await page.goto(homepageUrl(baseUrl));
}

async function assertMembaHomepage({ baseUrl, page }, { expect = playwrightExpect } = {}) {
  await expect(page).toHaveURL(homepageUrlPattern(baseUrl));
  await expect(page).toHaveTitle(/Memba/);
  await assertHomepageVolunteeringPromise({ page }, { expect });
  const getStartedLink = page.getByRole("link", { name: "Request access for your group" });
  await expect(getStartedLink.first ? getStartedLink.first() : getStartedLink).toBeVisible();

  const viewportWidth = typeof page.viewportSize === "function" ? page.viewportSize()?.width : undefined;
  if (viewportWidth === undefined || viewportWidth >= 640) {
    const signInLink = page.getByRole("link", { name: "Sign in" });
    await expect(signInLink.first ? signInLink.first() : signInLink).toBeVisible();
  }
}

async function assertHomepageVolunteeringPromise({ page }, { expect = playwrightExpect } = {}) {
  await expect(page.getByRole("heading", { name: HOMEPAGE_VOLUNTEERING_PROMISE })).toBeVisible();
}

async function assertNoHomepageVolunteeringPromise({ page }, { expect = playwrightExpect } = {}) {
  await expect(page.getByRole("heading", { name: HOMEPAGE_VOLUNTEERING_PROMISE })).toHaveCount(0);
}

async function assertHomepageRequestAccess({ page }, { expect = playwrightExpect } = {}) {
  await expect(page.getByRole("link", { name: /Request access(?: for your group)?/ }).first()).toBeVisible();
}

async function assertHomepageSignIn({ page }, { expect = playwrightExpect } = {}) {
  await expect(page.getByRole("link", { name: "Sign in" }).first()).toBeVisible();
}

async function assertHomepageStaffAccess({ page }, { expect = playwrightExpect } = {}) {
  const staffBar = page.locator("#homepage-staff-bar");
  await expect(staffBar).toBeVisible();
  await expect(staffBar.getByText("Memba staff", { exact: true })).toBeVisible();

  const consoleLink = page.locator("a#staff-console-link");
  await expect(consoleLink).toBeVisible();
  await expect(consoleLink).toHaveAttribute("href", "/admin/clubs");

  await expect(page.locator("a#admin-home-link")).toHaveCount(0);
}

async function assertHomepageFitsScreen({ page }, { expect = playwrightExpect } = {}) {
  const viewport = page.viewportSize();
  const overflow = await page.evaluate(() => ({
    body: document.body.scrollWidth,
    document: document.documentElement.scrollWidth,
    viewport: document.documentElement.clientWidth
  }));

  await expect(Math.max(overflow.body, overflow.document)).toBeLessThanOrEqual(
    viewport?.width || overflow.viewport
  );
}

module.exports = {
  HOMEPAGE_VOLUNTEERING_PROMISE,
  assertHomepageFitsScreen,
  assertHomepageRequestAccess,
  assertHomepageSignIn,
  assertHomepageStaffAccess,
  assertMembaHomepage,
  assertNoHomepageVolunteeringPromise,
  assertHomepageVolunteeringPromise,
  homepageUrl,
  homepageUrlPattern,
  visitHomepage
};
