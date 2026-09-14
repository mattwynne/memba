const assert = require("node:assert/strict");
const test = require("node:test");

const { loadConfiguration, runCucumber } = require("@cucumber/cucumber/api");

test("browser-backed custom-group creation scenarios have executable step plumbing", async () => {
  let scenarioCount = 0;
  const statuses = [];
  const { runConfiguration } = await loadConfiguration({
    file: false,
    provided: {
      dryRun: true,
      format: ["message:/dev/null"],
      paths: ["features/custom_group_creation.feature"],
      publishQuiet: true,
      require: ["features/support/**/*.js", "features/step_definitions/**/*.js"],
      tags: "@iteration-062 and not @not-ui"
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

  assert.equal(scenarioCount, 17);
  assert.deepEqual(
    [...new Set(statuses)],
    ["SKIPPED"],
    "Expected every browser-backed custom-group creation step to have exactly one definition"
  );
});
