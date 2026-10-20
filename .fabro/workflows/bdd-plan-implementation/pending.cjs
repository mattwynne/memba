#!/usr/bin/env node
// Read-only status check. "done" means this domain loop, never iteration publication.
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const {Parser, AstBuilder, GherkinClassicTokenMatcher} = require('../../../acceptance-tests/node_modules/@cucumber/gherkin');

// Keep the index's WIP convention aligned with scripts/iteration_status.py.
const activeStatuses = new Set(['implementing', 'ready-for-review', 'in-review', 'reviewing', 'finalizing']);

function iterations(source) {
  const rows = [];
  for (const line of source.split('\n')) {
    if (!line.startsWith('|') || !line.includes('[plan](')) continue;
    const cells = line.trim().slice(1, -1).split('|').map(cell => cell.trim());
    const link = cells[4]?.match(/\[plan\]\(([^)]+)\)/);
    if (!/^\d+$/.test(cells[0]) || !cells[2] || !link) throw new Error(`Invalid iteration row: ${line}`);
    const number = Number(cells[0]);
    if (rows.some(row => row.number === number)) throw new Error(`Duplicate iteration ${cells[0]}`);
    rows.push({number, status: cells[2].toLowerCase(), plan: path.posix.join('docs/iterations', link[1])});
  }
  if (!rows.length) throw new Error('No iterations found in docs/iterations/README.md');
  return rows;
}

function scenarios(source, file) {
  let id = 0;
  const parser = new Parser(new AstBuilder(() => String(id++)), new GherkinClassicTokenMatcher());
  let feature;
  try { feature = parser.parse(source).feature; }
  catch (error) { throw new Error(`${file}: ${error.message}`); }
  if (!feature) throw new Error(`${file}: no Feature found`);
  function walk(container, inherited) {
    const tags = [...inherited, ...(container.tags || []).map(tag => tag.name)];
    return container.children.flatMap(child => {
      if (child.rule) return walk(child.rule, tags);
      if (!child.scenario) return [];
      const scenario = child.scenario;
      const own = [...tags, ...scenario.tags.map(tag => tag.name)];
      const groups = scenario.examples.length ? scenario.examples : [null];
      return groups.map(examples => ({
        feature: file, scenario: scenario.name,
        line: examples?.location.line || scenario.location.line,
        tags: [...new Set([...own, ...(examples?.tags || []).map(tag => tag.name)])]
      }));
    });
  }
  return walk(feature, []);
}

function inspect(index, features) {
  const rows = iterations(index);
  const unfinished = features.flatMap(({file, source}) => scenarios(source, file))
    .filter(scenario => scenario.tags.includes('@todo') || scenario.tags.includes('@wip'));
  for (const scenario of unfinished) {
    const label = `${scenario.feature}:${scenario.line}: ${scenario.scenario}`;
    const numbers = [...new Set(scenario.tags.filter(tag => /^@iteration-\d+$/.test(tag)).map(tag => Number(tag.slice(11))))];
    // Historical multi-iteration tags need an explicit owner; never guess completion.
    if (numbers.length !== 1) throw new Error(`${label}: expected one iteration tag, got ${scenario.tags.join(' ')}`);
    scenario.iteration = numbers[0];
    const row = rows.find(row => row.number === scenario.iteration);
    if (!row) throw new Error(`${label}: iteration ${scenario.iteration} is absent from the index`);
    if (row.status === 'merged' && scenario.tags.includes('@todo')) {
      throw new Error(`${label}: dangling @todo for merged iteration ${scenario.iteration}`);
    }
  }
  const active = rows.filter(row => activeStatuses.has(row.status));
  if (active.length !== 1) throw new Error(`Expected one active iteration, found ${active.length}`);
  const wip = unfinished.filter(scenario => scenario.tags.includes('@wip'));
  if (wip.length) throw new Error(`WIP prevents completion: ${wip.map(s => `${s.feature}:${s.line}: ${s.scenario}`).join('; ')}`);
  const current = unfinished.filter(scenario => scenario.iteration === active[0].number);
  const pending = current.filter(scenario => scenario.tags.includes('@todo') && !scenario.tags.includes('@journey'));
  const journeys = current.filter(scenario => scenario.tags.includes('@todo') && scenario.tags.includes('@journey'));
  const describe = ({feature, scenario, line}) => ({feature, scenario, line});
  return {
    plan: active[0].plan,
    pending: pending.map(describe),
    pending_journeys: journeys.map(describe),
    domain_complete: pending.length === 0,
    preferred_next_label: pending.length ? 'choose' : 'done'
  };
}

function fromCommit(commit = 'HEAD', cwd = process.cwd()) {
  const git = (...args) => execFileSync('git', args, {cwd, encoding: 'utf8'});
  const sha = git('rev-parse', '--verify', '--end-of-options', `${commit}^{commit}`).trim();
  const read = file => git('show', `${sha}:${file}`);
  const files = git('ls-tree', '-rz', '--name-only', sha, '--', 'acceptance-tests/features')
    .split('\0').filter(file => file.endsWith('.feature'));
  if (!files.length) throw new Error('No acceptance feature files found');
  const result = inspect(read('docs/iterations/README.md'), files.map(file => ({file, source: read(file)})));
  read(result.plan); // A missing plan must not be mistaken for completed work.
  return {commit: sha, ...result};
}

module.exports = {iterations, scenarios, inspect, fromCommit, activeStatuses};
if (require.main === module) {
  try { console.log(JSON.stringify(fromCommit(process.argv[2]))); }
  catch (error) { console.error(error.message); process.exitCode = 1; }
}
