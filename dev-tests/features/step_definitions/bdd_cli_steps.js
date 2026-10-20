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

function runDev(world, args) {
  world.before = snapshot(world);
  world.result = spawnSync(dev, args, {
    cwd: world.root,
    encoding: "utf8",
    env: {...process.env, MEMBA_DEVENV_SHELL: "1", DEVENV_ROOT: sourceRoot}
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
