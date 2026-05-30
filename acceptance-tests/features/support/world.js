const { setWorldConstructor, setDefaultTimeout, Before, After } = require("@cucumber/cucumber");
const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");

class AcceptanceWorld {
  constructor() {
    this.baseUrl = process.env.BASE_URL || "http://localhost:4000";
    this.scenarioId = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
    this.clubs = {};
    this.people = {};
    this.messages = {};
    this.addressedMemberNames = [];
  }
}

setWorldConstructor(AcceptanceWorld);
setDefaultTimeout(30 * 1000);

Before(async function () {
  const launchOptions = { headless: process.env.HEADLESS !== "false" };
  const executablePath = chromiumExecutablePath();

  if (executablePath) {
    launchOptions.executablePath = executablePath;
  }

  this.browser = await chromium.launch(launchOptions);
  this.page = await this.browser.newPage();
});

After(async function () {
  if (this.browser) {
    await this.browser.close();
  }
});

function chromiumExecutablePath() {
  if (process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH) {
    return process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH;
  }

  const browsersPath = process.env.PLAYWRIGHT_BROWSERS_PATH;

  if (!browsersPath) {
    return null;
  }

  const chromiumDirectory = fs
    .readdirSync(browsersPath, { withFileTypes: true })
    .filter(
      (entry) => (entry.isDirectory() || entry.isSymbolicLink()) && /^chromium-\d+$/.test(entry.name)
    )
    .map((entry) => entry.name)
    .sort()
    .at(-1);

  if (!chromiumDirectory) {
    return null;
  }

  const executablePath = path.join(browsersPath, chromiumDirectory, "chrome-linux64", "chrome");

  return fs.existsSync(executablePath) ? executablePath : null;
}
