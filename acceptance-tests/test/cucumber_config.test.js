const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const cucumberConfig = require("../cucumber");

test("default browser Cucumber profile excludes todo-web scenarios", () => {
  assert.equal(cucumberConfig.default.tags, "not @todo-web");
});

test("default browser Cucumber profile still loads the shared feature suite", () => {
  assert.deepEqual(cucumberConfig.default.paths, ["features/**/*.feature"]);
});

test("default browser Cucumber profile excludes only operator scenarios from shared features", () => {
  const includedFeatureNames = browserIncludedFeatureNames();
  const excludedFeatureNames = browserExcludedFeatureNames();

  assert.deepEqual(includedFeatureNames, [
    "homepage.feature",
    "member_message_deliverability.feature"
  ]);
  assert.deepEqual(excludedFeatureNames, ["operator_email_deliverability.feature"]);
});

function browserIncludedFeatureNames() {
  return featureFiles()
    .filter((featureFile) => !featureHasTodoWebTag(featureFile))
    .map((featureFile) => path.basename(featureFile));
}

function browserExcludedFeatureNames() {
  return featureFiles()
    .filter(featureHasTodoWebTag)
    .map((featureFile) => path.basename(featureFile));
}

function featureFiles() {
  const featuresDirectory = path.resolve(__dirname, "../features");

  return fs
    .readdirSync(featuresDirectory)
    .filter((fileName) => fileName.endsWith(".feature"))
    .map((fileName) => path.join(featuresDirectory, fileName))
    .sort();
}

function featureHasTodoWebTag(featureFile) {
  return featureTags(featureFile).includes("@todo-web");
}

function featureTags(featureFile) {
  const tags = [];

  for (const line of fs.readFileSync(featureFile, "utf8").split(/\r?\n/)) {
    const trimmed = line.trim();

    if (trimmed === "" || trimmed.startsWith("#")) {
      continue;
    }

    if (trimmed.startsWith("@")) {
      tags.push(...trimmed.split(/\s+/));
      continue;
    }

    if (trimmed.startsWith("Feature:")) {
      return tags;
    }

    return tags;
  }

  return tags;
}
