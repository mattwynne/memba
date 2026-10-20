#!/usr/bin/env node
const {fromCommit, pick} = require("./core.cjs");

function usage(message, status = 2) {
  if (message) console.error(message);
  const output = status === 0 ? console.log : console.error;
  output("Usage: dev bdd <command>");
  output("");
  output("Commands:");
  output("  pending [COMMIT] [--json]");
  output("  pick FEATURE:EXACT_DECLARATION_LINE [--from COMMIT]");
  process.exitCode = status;
}

function pendingHelp() {
  console.log("Usage: dev bdd pending [COMMIT] [--json]");
  console.log("Report pickable domain work and pending journeys from an immutable Git snapshot.");
}

function pendingUsage(message) {
  if (message) console.error(message);
  console.error("Usage: dev bdd pending [COMMIT] [--json]");
  process.exitCode = 2;
}

function pickHelp() {
  console.log("Usage: dev bdd pick FEATURE:EXACT_DECLARATION_LINE [--from COMMIT]");
  console.log("Replace one eligible declaration's local @todo with @wip in a clean worktree.");
}

function parsePending(args) {
  let commit = "HEAD";
  let commitSet = false;
  let json = false;
  for (const argument of args) {
    if (argument === "--json" && !json) json = true;
    else if (!argument.startsWith("-") && !commitSet) {
      commit = argument;
      commitSet = true;
    }
    else return null;
  }
  return {commit, json};
}

function parsePick(args) {
  if (!args.length || args[0].startsWith("-")) return null;
  const result = {reference: args[0], from: undefined};
  for (let index = 1; index < args.length; index += 1) {
    if (args[index] !== "--from" || result.from !== undefined || index + 1 >= args.length) return null;
    result.from = args[index + 1];
    index += 1;
  }
  return result;
}

function printHuman(report) {
  console.log(`Commit: ${report.commit}`);
  console.log(`Active iteration: ${report.active_iteration}`);
  console.log(`Plan: ${report.plan}`);
  if (report.domain_complete) console.log("Domain loop complete (iteration is not necessarily merged).\n");
  else console.log(`Pending domain work (${report.pending.length}):`);
  for (const item of report.pending) console.log(`  ${item.reference}  ${item.declaration}: ${item.scenario}`);
  console.log(`Pending journeys (${report.pending_journeys.length}):`);
  for (const item of report.pending_journeys) console.log(`  ${item.reference}  ${item.declaration}: ${item.scenario}`);
}

function main(args) {
  const command = args.shift();
  if (command === "-h" || command === "--help") return usage(undefined, 0);
  if (command === "pending") {
    if (args.includes("-h") || args.includes("--help")) return pendingHelp();
    const options = parsePending(args);
    if (!options) return pendingUsage("Invalid pending arguments.");
    const report = fromCommit(options.commit);
    if (options.json) console.log(JSON.stringify(report));
    else printHuman(report);
    return;
  }
  if (command === "pick") {
    if (args.includes("-h") || args.includes("--help")) return pickHelp();
    const options = parsePick(args);
    if (!options) return usage("Invalid pick arguments.");
    const selected = pick(options.reference, options.from);
    console.log(`Picked ${selected.reference} (${selected.declaration}: ${selected.scenario}).`);
    return;
  }
  usage("Expected pending or pick.");
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
