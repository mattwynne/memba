const {Given, When, Then} = require("@cucumber/cucumber");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {execFileSync, spawnSync} = require("node:child_process");

const sourceRoot = path.resolve(__dirname, "../../..");
const dev = path.join(sourceRoot, "bin/dev");
const standardIndex = `| # | Date | Status | Title | Plan |
| 067 | today | merged | Previous | [plan](067-previous/plan.md) |
| 068 | today | implementing | Current | [plan](068-current/plan.md) |
| 069 | today | needs-revision | Future | [plan](069-future/plan.md) |
`;

function put(root, name, body) {
  const target = path.join(root, name);
  fs.mkdirSync(path.dirname(target), {recursive: true});
  fs.writeFileSync(target, body);
}

function git(world, ...args) {
  return execFileSync("git", args, {cwd: world.root, encoding: "utf8"}).trim();
}

function commit(world, message) {
  git(world, "add", ".");
  git(world, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
    "-c", "commit.gpgsign=false", "commit", "-qm", message);
}

function expand(value) {
  return value.replaceAll("\\n", "\n").replaceAll("\\|", "|");
}

function snapshot(world) {
  const entries = [];
  for (const name of git(world, "ls-files", "--cached", "--others", "--exclude-standard").split("\n")) {
    if (!name) continue;
    entries.push([name, fs.readFileSync(path.join(world.root, name)).toString("base64")]);
  }
  return entries;
}

function lineContaining(world, text, occurrence = 1) {
  const lines = fs.readFileSync(world.featurePath, "utf8").split("\n");
  let seen = 0;
  const index = lines.findIndex(line => {
    if (!line.includes(text)) return false;
    seen += 1;
    return seen === occurrence;
  });
  assert.notEqual(index, -1, `Fixture has no line containing ${JSON.stringify(text)}`);
  return index + 1;
}

function configureRace(world, kind, raceSource = "") {
  const preload = path.join(world.toolsRoot, "race-preload.cjs");
  fs.writeFileSync(preload, `
const fs = require("node:fs");
const {execFileSync} = require("node:child_process");
const path = require("node:path");
const originalReadFileSync = fs.readFileSync;
let fired = false;
fs.readFileSync = function(target, ...args) {
  const result = originalReadFileSync.call(this, target, ...args);
  if (fired) return result;
  let matches = false;
  try {
    if (typeof target === "number") {
      const targetStat = fs.statSync(process.env.BDD_RACE_TARGET, {bigint: true});
      const descriptorStat = fs.fstatSync(target, {bigint: true});
      matches = targetStat.dev === descriptorStat.dev && targetStat.ino === descriptorStat.ino;
    } else {
      matches = path.resolve(String(target)) === path.resolve(process.env.BDD_RACE_TARGET);
    }
  } catch (_) {}
  if (!matches) return result;
  fired = true;
  if (process.env.BDD_RACE_KIND === "unrelated-commit") {
    fs.writeFileSync(path.join(process.env.BDD_RACE_ROOT, "concurrent-unrelated.txt"), "concurrent commit\\n");
    execFileSync(process.env.BDD_REAL_GIT, ["add", "concurrent-unrelated.txt"], {cwd: process.env.BDD_RACE_ROOT});
  } else {
    fs.writeFileSync(process.env.BDD_RACE_TARGET, Buffer.from(process.env.BDD_RACE_CONTENT, "base64"));
    if (process.env.BDD_RACE_KIND === "commit") {
      execFileSync(process.env.BDD_REAL_GIT, ["add", "acceptance-tests/features/example.feature"], {cwd: process.env.BDD_RACE_ROOT});
    }
  }
  if (process.env.BDD_RACE_KIND === "commit" || process.env.BDD_RACE_KIND === "unrelated-commit") {
    execFileSync(process.env.BDD_REAL_GIT, ["-c", "user.name=Race", "-c", "user.email=race@example.invalid", "-c", "commit.gpgsign=false", "commit", "-qm", "Concurrent commit"], {cwd: process.env.BDD_RACE_ROOT});
  }
  return result;
};
`);
  world.concurrentFeatureBytes = raceSource ? Buffer.from(raceSource) : undefined;
  world.commandEnv = {
    NODE_OPTIONS: `--require=${preload}`,
    BDD_RACE_TARGET: world.featurePath,
    BDD_RACE_CONTENT: world.concurrentFeatureBytes?.toString("base64") || "",
    BDD_RACE_KIND: kind,
    BDD_RACE_ROOT: world.root,
    BDD_REAL_GIT: execFileSync("sh", ["-c", "command -v git"], {encoding: "utf8"}).trim()
  };
}

function runDev(world, args) {
  world.before = snapshot(world);
  world.result = spawnSync(dev, args, {
    cwd: world.root,
    encoding: "utf8",
    env: {
      ...process.env,
      MEMBA_DEVENV_SHELL: "1",
      DEVENV_ROOT: sourceRoot,
      ...world.commandEnv
    }
  });
}

Given("a committed project with this feature:", function (source) {
  git(this, "init", "-q");
  put(this.root, "docs/iterations/README.md", standardIndex);
  put(this.root, "docs/iterations/068-current/plan.md", "# Current plan\n\nStatus: implementing\n");
  this.committedFeatureSource = expand(source) + "\n";
  put(this.root, "acceptance-tests/features/example.feature", this.committedFeatureSource);
  commit(this, "Initial snapshot");
});

Given("the feature is replaced without committing by:", function (source) {
  put(this.root, "acceptance-tests/features/example.feature", expand(source) + "\n");
});

Given("I remember the commit as {string}", function (name) {
  this.commits.set(name, git(this, "rev-parse", "HEAD"));
});

Given("another commit replaces the feature with:", function (source) {
  put(this.root, "acceptance-tests/features/example.feature", expand(source) + "\n");
  commit(this, "Replace feature");
});

Given("another commit adds an unrelated file", function () {
  put(this.root, "unrelated.txt", "later\n");
  commit(this, "Later commit");
});

Given("the active plan is removed in another commit", function () {
  git(this, "rm", "docs/iterations/068-current/plan.md");
  commit(this, "Remove plan");
});

Given("the iteration index is committed with active iteration count {int}", function (count) {
  let index = standardIndex;
  if (count === 0) index = index.replace("| implementing |", "| ready |");
  if (count === 2) index = index.replace("| needs-revision |", "| implementing |");
  put(this.root, "docs/iterations/README.md", index);
  commit(this, "Change active iterations");
});

Given("the iteration index is replaced and committed with:", function (source) {
  put(this.root, "docs/iterations/README.md", expand(source) + "\n");
  commit(this, "Replace iteration index");
});

Given("the feature has invalid comment bytes and mode {string}", function (mode) {
  const existing = fs.readFileSync(this.featurePath);
  const bytes = Buffer.concat([Buffer.from("# invalid comment "), Buffer.from([0xff, 0xfe]), Buffer.from("\n"), existing]);
  fs.writeFileSync(this.featurePath, bytes);
  fs.chmodSync(this.featurePath, Number.parseInt(mode, 8));
  commit(this, "Add byte and mode fixture");
});

Given("a concurrent {word} replaces the feature during pick with:", function (kind, source) {
  const raceSource = expand(source) + "\n";
  configureRace(this, kind, raceSource);
});

Given("a concurrent unrelated commit occurs during pick", function () {
  configureRace(this, "unrelated-commit");
});

Given("the owned temporary write will fail after writing some bytes", function () {
  const preload = path.join(this.toolsRoot, "partial-write-preload.cjs");
  this.closedMarker = path.join(this.toolsRoot, "owned-temp-closed");
  fs.writeFileSync(preload, `
const fs = require("node:fs");
const originalOpenSync = fs.openSync;
const originalWriteFileSync = fs.writeFileSync;
const originalCloseSync = fs.closeSync;
let ownedDescriptor;
fs.openSync = function(target, ...args) {
  const descriptor = originalOpenSync.call(this, target, ...args);
  if (typeof target === "string" && target.includes(".bdd-pick-")) ownedDescriptor = descriptor;
  return descriptor;
};
fs.writeFileSync = function(target, data, ...args) {
  if (target !== ownedDescriptor) return originalWriteFileSync.call(this, target, data, ...args);
  const bytes = Buffer.isBuffer(data) ? data : Buffer.from(data);
  originalWriteFileSync.call(this, target, bytes.subarray(0, Math.max(1, Math.floor(bytes.length / 2))));
  const error = new Error("injected partial owned-temp write failure");
  error.code = "EIO";
  throw error;
};
fs.closeSync = function(target) {
  const result = originalCloseSync.call(this, target);
  if (target === ownedDescriptor) originalWriteFileSync(process.env.BDD_CLOSE_MARKER, "closed\\n");
  return result;
};
`);
  this.commandEnv = {
    NODE_OPTIONS: `--require=${preload}`,
    BDD_CLOSE_MARKER: this.closedMarker
  };
});

Given("a colliding ignored pick temporary file will be created by the CLI process", function () {
  fs.appendFileSync(path.join(this.root, ".git/info/exclude"), "\nacceptance-tests/features/.example.feature.bdd-pick-*\n");
  this.pidCollision = true;
});

Given("argc is available on the declared runtime PATH", function () {
  const environment = {...process.env, ...this.commandEnv};
  const resolved = spawnSync("sh", ["-c", "command -v argc"], {encoding: "utf8", env: environment});
  assert.equal(resolved.status, 0, "argc is unavailable on the declared runtime PATH");
  const executable = resolved.stdout.trim();
  assert.notEqual(executable, "", "command -v argc returned no executable");
  fs.accessSync(executable, fs.constants.X_OK);
});

Given("the worktree has an unrelated {word} change", function (kind) {
  if (kind === "untracked") put(this.root, "untracked.txt", "dirty\n");
  if (kind === "unstaged") {
    put(this.root, "unrelated.txt", "clean\n");
    commit(this, "Add unrelated file");
    put(this.root, "unrelated.txt", "dirty\n");
  }
  if (kind === "staged") {
    put(this.root, "staged.txt", "dirty\n");
    git(this, "add", "staged.txt");
  }
});

When("I run {string}", function (command) {
  const args = command.split(" ");
  assert.equal(args.shift(), "dev");
  runDev(this, args);
});

When("I run pending for commit {string} as JSON", function (name) {
  const sha = this.commits.get(name);
  runDev(this, ["bdd", "pending", sha, "--json"]);
});

When("I pick the declaration {string}", function (declaration) {
  const line = lineContaining(this, declaration);
  runDev(this, ["bdd", "pick", `acceptance-tests/features/example.feature:${line}`]);
});

When("I pick the line containing {string}", function (text) {
  const occurrence = text === "@todo" ? 1 : 1;
  const line = lineContaining(this, text, occurrence);
  runDev(this, ["bdd", "pick", `acceptance-tests/features/example.feature:${line}`]);
});

When("I pick the line before {string}", function (text) {
  const line = lineContaining(this, text) - 1;
  runDev(this, ["bdd", "pick", `acceptance-tests/features/example.feature:${line}`]);
});

When("I pick {string} from commit {string}", function (declaration, name) {
  const line = lineContaining(this, declaration);
  const sha = this.commits.get(name);
  runDev(this, ["bdd", "pick", `acceptance-tests/features/example.feature:${line}`, "--from", sha]);
});

When("I pick {string} from commit {string} during the concurrent change", function (declaration, name) {
  const line = lineContaining(this, declaration);
  this.before = snapshot(this);
  runDev(this, ["bdd", "pick", `acceptance-tests/features/example.feature:${line}`, "--from", this.commits.get(name)]);
});

When("I pick the declaration through the PID-collision shell {string}", function (declaration) {
  const line = lineContaining(this, declaration);
  this.before = snapshot(this);
  const script = `sentinel="acceptance-tests/features/.example.feature.bdd-pick-$$"; printf 'unowned sentinel\\n' > "$sentinel"; exec "$DEV_COMMAND" bdd pick "$PICK_REFERENCE"`;
  this.result = spawnSync("bash", ["-c", script], {
    cwd: this.root,
    encoding: "utf8",
    env: {
      ...process.env,
      MEMBA_DEVENV_SHELL: "1",
      DEVENV_ROOT: sourceRoot,
      DEV_COMMAND: dev,
      PICK_REFERENCE: `acceptance-tests/features/example.feature:${line}`
    }
  });
  this.sentinelPaths = fs.readdirSync(path.dirname(this.featurePath))
    .filter(name => name.startsWith(".example.feature.bdd-pick-"))
    .map(name => path.join(path.dirname(this.featurePath), name));
});

Then("the command succeeds", function () {
  assert.equal(this.result.status, 0, this.result.stderr || this.result.stdout);
});

Then("the command fails", function () {
  assert.notEqual(this.result.status, 0, this.result.stdout);
});

Then("the command exits with status {int}", function (status) {
  assert.equal(this.result.status, status, this.result.stderr || this.result.stdout);
});

Then("the command fails without stdout", function () {
  assert.notEqual(this.result.status, 0);
  assert.equal(this.result.stdout, "");
});

Then("stdout includes {string}", function (text) {
  assert.match(this.result.stdout, new RegExp(text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
});

Then("stdout does not include {string}", function (text) {
  assert.doesNotMatch(this.result.stdout, new RegExp(text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
});

Then("stderr includes {string}", function (text) {
  assert.match(this.result.stderr, new RegExp(text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
});

Then("command output includes {string}", function (text) {
  assert.match(this.result.stdout + this.result.stderr, new RegExp(text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
});

Then("the JSON report names the committed HEAD", function () {
  const report = JSON.parse(this.result.stdout);
  assert.equal(report.commit, git(this, "rev-parse", "HEAD"));
});

Then("the JSON report names commit {string}", function (name) {
  const report = JSON.parse(this.result.stdout);
  assert.equal(report.commit, this.commits.get(name));
});

Then("pending domain declarations are:", function (table) {
  const report = JSON.parse(this.result.stdout);
  assert.deepEqual(report.pending.map(({declaration, scenario}) => ({declaration, scenario})), table.hashes());
});

Then("pending journeys are:", function (table) {
  const report = JSON.parse(this.result.stdout);
  assert.deepEqual(report.pending_journeys.map(({declaration, scenario}) => ({declaration, scenario})), table.hashes());
});

Then("the pending reference points at the exact {string} line", function (declaration) {
  const report = JSON.parse(this.result.stdout);
  const expectedLine = this.committedFeatureSource.split("\n").findIndex(line => line.includes(declaration)) + 1;
  assert.notEqual(expectedLine, 0);
  assert.equal(report.pending[0].line, expectedLine);
  assert.equal(report.pending[0].reference, `acceptance-tests/features/example.feature:${report.pending[0].line}`);
});

Then("pending declaration references match their source lines", function () {
  const report = JSON.parse(this.result.stdout);
  for (const item of report.pending) {
    const declaration = item.declaration === "Examples" ? "Examples: Portable formats" : `${item.declaration}: ${item.scenario}`;
    const expectedLine = this.committedFeatureSource.split("\n").findIndex(line => line.includes(declaration)) + 1;
    assert.equal(item.line, expectedLine);
    assert.equal(item.reference, `acceptance-tests/features/example.feature:${expectedLine}`);
  }
});

Then("the feature now equals:", function (source) {
  assert.equal(fs.readFileSync(this.featurePath, "utf8"), source + "\n");
});

Then("the feature contains {string}", function (text) {
  assert.match(fs.readFileSync(this.featurePath, "utf8"), new RegExp(expand(text).replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
});

Then("the feature does not contain {string}", function (text) {
  assert.doesNotMatch(fs.readFileSync(this.featurePath, "utf8"), new RegExp(text));
});

Then("no file bytes changed", function () {
  assert.deepEqual(snapshot(this), this.before);
});

Then("the concurrent feature is preserved", function () {
  assert.deepEqual(fs.readFileSync(this.featurePath), this.concurrentFeatureBytes);
});

Then("the selected feature remains unchanged", function () {
  const before = Buffer.from(this.before.find(([name]) => name === "acceptance-tests/features/example.feature")[1], "base64");
  assert.deepEqual(fs.readFileSync(this.featurePath), before);
});

Then("HEAD no longer names commit {string}", function (name) {
  assert.notEqual(git(this, "rev-parse", "HEAD"), this.commits.get(name));
});

Then("the owned temporary descriptor was closed", function () {
  assert.equal(fs.readFileSync(this.closedMarker, "utf8"), "closed\n");
});

Then("no owned pick temporary file remains", function () {
  const remaining = fs.readdirSync(path.dirname(this.featurePath))
    .filter(name => name.startsWith(".example.feature.bdd-pick-"));
  assert.deepEqual(remaining, []);
});

Then("the unowned collision sentinel remains unchanged", function () {
  assert.equal(this.sentinelPaths.length, 1);
  assert.equal(fs.readFileSync(this.sentinelPaths[0], "utf8"), "unowned sentinel\n");
});

Then("only the TODO tag bytes changed and mode remains {string}", function (mode) {
  const before = Buffer.from(this.before.find(([name]) => name === "acceptance-tests/features/example.feature")[1], "base64");
  const expected = Buffer.from(before);
  const offset = expected.indexOf(Buffer.from("@todo"));
  assert.notEqual(offset, -1);
  const replaced = Buffer.concat([expected.subarray(0, offset), Buffer.from("@wip"), expected.subarray(offset + 5)]);
  assert.deepEqual(fs.readFileSync(this.featurePath), replaced);
  assert.equal(fs.statSync(this.featurePath).mode & 0o7777, Number.parseInt(mode, 8));
});
