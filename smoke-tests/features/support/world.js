const { setDefaultTimeout, setWorldConstructor, Before, After } = require("@cucumber/cucumber");
const { chromium } = require("playwright");
const { smokeConfig } = require("../../lib/config");
const { FastmailImapClient } = require("../../lib/fastmail_imap");
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
  this.mailboxes.member = await connectFastmailMailbox(this.config.member);
  this.mailboxes.unknown = await connectFastmailMailbox(this.config.unknown);
  this.mailboxes.staff = await connectFastmailMailbox(this.config.staff);

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
  for (const mailbox of Object.values(this.mailboxes || {})) {
    if (mailbox && typeof mailbox.close === "function") {
      mailbox.close();
    }
  }
});

function connectFastmailMailbox(config) {
  if (config.jmapToken) {
    return new FastmailJmapClient({ token: config.jmapToken }).connect();
  }

  return new FastmailImapClient({
    user: config.imapUser || config.smtpUser,
    password: config.imapPassword || config.smtpPassword
  }).connect();
}
