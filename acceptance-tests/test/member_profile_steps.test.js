const assert = require("node:assert/strict");
const path = require("node:path");
const test = require("node:test");
const { loadConfiguration, loadSources, runCucumber } = require("@cucumber/cucumber/api");

test("the approved Profile journey has exactly one executable definition per step", async () => {
  const cwd = path.resolve(__dirname, "..");
  const { runConfiguration } = await loadConfiguration({
    file: false,
    provided: {
      dryRun: true,
      format: ["message:/dev/null"],
      paths: ["features/journeys/member_profile.feature:7"],
      publishQuiet: true,
      require: ["features/support/**/*.js", "features/step_definitions/**/*.js"],
      tags: "@journey and @iteration-068 and not @todo"
    }
  }, { cwd });
  const { plan, errors } = await loadSources(runConfiguration.sources, { cwd });
  assert.deepEqual(errors, []);
  assert.equal(plan.length, 1);
  const statuses = [];
  let count = 0;
  await runCucumber(runConfiguration, { cwd }, (message) => {
    if (message.testCaseStarted) count += 1;
    if (message.testStepFinished) statuses.push(message.testStepFinished.testStepResult.status);
  });
  assert.equal(count, 1);
  assert.ok(statuses.length >= 8);
  assert.deepEqual([...new Set(statuses)], ["SKIPPED"]);
});
