const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const {parse, scenarios, complete, featurePath} = require('./double.cjs');
const {grade} = require('./grade.cjs');
const initial = fs.readFileSync(path.join(__dirname, 'cases/member_profile.feature'), 'utf8');
const [stale, foundation, blank] = scenarios(parse(initial)).slice(0, 3).map(s => s.name);
const tagNames = source => scenarios(parse(source)).map(s => s.tags.map(t => t.name));

function changeTag(source, name, from, to) {
  const tag = scenarios(parse(source)).find(s => s.name === name).tags.find(t => t.name === from);
  const lines = source.split('\n'), row = tag.location.line - 1;
  lines[row] = lines[row].replace(from, to).trimEnd();
  return lines.join('\n');
}
function temporary(t) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'bdd-plan-eval-'));
  t.after(() => fs.rmSync(dir, {recursive: true, force: true}));
  return dir;
}
function evidence(t, order = [foundation, blank, stale]) {
  const dir = temporary(t), calls = [];
  let source = initial;
  for (const scenario of order) {
    source = changeTag(source, scenario, '@todo', '@wip');
    calls.push({scenario, tags: tagNames(source)});
    source = changeTag(source, scenario, '@wip', '');
  }
  fs.writeFileSync(path.join(dir, 'calls.jsonl'), calls.map(JSON.stringify).join('\n') + '\n');
  fs.writeFileSync(path.join(dir, 'final.feature'), source);
  const featureDiff = `diff --git a/${featurePath} b/${featurePath}\n@@ -6 +6 @@\n-    @iteration-068 @todo\n+    @iteration-068\n`;
  fs.writeFileSync(path.join(dir, 'final.patch'), featureDiff + fs.readFileSync(path.join(__dirname, 'cases/core.patch'), 'utf8'));
  fs.writeFileSync(path.join(dir, 'events.jsonl'), order.map(() => JSON.stringify({event: 'stage.completed', node_id: 'scenario.completed', properties: {status: 'succeeded'}})).join('\n') + '\n');
  return dir;
}
const check = dir => grade(dir, path.join(dir, 'events.jsonl'));

test('foundation first; either remaining order is accepted', t => {
  assert.ok(check(evidence(t)).passed);
  assert.ok(check(evidence(t, [foundation, stale, blank])).passed);
});
test('file order and early completion still fail', t => {
  assert.throws(() => check(evidence(t, [stale, foundation, blank])), /predeclared foundation/);
  assert.throws(() => check(evidence(t, [foundation])), /imported workflow/);
});
test('child records alone cannot substitute for imported workflow completion', t => {
  const dir = evidence(t);
  fs.writeFileSync(path.join(dir, 'events.jsonl'), '{}\n');
  assert.throws(() => check(dir), /imported workflow/);
});
test('lost earlier tags or prematurely activated future work fail', t => {
  for (const index of [1, 3]) {
    const dir = evidence(t), file = path.join(dir, 'calls.jsonl');
    const calls = fs.readFileSync(file, 'utf8').trim().split('\n').map(JSON.parse);
    calls[1].tags[index].push('@wip');
    fs.writeFileSync(file, calls.map(JSON.stringify).join('\n') + '\n');
    assert.throws(() => check(dir), /keep earlier results/);
  }
});
test('lost code, unrelated edits and weakened assertions fail', t => {
  for (const [name, mutate, expected] of [
    ['final.patch', () => '', /prepared code/],
    ['final.patch', s => s + 'diff --git a/unrelated b/unrelated\n+change\n', /unrelated/],
    ['final.feature', s => s.replace('Then Alice should be known as', 'Then Alice might be known as'), /assertions/]
  ]) {
    const dir = evidence(t), file = path.join(dir, name);
    fs.writeFileSync(file, mutate(fs.readFileSync(file, 'utf8')));
    assert.throws(() => check(dir), expected);
  }
});
test('double applies supplied code once, records tags and requires one WIP', t => {
  const root = temporary(t), file = path.join(root, featurePath);
  fs.mkdirSync(path.dirname(file), {recursive: true});
  execFileSync('git', ['init', '-q'], {cwd: root});
  const patch = 'diff --git a/prepared b/prepared\nnew file mode 100644\n--- /dev/null\n+++ b/prepared\n@@ -0,0 +1 @@\n+result\n';
  let source = initial;
  for (const name of [foundation, blank]) {
    fs.writeFileSync(file, changeTag(source, name, '@todo', '@wip'));
    complete(patch, root);
    source = fs.readFileSync(file, 'utf8');
  }
  const calls = fs.readFileSync(path.join(root, '.fabro/tmp/bdd-plan/eval/calls.jsonl'), 'utf8').trim().split('\n').map(JSON.parse);
  assert.deepEqual(calls.map(c => c.scenario), [foundation, blank]);
  assert.equal(fs.readFileSync(path.join(root, 'prepared'), 'utf8'), 'result\n');
  assert.throws(() => complete(patch, root), /exactly one WIP/);
  fs.writeFileSync(file, changeTag(changeTag(initial, blank, '@todo', '@wip'), foundation, '@todo', '@wip'));
  assert.throws(() => complete(patch, root), /exactly one WIP/);
});
