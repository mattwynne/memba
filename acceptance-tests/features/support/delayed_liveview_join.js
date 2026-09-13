const fs = require("node:fs");

const delayedJoinConfig = {
  fieldIds: new Set([
    "member-message-subject-input",
    "person-name-input",
    "edit-club-slug-input"
  ]),
  targetPathPattern: /\/messages\/new|\/people\/new|\/admin\/clubs\/clb_[^/]+$/
};

function configuredJoinHoldMs() {
  const configuredValue = Number(process.env.ACCEPTANCE_DELAY_LIVEVIEW_JOIN_MS || 0);
  return Number.isFinite(configuredValue) && configuredValue > 0 ? configuredValue : 0;
}

async function installDelayedLiveViewJoinOnBrowserIfConfigured(browser) {
  const holdMs = configuredJoinHoldMs();

  if (!holdMs || !browser || browser.__membaDelayedLiveViewJoinInstalled) {
    return;
  }

  browser.__membaDelayedLiveViewJoinInstalled = true;
  const originalNewContext = browser.newContext.bind(browser);

  browser.newContext = async (...args) => {
    const context = await originalNewContext(...args);
    await installDelayedLiveViewJoinIfConfigured(context);
    return context;
  };
}

async function installDelayedLiveViewJoinIfConfigured(context) {
  const holdMs = configuredJoinHoldMs();

  if (!holdMs || !context || context.__membaDelayedLiveViewJoinInstalled) {
    return;
  }

  if (typeof context.routeWebSocket !== "function") {
    throw new Error("ACCEPTANCE_DELAY_LIVEVIEW_JOIN_MS requires Playwright routeWebSocket support");
  }

  context.__membaDelayedLiveViewJoinInstalled = true;
  const pendingJoins = new Set();
  let closed = false;

  const originalClose = context.close.bind(context);
  context.close = async (...args) => {
    closed = true;
    for (const pendingJoin of [...pendingJoins]) {
      pendingJoin.cancel();
    }
    return originalClose(...args);
  };

  await context.exposeBinding("__membaReleaseDelayedLiveViewJoin", ({ page }, data) => {
    logDelayedJoin({ kind: "field-blur", url: page.url(), ...data });

    for (const pendingJoin of [...pendingJoins]) {
      pendingJoin.release("field-blur");
    }
  });

  await context.addInitScript((fieldIds) => {
    document.addEventListener(
      "blur",
      (event) => {
        if (fieldIds.includes(event.target && event.target.id)) {
          window.__membaReleaseDelayedLiveViewJoin({
            target: event.target.id,
            rootClass: document.querySelector("[data-phx-main]")?.className || ""
          });
        }
      },
      true
    );
  }, [...delayedJoinConfig.fieldIds]);

  await context.routeWebSocket("**/live/websocket**", (webSocketRoute) => {
    const server = webSocketRoute.connectToServer();

    server.onMessage((message) => {
      const hold = joinHoldDetails(context, message);

      if (!hold) {
        webSocketRoute.send(message);
        return;
      }

      let released = false;
      let timeoutId = null;
      const pendingJoin = {
        release(reason) {
          if (released) {
            return;
          }

          released = true;
          pendingJoins.delete(pendingJoin);

          if (timeoutId) {
            clearTimeout(timeoutId);
            timeoutId = null;
          }

          logDelayedJoin({ kind: "join-released", reason, ...hold });

          if (!closed) {
            try {
              webSocketRoute.send(message);
            } catch (error) {
              logDelayedJoin({ kind: "join-release-send-failed", reason, error: error.message, ...hold });
            }
          }
        },
        cancel() {
          if (released) {
            return;
          }

          released = true;
          pendingJoins.delete(pendingJoin);

          if (timeoutId) {
            clearTimeout(timeoutId);
            timeoutId = null;
          }

          logDelayedJoin({ kind: "join-cancelled", ...hold });
        }
      };

      pendingJoins.add(pendingJoin);
      logDelayedJoin({ kind: "join-held", holdMs, ...hold });
      timeoutId = setTimeout(() => pendingJoin.release("timeout"), holdMs);
    });
  });
}

function joinHoldDetails(context, message) {
  const page = context.pages().at(-1);
  const url = page && typeof page.url === "function" ? page.url() : "";

  if (!delayedJoinConfig.targetPathPattern.test(url)) {
    return null;
  }

  let frame;

  try {
    frame = JSON.parse(String(message));
  } catch (_error) {
    return null;
  }

  if (!(frame && frame[3] === "phx_reply" && frame[4] && frame[4].response && frame[4].response.rendered)) {
    return null;
  }

  return { url, topic: frame[2], ref: frame[1] };
}

function logDelayedJoin(event) {
  const logPath = process.env.ACCEPTANCE_DELAY_LIVEVIEW_JOIN_LOG;

  if (!logPath) {
    return;
  }

  fs.appendFileSync(logPath, `${JSON.stringify({ time: Date.now(), ...event })}\n`);
}

module.exports = {
  installDelayedLiveViewJoinIfConfigured,
  installDelayedLiveViewJoinOnBrowserIfConfigured
};
