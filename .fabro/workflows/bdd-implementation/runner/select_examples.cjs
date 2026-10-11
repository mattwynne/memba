// Trusted admission: real Gherkin pickles, inherited tags and exact file hashes.
// Usage: node select_examples.cjs SOURCE JSON_SELECTORS
//        node select_examples.cjs SOURCE --discover iteration-068
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(process.argv[2]);
const features = path.join(root, 'acceptance-tests/features');
const {generateMessages} = require(path.join(root, 'acceptance-tests/node_modules/@cucumber/gherkin'));
const {IdGenerator, SourceMediaType} = require(path.join(root, 'acceptance-tests/node_modules/@cucumber/messages'));
function load(uri) {
  const file = path.resolve(root, 'acceptance-tests', uri);
  if (!file.startsWith(features + path.sep)) throw Error('Unsafe feature path');
  const source = fs.readFileSync(file, 'utf8');
  const messages = generateMessages(source, uri, SourceMediaType.TEXT_X_CUCUMBER_GHERKIN_PLAIN,
    {newId: IdGenerator.incrementing(), includePickles: true, includeGherkinDocument: true});
  if (messages.some(m => m.parseError)) throw Error('Invalid Gherkin');
  return {source, pickles: messages.filter(m => m.pickle).map(m => m.pickle)};
}
function describe(uri, source, pickle) {
  const tags = pickle.tags.map(t => t.name);
  return {id: `${uri}:${pickle.location.line}`, uri, name: pickle.name, line: pickle.location.line,
    kind: tags.includes('@journey') ? 'browser' : 'domain', tags,
    file_sha256: crypto.createHash('sha256').update(source).digest('hex')};
}
function files(dir) {
  return fs.readdirSync(dir, {withFileTypes: true}).sort((a, b) => a.name.localeCompare(b.name))
    .flatMap(e => e.isDirectory() ? files(path.join(dir, e.name)) : e.name.endsWith('.feature') ? [path.join(dir, e.name)] : []);
}
let result;
if (process.argv[3] === '--discover') {
  const tag = process.argv[4];
  if (!/^iteration-\d{3}[A-Z]?$/.test(tag)) throw Error('Exact iteration tag required');
  result = files(features).flatMap(file => {
    const uri = path.relative(path.join(root, 'acceptance-tests'), file);
    const {source, pickles} = load(uri);
    return pickles.filter(p => p.tags.some(t => t.name === '@' + tag)).map(p => describe(uri, source, p));
  });
  if (!result.length) throw Error('No approved iteration examples discovered');
} else {
  const selections = JSON.parse(process.argv[3]);
  result = selections.map(({uri, name, line}) => {
    const {source, pickles} = load(uri);
    const matches = pickles.filter(p => p.name === name && (!line || p.location.line === line));
    if (matches.length !== 1) throw Error(`Expected exactly one pickle for ${uri}/${name}; found ${matches.length}`);
    const described = describe(uri, source, matches[0]);
    if (described.tags.includes('@todo')) throw Error('Future @todo example is not admitted');
    if (described.kind === 'domain' && pickles.filter(p => p.name === name).length !== 1)
      throw Error('Domain row name is ambiguous; the ExUnit name filter cannot isolate this outline row');
    return described;
  });
}
if (new Set(result.map(p => p.id)).size !== result.length) throw Error('Duplicate selected example');
console.log(JSON.stringify(result));
