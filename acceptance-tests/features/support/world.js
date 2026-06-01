const {
  setDefaultTimeout,
  setWorldConstructor,
  BeforeAll,
  AfterAll,
  Before,
  After,
  Status
} = require("@cucumber/cucumber");
const { chromium } = require("playwright");
const { configureBrowserEnvironment } = require("./browser_environment");
const { createBrowserAcceptanceLifecycle } = require("./lifecycle");
const { restoreClubMessageSending } = require("./member_message");

const lifecycle = createBrowserAcceptanceLifecycle();
const defaultStepTimeoutMs = Number(process.env.ACCEPTANCE_STEP_TIMEOUT_MS || 30000);

setDefaultTimeout(defaultStepTimeoutMs);
configureBrowserEnvironment();

class AcceptanceWorld {
  constructor({ attach, log, parameters } = {}) {
    this.attach = attach;
    this.log = log;
    this.parameters = parameters;
    this.baseUrl = lifecycle.baseUrl;
    this.browserLogs = [];
  }
}

setWorldConstructor(AcceptanceWorld);

BeforeAll({ name: "Start Phoenix browser acceptance lifecycle", timeout: 360000 }, async function () {
  await lifecycle.start();
});

AfterAll({ name: "Stop Phoenix browser acceptance lifecycle", timeout: 120000 }, async function () {
  await lifecycle.stop();
});

Before(async function ({ pickle } = {}) {
  this.baseUrl = lifecycle.baseUrl;
  this.browser = await chromium.launch({ headless: process.env.HEADLESS !== "false" });
  this.context = await this.browser.newContext();
  this.page = await this.context.newPage();

  this.page.on("console", (message) => {
    this.browserLogs.push(`[console:${message.type()}] ${message.text()}`);
  });

  this.page.on("pageerror", (error) => {
    this.browserLogs.push(`[pageerror] ${error.stack || error.message}`);
  });

  this.page.on("requestfailed", (request) => {
    const failure = request.failure();
    this.browserLogs.push(
      `[requestfailed] ${request.method()} ${request.url()} ${failure ? failure.errorText : ""}`
    );
  });

});

After(async function ({ result } = {}) {
  await restoreClubMessageSending(this);

  const failed = result && result.status === Status.FAILED;

  if (failed && this.attach) {
    if (this.browserLogs.length > 0) {
      await this.attach(this.browserLogs.join("\n"), {
        mediaType: "text/plain",
        fileName: "browser.log"
      });
    }

    const appLogTail = lifecycle.getLogTail();

    if (appLogTail.length > 0) {
      await this.attach(appLogTail, {
        mediaType: "text/plain",
        fileName: "phoenix.log"
      });
    }

    if (this.page) {
      try {
        await this.attach(await this.page.screenshot({ fullPage: true }), {
          mediaType: "image/png",
          fileName: "failure.png"
        });
      } catch (error) {
        await this.attach(`Unable to capture browser screenshot: ${error.message}`);
      }
    }
  }

  if (this.context) {
    await this.context.close();
  }

  if (this.browser) {
    await this.browser.close();
  }
});
