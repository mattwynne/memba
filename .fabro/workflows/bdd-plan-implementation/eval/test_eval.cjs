const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const {parse, scenarios, removeTags, run, featurePath} = require('./double.cjs');
const {grade} = require('./grade.cjs');
const cases = path.join(__dirname, 'cases');
const initial = fs.readFileSync(path.join(cases, 'member_profile.feature'), 'utf8');
const [stale, foundation, blank] = scenarios(parse(initial)).slice(0, 3).map(s => s.name);

function activate(source, name) {
  const tag = scenarios(parse(source)).find(s => s.name === name).tags.find(t => t.name === '@todo');
  const lines = source.split('\n');
  const row = tag.location.line - 1;
  lines[row] = lines[row].replace('@todo', '@wip');
  return lines.join('\n');
}

function evidence(t, order = [foundation, blank, stale]) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'bdd-plan-eval-'));
  t.after(() => fs.rmSync(dir, {recursive: true, force: true}));
  let source = initial;
  order.forEach((name, i) => {
    source = activate(source, name);
    fs.writeFileSync(path.join(dir, `${i + 1}-before.feature`), source);
    const selected = scenarios(parse(source)).find(s => s.name === name);
    source = removeTags(source, selected.tags.filter(t => t.name === '@wip'));
    fs.writeFileSync(path.join(dir, `${i + 1}-after.feature`), source);
  });
  fs.writeFileSync(path.join(dir, 'final.feature'), source);
  fs.writeFileSync(path.join(dir, 'calls.jsonl'), order.map(scenario => JSON.stringify({scenario, code: 'a'.repeat(64)})).join('\n') + '\n');
  fs.copyFileSync(path.join(cases, 'core.patch'), path.join(dir, 'code.patch'));
  const files = JSON.parse(fs.readFileSync(path.join(cases, 'core-files.json')));
  fs.writeFileSync(path.join(dir, 'changed-paths'), [featurePath, ...files].join('\n') + '\n');
  return dir;
}

test('foundation first; either remaining order is acceptable', t => {
  assert.ok(grade(evidence(t)).passed);
  assert.ok(grade(evidence(t, [foundation, stale, blank])).passed);
});
test('following file order fails', t => {
  assert.throws(() => grade(evidence(t, [stale, foundation, blank])), /foundation/);
});
test('finishing after one child fails', t => {
  assert.throws(() => grade(evidence(t, [foundation])), /Every planned scenario/);
});
test('losing earlier feature completion fails', t => {
  const dir = evidence(t);
  fs.copyFileSync(path.join(dir, '1-before.feature'), path.join(dir, '2-before.feature'));
  assert.throws(() => grade(dir), /Unexpected tags/);
});
test('lost code, unrelated edits, or weakened assertions fail', t => {
  let dir = evidence(t);
  fs.writeFileSync(path.join(dir, 'code.patch'), '');
  assert.throws(() => grade(dir), /prepared code/);
  dir = evidence(t);
  fs.appendFileSync(path.join(dir, 'changed-paths'), 'docs/iterations/README.md\n');
  assert.throws(() => grade(dir), /unrelated files/);
  dir = evidence(t);
  const file = path.join(dir, 'final.feature');
  fs.writeFileSync(file, fs.readFileSync(file, 'utf8').replace('Then Alice should be known as', 'Then Alice might be known as'));
  assert.throws(() => grade(dir), /wording and assertions/);
});
test('activating unrelated future work fails', t => {
  const dir = evidence(t), file = path.join(dir, 'final.feature');
  fs.writeFileSync(file, activate(fs.readFileSync(file, 'utf8'), 'Alice adds a photo'));
  assert.throws(() => grade(dir), /Unexpected tags/);
});
test('double applies prepared code once and preserves both completed scenarios', t => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'bdd-plan-double-'));
  t.after(() => fs.rmSync(root, {recursive: true, force: true}));
  const fixture = path.join(root, 'fixture');
  fs.mkdirSync(fixture);
  fs.mkdirSync(path.dirname(path.join(root, featurePath)), {recursive: true});
  fs.writeFileSync(path.join(fixture, 'core.patch'), 'diff --git a/web/lib/prepared.ex b/web/lib/prepared.ex\nnew file mode 100644\n--- /dev/null\n+++ b/web/lib/prepared.ex\n@@ -0,0 +1 @@\n+prepared\n');
  fs.writeFileSync(path.join(fixture, 'core-files.json'), '["web/lib/prepared.ex"]');
  execFileSync('git', ['init', '-q'], {cwd: root});
  fs.writeFileSync(path.join(root, featurePath), activate(initial, foundation));
  run(root, fixture);
  const first = fs.readFileSync(path.join(root, featurePath), 'utf8');
  fs.writeFileSync(path.join(root, featurePath), activate(first, blank));
  run(root, fixture);
  const calls = fs.readFileSync(path.join(root, '.fabro/tmp/bdd-plan/eval/calls.jsonl'), 'utf8').trim().split('\n').map(JSON.parse);
  assert.deepEqual(calls.map(c => c.scenario), [foundation, blank]);
  assert.equal(calls[0].code, calls[1].code);
  assert.equal(fs.readFileSync(path.join(root, 'web/lib/prepared.ex'), 'utf8'), 'prepared\n');
});
