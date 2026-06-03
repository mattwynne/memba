const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const cucumberConfig = require("../cucumber");

const inboundClubEmailScenarioNames = [
  "Alice emails the KMC everyone address",
  "Alice emails from an alternate address",
  "An unknown sender emails the KMC everyone address",
  "A member of another club emails the KMC everyone address",
  "Alice emails an attachment to the KMC everyone address",
  "Alice emails without a plain-text message body",
  "Alice emails new text above a signature and quoted message"
];

test("default browser Cucumber profile excludes deferred scenarios", () => {
  assert.equal(cucumberConfig.default.tags, "not @todo-web and not @wip");
});

test("default browser Cucumber profile still loads the shared feature suite", () => {
  assert.deepEqual(cucumberConfig.default.paths, ["features/**/*.feature"]);
});

test("default browser Cucumber profile selects all non-deferred web-backed shared features", () => {
  const selectedFeatureNames = browserSelectedFeatureNames();

  assert.deepEqual(selectedFeatureNames, [
    "authentication.feature",
    "homepage.feature",
    "memba_staff_email_deliverability.feature",
    "member_club_subdomains.feature",
    "member_message_deliverability.feature",
    "person_email_addresses.feature"
  ]);
});

test("only explicitly deferred features are skipped from the browser run", () => {
  const skippedFeatures = browserSkippedFeatures();

  assert.deepEqual(skippedFeatures.map((feature) => feature.name), ["staff_club_slugs.feature"]);
});

test("inbound club email scenarios remain tagged wip until enabled", () => {
  const featurePath = browserFeaturePathNamed("member_message_deliverability.feature");
  const scenarios = featureScenarios(featurePath);

  assert.deepEqual(
    inboundClubEmailScenarioNames.map((scenarioName) => scenarios.get(scenarioName)?.name),
    inboundClubEmailScenarioNames
  );

  for (const scenarioName of inboundClubEmailScenarioNames) {
    const scenario = scenarios.get(scenarioName);

    assert.ok(
      scenario.tags.includes("@wip"),
      `Expected "${scenarioName}" to remain tagged @wip`
    );
    assert.equal(
      matchesDefaultBrowserTags(scenario.tags),
      false,
      `Expected "${scenarioName}" to be excluded by the default browser profile`
    );
  }
});

function browserSelectedFeatureNames() {
  return browserFeatures()
    .filter((feature) => matchesDefaultBrowserTags(feature.tags))
    .map((feature) => feature.name)
    .sort();
}

function browserSkippedFeatures() {
  return browserFeatures()
    .filter((feature) => !matchesDefaultBrowserTags(feature.tags))
    .sort((left, right) => left.name.localeCompare(right.name));
}

function browserFeatures() {
  assert.deepEqual(cucumberConfig.default.paths, ["features/**/*.feature"]);

  const featuresRoot = path.resolve(__dirname, "../features");

  return listFeatureFiles(featuresRoot).map((filePath) => ({
    name: path.basename(filePath),
    tags: featureTags(filePath)
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
      scenarios.set(name, { name, tags: pendingTags });
      pendingTags = [];
      continue;
    }

    pendingTags = [];
  }

  return scenarios;
}

function matchesDefaultBrowserTags(tags) {
  assert.equal(cucumberConfig.default.tags, "not @todo-web and not @wip");

  return !tags.includes("@todo-web") && !tags.includes("@wip");
}
