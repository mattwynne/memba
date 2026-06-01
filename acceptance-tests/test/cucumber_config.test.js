const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const cucumberConfig = require("../cucumber");

test("default browser Cucumber profile excludes deferred scenarios", () => {
  assert.equal(cucumberConfig.default.tags, "not @todo-web and not @wip");
});

test("default browser Cucumber profile still loads the shared feature suite", () => {
  assert.deepEqual(cucumberConfig.default.paths, ["features/**/*.feature"]);
});

test("default browser Cucumber profile selects all web-backed shared features", () => {
  const selectedFeatureNames = browserSelectedFeatureNames();

  assert.deepEqual(selectedFeatureNames, [
    "authentication.feature",
    "homepage.feature",
    "member_message_deliverability.feature",
    "operator_email_deliverability.feature"
  ]);
});

test("operator deliverability is no longer deferred from the browser run", () => {
  const skippedFeatures = browserSkippedFeatures();

  assert.deepEqual(skippedFeatures, []);
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

function matchesDefaultBrowserTags(tags) {
  assert.equal(cucumberConfig.default.tags, "not @todo-web and not @wip");

  return !tags.includes("@todo-web") && !tags.includes("@wip");
}
