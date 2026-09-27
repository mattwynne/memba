"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs/promises");
const path = require("node:path");
const test = require("node:test");
const { loadConfiguration } = require("@cucumber/cucumber/api");
const { report } = require("../scripts/step-reachability");

// Put the fixture below node_modules so fixture step files resolve the same
// installed @cucumber/cucumber package without installing anything elsewhere.
test("uses Cucumber's compiled pickles, inherited tags and registered expression matches", async () => {
  const cwd = await fs.mkdtemp(path.join(__dirname, "../node_modules/reachability-"));
  try {
    await fs.mkdir(path.join(cwd, "features", "step_definitions"), { recursive: true });
    await fs.writeFile(path.join(cwd, "features", "sample.feature"), `Feature: reachability
  Background:
    Given shared background

  @not-ui
  Rule: domain only
    Scenario: inherited rule tag
      Then domain rule step

  Rule: browser rule
    Background:
      Given rule background
    Scenario Outline: outline <who>
      When <who> signs in
      Then checked <who>
      Examples: browser rows
        | who   |
        | Alice |
      @todo-ui
      Examples: excluded rows
        | who |
        | Bob |

  @todo-ui
  Scenario: excluded scenario
    Then excluded step
`);
    await fs.writeFile(path.join(cwd, "features", "step_definitions", "steps.js"), `const { Given, When, Then, defineParameterType } = require('@cucumber/cucumber');
defineParameterType({ name: 'person', regexp: /Alice|Bob/ });
Given('shared background', () => {});
Given('rule background', () => {});
Then('domain rule step', () => {});
When('{person} signs in', () => {});
When('Bob signs in', () => {});
Then(/^checked (Alice|Bob)$/, () => {});
Then('excluded step', () => {});
Then('never used', () => {});
`);
    const { runConfiguration } = await loadConfiguration({
      file: false,
      provided: {
        paths: ["features/**/*.feature"],
        require: ["features/step_definitions/**/*.js"],
        tags: "not @not-ui and not @todo-ui"
      }
    }, { cwd });
    const groups = await report({ cwd, configuration: runConfiguration });
    const patterns = (name) => groups[name].map((item) => item.pattern);
    assert.deepEqual(patterns("browserReachable"), [
      "shared background", "rule background", "{person} signs in", "^checked (Alice|Bob)$"
    ]);
    assert.deepEqual(patterns("outsideBrowserOnly"), [
      "domain rule step", "Bob signs in", "excluded step"
    ]);
    assert.deepEqual(patterns("unreachableByAnyFeature"), ["never used"]);
    assert.equal(groups.browserReachable[0].file, "features/step_definitions/steps.js");
    assert.equal(groups.browserReachable[0].line, 3);
  } finally {
    await fs.rm(cwd, { recursive: true, force: true });
  }
});
