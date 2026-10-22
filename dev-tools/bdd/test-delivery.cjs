const {test} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const {execFileSync, spawnSync} = require("node:child_process");

const source = path.resolve(__dirname, "../..");
const plan = "docs/iterations/002-current/plan.md";
const runId = "01M5GFYTJZPAAYTVZFDAXSMSXV";

// Real CLI, Git remotes and lifecycle/pending checks; only Fabro is replaced.
// Every push is to a disposable local bare repository. No server/model calls.
function fixture(t, options = {}) {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "memba-domain-delivery-"));
  t.after(() => fs.rmSync(temp, {recursive: true, force: true}));
  const root = path.join(temp, "repo");
  fs.mkdirSync(root);
  const git = (...args) => execFileSync("git", args, {
    cwd: root, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"]
  }).trim();
  const put = (name, value) => {
    const target = path.join(root, name);
    fs.mkdirSync(path.dirname(target), {recursive: true});
    fs.writeFileSync(target, value);
  };
  for (const name of ["bin/dev", ".fabro/workflows/scripts/iteration_status.py",
    "dev-tools/bdd/cli.cjs", "dev-tools/bdd/core.cjs"]) {
    put(name, fs.readFileSync(path.join(source, name)));
    fs.chmodSync(path.join(root, name), fs.statSync(path.join(source, name)).mode);
  }
  const status = options.status || "validated";
  put(plan, `# Current\n\nStatus: ${status}\n\n## Goal\n\nAn agreed rule.\n`);
  put("docs/iterations/README.md", `| # | Date | Status | Title | Plan |\n| 001 | today | ${options.predecessor || "merged"} | Previous | [plan](001-previous/plan.md) |\n| 002 | today | ${status} | Current | [plan](${options.wrongPlan ? "002-other" : "002-current"}/plan.md) |\n| 003 | today | ${options.activeOther ? "implementing" : "ready"} | Later | [plan](003-later/plan.md) |\n`);
  if (options.wrongPlan) put("docs/iterations/002-other/plan.md", "Status: validated\n");
  put("acceptance-tests/features/example.feature", `Feature: An agreed rule\n  @iteration-002 ${options.journeyOnly ? "@journey " : ""}${options.wip ? "@wip" : "@todo"}\n  Scenario: Current example\n    Given an agreed condition\n    Then an agreed outcome\n`);
  git("init", "-q", "-b", "main");
  git("config", "user.name", "Delivery test");
  git("config", "user.email", "delivery@example.invalid");
  git("config", "commit.gpgsign", "false");
  git("add", ".");
  git("commit", "-qm", "Published fixture");
  const remote = path.join(temp, "origin.git");
  git("init", "--bare", "-q", remote);
  git("remote", "add", "origin", remote);
  git("push", "-qu", "origin", "main");
  const tools = path.join(temp, "tools");
  fs.mkdirSync(tools);
  const calls = path.join(temp, "fabro-calls.jsonl");
  fs.writeFileSync(calls, "");
  const fake = `#!/usr/bin/env node
const fs = require('node:fs');
const cp = require('node:child_process');
const args = process.argv.slice(2);
fs.appendFileSync(process.env.TEST_FABRO_CALLS, JSON.stringify(args)+'\\n');
const git = (...a) => cp.execFileSync('git', a, {stdio: 'ignore'});
if (args[0] === 'run' && args[1].includes('plan-validation')) {
  cp.execFileSync('.fabro/workflows/scripts/iteration_status.py', ['mark', ${JSON.stringify(plan)}, 'validated']);
  git('add', ${JSON.stringify(plan)}, 'docs/iterations/README.md');
  git('commit', '-qm', 'Validated fixture'); git('push', 'origin', 'HEAD:main');
  if (process.env.TEST_VALIDATION_DIRTY === '1') fs.writeFileSync('unexpected.txt', 'preserve');
} else if (args[0] === 'run' && args[1].includes('bdd-plan-implementation')) {
  process.stdout.write(process.env.TEST_ACK);
  process.exit(Number(process.env.TEST_CREATE_STATUS));
} else if (args[0] === 'run' && args[1].includes('iteration-implementation')) {
  console.log(${JSON.stringify(runId)}); process.exit(1);
} else if (args[0] === 'inspect') {
  console.log(JSON.stringify([{status: {kind: 'failed'}}]));
} else { console.error('Unexpected fake Fabro call'); process.exit(98); }
`;
  fs.writeFileSync(path.join(tools, "fabro"), fake, {mode: 0o755});
  // Fail closed if a fixture ever tries to enter an app/devenv command.
  for (const name of ["devenv", "mix", "elixir"]) {
    fs.writeFileSync(path.join(tools, name), "#!/bin/sh\necho 'App execution forbidden in delivery fixture' >&2\nexit 97\n", {mode: 0o755});
  }
  const env = {...process.env, PATH: tools + path.delimiter + process.env.PATH,
    MEMBA_DEVENV_SHELL: "1", DEVENV_ROOT: root,
    NODE_PATH: path.join(source, "acceptance-tests/node_modules"),
    TEST_FABRO_CALLS: calls, TEST_ACK: options.ack ?? JSON.stringify({run_id: runId}),
    TEST_CREATE_STATUS: String(options.createStatus || 0), TEST_VALIDATION_DIRTY: options.validationDirty ? "1" : "0"};
  const launch = (...args) => spawnSync(path.join(root, "bin/dev"),
    ["fabro", "deliver", plan, "--no-wait", ...args], {cwd: root, env, encoding: "utf8"});
  return {root, git, put, launch, calls: () => fs.readFileSync(calls, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse),
    status: () => fs.readFileSync(path.join(root, plan), "utf8").match(/^Status: (.*)$/m)[1]};
}

function domainCalls(f) {
  return f.calls().filter(a => a[0] === "run" && a[1].includes("bdd-plan-implementation"));
}

test("validated domain delivery uses canonical graph, literal HEAD and explicit environment without publication", t => {
  const f = fixture(t);
  const feature = fs.readFileSync(path.join(f.root, "acceptance-tests/features/example.feature"));
  const result = f.launch("--domain-only");
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.equal(f.calls().length, 1);
  assert.deepEqual(domainCalls(f)[0], ["run", ".fabro/workflows/bdd-plan-implementation/workflow.toml",
    "--environment", "memba-dev", "-I", "commit=HEAD", "--no-upgrade-check", "--detach", "--json"]);
  assert.equal(f.status(), "implementing");
  assert.equal(f.git("status", "--porcelain"), "");
  assert.equal(f.git("rev-parse", "HEAD"), f.git("rev-parse", "origin/main"));
  assert.deepEqual(fs.readFileSync(path.join(f.root, "acceptance-tests/features/example.feature")), feature);
  assert.match(result.stdout, /not evidence that implementation has passed/);
  assert.match(result.stdout, /separately approving merge or delivery/);
});

test("ready plan is validated before domain implementation", t => {
  const f = fixture(t, {status: "ready"});
  const result = f.launch("--domain-only");
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.equal(f.calls().length, 2);
  assert.match(f.calls()[0][1], /plan-validation/);
  assert.ok(f.calls()[0].includes("--auto-approve"));
  assert.ok(!domainCalls(f)[0].includes("--auto-approve"));
});

test("source dirt introduced during validation stops before reserving or starting implementation", t => {
  const f = fixture(t, {status: "ready", validationDirty: true});
  const result = f.launch("--domain-only");
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /requires clean main/);
  assert.equal(f.calls().length, 1);
  assert.match(f.calls()[0][1], /plan-validation/);
  assert.equal(f.status(), "validated");
  assert.equal(fs.readFileSync(path.join(f.root, "unexpected.txt"), "utf8"), "preserve");
});

for (const [name, options, mutate, message] of [
  ["non-main branch", {}, f => f.git("switch", "-qc", "other"), /main branch/],
  ["dirty source", {}, f => f.put("uncommitted.txt", "preserve me"), /clean working tree/],
  ["unpublished local commits", {}, f => {f.put("local.txt", "not approved"); f.git("add", "."); f.git("commit", "-qm", "Unpublished");}, /HEAD to equal origin\/main/],
  ["unpublished ready plan", {status: "ready"}, f => {f.put("local.txt", "not approved"); f.git("add", "."); f.git("commit", "-qm", "Unpublished");}, /HEAD to equal origin\/main/],
  ["unready plan", {status: "needs-revision"}, () => {}, /ready or validated/],
  ["unmerged predecessor", {predecessor: "ready"}, () => {}, /earlier iteration/],
  ["occupied WIP slot", {activeOther: true}, () => {}, /WIP limit/]
]) {
  test(`domain launch refuses ${name} without calling Fabro`, t => {
    const f = fixture(t, options); mutate(f);
    const result = f.launch("--domain-only");
    assert.notEqual(result.status, 0);
    assert.match(result.stdout + result.stderr, message);
    assert.deepEqual(f.calls(), []);
    assert.notEqual(f.status(), "implementing");
  });
}

for (const [name, options] of [["journey-only work", {journeyOnly: true}],
  ["existing WIP", {wip: true}], ["mismatched active plan link", {wrongPlan: true}]]) {
  test(`domain admission refuses ${name} and releases its known-unlaunched reservation`, t => {
    const f = fixture(t, options);
    const result = f.launch("--domain-only");
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Domain admission failed/);
    assert.deepEqual(f.calls(), []);
    assert.equal(f.status(), "validated");
    assert.equal(f.git("status", "--porcelain"), "");
  });
}

for (const [name, options] of [["missing run ID", {ack: "{}"}],
  ["non-JSON acknowledgement", {ack: "unknown acknowledgement"}],
  ["invalid run ID", {ack: JSON.stringify({run_id: "not-a-run-id"})}],
  ["lost acknowledgement", {ack: "", createStatus: 1}],
  ["local failure with a run ID", {createStatus: 1}]]) {
  test(`${name} preserves reservation and never retries or launches review`, t => {
    const f = fixture(t, options);
    const result = f.launch("--domain-only");
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /inspect Fabro before retrying/);
    assert.equal(domainCalls(f).length, 1);
    assert.equal(f.calls().length, 1);
    assert.equal(f.status(), "implementing");
  });
}

test("ordinary delivery still selects the existing implementation workflow", t => {
  const f = fixture(t);
  // The fake returns a confirmed failed legacy run, before any review/publication.
  const result = f.launch();
  assert.notEqual(result.status, 0);
  assert.ok(f.calls().some(a => a[0] === "run" && a[1] === ".fabro/workflows/iteration-implementation/workflow.toml"));
  assert.equal(domainCalls(f).length, 0);
  assert.equal(f.status(), "validated");
});
