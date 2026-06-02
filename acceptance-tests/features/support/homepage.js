const { expect: playwrightExpect } = require("@playwright/test");

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
  await expect(page.getByRole("heading", { name: "Volunteering shouldn’t feel like work." })).toBeVisible();
  const getStartedLink = page.getByRole("link", { name: "Get started" });
  await expect(getStartedLink.first ? getStartedLink.first() : getStartedLink).toBeVisible();

  const viewportWidth = typeof page.viewportSize === "function" ? page.viewportSize()?.width : undefined;
  if (viewportWidth === undefined || viewportWidth >= 640) {
    const signInLink = page.getByRole("link", { name: "Sign in" });
    await expect(signInLink.first ? signInLink.first() : signInLink).toBeVisible();
  }
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
  assertHomepageFitsScreen,
  assertMembaHomepage,
  homepageUrl,
  homepageUrlPattern,
  visitHomepage
};
