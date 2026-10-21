#!/usr/bin/env node
const fs = require("node:fs");
const path = require("node:path");
const {execFileSync, spawnSync} = require("node:child_process");

function runGit(root, args) {
  try {
    return execFileSync("git", args, {
      cwd: root,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"]
    }).trim();
  } catch (error) {
    throw new Error(String(error.stderr || error.message).trim());
  }
}

function repositoryRoot(cwd = process.cwd()) {
  return runGit(cwd, ["rev-parse", "--show-toplevel"]);
}

function scratchPaths(root) {
  const directory = path.join(root, ".fabro/tmp/bdd-plan");
  return {
    directory,
    pending: path.join(directory, "pending.json"),
    selection: path.join(directory, "selection.json"),
    notes: path.join(directory, "selection-notes.jsonl"),
    plan: path.join(directory, "plan-path")
  };
}

function ensureSafeScratchDirectory(root) {
  let current = root;
  for (const component of [".fabro", "tmp", "bdd-plan"]) {
    current = path.join(current, component);
    let stat;
    try {
      stat = fs.lstatSync(current);
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
      fs.mkdirSync(current, {mode: 0o700});
      stat = fs.lstatSync(current);
    }
    if (stat.isSymbolicLink()) {
      throw new Error(`workflow scratch component is a symbolic link: ${path.relative(root, current)}`);
    }
    if (!stat.isDirectory()) {
      throw new Error(`workflow scratch component is not a directory: ${path.relative(root, current)}`);
    }
  }
  return current;
}

function assertRegularFileIfPresent(target, label) {
  let stat;
  try {
    stat = fs.lstatSync(target);
  } catch (error) {
    if (error.code === "ENOENT") return;
    throw error;
  }
  if (stat.isSymbolicLink() || !stat.isFile()) {
    throw new Error(`${label} must be a regular file, not a symbolic link or other file type`);
  }
}

function assertRegularFile(target, label) {
  let stat;
  try {
    stat = fs.lstatSync(target);
  } catch (error) {
    if (error.code === "ENOENT") throw new Error(`${label} is missing`);
    throw error;
  }
  if (stat.isSymbolicLink() || !stat.isFile()) {
    throw new Error(`${label} must be a regular file, not a symbolic link or other file type`);
  }
}

function appendRegularFile(target, contents, label) {
  const noFollow = fs.constants.O_NOFOLLOW;
  if (typeof noFollow !== "number") throw new Error("safe no-follow append is unavailable");
  let descriptor;
  try {
    descriptor = fs.openSync(
      target,
      fs.constants.O_WRONLY | fs.constants.O_APPEND | fs.constants.O_CREAT | noFollow,
      0o600
    );
    if (!fs.fstatSync(descriptor).isFile()) throw new Error(`${label} must be a regular file`);
    fs.writeFileSync(descriptor, contents);
  } finally {
    if (descriptor !== undefined) fs.closeSync(descriptor);
  }
}

function writeAtomic(target, contents) {
  fs.mkdirSync(path.dirname(target), {recursive: true});
  const temporary = `${target}.tmp-${process.pid}`;
  let created = false;
  let descriptor;
  try {
    descriptor = fs.openSync(
      temporary,
      fs.constants.O_WRONLY | fs.constants.O_CREAT | fs.constants.O_EXCL,
      0o600
    );
    created = true;
    fs.writeFileSync(descriptor, contents);
    fs.closeSync(descriptor);
    descriptor = undefined;
    fs.renameSync(temporary, target);
  } finally {
    if (descriptor !== undefined) fs.closeSync(descriptor);
    if (created) {
      try { fs.unlinkSync(temporary); } catch (error) {
        if (error.code !== "ENOENT") throw error;
      }
    }
  }
}

function assertDeclaredScratchIgnored(root) {
  const declared = new Set(fs.readFileSync(path.join(root, ".gitignore"), "utf8").split(/\r?\n/));
  const required = ["/.fabro/tmp/", "/.fabro/blobs/"];
  const missing = required.filter(pattern => !declared.has(pattern));
  if (missing.length) {
    throw new Error(`repository .gitignore must declare owned runtime paths: ${required.join(" and ")}`);
  }
}

function assertClean(root) {
  const status = execFileSync("git", ["status", "--porcelain=v1", "-z", "--untracked-files=all"], {
    cwd: root,
    encoding: "buffer",
    stdio: ["ignore", "pipe", "pipe"]
  });
  if (status.length) throw new Error("worktree must be completely clean outside ignored workflow scratch");
}

function publicBdd(root, args) {
  const result = spawnSync(path.join(root, "bin/dev"), ["bdd", ...args], {
    cwd: root,
    encoding: "utf8"
  });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(result.stderr.trim() || `bin/dev bdd ${args[0]} failed`);
  return result.stdout;
}

function readJson(target, label) {
  let value;
  try {
    value = JSON.parse(fs.readFileSync(target, "utf8"));
  } catch (error) {
    throw new Error(`${label} is missing or invalid: ${error.message}`);
  }
  return value;
}

function setup(root, binding) {
  if (binding !== "HEAD") {
    throw new Error(`selector commit input must be exactly HEAD, got ${JSON.stringify(binding)}`);
  }
  assertDeclaredScratchIgnored(root);
  assertClean(root);
  ensureSafeScratchDirectory(root);
  console.log(JSON.stringify({preferred_next_label: "bootstrap"}));
}

function inspect(root) {
  const files = scratchPaths(root);
  assertDeclaredScratchIgnored(root);
  assertClean(root);
  ensureSafeScratchDirectory(root);
  try { fs.unlinkSync(files.selection); } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }

  const commit = runGit(root, ["rev-parse", "--verify", "HEAD^{commit}"]);
  const tree = runGit(root, ["rev-parse", "--verify", `${commit}^{tree}`]);
  let report;
  try {
    report = JSON.parse(publicBdd(root, ["pending", "HEAD", "--json"]));
  } catch (error) {
    throw new Error(`pending inspection failed: ${error.message}`);
  }
  if (report.commit !== commit) throw new Error("pending inspection did not describe the captured HEAD");
  writeAtomic(files.pending, JSON.stringify(report, null, 2) + "\n");
  writeAtomic(files.selection, JSON.stringify({commit, tree}, null, 2) + "\n");

  if (report.domain_complete) {
    console.error(`Domain loop complete at ${commit}; ${report.pending_journeys.length} pending journey declaration(s) remain reported.`);
    console.log(JSON.stringify({preferred_next_label: "done"}));
  } else {
    console.error(`Pending domain inspection at ${commit}: ${report.pending.length} eligible declaration(s).`);
    console.log(JSON.stringify({preferred_next_label: "choose"}));
  }
}

function selectorResponse(source) {
  let value;
  try {
    value = JSON.parse(source);
  } catch (error) {
    throw new Error(`selector response is not JSON: ${error.message}`);
  }
  if (!value || Array.isArray(value) || typeof value !== "object") {
    throw new Error("selector response must be one JSON object");
  }
  const expected = ["feature", "plan", "reason", "scenario"];
  const actual = Object.keys(value).sort();
  const writtenKeys = [...source.matchAll(/"((?:\\.|[^"\\])*)"\s*:/g)]
    .map(match => JSON.parse(`"${match[1]}"`));
  if (writtenKeys.length !== actual.length || new Set(writtenKeys).size !== writtenKeys.length) {
    throw new Error("selector response contains duplicate or nested fields");
  }
  if (actual.length === 1 && actual[0] === "error") {
    if (typeof value.error !== "string" || !value.error.trim()) {
      throw new Error("selector response error must be a non-empty string");
    }
    return value;
  }
  if (actual.length !== expected.length || actual.some((key, index) => key !== expected[index])) {
    throw new Error(`selector response must contain exactly ${expected.join(", ")}, or error`);
  }
  for (const field of ["feature", "plan", "scenario"]) {
    if (typeof value[field] !== "string" || !value[field].trim() || value[field] !== value[field].trim()) {
      throw new Error(`selector response ${field} must be a non-empty exact string`);
    }
  }
  if (typeof value.reason !== "string" || !value.reason.trim()) {
    throw new Error("selector response reason must be a non-empty string");
  }
  return value;
}

function pick(root, source) {
  const files = scratchPaths(root);
  const answer = selectorResponse(source);
  if (Object.hasOwn(answer, "error")) {
    throw new Error(`selector reported error: ${answer.error.trim()}`);
  }
  ensureSafeScratchDirectory(root);
  assertRegularFileIfPresent(files.notes, "selection notes");
  assertRegularFile(files.selection, "preselection snapshot");
  const snapshot = readJson(files.selection, "preselection snapshot");
  if (!/^[0-9a-f]{40}$/.test(snapshot.commit) || !/^[0-9a-f]{40}$/.test(snapshot.tree)) {
    throw new Error("preselection snapshot has invalid Git object identities");
  }

  assertClean(root);
  const commit = runGit(root, ["rev-parse", "--verify", "HEAD^{commit}"]);
  const tree = runGit(root, ["rev-parse", "--verify", `${commit}^{tree}`]);
  if (tree !== snapshot.tree) {
    throw new Error(`repository tree changed after selection (${snapshot.tree} -> ${tree})`);
  }

  let report;
  try {
    report = JSON.parse(publicBdd(root, ["pending", commit, "--json"]));
  } catch (error) {
    throw new Error(`current pending validation failed: ${error.message}`);
  }
  if (report.commit !== commit) throw new Error("current pending validation did not describe the captured HEAD");
  if (answer.plan !== report.plan) throw new Error(`selector plan is stale or unknown: ${answer.plan}`);
  const matches = report.pending.filter(choice =>
    choice.feature === answer.feature && choice.scenario === answer.scenario);
  if (matches.length !== 1) {
    throw new Error(`selector choice must resolve to exactly one eligible declaration; found ${matches.length}`);
  }

  const choice = matches[0];
  ensureSafeScratchDirectory(root);
  assertRegularFileIfPresent(files.notes, "selection notes");
  publicBdd(root, ["pick", choice.reference, "--from", commit]);
  writeAtomic(files.plan, report.plan + "\n");
  appendRegularFile(files.notes, JSON.stringify({
    commit,
    tree,
    plan: report.plan,
    feature: choice.feature,
    scenario: choice.scenario,
    declaration: choice.declaration,
    line: choice.line,
    reference: choice.reference,
    reason: answer.reason
  }) + "\n", "selection notes");
  console.error(`Selected ${choice.reference} at ${commit}: ${answer.reason}`);
  console.log(JSON.stringify({preferred_next_label: "implement"}));
}

function main(args, stdin = fs.readFileSync(0, "utf8")) {
  const root = repositoryRoot();
  if (args[0] === "setup" && args.length === 2) return setup(root, args[1]);
  if (args[0] === "inspect" && args.length === 1) return inspect(root);
  if (args[0] === "pick" && args.length === 1) return pick(root, stdin);
  throw new Error("Usage: workflow.cjs setup HEAD | inspect | pick");
}

if (require.main === module) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}

module.exports = {appendRegularFile, ensureSafeScratchDirectory, inspect, pick, selectorResponse, setup, writeAtomic};
