const assert = require("node:assert/strict");
const test = require("node:test");

const cucumberConfig = require("../cucumber");

test("default browser Cucumber profile excludes todo-web scenarios", () => {
  assert.equal(cucumberConfig.default.tags, "not @todo-web");
});

test("default browser Cucumber profile still loads the shared feature suite", () => {
  assert.deepEqual(cucumberConfig.default.paths, ["features/**/*.feature"]);
});
