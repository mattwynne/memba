#!/usr/bin/env python3
"""Repeated, tool-free navigator decisions through native Fabro; not a workflow controller."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess

WORKFLOW = Path(__file__).resolve().parent.parent
CASE = WORKFLOW / "eval/cases/scenario-passes.md"


def wilson(successes, total):
    """Two-sided 95% Wilson score interval; no observations means no estimate."""
    if not total:
        return None
    z = 1.959963984540054
    p = successes / total
    denominator = 1 + z * z / total
    centre = (p + z * z / (2 * total)) / denominator
    half = z * math.sqrt(p * (1 - p) / total + z * z / (4 * total**2)) / denominator
    return [max(0, centre - half), min(1, centre + half)]


def prepare(out, runs, prompt):
    if runs < 1:
        raise ValueError("--runs must be positive")
    # Refuse an existing directory: never overwrite a batch or accidentally relaunch it.
    out.mkdir(parents=True)
    navigator = prompt.read_text()
    case = CASE.read_text()
    config = (WORKFLOW / "workflow.toml").read_text().replace(
        'graph = "workflow.fabro"', 'graph = "navigator.fabro"'
    ).replace('plan = ""', 'plan = "the iteration plan supplied below"')
    (out / "navigator-prompt.md").write_text(navigator)
    (out / "case.md").write_text(case)
    (out / "prompt.md").write_text(navigator + "\n\n---\n\n" + case)
    (out / "workflow.toml").write_text(config)
    nodes = [f"trial_{i}" for i in range(1, runs + 1)]
    edges = [f"  {a} -> {b}" for a, b in zip(["start"] + nodes, nodes + ["done"])]
    # Full fidelity suppresses the previous trial's preamble. Prompt nodes have
    # no tools or continuing conversation: every trial is a fresh single call.
    (out / "navigator.fabro").write_text(
        'digraph NavigatorUnitEval {\n'
        '  graph [goal="Choose the navigator handoff", default_max_retries=0]\n'
        '  start [shape=Mdiamond]\n  done [shape=Msquare]\n'
        '  node [shape=tab, backend="api", fidelity="full", prompt="@prompt.md"]\n'
        + "\n".join(f'  {node} [label="Navigator"]' for node in nodes) + "\n"
        + "\n".join(edges) + "\n}\n"
    )
    manifest = {
        "runs": runs, "expected_label": "check", "case": "scenario-passes",
        "prompt_sha256": hashlib.sha256(navigator.encode()).hexdigest(),
        "case_sha256": hashlib.sha256(case.encode()).hexdigest(),
        "source_head": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
    }
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def report(out):
    manifest = json.loads((out / "manifest.json").read_text())
    events = [json.loads(line) for line in (out / "dump/events.jsonl").read_text().splitlines()]
    completed = {e["node_id"]: e["properties"] for e in events if e["event"] == "stage.completed"}
    trials = []
    for i in range(1, manifest["runs"] + 1):
        node = f"trial_{i}"
        stage = completed.get(node, {})
        replies = list((out / "dump/stages").glob(f"*-{node}@1/response.md"))
        observed = len(replies) == 1 and bool(replies[0].read_text().strip())
        label = stage.get("preferred_label")  # Fabro's extraction, not our JSON parser/LLM judge.
        passed = observed and stage.get("status") == "succeeded" and label == manifest["expected_label"]
        trials.append({"trial": i, "route": label,
                       "result": "pass" if passed else "wrong_decision" if observed else "no_response"})
    observed = sum(t["result"] != "no_response" for t in trials)
    successes = sum(t["result"] == "pass" for t in trials)
    summary = {**manifest, "observed": observed, "successes": successes,
               "no_response": len(trials) - observed, "wilson_95": wilson(successes, observed),
               "trials": trials}
    (out / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(f"{successes}/{observed} observed decisions selected checks; "
          f"{len(trials) - observed}/{len(trials)} requested trials have no response.")
    if observed:
        low, high = summary["wilson_95"]
        print(f"Success rate {successes / observed:.1%}; 95% Wilson interval {low:.1%}–{high:.1%}.")
    print(f"Evidence: {out}")
    return 0 if successes == len(trials) else 1


def run(args):
    out = args.out.resolve()
    prepare(out, args.runs, args.prompt)

    def cli(name, *command, check=True):
        with (out / f"{name}.json").open("w") as stdout, (out / f"{name}.stderr").open("w") as stderr:
            subprocess.run(["fabro", "--no-upgrade-check", *command, "--server", args.server],
                           stdout=stdout, stderr=stderr, check=check)
        return (out / f"{name}.json").read_text()

    with (out / "validation.log").open("w") as log:
        subprocess.run(["fabro", "--no-upgrade-check", "validate", str(out / "workflow.toml")],
                       stdout=log, stderr=subprocess.STDOUT, check=True)
    # One launch only. Unknown acknowledgement, interruption or error is retained;
    # never replace it with another launch. The saved run ID supports later inspection.
    launch = json.loads(cli("launch", "run", str(out / "workflow.toml"), "--detach", "--json",
                            "--environment", "memba-dev",
                            "--label", f"navigator-eval={out.name}"))
    run_id = launch["run_id"]
    print(f"Run {run_id}; {args.runs} predeclared trials. Evidence: {out}", flush=True)
    terminal = json.loads(cli("wait", "wait", run_id, "--json", "--interval", "5000", check=False))
    if terminal.get("status") not in ("succeeded", "failed", "cancelled", "canceled", "interrupted"):
        raise RuntimeError(f"Run {run_id} is not terminal; inspect it, do not relaunch this batch")
    cli("dump", "dump", run_id, "--output", str(out / "dump"))
    return report(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    launch = commands.add_parser("run")
    launch.add_argument("--runs", type=int, required=True, help="Choose sample size before launching")
    launch.add_argument("--out", type=Path, required=True, help="New directory under eval/results/")
    launch.add_argument("--prompt", type=Path, default=WORKFLOW / "prompts/bdd-navigator.md")
    launch.add_argument("--server", default=os.environ.get("FABRO_SERVER", "https://fabro.home.wynne.family"))
    summarize = commands.add_parser("report", help="Recompute statistics offline; never launch or retry")
    summarize.add_argument("out", type=Path)
    args = parser.parse_args()
    raise SystemExit(run(args) if args.command == "run" else report(args.out))


if __name__ == "__main__":
    main()
