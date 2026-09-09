const assert = require("node:assert/strict");
const test = require("node:test");

const { loadConfiguration, runCucumber } = require("@cucumber/cucumber/api");

test("browser-backed iteration 059 scenarios have executable step plumbing", async () => {
  let scenarioCount = 0;
  const statuses = [];
  const { runConfiguration } = await loadConfiguration({
    file: false,
    provided: {
      dryRun: true,
      format: ["message:/dev/null"],
      paths: ["features/**/*.feature"],
      publishQuiet: true,
      require: ["features/support/**/*.js", "features/step_definitions/**/*.js"],
      tags: "@iteration-059 and not @not-ui"
    }
  });

  await runCucumber(runConfiguration, undefined, (message) => {
    if (message.testCaseStarted) {
      scenarioCount += 1;
    }

    if (message.testStepFinished) {
      statuses.push(message.testStepFinished.testStepResult.status);
    }
  });

  assert.equal(scenarioCount, 4);
  assert.deepEqual(
    [...new Set(statuses)],
    ["SKIPPED"],
    "Expected every browser-backed iteration-059 step to have exactly one definition"
  );
});
