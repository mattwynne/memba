const { spawn } = require("node:child_process");
const path = require("node:path");
const { createBrowserAcceptanceLifecycle } = require("./features/support/lifecycle");

function hasParallelArg(args) {
  return args.some((arg, index) => arg === "--parallel" || arg.startsWith("--parallel=") || (args[index - 1] === "--parallel" && /^\d+$/.test(arg)));
}

async function main() {
  const args = process.argv.slice(2);
  const runInSharedApp = hasParallelArg(args) && process.env.ACCEPTANCE_SKIP_APP_START !== "1";

  if (!runInSharedApp) {
    process.exitCode = await runCucumber(args, process.env);
    return;
  }

  process.env.MIX_TEST_PARTITION = process.env.MIX_TEST_PARTITION || `acceptance_${Date.now()}`;

  const lifecycle = createBrowserAcceptanceLifecycle();

  await lifecycle.start();

  try {
    process.exitCode = await runCucumber(args, {
      ...process.env,
      ACCEPTANCE_SKIP_APP_START: "1",
      ACCEPTANCE_PROJECTION_TIMEOUT_MS: process.env.ACCEPTANCE_PROJECTION_TIMEOUT_MS || "20000",
      ACCEPTANCE_RESET_STATE: "0",
      ACCEPTANCE_SCENARIO_SCOPING: "1",
      BASE_URL: lifecycle.baseUrl
    });
  } finally {
    await lifecycle.stop();
  }
}

function runCucumber(args, env) {
  return new Promise((resolve, reject) => {
    const cucumberBin = path.resolve(__dirname, "node_modules", ".bin", "cucumber-js");
    const child = spawn(cucumberBin, args, {
      cwd: __dirname,
      env,
      stdio: "inherit"
    });

    child.once("error", reject);
    child.once("close", (code, signal) => {
      if (signal) {
        resolve(1);
      } else {
        resolve(code || 0);
      }
    });
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
