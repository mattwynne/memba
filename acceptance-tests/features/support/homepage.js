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
  const signInLink = page.getByRole("link", { name: "Sign in" });
  await expect(signInLink.first ? signInLink.first() : signInLink).toBeVisible();
}

module.exports = {
  assertMembaHomepage,
  homepageUrl,
  homepageUrlPattern,
  visitHomepage
};
