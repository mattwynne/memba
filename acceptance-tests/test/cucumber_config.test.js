const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const cucumberConfig = require("../cucumber");

const defaultBrowserTagExpression = "not @not-ui and not @todo-ui";

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
    "club_member_invitations.feature",
    "club_membership_administration.feature",
    "club_message_replies.feature",
    "email_branding.feature",
    "homepage.feature",
    "list_members.feature",
    "memba_staff_email_deliverability.feature",
    "memba_staff_operations.feature",
    "member_club_subdomains.feature",
    "member_message_deliverability.feature",
    "person_email_addresses.feature",
    "request_account.feature",
    "staff_club_slugs.feature"
  ]);
});

test("shared feature suite uses only runner-intent and runner-debt tags", () => {
  const unsupportedTags = browserFeatures().flatMap((feature) =>
    feature.scenarios.flatMap((scenario) =>
      scenario.tags
        .filter((tag) => !supportedFeatureTag(tag))
        .map((tag) => `${feature.name}: ${scenario.name}: ${tag}`)
    )
  );

  assert.deepEqual(unsupportedTags, []);
});

test("iteration 031 scenarios are no longer blocked from the browser runner", () => {
  const iterationScenarios = browserFeatures().flatMap((feature) =>
    feature.scenarios
      .filter((scenario) => scenario.tags.includes("@iteration-031"))
      .map((scenario) => `${feature.name}: ${scenario.name}: ${scenario.tags.join(" ")}`)
  );

  assert.equal(iterationScenarios.length, 4);
  assert.deepEqual(
    iterationScenarios.filter((scenario) => scenario.includes("@todo-ui")),
    []
  );
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

function supportedFeatureTag(tag) {
  return ["@not-domain", "@not-ui", "@todo-domain", "@todo-ui"].includes(tag) || /^@iteration-\d+$/.test(tag);
}

function matchesDefaultBrowserTags(tags) {
  assert.equal(cucumberConfig.default.tags, defaultBrowserTagExpression);

  return (
    !tags.includes("@not-ui") &&
    !tags.includes("@todo-ui")
  );
}
