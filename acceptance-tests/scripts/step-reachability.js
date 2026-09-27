#!/usr/bin/env node
"use strict";

const path = require("node:path");
const { Writable } = require("node:stream");
const { loadConfiguration, runCucumber } = require("@cucumber/cucumber/api");

// Cucumber emits the compiled Gherkin pickles and its *own* step match IDs in
// testCase envelopes. Do not reimplement tag inheritance, outline expansion or
// Cucumber Expression / RegExp matching here.
async function collect(configuration, cwd, support) {
  const definitions = new Map();
  const reached = new Set();
  const sink = new Writable({ write(_chunk, _encoding, done) { done(); } });
  const result = await runCucumber(
    {
      ...configuration,
      support: support || configuration.support,
      runtime: { ...configuration.runtime, dryRun: true },
      formats: { ...configuration.formats, stdout: "progress", files: {}, publish: false }
    },
    { cwd, stdout: sink, stderr: sink },
    (envelope) => {
      if (envelope.stepDefinition) {
        definitions.set(envelope.stepDefinition.id, envelope.stepDefinition);
      }
      if (envelope.testCase) {
        for (const step of envelope.testCase.testSteps) {
          for (const id of step.stepDefinitionIds || []) reached.add(id);
        }
      }
    }
  );
  if (!result.success) {
    throw new Error("Cucumber dry run failed; cannot make a complete reachability report");
  }
  return { definitions, reached, support: result.support };
}

async function report({ cwd = path.resolve(__dirname, ".."), configuration } = {}) {
  const config = configuration || (await loadConfiguration({}, { cwd })).runConfiguration;
  // An empty tag expression selects *all* feature pickles. The second run uses
  // the project's default browser tag expression, with the same support library.
  const all = await collect({ ...config, sources: { ...config.sources, tagExpression: "" } }, cwd);
  const browser = await collect(config, cwd, all.support);
  if (all.definitions.size !== browser.definitions.size ||
      [...all.definitions.keys()].some((id) => !browser.definitions.has(id))) {
    throw new Error("Step registrations changed between dry runs; report is unsafe");
  }
  const groups = { browserReachable: [], outsideBrowserOnly: [], unreachableByAnyFeature: [] };
  for (const [id, definition] of all.definitions) {
    const ref = definition.sourceReference;
    const entry = {
      file: ref.uri,
      line: ref.location.line,
      pattern: definition.pattern.source,
      type: definition.pattern.type
    };
    const group = browser.reached.has(id) ? "browserReachable" :
      all.reached.has(id) ? "outsideBrowserOnly" : "unreachableByAnyFeature";
    groups[group].push(entry);
  }
  for (const entries of Object.values(groups)) {
    entries.sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line);
  }
  return groups;
}

if (require.main === module) {
  report().then((groups) => {
    console.log(JSON.stringify({
      note: "Feature-step reachability only. Imports by tests/support and direct helper calls are NOT analyzed; do not delete definitions or helpers solely from this report.",
      groups
    }, null, 2));
  }).catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

module.exports = { report };
