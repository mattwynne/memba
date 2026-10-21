const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const {execFileSync, spawnSync} = require("node:child_process");
const workflowModule = require("./workflow.cjs");

const sourceRoot = path.resolve(__dirname, "../..");
const workflow = path.join(__dirname, "workflow.cjs");
const installedNodeModules = process.env.BDD_TEST_NODE_MODULES ||
  path.join(sourceRoot, "acceptance-tests/node_modules");

function put(root, name, body) {
  const target = path.join(root, name);
  fs.mkdirSync(path.dirname(target), {recursive: true});
  fs.writeFileSync(target, body);
}

function git(root, ...args) {
  return execFileSync("git", args, {cwd: root, encoding: "utf8"}).trim();
}

function commit(root, message) {
  git(root, "add", ".");
  git(root, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
    "-c", "commit.gpgsign=false", "commit", "-qm", message);
  return git(root, "rev-parse", "HEAD");
}

function scenario(name, extraTags = "") {
  return `  @iteration-068 @todo${extraTags}\n  Scenario: ${name}\n    Given something\n`;
}

function repository(t, body = scenario("Foundation") + scenario("Constraint")) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "bdd-workflow-"));
  t.after(() => fs.rmSync(root, {recursive: true, force: true}));
  git(root, "init", "-q");
  put(root, "docs/iterations/README.md", `| # | Date | Status | Title | Plan |\n|---|---|---|---|---|\n| 068 | today | implementing | Current | [delivery log](068-current/plan.md) |\n`);
  put(root, "docs/iterations/068-current/plan.md", "# Current plan\n");
  put(root, "acceptance-tests/features/example.feature", `Feature: Example\n${body}`);
  put(root, ".gitignore", "/.fabro/tmp/**\n/.fabro/blobs/**\n/acceptance-tests/node_modules/\n");
  fs.mkdirSync(path.join(root, "bin"), {recursive: true});
  fs.copyFileSync(path.join(sourceRoot, "bin/dev"), path.join(root, "bin/dev"));
  fs.chmodSync(path.join(root, "bin/dev"), 0o755);
  fs.mkdirSync(path.join(root, "dev-tools/bdd"), {recursive: true});
  for (const name of ["cli.cjs", "core.cjs"]) {
    fs.copyFileSync(path.join(sourceRoot, "dev-tools/bdd", name), path.join(root, "dev-tools/bdd", name));
  }
  fs.mkdirSync(path.join(root, "acceptance-tests"), {recursive: true});
  fs.copyFileSync(path.join(sourceRoot, "acceptance-tests/package.json"), path.join(root, "acceptance-tests/package.json"));
  if (!fs.existsSync(path.join(installedNodeModules, "@cucumber/gherkin"))) {
    throw new Error(`BDD_TEST_NODE_MODULES does not contain @cucumber/gherkin: ${installedNodeModules}`);
  }
  fs.symlinkSync(installedNodeModules, path.join(root, "acceptance-tests/node_modules"), "dir");
  commit(root, "fixture");
  return root;
}

function run(root, command, input, extra = command === "setup" ? ["HEAD"] : []) {
  return spawnSync("node", [workflow, command, ...extra], {
    cwd: root,
    input,
    encoding: "utf8"
  });
}

function succeeds(result) {
  assert.equal(result.status, 0, result.stderr);
  return result;
}

function response(scenarioName, reason = "establishes the next dependency") {
  return JSON.stringify({
    plan: "docs/iterations/068-current/plan.md",
    feature: "acceptance-tests/features/example.feature",
    scenario: scenarioName,
    reason
  });
}

test("inspect binds each visit to current HEAD and complete root tree", t => {
  const root = repository(t);
  succeeds(run(root, "setup"));
  const first = JSON.parse(succeeds(run(root, "inspect")).stdout);
  assert.equal(first.preferred_next_label, "choose");
  const firstSnapshot = JSON.parse(fs.readFileSync(path.join(root, ".fabro/tmp/bdd-plan/selection.json")));
  assert.equal(firstSnapshot.commit, git(root, "rev-parse", "HEAD"));
  assert.equal(firstSnapshot.tree, git(root, "rev-parse", "HEAD^{tree}"));

  git(root, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
    "-c", "commit.gpgsign=false", "commit", "--allow-empty", "-qm", "stock checkpoint");
  assert.equal(run(root, "pick", response("Foundation", "  establishes the foundation gap  ")).status, 0);
  put(root, "acceptance-tests/features/example.feature",
    fs.readFileSync(path.join(root, "acceptance-tests/features/example.feature"), "utf8").replace("@wip\n  Scenario: Foundation", "\n  Scenario: Foundation"));
  commit(root, "implement foundation");

  assert.equal(JSON.parse(run(root, "inspect").stdout).preferred_next_label, "choose");
  const secondSnapshot = JSON.parse(fs.readFileSync(path.join(root, ".fabro/tmp/bdd-plan/selection.json")));
  assert.notEqual(secondSnapshot.commit, firstSnapshot.commit);
  assert.equal(secondSnapshot.commit, git(root, "rev-parse", "HEAD"));
  assert.notEqual(secondSnapshot.tree, firstSnapshot.tree);
  git(root, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
    "-c", "commit.gpgsign=false", "commit", "--allow-empty", "-qm", "stock checkpoint 2");
  assert.equal(run(root, "pick", response("Constraint")).status, 0);
  const notes = fs.readFileSync(path.join(root, ".fabro/tmp/bdd-plan/selection-notes.jsonl"), "utf8").trim().split("\n").map(JSON.parse);
  assert.deepEqual(notes.map(note => note.scenario), ["Foundation", "Constraint"]);
  assert.equal(notes[0].reason, "  establishes the foundation gap  ");
  assert.equal(notes[1].commit, git(root, "rev-parse", "HEAD"));
});

test("tree changes, dirty worktrees and stale choices fail without picker edits", t => {
  for (const mutate of [
    root => { put(root, "lib/source.txt", "changed\n"); commit(root, "source changed"); },
    root => put(root, "visible-untracked.txt", "dirty\n")
  ]) {
    const root = repository(t);
    succeeds(run(root, "setup"));
    succeeds(run(root, "inspect"));
    mutate(root);
    const before = fs.readFileSync(path.join(root, "acceptance-tests/features/example.feature"), "utf8");
    const result = run(root, "pick", response("Foundation"));
    assert.notEqual(result.status, 0);
    assert.equal(fs.readFileSync(path.join(root, "acceptance-tests/features/example.feature"), "utf8"), before);
    assert.equal(fs.existsSync(path.join(root, ".fabro/tmp/bdd-plan/selection-notes.jsonl")), false);
  }
});

test("malformed, stale and ambiguous selector responses are never repaired or guessed", t => {
  const cases = [
    [scenario("Foundation") + scenario("Constraint"), "not JSON"],
    [scenario("Foundation") + scenario("Constraint"), "```json\n" + response("Foundation") + "\n```"],
    [scenario("Foundation") + scenario("Constraint"), response("Missing")],
    [scenario("Foundation") + scenario("Foundation"), response("Foundation")],
    [scenario("Foundation") + scenario("Constraint"),
      '{"plan":"docs/iterations/068-current/plan.md","plan":"docs/iterations/other.md","feature":"acceptance-tests/features/example.feature","scenario":"Foundation","reason":"duplicate"}'],
    [scenario("Foundation") + scenario("Constraint"), JSON.stringify({
      plan: "docs/iterations/other.md", feature: "acceptance-tests/features/example.feature",
      scenario: "Foundation", reason: "wrong plan"
    })]
  ];
  for (const [body, answer] of cases) {
    const root = repository(t, body);
    succeeds(run(root, "setup"));
    succeeds(run(root, "inspect"));
    const before = fs.readFileSync(path.join(root, "acceptance-tests/features/example.feature"), "utf8");
    assert.notEqual(run(root, "pick", answer).status, 0);
    assert.equal(fs.readFileSync(path.join(root, "acceptance-tests/features/example.feature"), "utf8"), before);
  }
});

test("a valid selector error stops clearly without changing source", t => {
  const root = repository(t);
  succeeds(run(root, "setup"));
  succeeds(run(root, "inspect"));
  const before = fs.readFileSync(path.join(root, "acceptance-tests/features/example.feature"), "utf8");
  const result = run(root, "pick", JSON.stringify({error: "No unique active plan"}));
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /selector reported error: No unique active plan/);
  assert.doesNotMatch(result.stderr, /must contain exactly/);
  assert.equal(fs.readFileSync(path.join(root, "acceptance-tests/features/example.feature"), "utf8"), before);
});

test("completion reports journeys while pending errors fail closed", t => {
  const done = repository(t, scenario("Browser journey", " @journey"));
  succeeds(run(done, "setup"));
  assert.equal(JSON.parse(succeeds(run(done, "inspect")).stdout).preferred_next_label, "done");
  const report = JSON.parse(fs.readFileSync(path.join(done, ".fabro/tmp/bdd-plan/pending.json")));
  assert.equal(report.domain_complete, true);
  assert.equal(report.pending_journeys[0].scenario, "Browser journey");

  const broken = repository(t, scenario("Already active").replace("@todo", "@wip"));
  assert.equal(run(broken, "setup").status, 0);
  const result = run(broken, "inspect");
  assert.notEqual(result.status, 0);
  assert.equal(result.stdout, "");
});

test("setup verifies tracked ignore policy without changing repository metadata", t => {
  const root = repository(t);
  put(root, ".fabro/tmp/bdd/partial.log", "keep me\n");
  const exclude = path.join(root, ".git/info/exclude");
  const beforeExclude = fs.readFileSync(exclude, "utf8");
  assert.equal(run(root, "setup").status, 0);
  assert.equal(git(root, "check-ignore", ".fabro/tmp/bdd/partial.log"), ".fabro/tmp/bdd/partial.log");
  put(root, ".fabro/blobs/materialized", "native\n");
  assert.equal(git(root, "check-ignore", ".fabro/blobs/materialized"), ".fabro/blobs/materialized");
  assert.equal(fs.readFileSync(exclude, "utf8"), beforeExclude);
  put(root, "outside.txt", "visible\n");
  assert.notEqual(run(root, "inspect").status, 0);
});

test("stock checkpoint pathspecs exclude ignored runtime files without hiding tracked workflows", t => {
  const sourceIgnore = fs.readFileSync(path.join(sourceRoot, ".gitignore"), "utf8");
  const runtimeIgnoreLines = sourceIgnore.split(/\r?\n/).filter(line =>
    line.startsWith("/.fabro/tmp") || line.startsWith("/.fabro/blobs")
  );
  assert.deepEqual(runtimeIgnoreLines, ["/.fabro/tmp/**", "/.fabro/blobs/**"]);

  const builtInExcludes = [
    ".git", "node_modules", ".pnpm-store", ".npm", "target", ".next",
    "__pycache__", ".venv", "venv", ".cache", ".tox", ".pytest_cache",
    ".mypy_cache", "dist"
  ].map(directory => `**/${directory}/**`);
  const configs = [
    ".fabro/workflows/bdd-plan-implementation/workflow.toml",
    ".fabro/workflows/bdd-scenario-implementation/workflow.toml"
  ];

  for (const config of configs) {
    const configText = fs.readFileSync(path.join(sourceRoot, config), "utf8");
    const match = configText.match(/^exclude_globs = (\[[^\n]+\])$/m);
    assert.ok(match, `missing checkpoint exclusions in ${config}`);
    const configuredExcludes = JSON.parse(match[1]);
    assert.deepEqual(configuredExcludes, [".fabro/tmp/**", ".fabro/blobs/**"]);

    const root = fs.mkdtempSync(path.join(os.tmpdir(), "bdd-checkpoint-pathspec-"));
    t.after(() => fs.rmSync(root, {recursive: true, force: true}));
    git(root, "init", "-q");
    git(root, "config", "user.name", "Test");
    git(root, "config", "user.email", "test@example.invalid");
    put(root, ".gitignore", `${runtimeIgnoreLines.join("\n")}\n`);
    put(root, "tracked.txt", "base\n");
    put(root, ".fabro/workflows/example.toml", "base workflow\n");
    commit(root, "fixture");
    put(root, "tracked.txt", "changed\n");
    put(root, ".fabro/workflows/example.toml", "changed workflow\n");
    put(root, ".fabro/tmp/evidence.log", "runtime\n");
    put(root, ".fabro/blobs/materialized", "runtime\n");

    const pathspecs = [...builtInExcludes, ...configuredExcludes]
      .map(pattern => `':(glob,exclude)${pattern}'`)
      .join(" ");
    const command = "git -c maintenance.auto=0 -c gc.auto=0 " +
      "-c commit.gpgsign=false -c tag.gpgsign=false add -A -- . " + pathspecs;
    const result = spawnSync("/bin/sh", ["-c", command], {cwd: root, encoding: "utf8"});
    assert.equal(result.status, 0, `${config}: ${result.stderr}`);
    assert.equal(result.stderr, "");
    assert.deepEqual(
      git(root, "diff", "--cached", "--name-only").split("\n"),
      [".fabro/workflows/example.toml", "tracked.txt"]
    );
    assert.equal(git(root, "check-ignore", ".fabro/tmp/evidence.log"), ".fabro/tmp/evidence.log");
    assert.equal(git(root, "check-ignore", ".fabro/blobs/materialized"), ".fabro/blobs/materialized");
    assert.notEqual(
      spawnSync("git", ["check-ignore", "--quiet", "--", ".fabro/tmp"], {cwd: root}).status,
      0
    );
    assert.notEqual(
      spawnSync("git", ["check-ignore", "--quiet", "--", ".fabro/blobs"], {cwd: root}).status,
      0
    );
    const status = git(root, "status", "--porcelain=v1", "--untracked-files=all");
    assert.doesNotMatch(status, /\.fabro\/(tmp|blobs)/);
  }
});

test("setup refuses a repository without the declared runtime ignores", t => {
  const root = repository(t);
  put(root, ".gitignore", "/acceptance-tests/node_modules/\n");
  commit(root, "remove workflow ignores");
  const result = run(root, "setup");
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /\.fabro\/tmp.*\.fabro\/blobs/s);
});

test("setup rejects a commit input override before creating scratch", t => {
  const root = repository(t);
  const result = run(root, "setup", undefined, [git(root, "rev-parse", "HEAD")]);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /must be exactly HEAD/);
  assert.equal(fs.existsSync(path.join(root, ".fabro/tmp/bdd-plan")), false);
});

test("atomic writes never truncate or remove a pre-existing temporary path", t => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "bdd-atomic-"));
  t.after(() => fs.rmSync(root, {recursive: true, force: true}));
  const target = path.join(root, "state.json");
  const victim = path.join(root, "victim");
  const collision = `${target}.tmp-${process.pid}`;
  fs.writeFileSync(target, "original\n");
  fs.writeFileSync(victim, "owned elsewhere\n");
  fs.symlinkSync(victim, collision);
  assert.throws(() => workflowModule.writeAtomic(target, "replacement\n"), /EEXIST/);
  assert.equal(fs.readFileSync(target, "utf8"), "original\n");
  assert.equal(fs.readFileSync(victim, "utf8"), "owned elsewhere\n");
  assert.equal(fs.readlinkSync(collision), victim);
  fs.unlinkSync(collision);
  workflowModule.writeAtomic(target, "replacement\n");
  assert.equal(fs.readFileSync(target, "utf8"), "replacement\n");
});

test("workflow scratch parent symlinks never redirect snapshots outside the repository", t => {
  const root = repository(t);
  const victim = fs.mkdtempSync(path.join(os.tmpdir(), "bdd-parent-victim-"));
  t.after(() => fs.rmSync(victim, {recursive: true, force: true}));
  fs.mkdirSync(path.join(root, ".fabro/tmp"), {recursive: true});
  fs.symlinkSync(victim, path.join(root, ".fabro/tmp/bdd-plan"), "dir");

  const setupResult = run(root, "setup");
  assert.notEqual(setupResult.status, 0);
  assert.match(setupResult.stderr, /symbolic link|safe directory/i);
  assert.deepEqual(fs.readdirSync(victim), []);
});

test("each owned scratch directory component rejects symlinks and non-directories", t => {
  for (const kind of ["symlink", "file"])
  for (const components of [[".fabro"], [".fabro", "tmp"], [".fabro", "tmp", "bdd-plan"]]) {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), "bdd-component-root-"));
    const victim = fs.mkdtempSync(path.join(os.tmpdir(), "bdd-component-victim-"));
    t.after(() => fs.rmSync(root, {recursive: true, force: true}));
    t.after(() => fs.rmSync(victim, {recursive: true, force: true}));
    const parent = path.join(root, ...components.slice(0, -1));
    fs.mkdirSync(parent, {recursive: true});
    const unsafe = path.join(parent, components.at(-1));
    if (kind === "symlink") fs.symlinkSync(victim, unsafe, "dir");
    else fs.writeFileSync(unsafe, "not a directory\n");

    assert.throws(() => workflowModule.ensureSafeScratchDirectory(root), /symbolic link|not a directory/);
    assert.deepEqual(fs.readdirSync(victim), []);
  }
});

test("selection notes symlinks fail before public pick and preserve victim bytes", t => {
  const root = repository(t);
  succeeds(run(root, "setup"));
  succeeds(run(root, "inspect"));
  const feature = path.join(root, "acceptance-tests/features/example.feature");
  const beforeFeature = fs.readFileSync(feature, "utf8");
  const victimDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "bdd-notes-victim-"));
  t.after(() => fs.rmSync(victimDirectory, {recursive: true, force: true}));
  const victim = path.join(victimDirectory, "notes");
  fs.writeFileSync(victim, "owned elsewhere\n");
  fs.symlinkSync(victim, path.join(root, ".fabro/tmp/bdd-plan/selection-notes.jsonl"));

  const result = run(root, "pick", response("Foundation"));
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /selection notes.*regular file|symbolic link/i);
  assert.equal(fs.readFileSync(victim, "utf8"), "owned elsewhere\n");
  assert.equal(fs.readFileSync(feature, "utf8"), beforeFeature);
});

test("preselection snapshot symlinks fail before public pick", t => {
  const root = repository(t);
  succeeds(run(root, "setup"));
  succeeds(run(root, "inspect"));
  const feature = path.join(root, "acceptance-tests/features/example.feature");
  const beforeFeature = fs.readFileSync(feature, "utf8");
  const snapshot = path.join(root, ".fabro/tmp/bdd-plan/selection.json");
  const victimDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "bdd-snapshot-victim-"));
  t.after(() => fs.rmSync(victimDirectory, {recursive: true, force: true}));
  const victim = path.join(victimDirectory, "selection.json");
  fs.copyFileSync(snapshot, victim);
  fs.unlinkSync(snapshot);
  fs.symlinkSync(victim, snapshot);

  const result = run(root, "pick", response("Foundation"));
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /preselection snapshot.*regular file|symbolic link/i);
  assert.equal(fs.readFileSync(feature, "utf8"), beforeFeature);
});

test("public BDD status vocabulary stays aligned with the lifecycle helper", t => {
  const root = repository(t);
  const publicStatuses = JSON.parse(execFileSync("node", ["-e",
    "const {activeStatuses}=require('./dev-tools/bdd/core.cjs'); process.stdout.write(JSON.stringify([...activeStatuses].sort()))"
  ], {cwd: root, encoding: "utf8"}));
  const lifecycle = JSON.parse(execFileSync("python3", ["-c",
    "import json,runpy,sys; m=runpy.run_path(sys.argv[1]); print(json.dumps(sorted(m['ACTIVE_STATUSES'])))",
    path.join(sourceRoot, ".fabro/workflows/scripts/iteration_status.py")
  ], {encoding: "utf8"}));
  assert.deepEqual(publicStatuses, lifecycle);
});
