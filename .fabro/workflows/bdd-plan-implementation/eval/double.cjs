// Supplied to the child at execution time, never copied into its starting checkout.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {execFileSync} = require('node:child_process');
const {AstBuilder, GherkinClassicTokenMatcher, Parser} = require(process.cwd() + '/acceptance-tests/node_modules/@cucumber/gherkin');
const featurePath = 'acceptance-tests/features/member_profile.feature';

function parse(source) {
  let id = 0;
  return new Parser(new AstBuilder(() => String(id++)), new GherkinClassicTokenMatcher()).parse(source).feature;
}

function scenarios(feature, inherited = []) {
  const tags = [...inherited, ...(feature.tags || [])];
  return feature.children.flatMap(child => child.rule ? scenarios(child.rule, tags)
    : child.scenario ? [{...child.scenario, tags: [...tags, ...child.scenario.tags]}] : []);
}

function complete(patch, root = process.cwd()) {
  const file = path.join(root, featurePath), source = fs.readFileSync(file, 'utf8');
  const all = scenarios(parse(source));
  const selected = all.filter(s => s.tags.some(t => t.name === '@wip'));
  assert.equal(selected.length, 1, 'The child requires exactly one WIP scenario');
  const scenario = selected[0];
  assert.ok(!scenario.tags.some(t => ['@todo', '@journey'].includes(t.name)), 'WIP must be an active domain scenario');
  const scratch = path.join(root, '.fabro/tmp/bdd');
  const evidence = path.join(root, '.fabro/tmp/bdd-plan/eval');
  fs.mkdirSync(scratch, {recursive: true});
  fs.mkdirSync(evidence, {recursive: true});
  const log = path.join(evidence, 'calls.jsonl');
  if (!fs.existsSync(log)) execFileSync('git', ['apply', '-'], {cwd: root, input: patch});
  const tag = scenario.tags.find(t => t.name === '@wip');
  const lines = source.split('\n'), row = tag.location.line - 1, col = tag.location.column - 1;
  lines[row] = (lines[row].slice(0, col) + lines[row].slice(col + tag.name.length)).trimEnd();
  fs.writeFileSync(file, lines.join('\n'));
  fs.appendFileSync(log, JSON.stringify({scenario: scenario.name, tags: all.map(s => s.tags.map(t => t.name))}) + '\n');
  fs.writeFileSync(path.join(scratch, 'result.md'), `TEST DOUBLE: completed ${scenario.name}. WIP removed; no application tests run.\n`);
  console.log(`Test-double child completed: ${scenario.name}`);
}

module.exports = {parse, scenarios, complete, featurePath};
