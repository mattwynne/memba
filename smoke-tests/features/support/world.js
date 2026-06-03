const { setDefaultTimeout, setWorldConstructor, Before, After } = require("@cucumber/cucumber");
const { chromium } = require("playwright");
const { smokeConfig } = require("../../lib/config");
const { FastmailJmapClient } = require("../../lib/fastmail_jmap");

setDefaultTimeout(Number(process.env.MEMBA_SMOKE_STEP_TIMEOUT_MS || 180000));

class SmokeWorld {
  constructor({ attach, log } = {}) {
    this.attach = attach;
    this.log = log;
    this.config = null;
    this.browser = null;
    this.context = null;
    this.page = null;
    this.mailboxes = {};
    this.messages = {};
  }
}

setWorldConstructor(SmokeWorld);

Before(async function () {
  this.config = smokeConfig();
  this.mailboxes.member = await new FastmailJmapClient({ token: this.config.member.jmapToken }).connect();
  this.mailboxes.unknown = await new FastmailJmapClient({ token: this.config.unknown.jmapToken }).connect();
  this.mailboxes.staff = await new FastmailJmapClient({ token: this.config.staff.jmapToken }).connect();

  this.browser = await chromium.launch({ headless: this.config.browser.headless });
  this.context = await this.browser.newContext();
  this.page = await this.context.newPage();
});

After(async function () {
  if (this.context) {
    await this.context.close();
  }
  if (this.browser) {
    await this.browser.close();
  }
});
