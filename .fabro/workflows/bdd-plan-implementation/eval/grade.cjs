// One host-side checker; no grading answers are sent to the navigator.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {parse, scenarios, featurePath} = require('./double.cjs');
const cases = path.join(__dirname, 'cases');
const foundation = "Alice's corrected name appears across clubs and on earlier contributions";
const tags = s => s.tags.map(t => t.name).sort();
const body = source => JSON.stringify(parse(source), (key, value) => ['id', 'location', 'tags'].includes(key) ? undefined : value);

function grade(dir, eventsFile) {
  const read = name => fs.readFileSync(path.join(dir, name), 'utf8');
  const initial = fs.readFileSync(path.join(cases, 'member_profile.feature'), 'utf8');
  const original = scenarios(parse(initial));
  const planned = original.filter(s => tags(s).includes('@iteration-068')).map(s => s.name);
  const calls = read('calls.jsonl').trim().split('\n').map(JSON.parse);
  const events = fs.readFileSync(eventsFile, 'utf8').trim().split('\n').map(JSON.parse);
  const children = events.filter(e => e.event === 'stage.completed' && e.node_id === 'scenario' && e.properties.status === 'succeeded');
  assert.equal(children.length, planned.length, 'Every scenario must complete a native child');
  assert.deepEqual(calls.map(c => c.scenario).sort(), planned.sort(), 'Exactly one child per scenario');
  assert.equal(calls[0].scenario, foundation, 'Start with the predeclared foundation');
  const completed = new Set();
  function check(actual, current = null) {
    const expected = original.map(s => {
      const result = tags(s).filter(t => t !== '@todo' || (!completed.has(s.name) && s.name !== current));
      if (s.name === current) result.push('@wip');
      return result.sort();
    });
    assert.deepEqual(actual.map(ts => [...ts].sort()), expected, 'Only the chosen scenario changes tags; keep earlier results');
  }
  for (const call of calls) {
    check(call.tags, call.scenario);
    completed.add(call.scenario);
  }
  const final = read('final.feature');
  assert.equal(body(final), body(initial), 'Preserve scenario wording and assertions');
  check(scenarios(parse(final)).map(tags));
  const featureHeader = `diff --git a/${featurePath} b/${featurePath}\n`;
  const otherChanges = read('final.patch').split(/(?=^diff --git )/m).filter(part => !part.startsWith(featureHeader)).join('');
  assert.equal(otherChanges, fs.readFileSync(path.join(cases, 'core.patch'), 'utf8'), 'Keep prepared code and change no unrelated files');
  return {passed: true, order: calls.map(c => c.scenario)};
}

module.exports = {grade};
if (require.main === module) {
  try { console.log(JSON.stringify(grade(process.argv[2], process.argv[3]))); }
  catch (error) { console.log(JSON.stringify({passed: false, error: error.message})); process.exitCode = 1; }
}
