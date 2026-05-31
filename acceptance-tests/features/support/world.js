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

const staffEmail = process.env.ACCEPTANCE_STAFF_EMAIL || "acceptance-staff@memba.io";
const magicLinkSubject = "Sign in to Memba";

async function signInStaff(world) {
  await world.page.goto(`${world.baseUrl}/auth`);
  await world.page.getByLabel("Email address").fill(staffEmail);
  await world.page.getByRole("button", { name: "Email me a sign-in link" }).click();

  const magicLink = await waitForMagicLink(world);
  await world.page.goto(magicLink);
  await world.page.waitForURL((url) => url.pathname !== "/auth", { timeout: 10000 });
}

async function waitForMagicLink(world) {
  const deadline = Date.now() + Number(process.env.ACCEPTANCE_PROJECTION_TIMEOUT_MS || 10000);
  let lastError = null;

  do {
    try {
      const response = await world.context.request.get(`${world.baseUrl}/dev/mailbox/json`);

      if (response.status() !== 200) {
        lastError = new Error(`GET /dev/mailbox/json returned HTTP ${response.status()}`);
      } else {
        const payload = await response.json();
        const email = (payload.data || []).find(
          (mailboxEmail) =>
            mailboxEmail.subject === magicLinkSubject &&
            mailboxEmail.to.some((recipient) => recipient.includes(staffEmail))
        );
        const magicLink = email && magicLinkFromTextBody(email.text_body);

        if (magicLink) {
          return magicLink;
        }
      }
    } catch (error) {
      lastError = error;
    }

    await new Promise((resolve) => setTimeout(resolve, 250));
  } while (Date.now() <= deadline);

  throw new Error(
    `Timed out waiting for staff magic link email for ${staffEmail}. Last error: ${
      lastError ? lastError.message : "(none)"
    }`
  );
}

function magicLinkFromTextBody(textBody) {
  const match = String(textBody || "").match(/https?:\/\/\S+\/auth\/magic\/\S+/);
  return match && match[0];
}

BeforeAll({ name: "Start Phoenix browser acceptance lifecycle", timeout: 360000 }, async function () {
  await lifecycle.start();
});

AfterAll({ name: "Stop Phoenix browser acceptance lifecycle", timeout: 120000 }, async function () {
  await lifecycle.stop();
});

Before(async function () {
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

  await signInStaff(this);
});

After(async function ({ result } = {}) {
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
