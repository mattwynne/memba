const assert = require("node:assert/strict");
const { spawn } = require("node:child_process");
const path = require("node:path");
const test = require("node:test");

const {
  assetBuildStep,
  buildLifecycleConfig,
  buildMixCommand,
  buildPhoenixCommand,
  buildPostgresReadinessCommand,
  createBrowserAcceptanceLifecycle,
  databaseSetupSteps,
  LogBuffer,
  startManagedProcess
} = require("../features/support/lifecycle");

function testEnv(overrides = {}) {
  return {
    PATH: process.env.PATH,
    ACCEPTANCE_PORT: "4444",
    MEMBA_POSTGRES_PORT: "15555",
    ...overrides
  };
}

function killProcessGroupForTest(child, signal) {
  if (!child.pid) {
    return;
  }

  try {
    if (process.platform === "win32") {
      child.kill(signal);
    } else {
      process.kill(-child.pid, signal);
    }
  } catch (_error) {
    // The process may already have exited.
  }
}

function runNodeScript(script, { timeoutMs }) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, ["-e", script], {
      cwd: path.resolve(__dirname, ".."),
      env: process.env,
      detached: process.platform !== "win32",
      stdio: ["ignore", "pipe", "pipe"]
    });
    let stdout = "";
    let stderr = "";
    let settled = false;

    const timeout = setTimeout(() => {
      if (settled) {
        return;
      }

      settled = true;
      killProcessGroupForTest(child, "SIGKILL");
      reject(
        new Error(
          `node script did not exit within ${timeoutMs}ms.\nstdout:\n${stdout}\nstderr:\n${stderr}`
        )
      );
    }, timeoutMs);

    child.stdout.on("data", (chunk) => {
      stdout += chunk;
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });

    child.once("error", (error) => {
      if (settled) {
        return;
      }

      settled = true;
      clearTimeout(timeout);
      reject(error);
    });

    child.once("close", (code, signal) => {
      if (settled) {
        return;
      }

      settled = true;
      clearTimeout(timeout);

      if (code === 0) {
        resolve({ stdout, stderr });
        return;
      }

      reject(
        new Error(
          `node script exited with code ${code}${signal ? ` and signal ${signal}` : ""}.\n` +
            `stdout:\n${stdout}\nstderr:\n${stderr}`
        )
      );
    });
  });
}

async function waitForManagedLog(logBuffer, text, managedProcess, timeoutMs = 1000) {
  const deadline = Date.now() + timeoutMs;

  while (!logBuffer.tail().includes(text)) {
    const exitStatus = managedProcess.exitStatus();

    if (exitStatus) {
      throw new Error(
        `managed process exited before logging ${text}: ${JSON.stringify(exitStatus)}`
      );
    }

    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for managed process to log ${text}`);
    }

    await new Promise((resolve) => setImmediate(resolve));
  }
}

test(
  "managed process stop clears graceful shutdown timeout after the child exits",
  { timeout: 7000 },
  async () => {
    const lifecyclePath = path.resolve(__dirname, "../features/support/lifecycle");
    const managedChildScript = `
process.once("SIGTERM", () => process.exit(0));
process.stdout.write("ready\\n");
setInterval(() => {}, 1000);
setTimeout(() => process.exit(42), 30000);
`;
    const script = `
const { LogBuffer, startManagedProcess } = require(${JSON.stringify(lifecyclePath)});
const logBuffer = new LogBuffer();
const managed = startManagedProcess({
  command: process.execPath,
  args: ["-e", ${JSON.stringify(managedChildScript)}],
  cwd: process.cwd(),
  env: process.env
}, { label: "graceful-child", logBuffer, shutdownTimeoutMs: 60000 });

async function waitUntilReady() {
  const deadline = Date.now() + 1000;

  while (!logBuffer.tail().includes("ready")) {
    const exitStatus = managed.exitStatus();

    if (exitStatus) {
      throw new Error("managed child exited before readiness: " + JSON.stringify(exitStatus));
    }

    if (Date.now() > deadline) {
      throw new Error("timed out waiting for managed child readiness");
    }

    await new Promise((resolve) => setImmediate(resolve));
  }
}

(async () => {
  await waitUntilReady();
  await managed.stop();
  process.stdout.write("managed stopped\\n");
})().catch((error) => {
  console.error(error.stack || error.message);
  process.exit(1);
});
`;

    const result = await runNodeScript(script, { timeoutMs: 5000 });

    assert.match(result.stdout, /managed stopped/);
  }
);

test(
  "managed process stop escalates to SIGKILL after the configured shutdown timeout",
  { timeout: 5000 },
  async () => {
    const logBuffer = new LogBuffer();
    const managed = startManagedProcess(
      {
        command: process.execPath,
        args: [
          "-e",
          `
process.once("SIGTERM", () => process.stdout.write("term\\n"));
process.stdout.write("ready\\n");
setInterval(() => {}, 1000);
`
        ],
        cwd: path.resolve(__dirname, ".."),
        env: process.env
      },
      { label: "sigkill-child", logBuffer, shutdownTimeoutMs: 100 }
    );

    try {
      await waitForManagedLog(logBuffer, "ready", managed);
      const startedAt = Date.now();

      await managed.stop();

      assert.ok(Date.now() - startedAt >= 100);
      assert.deepEqual(managed.exitStatus(), { code: null, signal: "SIGKILL" });
    } finally {
      if (!managed.exitStatus()) {
        await managed.stop();
      }
    }
  }
);

test("lifecycle prepares Postgres, database, Phoenix, readiness, and teardown in a dev shell", async () => {
  const calls = [];
  const env = testEnv({ MEMBA_DEVENV_SHELL: "1" });
  const lifecycle = createBrowserAcceptanceLifecycle({
    env,
    processRunner: {
      async run(spec, { label }) {
        calls.push({ type: "run", label, spec });
      },
      async start(spec, { label }) {
        calls.push({ type: "start", label, spec });

        return {
          exitStatus: () => null,
          async stop() {
            calls.push({ type: "stop", label });
          }
        };
      }
    },
    async httpReady(url) {
      calls.push({ type: "httpReady", url });
      return { statusCode: 200 };
    }
  });

  await lifecycle.start();
  await lifecycle.stop();

  assert.equal(lifecycle.baseUrl, "http://lvh.me:4444");
  assert.deepEqual(
    calls.map((call) => `${call.type}:${call.label || call.url}`),
    [
      "run:Postgres readiness",
      ...databaseSetupSteps.map((step) => `run:Database setup: ${step.label}`),
      `run:Asset setup: ${assetBuildStep.label}`,
      "start:Phoenix server",
      "httpReady:http://lvh.me:4444",
      "stop:Phoenix server"
    ]
  );
});

test("Postgres readiness uses devenv processes instead of removed bin/dev postgres", async () => {
  const config = await buildLifecycleConfig(testEnv());
  const command = buildPostgresReadinessCommand(config);

  assert.equal(command.command, "bash");
  assert.equal(command.args[0], "-lc");
  assert.match(command.args[1], /processes status postgres/);
  assert.match(command.args[1], /devenv -O services\.postgres\.port:int "\$MEMBA_POSTGRES_PORT" processes up --no-strict-ports -d postgres/);
  assert.match(command.args[1], /devenv -O services\.postgres\.port:int "\$MEMBA_POSTGRES_PORT" processes wait --timeout 120/);
  assert.doesNotMatch(command.args[1], /bin\/dev postgres/);
  assert.equal(command.env.MEMBA_POSTGRES_PORT, "15555");
});

test("non-dev-shell mix commands run through devenv on the selected Postgres port", async () => {
  const config = await buildLifecycleConfig(testEnv());
  const command = buildMixCommand(config, ["ecto.create", "--quiet"]);

  assert.equal(command.command, "devenv");
  assert.deepEqual(command.args.slice(0, 6), [
    "shell",
    "-O",
    "services.postgres.port:int",
    "15555",
    "--",
    path.resolve(__dirname, "../../bin/mix")
  ]);
  assert.deepEqual(command.args.slice(6), ["ecto.create", "--quiet"]);
  assert.equal(command.env.MIX_ENV, "test");
  assert.equal(command.env.PHX_SERVER, "true");
  assert.equal(command.env.PORT, "4444");
  assert.equal(command.env.MEMBA_POSTGRES_PORT, "15555");
});

test("Phoenix server command starts a named node for acceptance server commands", async () => {
  const config = await buildLifecycleConfig(testEnv({ MEMBA_DEVENV_SHELL: "1" }));
  const command = buildPhoenixCommand(config);

  assert.equal(command.command, path.resolve(__dirname, "../../bin/mix"));
  assert.deepEqual(command.args, ["phx.server"]);
  assert.match(command.env.ELIXIR_ERL_OPTIONS, /-sname memba_acceptance_server/);
  assert.match(command.env.ELIXIR_ERL_OPTIONS, /-setcookie memba_acceptance_cookie/);
  assert.equal(command.env.ACCEPTANCE_SERVER_NODE, "memba_acceptance_server");
  assert.equal(command.env.ACCEPTANCE_SERVER_COOKIE, "memba_acceptance_cookie");
});

test("readiness timeout reports Phoenix startup/readiness diagnostics", async () => {
  const env = testEnv({
    MEMBA_DEVENV_SHELL: "1",
    ACCEPTANCE_HTTP_READY_TIMEOUT_MS: "0"
  });
  const lifecycle = createBrowserAcceptanceLifecycle({
    env,
    processRunner: {
      async run() {},
      async start() {
        return {
          exitStatus: () => null,
          async stop() {}
        };
      }
    },
    async httpReady() {
      throw new Error("connection refused");
    },
    async delay() {}
  });

  await assert.rejects(
    () => lifecycle.start(),
    /Phoenix startup\/readiness failed: timed out after 0ms/
  );
});

test("database setup failures report database setup diagnostics", async () => {
  const env = testEnv({ MEMBA_DEVENV_SHELL: "1" });
  const lifecycle = createBrowserAcceptanceLifecycle({
    env,
    processRunner: {
      async run(_spec, { label }) {
        if (label === "Database setup: migrate test database") {
          throw new Error("migration failed");
        }
      },
      async start() {
        throw new Error("Phoenix should not start after database setup failure");
      }
    },
    async httpReady() {
      return { statusCode: 200 };
    }
  });

  await assert.rejects(
    () => lifecycle.start(),
    /Database setup failed while migrate test database\.\nCause: migration failed/
  );
});


test("asset setup failures report asset setup diagnostics", async () => {
  const env = testEnv({ MEMBA_DEVENV_SHELL: "1" });
  const lifecycle = createBrowserAcceptanceLifecycle({
    env,
    processRunner: {
      async run(_spec, { label }) {
        if (label === "Asset setup: build browser assets") {
          throw new Error("asset build failed");
        }
      },
      async start() {
        throw new Error("Phoenix should not start after asset setup failure");
      }
    },
    async httpReady() {
      return { statusCode: 200 };
    }
  });

  await assert.rejects(
    () => lifecycle.start(),
    /Asset setup failed while build browser assets\.\nCause: asset build failed/
  );
});
