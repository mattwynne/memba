// Test double only: no application tests or model calls.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {execFileSync} = require('node:child_process');
const {createHash} = require('node:crypto');
const {AstBuilder, GherkinClassicTokenMatcher, Parser} = require('../../../../acceptance-tests/node_modules/@cucumber/gherkin');
const featurePath = 'acceptance-tests/features/member_profile.feature';

function parse(source) {
  let id = 0;
  return new Parser(new AstBuilder(() => String(id++)), new GherkinClassicTokenMatcher()).parse(source).feature;
}

function scenarios(feature, inherited = []) {
  const tags = [...inherited, ...(feature.tags || [])];
  return feature.children.flatMap(child => child.rule
    ? scenarios(child.rule, tags)
    : child.scenario ? [{...child.scenario, tags: [...tags, ...child.scenario.tags]}] : []);
}

function removeTags(source, tags) {
  const lines = source.split('\n');
  for (const tag of [...tags].sort((a, b) => b.location.column - a.location.column)) {
    const row = tag.location.line - 1, col = tag.location.column - 1;
    lines[row] = (lines[row].slice(0, col) + lines[row].slice(col + tag.name.length)).trimEnd();
  }
  return lines.join('\n');
}

function run(root = process.cwd(), fixture = path.join(__dirname, 'cases')) {
  const file = path.join(root, featurePath);
  const before = fs.readFileSync(file, 'utf8');
  const selected = scenarios(parse(before)).filter(s => s.tags.some(t => t.name === '@wip'));
  assert.equal(selected.length, 1, 'The child requires exactly one WIP scenario');
  const scenario = selected[0];
  assert.ok(!scenario.tags.some(t => ['@todo', '@journey'].includes(t.name)), 'WIP must be an active domain scenario');
  const evidence = path.join(root, '.fabro/tmp/bdd-plan/eval');
  fs.mkdirSync(evidence, {recursive: true});
  const callsFile = path.join(evidence, 'calls.jsonl');
  const calls = fs.existsSync(callsFile) ? fs.readFileSync(callsFile, 'utf8').trim().split('\n').map(JSON.parse) : [];
  const n = calls.length + 1;
  fs.writeFileSync(path.join(evidence, `${n}-before.feature`), before);
  // A shared prepared implementation, not a claim about real driver granularity.
  if (!calls.length) execFileSync('git', ['apply', path.join(fixture, 'core.patch')], {cwd: root});
  const files = JSON.parse(fs.readFileSync(path.join(fixture, 'core-files.json'), 'utf8'));
  const hash = createHash('sha256');
  for (const name of files) hash.update(name).update(fs.readFileSync(path.join(root, name)));
  const after = removeTags(before, scenario.tags.filter(t => t.name === '@wip'));
  fs.writeFileSync(file, after);
  fs.writeFileSync(path.join(evidence, `${n}-after.feature`), after);
  fs.appendFileSync(callsFile, JSON.stringify({scenario: scenario.name, code: hash.digest('hex')}) + '\n');
  const scratch = path.join(root, '.fabro/tmp/bdd');
  fs.mkdirSync(scratch, {recursive: true});
  fs.writeFileSync(path.join(scratch, 'result.md'), `TEST DOUBLE: ${scenario.name}\nPrepared completion supplied; WIP removed. No application tests were run.\n`);
  console.log(`Test-double child completed: ${scenario.name}`);
}

module.exports = {parse, scenarios, removeTags, run, featurePath};
if (require.main === module) run();
