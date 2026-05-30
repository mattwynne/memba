const { setWorldConstructor, Before, After } = require("@cucumber/cucumber");
const { chromium } = require("playwright");

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

Before(async function () {
  this.browser = await chromium.launch({ headless: process.env.HEADLESS !== "false" });
  this.page = await this.browser.newPage();
});

After(async function () {
  if (this.browser) {
    await this.browser.close();
  }
});
