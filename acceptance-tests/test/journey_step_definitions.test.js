const assert = require("node:assert/strict");
const path = require("node:path");
const test = require("node:test");

const { loadConfiguration, loadSources, runCucumber } = require("@cucumber/cucumber/api");

const cwd = path.resolve(__dirname, "..");

test("every selected browser journey has exactly one definition per step", async () => {
  // Include the root features while @journey scenarios are being moved into journeys/.
  // Dry-run resolves definitions without executing hooks, steps, or a Phoenix server.
  const { runConfiguration } = await loadConfiguration(
    {
      file: false,
      provided: {
        dryRun: true,
        format: ["message:/dev/null"],
        paths: ["features/journeys/**/*.feature", "features/*.feature"],
        publishQuiet: true,
        require: ["features/support/**/*.js", "features/step_definitions/**/*.js"],
        tags: "@journey and not @todo"
      }
    },
    { cwd }
  );

  const { plan, errors } = await loadSources(runConfiguration.sources, { cwd });
  assert.deepEqual(errors, []);
  assert.ok(
    plan.some(({ uri }) => uri.startsWith("features/journeys/")),
    "Expected at least one selected journey pickle under features/journeys/"
  );

  let scenarioCount = 0;
  const statuses = [];
  await runCucumber(runConfiguration, { cwd }, (message) => {
    if (message.testCaseStarted) {
      scenarioCount += 1;
    }
    if (message.testStepFinished) {
      statuses.push(message.testStepFinished.testStepResult.status);
    }
  });

  assert.equal(scenarioCount, plan.length, "Expected every @journey pickle to be dry-run");
  assert.ok(statuses.length > 0, "Expected journey steps to be checked");
  assert.deepEqual(
    [...new Set(statuses)],
    ["SKIPPED"],
    "Undefined or ambiguous @journey steps must not pass the dry-run"
  );
});
