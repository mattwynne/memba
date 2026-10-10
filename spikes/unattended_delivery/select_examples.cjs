// Trusted admission utility: real Gherkin pickles include inherited tags/outline rows.
// Usage: node select_examples.cjs RUNTIME_SOURCE JSON_SELECTORS
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(process.argv[2]);
const { generateMessages } = require(path.join(root, 'acceptance-tests/node_modules/@cucumber/gherkin'));
const { IdGenerator, SourceMediaType } = require(path.join(root, 'acceptance-tests/node_modules/@cucumber/messages'));
const selections = JSON.parse(process.argv[3]);
const result = selections.map(({ uri, name, line }) => {
  const file = path.resolve(root, 'acceptance-tests', uri);
  if (!file.startsWith(path.join(root, 'acceptance-tests/features') + path.sep)) throw Error('Unsafe feature path');
  const source = fs.readFileSync(file, 'utf8');
  const messages = generateMessages(source, uri, SourceMediaType.TEXT_X_CUCUMBER_GHERKIN_PLAIN,
    { newId: IdGenerator.incrementing(), includePickles: true, includeGherkinDocument: true });
  if (messages.some(m => m.parseError)) throw Error('Invalid Gherkin');
  const pickles = messages.filter(m => m.pickle).map(m => m.pickle);
  const matches = pickles.filter(p => p.name === name && (!line || p.location.line === line));
  if (matches.length !== 1) throw Error(`Expected exactly one pickle for ${uri}/${name}; found ${matches.length}`);
  const pickle = matches[0];
  const tags = pickle.tags.map(t => t.name);
  if (tags.includes('@todo')) throw Error('Future @todo example is not admitted for baseline rehearsal');
  const kind = tags.includes('@journey') ? 'browser' : 'domain';
  if (kind === 'domain' && pickles.filter(p => p.name === name).length !== 1)
    throw Error('Domain row name is ambiguous; current ExUnit name filter cannot isolate this outline row');
  return { id: `${uri}:${pickle.location.line}`, uri, name, line: pickle.location.line,
    kind, tags, file_sha256: crypto.createHash('sha256').update(source).digest('hex') };
});
if (new Set(result.map(p => p.id)).size !== result.length) throw Error('Duplicate selected example');
console.log(JSON.stringify(result));
