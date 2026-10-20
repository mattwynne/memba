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

function writeAtomic(target, contents) {
  fs.mkdirSync(path.dirname(target), {recursive: true});
  const temporary = `${target}.tmp-${process.pid}`;
  try {
    fs.writeFileSync(temporary, contents);
    fs.renameSync(temporary, target);
  } finally {
    try { fs.unlinkSync(temporary); } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
  }
}

function ensureScratchIgnored(root) {
  const excludeName = runGit(root, ["rev-parse", "--git-path", "info/exclude"]);
  const exclude = path.isAbsolute(excludeName) ? excludeName : path.join(root, excludeName);
  fs.mkdirSync(path.dirname(exclude), {recursive: true});
  const current = fs.existsSync(exclude) ? fs.readFileSync(exclude, "utf8") : "";
  if (!current.split(/\r?\n/).includes("/.fabro/tmp/")) {
    fs.appendFileSync(exclude, `${current && !current.endsWith("\n") ? "\n" : ""}/.fabro/tmp/\n`);
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

function setup(root) {
  ensureScratchIgnored(root);
  assertClean(root);
  fs.mkdirSync(scratchPaths(root).directory, {recursive: true});
  console.log(JSON.stringify({preferred_next_label: "inspect"}));
}

function inspect(root) {
  const files = scratchPaths(root);
  ensureScratchIgnored(root);
  assertClean(root);
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
  if (actual.length !== expected.length || actual.some((key, index) => key !== expected[index])) {
    throw new Error(`selector response must contain exactly ${expected.join(", ")}`);
  }
  if (writtenKeys.length !== actual.length || new Set(writtenKeys).size !== writtenKeys.length) {
    throw new Error("selector response contains duplicate or nested fields");
  }
  for (const field of expected) {
    if (typeof value[field] !== "string" || !value[field].trim() || value[field] !== value[field].trim()) {
      throw new Error(`selector response ${field} must be a non-empty exact string`);
    }
  }
  return value;
}

function pick(root, source) {
  const files = scratchPaths(root);
  const answer = selectorResponse(source);
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
  publicBdd(root, ["pick", choice.reference, "--from", commit]);
  writeAtomic(files.plan, report.plan + "\n");
  fs.appendFileSync(files.notes, JSON.stringify({
    commit,
    tree,
    plan: report.plan,
    feature: choice.feature,
    scenario: choice.scenario,
    declaration: choice.declaration,
    line: choice.line,
    reference: choice.reference,
    reason: answer.reason
  }) + "\n");
  console.error(`Selected ${choice.reference} at ${commit}: ${answer.reason}`);
  console.log(JSON.stringify({preferred_next_label: "implement"}));
}

function main(args, stdin = fs.readFileSync(0, "utf8")) {
  const root = repositoryRoot();
  if (args.length !== 1) throw new Error("Usage: workflow.cjs setup|inspect|pick");
  if (args[0] === "setup") return setup(root);
  if (args[0] === "inspect") return inspect(root);
  if (args[0] === "pick") return pick(root, stdin);
  throw new Error("Usage: workflow.cjs setup|inspect|pick");
}

if (require.main === module) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}

module.exports = {inspect, pick, selectorResponse, setup};
