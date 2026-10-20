const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {execFileSync, spawnSync} = require('node:child_process');
const {inspect, fromCommit, activeStatuses, iterations} = require('../pending.cjs');
const helper = path.resolve(__dirname, '../pending.cjs');
const index = `| # | Date | Status | Title | Plan |
| 067 | today | merged | Previous | [plan](067-previous/plan.md) |
| 068 | today | implementing | Current | [plan](068-current/plan.md) |
| 069 | today | needs-revision | Future | [plan](069-future/plan.md) |
`;
const feature = source => [{file: 'acceptance-tests/features/example.feature', source}];
const example = (tags, name = 'Example') => `${tags}\nFeature: Feature\n  Scenario: ${name}\n    Given something\n`;

test('current domain TODO chooses; no TODO finishes only the domain loop', () => {
  const pending = inspect(index, feature(example('@iteration-068 @todo')));
  assert.equal(pending.preferred_next_label, 'choose');
  assert.equal(pending.plan, 'docs/iterations/068-current/plan.md');
  assert.equal(pending.pending[0].scenario, 'Example');
  const done = inspect(index, feature(example('@iteration-068')));
  assert.equal(done.preferred_next_label, 'done');
  assert.equal(done.domain_complete, true);
  assert.equal(index.includes('| implementing |'), true); // No metadata edits.
});
test('future TODO is allowed and does not keep current domain work open', () => {
  const result = inspect(index, feature(example('@iteration-069 @todo')));
  assert.equal(result.preferred_next_label, 'done');
  assert.deepEqual(result.pending, []);
});
test('TODO for a merged iteration is an error, including browser journeys', () => {
  for (const tags of ['@iteration-067 @todo', '@iteration-067 @journey @todo']) {
    assert.throws(() => inspect(index, feature(example(tags, 'Left behind'))), /example.feature:3: Left behind: dangling @todo for merged iteration 67/);
  }
});
test('current journeys are reported but do not trigger domain implementation', () => {
  const result = inspect(index, feature(example('@iteration-068 @journey @todo')));
  assert.equal(result.preferred_next_label, 'done');
  assert.equal(result.pending_journeys.length, 1);
  assert.equal(result.pending_journeys[0].scenario, 'Example');
});
test('WIP prevents completion, with or without TODO or journey tags', () => {
  for (const tags of ['@iteration-068 @wip', '@iteration-068 @todo @wip', '@iteration-068 @journey @wip', '@iteration-069 @wip']) {
    assert.throws(() => inspect(index, feature(example(tags))), /WIP prevents completion/);
  }
});
test('feature, rule, scenario and Examples tags are inherited', () => {
  const result = inspect(index, feature(`@iteration-068
Feature: Inheritance
  @todo
  Rule: Pending rules
    Scenario: Rule example
      Given something
  Rule: Other rules
    @todo
    Scenario: Scenario example
      Given something
    Scenario Outline: Outline example
      Given <thing>
      @todo
      Examples:
        | thing |
        | one   |
`));
  assert.deepEqual(result.pending.map(s => s.scenario), ['Rule example', 'Scenario example', 'Outline example']);
});
test('inherited TODO on a completed iteration is not silently filtered', () => {
  const result = `@todo @iteration-067
Feature: Inherited pending work
  Rule: Rule
    Scenario: Still pending
      Given something
`;
  assert.throws(() => inspect(index, feature(result)), /Still pending: dangling @todo/);
});
test('untagged, unknown or ambiguous unfinished iteration ownership errors', () => {
  for (const tags of ['@todo', '@wip', '@iteration-999 @todo', '@iteration-067 @iteration-069 @todo']) {
    assert.throws(() => inspect(index, feature(example(tags))), /iteration tag|absent from the index/);
  }
});
test('zero or multiple active iterations never mean done', () => {
  assert.throws(() => inspect(index.replace('implementing', 'ready'), feature(example('@iteration-068'))), /found 0/);
  assert.throws(() => inspect(index.replace('needs-revision', 'implementing'), feature(example('@iteration-068'))), /found 2/);
});
test('bad index, duplicate entries and malformed Gherkin never mean done', () => {
  assert.throws(() => inspect('not an iteration index', feature(example('@iteration-068'))), /No iterations found/);
  assert.throws(() => inspect(index + index.split('\n')[2] + '\n', feature(example('@iteration-068'))), /Duplicate iteration/);
  assert.throws(() => inspect(index, feature('not Gherkin')), /example.feature/);
});
test('active status vocabulary matches the existing lifecycle helper', () => {
  const old = path.resolve(__dirname, '../../scripts/iteration_status.py');
  const actual = JSON.parse(execFileSync('python3', ['-c', 'import runpy,json,sys; m=runpy.run_path(sys.argv[1]); print(json.dumps({"active":sorted(m["ACTIVE_STATUSES"]),"merged":m["MERGED_STATUS"]}))', old], {encoding: 'utf8'}));
  assert.deepEqual([...activeStatuses].sort(), actual.active);
  assert.equal(actual.merged, 'merged');
  assert.equal(iterations(index)[0].status, actual.merged);
});
test('CLI reads the requested immutable commit, validates plan existence and fails nonzero', t => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'pending-scenarios-'));
  t.after(() => fs.rmSync(root, {recursive: true, force: true}));
  const put = (name, body) => { const file = path.join(root, name); fs.mkdirSync(path.dirname(file), {recursive: true}); fs.writeFileSync(file, body); };
  const git = (...args) => execFileSync('git', args, {cwd: root, encoding: 'utf8'}).trim();
  git('init', '-q');
  put('docs/iterations/README.md', index);
  put('docs/iterations/068-current/plan.md', 'Status: implementing\n');
  put('acceptance-tests/features/example.feature', example('@iteration-068'));
  git('add', '.');
  git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Snapshot');
  const commit = git('rev-parse', 'HEAD');
  put('acceptance-tests/features/example.feature', example('@iteration-067 @todo'));
  const before = git('diff');
  assert.equal(fromCommit(commit, root).preferred_next_label, 'done');
  assert.equal(git('diff'), before);
  const bad = spawnSync('node', [helper, 'not-a-commit'], {cwd: root, encoding: 'utf8'});
  assert.notEqual(bad.status, 0);
  assert.equal(bad.stdout, '');
  git('rm', 'docs/iterations/068-current/plan.md');
  put('acceptance-tests/features/example.feature', example('@iteration-068'));
  git('add', '.');
  git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Broken snapshot');
  const result = spawnSync('node', [helper, 'HEAD'], {cwd: root, encoding: 'utf8'});
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /068-current\/plan.md/);
});
