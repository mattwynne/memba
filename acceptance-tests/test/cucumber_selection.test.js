const assert = require("node:assert/strict");
const path = require("node:path");
const test = require("node:test");
const { loadConfiguration, loadSources } = require("@cucumber/cucumber/api");

const cwd = path.resolve(__dirname, "..");

async function selectedScenarios(paths) {
  const { runConfiguration } = await loadConfiguration(
    { provided: paths ? { paths } : {} },
    { cwd }
  );
  const { plan, errors } = await loadSources(runConfiguration.sources, { cwd });
  assert.deepEqual(errors, []);
  return plan.sort((left, right) =>
    left.uri.localeCompare(right.uri) || left.location.line - right.location.line
  );
}

function selectedFiles(scenarios) {
  return [...new Set(scenarios.map(({ uri }) => uri))].sort();
}

test("an explicit feature path does not also select the default suite", async () => {
  const scenarios = await selectedScenarios(["features/homepage.feature"]);
  assert.ok(scenarios.length > 0);
  assert.deepEqual(selectedFiles(scenarios), ["features/homepage.feature"]);
});

test("multiple explicit feature paths select only those files", async () => {
  const paths = ["features/homepage.feature", "features/authentication.feature"];
  const scenarios = await selectedScenarios(paths);
  assert.deepEqual(selectedFiles(scenarios), [...paths].sort());
});

test("a file and line select only that scenario", async () => {
  const suite = await selectedScenarios();
  const scenario = suite.find(({ uri }) => uri === "features/homepage.feature");
  assert.ok(scenario);
  assert.deepEqual(
    await selectedScenarios([`${scenario.uri}:${scenario.location.line}`]),
    [scenario]
  );
});

test("no explicit path preserves the full shared-feature suite", async () => {
  const defaultSuite = await selectedScenarios();
  assert.ok(selectedFiles(defaultSuite).length > 1);
  assert.deepEqual(defaultSuite, await selectedScenarios(["features/**/*.feature"]));
});
