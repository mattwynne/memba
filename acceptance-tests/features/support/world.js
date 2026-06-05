const {
  setDefaultTimeout,
  setWorldConstructor,
  BeforeAll,
  AfterAll,
  Before,
  After,
  BeforeStep,
  AfterStep,
  Status
} = require("@cucumber/cucumber");
const { chromium } = require("playwright");
const { configureBrowserEnvironment } = require("./browser_environment");
const { createBrowserAcceptanceLifecycle } = require("./lifecycle");
const { restoreClubMessageSending } = require("./member_message");

const lifecycle = createBrowserAcceptanceLifecycle();
const defaultStepTimeoutMs = Number(process.env.ACCEPTANCE_STEP_TIMEOUT_MS || 30000);
const progressLoggingEnabled = new Set(["1", "true", "yes"]).has(
  String(process.env.ACCEPTANCE_LOG_PROGRESS || "").toLowerCase()
);

function acceptanceLog(message) {
  if (!progressLoggingEnabled) {
    return;
  }

  process.stderr.write(`[acceptance ${new Date().toISOString()}] ${message}\n`);
}

function nowMs() {
  return Number(process.hrtime.bigint()) / 1_000_000;
}

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
  acceptanceLog("BeforeAll: starting Phoenix browser acceptance lifecycle");
  await lifecycle.start();
  acceptanceLog("BeforeAll: Phoenix browser acceptance lifecycle ready");
});

AfterAll({ name: "Stop Phoenix browser acceptance lifecycle", timeout: 120000 }, async function () {
  acceptanceLog("AfterAll: stopping Phoenix browser acceptance lifecycle");
  await lifecycle.stop();
  acceptanceLog("AfterAll: stopped Phoenix browser acceptance lifecycle");
});

BeforeStep(function ({ pickleStep } = {}) {
  this.currentStepStartedAt = nowMs();
  this.currentStepText = pickleStep && pickleStep.text;
  acceptanceLog(`step start: ${this.scenarioName || "(unknown scenario)"} :: ${this.currentStepText || "(unknown step)"}`);
});

AfterStep(function ({ pickleStep } = {}) {
  const durationMs = this.currentStepStartedAt ? Math.round(nowMs() - this.currentStepStartedAt) : "unknown";
  const stepText = (pickleStep && pickleStep.text) || this.currentStepText || "(unknown step)";
  acceptanceLog(`step finish: ${this.scenarioName || "(unknown scenario)"} :: ${stepText} :: ${durationMs}ms`);
});

Before(async function ({ pickle } = {}) {
  this.baseUrl = lifecycle.baseUrl;
  this.scenarioName = pickle && pickle.name;
  this.scenarioStartedAt = nowMs();
  acceptanceLog(`scenario start: ${this.scenarioName || "(unknown scenario)"}`);

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

  acceptanceLog(`scenario reset app state: ${this.scenarioName || "(unknown scenario)"}`);
  await resetAcceptanceState(this);
});

After(async function ({ result } = {}) {
  acceptanceLog(`scenario teardown start: ${this.scenarioName || "(unknown scenario)"} status=${result && result.status}`);
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

  const durationMs = this.scenarioStartedAt ? Math.round(nowMs() - this.scenarioStartedAt) : "unknown";
  acceptanceLog(`scenario finish: ${this.scenarioName || "(unknown scenario)"} status=${result && result.status} duration=${durationMs}ms`);
});

async function resetAcceptanceState(world) {
  const response = await world.context.request.post(
    new URL("/dev/test-support/reset", `${world.baseUrl}/`).toString()
  );

  if (response.status() !== 204) {
    const body = typeof response.text === "function" ? await response.text() : "(response body unavailable)";

    throw new Error(`Expected acceptance reset to return 204, got ${response.status()}: ${body}`);
  }
}
