// Host-side scoring. The navigator is not given these answers.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {parse, scenarios, featurePath} = require('./double.cjs');
const cases = path.join(__dirname, 'cases');
const foundation = "Alice's corrected name appears across clubs and on earlier contributions";
const names = s => s.tags.map(t => t.name).sort();
const body = source => JSON.stringify(parse(source), (key, value) => ['id', 'location', 'tags'].includes(key) ? undefined : value);

function grade(dir) {
  const initial = fs.readFileSync(path.join(cases, 'member_profile.feature'), 'utf8');
  const original = scenarios(parse(initial));
  const planned = original.filter(s => names(s).includes('@iteration-068')).map(s => s.name);
  const read = name => fs.readFileSync(path.join(dir, name), 'utf8');
  const calls = read('calls.jsonl').trim().split('\n').map(JSON.parse);
  assert.equal(calls.length, planned.length, 'Every planned scenario must call the child');
  assert.equal(calls[0].scenario, foundation, 'Start with the useful foundation, not file order');
  assert.deepEqual(calls.map(c => c.scenario).sort(), planned.sort(), 'Exactly one child per scenario');
  const completed = new Set();
  function check(source, current = null) {
    assert.equal(body(source), body(initial), 'Preserve scenario wording and assertions');
    const actual = scenarios(parse(source));
    original.forEach((s, i) => {
      const expected = names(s).filter(t => t !== '@todo' || (!completed.has(s.name) && s.name !== current));
      if (s.name === current) expected.push('@wip');
      assert.deepEqual(names(actual[i]), expected.sort(), `Unexpected tags: ${s.name}`);
    });
  }
  calls.forEach((call, i) => {
    check(read(`${i + 1}-before.feature`), call.scenario);
    completed.add(call.scenario);
    check(read(`${i + 1}-after.feature`));
    assert.match(call.code, /^[a-f0-9]{64}$/);
    assert.equal(call.code, calls[0].code, 'Keep the earlier prepared implementation');
  });
  check(read('final.feature'));
  assert.equal(read('code.patch'), fs.readFileSync(path.join(cases, 'core.patch'), 'utf8'), 'Keep all prepared code through completion');
  const files = JSON.parse(fs.readFileSync(path.join(cases, 'core-files.json'), 'utf8'));
  assert.deepEqual(read('changed-paths').trim().split('\n').sort(), [featurePath, ...files].sort(), 'Do not change unrelated files');
  return {passed: true, order: calls.map(c => c.scenario)};
}

module.exports = {grade};
if (require.main === module) {
  try { console.log(JSON.stringify(grade(process.argv[2]))); }
  catch (error) { console.log(JSON.stringify({passed: false, error: error.message})); process.exitCode = 1; }
}
