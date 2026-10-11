// OFFLINE actual SDK/session tests. No inference, login, refresh or credential changes.
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {assertModel, Broker, checkRequestBudget, checkpointSession, classifyProviderFailure, digest, openSession, resourceLoader, validateRequest} from './sol_adapter.mjs';
const sdkPath = process.env.WORKFLOW_PI_SDK_ROOT ?? '/home/matt/.local/lib/node_modules/@earendil-works/pi-coding-agent';
const sdk = await import(path.join(sdkPath, 'dist/index.js'));
const runtime = await sdk.ModelRuntime.create({allowModelNetwork: false});
const model = runtime.getModel('openai-codex', 'gpt-6.1-sol');
const config = {provider: model.provider, api: model.api, base_url: model.baseUrl, model_digest: digest(model)};

const withRoot = fn => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'sol-offline-'));
  try {return fn(root);} finally {fs.rmSync(root, {recursive: true});}
};

test('dead owned broker rejects new requests instead of hanging', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'sol-broker-'));
  fs.mkdirSync(path.join(root, 'model-cwd'));
  const broker = new Broker(root, 'offline', () => {});
  try {
    await assert.rejects(broker.request('initialize'), /Owned broker exited/);
    await assert.rejects(broker.request('tools/list'), /Owned broker exited/);
  } finally {await broker.close(); fs.rmSync(root, {recursive: true});}
});

test('already-signalled owned broker closes without waiting for a past exit event', async () => {
  const broker = Object.create(Broker.prototype);
  broker.process = {stdin: {end() {}}, exitCode: null, signalCode: 'SIGTERM',
    once() {throw new Error('must not wait for already emitted exit');}};
  await broker.close();
});

test('exact model/runtime metadata: no fallback to another catalog model', () => {
  assertModel(model, config);
  assert.throws(() => assertModel({...model, id: 'gpt-6-astra'}, config));
  assert.throws(() => assertModel({...model, baseUrl: 'https://other'}, config));
  assert.throws(() => assertModel({...model, cost: {}}, config));
  assert.throws(() => assertModel(undefined, config));
});

test('finite response-observed token/turn budget rejects the next request', () => {
  const config = {max_turns: 8, visit_token_limit: 50000};
  checkRequestBudget(7, 49999, config);
  assert.throws(() => checkRequestBudget(8, 0, config), /budget exhausted/);
  assert.throws(() => checkRequestBudget(0, 50000, config), /budget exhausted/);
});

test('explicit accounting-only policy counts all usage without a token execution stop; request 161 denied', () => {
  const config = {max_turns: 160, token_policy: 'accounting-only'};
  for (let requests = 0; requests < 160; requests++)
    checkRequestBudget(requests, Number.MAX_SAFE_INTEGER, config);
  assert.throws(() => checkRequestBudget(160, 0, config), /request budget exhausted/);
});

test('outgoing native tools/shell/web forbidden and reviewer only inspect', () => {
  const payload = {model: model.id, parallel_tool_calls: true, tools: [{type: 'function', name: 'inspect'}]};
  validateRequest(payload, ['inspect']);
  for (const tool of ['bash', 'read', 'write', 'edit', 'observe'])
    assert.throws(() => validateRequest({...payload, tools: [...payload.tools, {type: 'function', name: tool}]}, ['inspect']));
  assert.throws(() => validateRequest({...payload, model: 'gpt-5.6-sol'}, ['inspect']));
  assert.throws(() => validateRequest({...payload, tools: [{type: 'web_search'}]}, ['inspect']));
});

test('persistent builder restored byte history; reviewer fresh; stale/replacement refused', () => withRoot(root => {
  const contract = {model: model.id, scope: ['fixed']};
  const {manager, identityPath} = openSession(sdk, root, 'builder', 'new', config, contract);
  manager.appendModelChange(model.provider, model.id);
  manager.appendMessage({role: 'user', content: 'unique builder history', timestamp: Date.now()});
  // SessionManager defers the first disk write until an assistant exists.
  manager.appendMessage({role: 'assistant', content: [{type: 'text', text: 'offline double'}],
    provider: model.provider, model: model.id, api: model.api, stopReason: 'stop', timestamp: Date.now(),
    usage: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, cost: {total: 0}}});
  fs.writeFileSync(identityPath, JSON.stringify({id: manager.getSessionId(), file: manager.getSessionFile(),
    contract: digest(contract), provider: model.provider, model: model.id}));
  const resumed = openSession(sdk, root, 'builder', 'resume', config, contract).manager;
  assert.equal(resumed.getSessionId(), manager.getSessionId());
  assert.equal(resumed.buildSessionContext().messages[0].content, 'unique builder history');
  const reviewer = openSession(sdk, root, 'reviewer', 'new', config, contract).manager;
  assert.notEqual(reviewer.getSessionId(), manager.getSessionId());
  assert.deepEqual(reviewer.buildSessionContext().messages, []);
  assert.throws(() => openSession(sdk, root, 'builder', 'new', config, contract));
  assert.throws(() => openSession(sdk, root, 'builder', 'resume', config, {...contract, scope: []}));
}));

test('actual SDK has no builtins/resources, strict custom inspector not host read', async () => {
  const loader = resourceLoader(sdk, 'Only explicit candidate tools.');
  assert.deepEqual(loader.getAgentsFiles(), {agentsFiles: []});
  assert.equal(loader.getExtensions().extensions.length, 0);
  assert.throws(() => loader.extendResources({}));
  const {session} = await sdk.createAgentSession({modelRuntime: runtime, model,
    tools: ['inspect'], noTools: 'builtin', resourceLoader: loader,
    sessionManager: sdk.SessionManager.inMemory(), settingsManager: sdk.SettingsManager.inMemory({
      compaction: {enabled: false}, retry: {enabled: false, provider: {maxRetries: 0}}}),
    customTools: [{name: 'inspect', label: 'inspect', description: 'Confined candidate inspector',
      parameters: {type: 'object', properties: {path: {type: 'string'}}, additionalProperties: false},
      execute: async () => ({content: [{type: 'text', text: 'fixture-only'}], details: {}})}]});
  try {assert.deepEqual(session.agent.state.tools.map(t => t.name), ['inspect']);}
  finally {session.dispose();}
});

test('first-request crash retains the actual SDK identity/user history without invented assistant', () => withRoot(root => {
  const contract = {model: model.id};
  const {manager, identityPath} = openSession(sdk, root, 'builder', 'new', config, contract);
  manager.appendModelChange(model.provider, model.id);
  manager.appendMessage({role: 'user', content: 'real opening request awaiting response', timestamp: Date.now()});
  checkpointSession(manager);
  fs.writeFileSync(identityPath, JSON.stringify({id: manager.getSessionId(), file: manager.getSessionFile(),
    contract: digest(contract), provider: model.provider, model: model.id}));
  const resumed = openSession(sdk, root, 'builder', 'resume', config, contract).manager;
  assert.equal(resumed.getSessionId(), manager.getSessionId());
  assert.equal(resumed.buildSessionContext().messages[0].content, 'real opening request awaiting response');
  assert.equal(resumed.buildSessionContext().messages.some(m => m.role === 'assistant'), false);
}));

test('the same live SDK manager can append its first assistant after pre-request journaling', () => withRoot(root => {
  const manager = sdk.SessionManager.create(root, root);
  manager.appendModelChange(model.provider, model.id);
  manager.appendMessage({role: 'user', content: 'offline first response fixture', timestamp: Date.now()});
  const id = manager.getSessionId();
  checkpointSession(manager);
  assert.equal(manager.buildSessionContext().messages.some(m => m.role === 'assistant'), false);
  assert.doesNotThrow(() => manager.appendMessage({role: 'assistant',
    content: [{type: 'text', text: 'offline SDK persistence fixture; no provider call'}],
    provider: model.provider, model: model.id, api: model.api, stopReason: 'stop', timestamp: Date.now(),
    usage: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, cost: {total: 0}}}));
  const reopened = sdk.SessionManager.open(manager.getSessionFile(), root);
  assert.equal(reopened.getSessionId(), id);
  assert.equal(reopened.buildSessionContext().messages.length, 2);
}));

test('provider continuation uses typed transport failures, not product diagnostic text', () => {
  for (const status of [429, 500, 503]) assert.equal(classifyProviderFailure(status), true);
  for (const status of [200, 400, 401, 403]) assert.equal(classifyProviderFailure(status), false);
  assert.equal(classifyProviderFailure(200, {type: 'response.failed', response: {error: {code: 'server_error'}}}), true);
  assert.equal(classifyProviderFailure(200, {error: {code: 'invalid_context_length', message: 'server_error'}}), false);
});

test('interrupted reviewer resumes only its own exact candidate, never builder history', () => withRoot(root => {
  const contract = {model: model.id, automatic_continuation: true};
  fs.writeFileSync(path.join(root, 'state.json'), JSON.stringify({candidate: 'a'.repeat(40)}));
  const {manager, identityPath} = openSession(sdk, root, 'reviewer', 'new', config, contract);
  manager.appendModelChange(model.provider, model.id);
  manager.appendMessage({role: 'user', content: 'unique read-only review history', timestamp: Date.now()});
  manager.appendMessage({role: 'assistant', content: [{type: 'text', text: 'offline interrupted review'}],
    provider: model.provider, model: model.id, api: model.api, stopReason: 'stop', timestamp: Date.now(),
    usage: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, cost: {total: 0}}});
  fs.writeFileSync(identityPath, JSON.stringify({id: manager.getSessionId(), file: manager.getSessionFile(),
    contract: digest(contract), provider: model.provider, model: model.id, candidate: 'a'.repeat(40)}));
  const resumed = openSession(sdk, root, 'reviewer', 'resume', config, contract).manager;
  assert.equal(resumed.getSessionId(), manager.getSessionId());
  assert.equal(resumed.buildSessionContext().messages[0].content, 'unique read-only review history');
  fs.writeFileSync(path.join(root, 'state.json'), JSON.stringify({candidate: 'b'.repeat(40)}));
  assert.throws(() => openSession(sdk, root, 'reviewer', 'resume', config, contract), /Stale Sol reviewer/);
}));

test('formatter is an explicit builder capability, still forbidden to reviewer', () => {
  const names = ['inspect', 'edit', 'observe', 'format'];
  const payload = {model: model.id, parallel_tool_calls: true, tools: names.map(name => ({type: 'function', name}))};
  validateRequest(payload, names);
  assert.throws(() => validateRequest(payload, ['inspect']));
});
