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
  await expect(page.getByRole("heading", { name: "Phoenix Framework" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Guides & Docs" })).toBeVisible();
}

module.exports = {
  assertMembaHomepage,
  homepageUrl,
  homepageUrlPattern,
  visitHomepage
};
