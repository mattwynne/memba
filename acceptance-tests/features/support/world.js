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
const { closeHarnesses } = require("./member_harness");

const lifecycle = createBrowserAcceptanceLifecycle();
let sharedBrowser = null;
let infrastructureStopping = false;
const defaultStepTimeoutMs = Number(process.env.ACCEPTANCE_STEP_TIMEOUT_MS || 30000);
const progressLoggingEnabled = !new Set(["0", "false", "no"]).has(
  String(process.env.ACCEPTANCE_LOG_PROGRESS || "").toLowerCase()
);
const slowStepThresholdMs = Number(process.env.ACCEPTANCE_SLOW_STEP_THRESHOLD_MS || 1000);

function acceptanceLog(message) {
  if (!progressLoggingEnabled) {
    return;
  }

  process.stderr.write(`[acceptance ${new Date().toISOString()}] ${message}\n`);
}

function nowMs() {
  return Number(process.hrtime.bigint()) / 1_000_000;
}

async function stopAcceptanceInfrastructure(reason) {
  if (infrastructureStopping) {
    return;
  }

  infrastructureStopping = true;

  if (sharedBrowser) {
    acceptanceLog(`${reason}: closing shared browser`);
    await sharedBrowser.close();
    sharedBrowser = null;
    acceptanceLog(`${reason}: closed shared browser`);
  }

  acceptanceLog(`${reason}: stopping Phoenix browser acceptance lifecycle`);
  await lifecycle.stop();
  acceptanceLog(`${reason}: stopped Phoenix browser acceptance lifecycle`);
}

function installSignalCleanup(signal, exitCode) {
  process.once(signal, () => {
    acceptanceLog(`received ${signal}; cleaning up browser acceptance infrastructure`);

    stopAcceptanceInfrastructure(signal)
      .catch((error) => {
        process.stderr.write(
          `[acceptance ${new Date().toISOString()}] cleanup after ${signal} failed: ${error.stack || error.message}\n`
        );
      })
      .finally(() => process.exit(exitCode));
  });
}

installSignalCleanup("SIGHUP", 128 + 1);
installSignalCleanup("SIGINT", 128 + 2);
installSignalCleanup("SIGTERM", 128 + 15);

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
  acceptanceLog("BeforeAll: launching shared browser");
  sharedBrowser = await chromium.launch({ headless: process.env.HEADLESS !== "false" });
  acceptanceLog("BeforeAll: shared browser ready");
});

AfterAll({ name: "Stop Phoenix browser acceptance lifecycle", timeout: 120000 }, async function () {
  await stopAcceptanceInfrastructure("AfterAll");
});

BeforeStep(function ({ pickleStep } = {}) {
  this.currentStepStartedAt = nowMs();
  this.currentStepText = pickleStep && pickleStep.text;
});

AfterStep(function ({ pickleStep } = {}) {
  const durationMs = this.currentStepStartedAt ? Math.round(nowMs() - this.currentStepStartedAt) : "unknown";
  const stepText = (pickleStep && pickleStep.text) || this.currentStepText || "(unknown step)";
  if (durationMs !== "unknown" && durationMs >= slowStepThresholdMs) {
    acceptanceLog(`slow step: ${this.scenarioName || "(unknown scenario)"} :: ${stepText} :: ${durationMs}ms`);
  }
});

Before(async function ({ pickle } = {}) {
  this.baseUrl = lifecycle.baseUrl;
  this.scenarioName = pickle && pickle.name;
  this.scenarioStartedAt = nowMs();
  acceptanceLog(`scenario start: ${this.scenarioName || "(unknown scenario)"}`);

  this.browser = sharedBrowser;
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

  await closeHarnesses(this);

  if (this.context) {
    await this.context.close();
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
