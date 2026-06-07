const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const cucumberConfig = require("../cucumber");

const defaultBrowserTagExpression = "not @not-ui and not @todo-ui and not @todo and not @wip";

test("default browser Cucumber profile excludes scenarios not ready or not intended for UI", () => {
  assert.equal(cucumberConfig.default.tags, defaultBrowserTagExpression);
});

test("default browser Cucumber profile still loads the shared feature suite", () => {
  assert.deepEqual(cucumberConfig.default.paths, ["features/**/*.feature"]);
});

test("default browser Cucumber profile selects all web-backed shared features", () => {
  const selectedFeatureNames = browserSelectedFeatureNames();

  assert.deepEqual(selectedFeatureNames, [
    "authentication.feature",
    "homepage.feature",
    "memba_staff_email_deliverability.feature",
    "memba_staff_operations.feature",
    "member_club_subdomains.feature",
    "member_message_deliverability.feature",
    "person_email_addresses.feature",
    "request_account.feature",
    "staff_club_slugs.feature"
  ]);
});

test("shared feature suite has no parked todo scenarios", () => {
  const parkedScenarios = browserFeatures().flatMap((feature) =>
    feature.scenarios
      .filter((scenario) => scenario.tags.some((tag) => tag.startsWith("@todo")))
      .map((scenario) => `${feature.name}: ${scenario.name}`)
  );

  assert.deepEqual(parkedScenarios, []);
});

function browserSelectedFeatureNames() {
  return browserFeatures()
    .filter((feature) => feature.scenarios.some((scenario) => matchesDefaultBrowserTags(scenario.tags)))
    .map((feature) => feature.name)
    .sort();
}

function browserSkippedFeatures() {
  return browserFeatures()
    .filter((feature) => feature.scenarios.every((scenario) => !matchesDefaultBrowserTags(scenario.tags)))
    .sort((left, right) => left.name.localeCompare(right.name));
}

function browserFeatures() {
  assert.deepEqual(cucumberConfig.default.paths, ["features/**/*.feature"]);

  const featuresRoot = path.resolve(__dirname, "../features");

  return listFeatureFiles(featuresRoot).map((filePath) => ({
    name: path.basename(filePath),
    tags: featureTags(filePath),
    scenarios: [...featureScenarios(filePath).values()]
  }));
}

function browserFeaturePathNamed(featureName) {
  const featuresRoot = path.resolve(__dirname, "../features");
  const featurePath = listFeatureFiles(featuresRoot).find(
    (filePath) => path.basename(filePath) === featureName
  );

  assert.ok(featurePath, `Expected browser feature file ${featureName}`);

  return featurePath;
}

function listFeatureFiles(directory) {
  return fs
    .readdirSync(directory, { withFileTypes: true })
    .flatMap((entry) => {
      const entryPath = path.join(directory, entry.name);

      if (entry.isDirectory()) {
        return listFeatureFiles(entryPath);
      }

      return entry.isFile() && entry.name.endsWith(".feature") ? [entryPath] : [];
    })
    .sort();
}

function featureTags(filePath) {
  const tags = [];

  for (const line of fs.readFileSync(filePath, "utf8").split(/\r?\n/)) {
    const trimmed = line.trim();

    if (trimmed === "") {
      continue;
    }

    if (trimmed.startsWith("@")) {
      tags.push(...trimmed.split(/\s+/));
      continue;
    }

    if (trimmed.startsWith("Feature:")) {
      break;
    }
  }

  return tags;
}

function featureScenarios(filePath) {
  const scenarios = new Map();
  const featureLevelTags = featureTags(filePath);
  let pendingTags = [];

  for (const line of fs.readFileSync(filePath, "utf8").split(/\r?\n/)) {
    const trimmed = line.trim();
    const scenarioMatch = trimmed.match(/^Scenario(?: Outline)?:\s*(.+)$/);

    if (trimmed === "") {
      continue;
    }

    if (trimmed.startsWith("@")) {
      pendingTags.push(...trimmed.split(/\s+/));
      continue;
    }

    if (scenarioMatch) {
      const name = scenarioMatch[1];
      scenarios.set(name, { name, tags: [...featureLevelTags, ...pendingTags] });
      pendingTags = [];
      continue;
    }

    pendingTags = [];
  }

  return scenarios;
}

function matchesDefaultBrowserTags(tags) {
  assert.equal(cucumberConfig.default.tags, defaultBrowserTagExpression);

  return (
    !tags.includes("@not-ui") &&
    !tags.includes("@todo-ui") &&
    !tags.includes("@todo") &&
    !tags.includes("@wip")
  );
}
