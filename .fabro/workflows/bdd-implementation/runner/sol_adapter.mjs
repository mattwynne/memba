// Trusted, explicit Pi SDK adapter. No discovery or native tools. Python owns authority.
import {spawn} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import crypto from 'node:crypto';

export function digest(value) {
  const encode = value => Array.isArray(value) ? '[' + value.map(encode).join(',') + ']' :
    value && typeof value === 'object' ? '{' + Object.keys(value).sort().map(k =>
      encode(k) + ':' + encode(value[k])).join(',') + '}' : JSON.stringify(value).replace(/[^\x00-\x7f]/g,
        c => '\\u' + c.charCodeAt(0).toString(16).padStart(4, '0'));
  // Match candidate.digest's Python json.dumps(sort_keys=True) ASCII/separators.
  return crypto.createHash('sha256').update(encode(value)).digest('hex');
}

export function assertModel(model, config) {
  if (!model || model.id !== 'gpt-6.1-sol' || model.provider !== 'openai-codex' ||
      model.api !== config.api || model.baseUrl !== config.base_url || digest(model) !== config.model_digest)
    throw new Error('Sol catalog identity changed or unavailable; no fallback');
}

export function resourceLoader(sdk, systemPrompt) {
  return {
    getExtensions: () => ({extensions: [], errors: [], runtime: sdk.createExtensionRuntime()}),
    getSkills: () => ({skills: [], diagnostics: []}), getPrompts: () => ({prompts: [], diagnostics: []}),
    getThemes: () => ({themes: [], diagnostics: []}), getAgentsFiles: () => ({agentsFiles: []}),
    getSystemPrompt: () => systemPrompt, getSystemPromptSource: () => undefined,
    getAppendSystemPrompt: () => [], getAppendSystemPromptSources: () => [],
    extendResources: () => {throw new Error('Resource loading prohibited');}, reload: async () => {},
  };
}

export class Broker {
  constructor(job, attempt, log) {
    this.sequence = 0; this.pending = new Map(); this.buffer = ''; this.log = log;
    this.process = spawn('/usr/bin/python3', [path.join(job, 'session_candidate.py'), 'broker', job, attempt],
      {cwd: path.join(job, 'model-cwd'), stdio: ['pipe', 'pipe', 'inherit']});
    this.process.stdout.setEncoding('utf8');
    this.process.stdout.on('data', data => {
      this.buffer += data;
      let i;
      while ((i = this.buffer.indexOf('\n')) >= 0) {
        const line = this.buffer.slice(0, i); this.buffer = this.buffer.slice(i + 1);
        try {
          const message = JSON.parse(line), waiter = this.pending.get(message.id);
          if (!waiter) throw new Error('Unexpected broker reply');
          this.pending.delete(message.id); waiter.resolve(message.result);
        } catch (error) { this.fail(error); }
      }
    });
    this.process.stdin.on('error', error => this.fail(error));
    this.process.on('error', error => this.fail(error));
    this.process.on('exit', () => this.fail(new Error('Owned broker exited')));
  }
  fail(error) { this.closed = error; for (const waiter of this.pending.values()) waiter.reject(error); this.pending.clear(); }
  request(method, params = {}) {
    if (this.closed) return Promise.reject(this.closed);
    return new Promise((resolve, reject) => {
      const id = ++this.sequence; this.pending.set(id, {resolve, reject});
      this.process.stdin.write(JSON.stringify({jsonrpc: '2.0', id, method, params}) + '\n');
    });
  }
  async close() {
    this.process.stdin.end();
    if (this.process.exitCode === null && this.process.signalCode === null) {
      await new Promise(resolve => {
        this.process.once('exit', resolve);
        const timer = setTimeout(() => this.process.kill('SIGKILL'), 1000);
        timer.unref();
      });
    }
  }
}

export function validateRequest(payload, expectedNames) {
  const names = (payload.tools ?? []).map(t => t.name);
  if (payload.model !== 'gpt-6.1-sol' || payload.parallel_tool_calls !== true ||
      names.length !== expectedNames.length || names.some(n => !expectedNames.includes(n)) ||
      (payload.additional_tools?.length ?? 0) || payload.tools?.some(t => t.type !== 'function'))
    throw new Error('Outgoing Sol request violated model/tool boundary');
}

export function checkRequestBudget(requests, tokens, config) {
  if (requests >= config.max_turns) throw new Error('Finite Sol request budget exhausted');
  // Compatibility only: explicit new accounting-only contracts have no token stop.
  if (config.token_policy !== 'accounting-only' && tokens >= config.visit_token_limit)
    throw new Error('Legacy Sol token budget exhausted');
}

export function checkpointSession(manager) {
  // Pi defers its first disk write until an assistant exists. Persist only the
  // actual public header/entries before inference: no invented assistant, and
  // a kill during the first request still resumes the SAME identity/history.
  const file = manager.getSessionFile(), header = manager.getHeader();
  if (!file || !header) throw new Error('Durable Sol session unavailable');
  const temp = file + '.pending';
  const fd = fs.openSync(temp, 'w', 0o600);
  try {fs.writeFileSync(fd, [header, ...manager.getEntries()].map(e => JSON.stringify(e)).join('\n') + '\n'); fs.fsyncSync(fd);}
  finally {fs.closeSync(fd);}
  fs.renameSync(temp, file);
  // Public SDK reload acknowledges persistence on THIS live manager. Without
  // it, the SDK's deferred first assistant write uses exclusive creation and
  // fails EEXIST against our durable pre-request journal.
  const leaf = manager.getLeafId();
  manager.setSessionFile(file);
  if (leaf) manager.branch(leaf);
}

export function classifyProviderFailure(status, event) {
  const code = event?.response?.error?.code ?? event?.error?.code ?? event?.code;
  return status === 429 || status >= 500 && status <= 599 ||
    ['server_error', 'internal_error', 'service_unavailable', 'rate_limit_exceeded'].includes(code);
}

export function openSession(sdk, job, role, mode, config, contract) {
  const sessions = path.join(job, 'sol-sessions'); fs.mkdirSync(sessions, {recursive: true, mode: 0o700});
  const identityPath = path.join(sessions, role + '.json');
  let manager;
  if (mode === 'resume' && (role === 'builder' || contract.automatic_continuation)) {
    const saved = JSON.parse(fs.readFileSync(identityPath, 'utf8'));
    if (saved.contract !== digest(contract) || saved.provider !== config.provider || saved.model !== contract.model ||
        !saved.file.startsWith(sessions + path.sep) || !fs.existsSync(saved.file)) throw new Error('Stale Sol builder session');
    if (role === 'reviewer' && saved.candidate !== JSON.parse(fs.readFileSync(path.join(job, 'state.json'))).candidate)
      throw new Error('Stale Sol reviewer candidate');
    manager = sdk.SessionManager.open(saved.file, sessions);
    if (manager.getSessionId() !== saved.id) throw new Error('Wrong resumed Sol session');
  } else {
    if (role === 'builder' && fs.existsSync(identityPath)) throw new Error('Refuse replacement builder session');
    manager = sdk.SessionManager.create(path.join(job, 'model-cwd'), sessions);
  }
  const previous = manager.buildSessionContext();
  if (previous.model && (previous.model.provider !== config.provider || previous.model.modelId !== contract.model))
    throw new Error('Session model drift');
  return {manager, identityPath};
}

export async function run(job, attempt, role, prefix, mode, systemPrompt, prompt) {
  const contract = JSON.parse(fs.readFileSync(path.join(job, 'contract.json'), 'utf8'));
  const config = contract.sol_provider;
  const sdk = await import(pathToFileURL(path.join(config.sdk_root, 'dist/index.js')).href);
  const eventLog = prefix + '.events.jsonl';
  const log = value => fs.appendFileSync(eventLog, JSON.stringify(value) + '\n', {mode: 0o600});
  const usageLog = prefix + '.usage.json';
  const usage = {input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0};
  let estimatedCost = 0, requests = 0, completed = 0, session, broker, timer, stopped, resumeKind, retryAfter;
  const nativeModels = new Set();
  const writeUsage = complete => fs.writeFileSync(usageLog, JSON.stringify({
    provider: config.provider, requested_model: contract.model, native_response_models: [...nativeModels],
    session_id: session?.sessionId, session_file: session?.sessionFile, requests, completed_responses: completed,
    usage, usage_complete: complete, reported_cost_usd: null,
    token_policy: config.token_policy ?? 'legacy-response-token-limit',
    estimated_cost_usd: estimatedCost, estimate_basis: 'Pi catalog rates applied to response token usage; NOT provider-reported charge',
    hard_spend_cap_supported: false, stopped,
  }, null, 2) + '\n', {mode: 0o600});
  try {
    if (!['builder', 'reviewer'].includes(role)) throw new Error('Unknown role');
    const runtime = await sdk.ModelRuntime.create({allowModelNetwork: false, signal: AbortSignal.timeout(15000)});
    const model = runtime.getModel(config.provider, contract.model); assertModel(model, config);
    const {manager, identityPath} = openSession(sdk, job, role, mode, config, contract);
    broker = new Broker(job, attempt, log);
    await broker.request('initialize');
    const offered = (await broker.request('tools/list')).tools;
    const builderNames = ['inspect', 'edit', 'observe', ...(contract.formatter ? ['format'] : [])];
    const names = role === 'builder' ? builderNames : ['inspect'];
    if (offered.map(t => t.name).sort().join() !== [...builderNames].sort().join()) throw new Error('Broker tool drift');
    const tools = offered.filter(t => names.includes(t.name)).map(t => ({
      name: t.name, label: t.name, description: t.description,
      parameters: {...t.inputSchema, additionalProperties: false},
      execute: async (id, args, signal) => {
        signal?.throwIfAborted();
        const result = await broker.request('tools/call', {name: t.name, arguments: args});
        log({type: 'broker_result', tool: t.name, toolCallId: id, args, result});
        if (result.isError) throw new Error(result.content.map(c => c.text).join('\n'));
        return {content: result.content, details: {}};
      },
    }));
    const settings = sdk.SettingsManager.inMemory({compaction: {enabled: false}, retry: {enabled: false,
      provider: {maxRetries: 0, timeoutMs: 120000}}, transport: 'sse', enableInstallTelemetry: false});
    ({session} = await sdk.createAgentSession({cwd: path.join(job, 'model-cwd'), model, thinkingLevel: config.thinking,
      modelRuntime: runtime, resourceLoader: resourceLoader(sdk, systemPrompt), settingsManager: settings,
      sessionManager: manager, tools: names, noTools: 'builtin', customTools: tools}));
    if (session.model.provider !== config.provider || session.model.id !== contract.model ||
        session.agent.state.tools.map(t => t.name).sort().join() !== [...names].sort().join())
      throw new Error('Sol session capability drift');
    session.agent.toolExecution = 'sequential'; // Required: checkpoint/receipt transitions are serialized.
    fs.writeFileSync(identityPath, JSON.stringify({id: session.sessionId,
      file: session.sessionFile, provider: config.provider, model: contract.model, contract: digest(contract),
      candidate: JSON.parse(fs.readFileSync(path.join(job, 'state.json'))).candidate}), {mode: 0o600});
    log({type: 'identity', role, mode, session_id: session.sessionId, session_file: session.sessionFile,
      model, tools: names, builtin_tools: [], discovery: false, retries: 0, compaction: false});
    // Every response is SSE, no transport fallback or automatic provider/agent retries.
    const originalStream = session.agent.streamFunction;
    session.agent.streamFunction = (m, context, options) => {
      try { checkRequestBudget(requests, usage.totalTokens, config); }
      catch (error) {
        if (contract.automatic_continuation && requests >= config.max_turns) {resumeKind = 'visit-yield'; retryAfter = 0;}
        throw error;
      }
      if (contract.automatic_continuation) checkpointSession(manager);
      requests++;
      assertModel(m, config);
      return originalStream(m, context, {...options, maxRetries: 0, transport: 'sse', fetch: async (url, init) => {
        let response;
        try { response = await fetch(url, init); }
        catch (error) {
          if (['ECONNRESET', 'ETIMEDOUT', 'EAI_AGAIN', 'UND_ERR_CONNECT_TIMEOUT', 'UND_ERR_HEADERS_TIMEOUT', 'UND_ERR_SOCKET'].includes(error.cause?.code))
            resumeKind = 'provider';
          throw error;
        }
        if (classifyProviderFailure(response.status)) {
          resumeKind = 'provider';
          const raw = response.headers.get('retry-after');
          retryAfter = raw && (/^\d+$/.test(raw) ? Number(raw) : Math.max(0, (Date.parse(raw) - Date.now()) / 1000));
          log({type: 'provider_interruption', status: response.status, retry_after_seconds: retryAfter});
        }
        if (!response.ok || !response.body) return response;
        let buffer = '';
        const decoder = new TextDecoder();
        const stream = response.body.pipeThrough(new TransformStream({transform(chunk, controller) {
          buffer += decoder.decode(chunk, {stream: true});
          let i;
          while ((i = buffer.indexOf('\n')) >= 0) {
            const line = buffer.slice(0, i); buffer = buffer.slice(i + 1);
            if (line.startsWith('data: ') && line !== 'data: [DONE]') {
              const value = JSON.parse(line.slice(6));
              if (['error', 'response.failed'].includes(value.type) && classifyProviderFailure(0, value)) {
                resumeKind = 'provider';
                log({type: 'provider_interruption', event: value});
              }
              if (value.response?.model) {
                nativeModels.add(value.response.model);
                log({type: 'native_response_identity', event: value.type, model: value.response.model});
                if (value.response.model !== contract.model) throw new Error('Native Sol response model mismatch');
              }
            }
          }
          if (buffer.length > 2 * 1024 * 1024) throw new Error('Unbounded provider frame');
          controller.enqueue(chunk);
        }}));
        return new Response(stream, {status: response.status, statusText: response.statusText, headers: response.headers});
      }});
    };
    session.agent.onPayload = payload => {validateRequest(payload, names); log({type: 'request',
      requested_model: payload.model, tools: payload.tools.map(t => t.name)});};
    session.subscribe(event => {
      if (event.type === 'message_end') {
        log(event);
        if (event.message.role === 'assistant') {
          const m = event.message;
          if (m.provider !== config.provider || m.model !== contract.model) throw new Error('Message model drift');
          for (const key of Object.keys(usage)) usage[key] += m.usage[key] ?? 0;
          estimatedCost += m.usage.cost?.total ?? 0;
          if (['stop', 'toolUse', 'length'].includes(m.stopReason)) completed++;
          writeUsage(false);
        }
      } else if (event.type !== 'message_update') log(event);
    });
    timer = setTimeout(() => {stopped = 'Model visit deadline'; session.abort();},
      Math.max(1, Math.min(contract.visit_seconds * 1000, JSON.parse(fs.readFileSync(path.join(job, 'state.json'))).deadline * 1000 - Date.now())));
    const abort = () => {stopped = 'Owned process cancelled'; session.abort();};
    process.once('SIGTERM', abort); process.once('SIGINT', abort);
    await session.prompt(prompt, {expandPromptTemplates: false});
    const last = session.messages.at(-1);
    if (contract.automatic_continuation && last?.stopReason === 'length') {resumeKind = 'visit-yield'; retryAfter = 0;}
    if (stopped || last?.role !== 'assistant' || last.stopReason !== 'stop')
      throw new Error(stopped || last?.errorMessage || 'Incomplete Sol response');
    if (!nativeModels.has(contract.model)) throw new Error('Native response model identity missing');
    writeUsage(true);
    return {subtype: 'success', is_error: false, provider: config.provider, model: contract.model,
      native_response_models: [...nativeModels], session_id: session.sessionId,
      result: last.content.filter(c => c.type === 'text').map(c => c.text).join('\n'),
      total_cost_usd: null, estimated_cost_usd: estimatedCost, usage};
  } catch (error) {
    stopped = error.message; writeUsage(false);
    error.resumeEnvelope = contract.automatic_continuation && [...nativeModels].every(m => m === contract.model)
      ? {resume_kind: resumeKind, retry_after_seconds: retryAfter, native_response_models: [...nativeModels]} : {};
    throw error;
  } finally {
    clearTimeout(timer); session?.dispose(); await broker?.close();
  }
}

if (process.argv[1] && pathToFileURL(fs.realpathSync(process.argv[1])).href === import.meta.url) {
  const args = process.argv.slice(2); let prompt = '';
  for await (const chunk of process.stdin) prompt += chunk;
  try {console.log(JSON.stringify(await run(...args, prompt)));}
  catch (error) {console.log(JSON.stringify({subtype: 'error', is_error: true, result: error.message,
    provider: 'openai-codex', model: 'gpt-6.1-sol', total_cost_usd: null, ...error.resumeEnvelope})); process.exitCode = 1;}
}
