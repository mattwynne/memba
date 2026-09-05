#!/usr/bin/env bash
set -euo pipefail

workflow_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workflow_path=$workflow_dir/workflow.fabro

assert_contains() {
  local expected=$1

  if ! grep -Fq "$expected" "$workflow_path"; then
    echo "Expected iteration-implementation workflow to contain: $expected" >&2
    exit 1
  fi
}

assert_not_contains() {
  local unexpected=$1

  if grep -Fq "$unexpected" "$workflow_path"; then
    echo "Expected iteration-implementation workflow not to contain: $unexpected" >&2
    exit 1
  fi
}

# Fabro 0.316 allows a failed command node to route onward if the graph handles
# that outcome. The implementation workflow's positive success contract is that
# the implementation is actually published to main; failure-message nodes are not
# goal gates because skipped goal gates fail too.
assert_contains 'publish_to_main ['
assert_contains 'goal_gate=true'
assert_contains 'final_artifact_gate -> publish_to_main [condition="outcome=succeeded"]'
assert_contains 'final_artifact_gate -> final_artifact_failed'
assert_contains 'final_artifact_failed -> exit'
assert_not_contains 'final_artifact_gate -> publish_to_main;'

python3 - "$workflow_path" <<'PY'
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

workflow = Path(sys.argv[1]).read_text()

NODE_RE = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*\[", re.MULTILINE)
EDGE_RE = re.compile(
    r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*->\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?:\[(.*?)\])?\s*$",
    re.MULTILINE,
)
CONDITION_RE = re.compile(r'condition="([^"]+)"')

nodes: dict[str, str] = {}
for match in NODE_RE.finditer(workflow):
    name = match.group(1)
    start = match.end()
    end = workflow.find("\n    ]", start)
    if end == -1:
        continue
    nodes[name] = workflow[start:end]

goal_gates = {name for name, body in nodes.items() if "goal_gate=true" in body}
expected_goal_gates = {"publish_to_main"}
if goal_gates != expected_goal_gates:
    raise SystemExit(f"expected only positive publish goal gate {expected_goal_gates}, found {sorted(goal_gates)}")

failure_nodes = sorted(name for name, body in nodes.items() if 'label="Fail:' in body)
if any(name in goal_gates for name in failure_nodes):
    raise SystemExit(f"failure nodes must not be goal gates under skipped-gate semantics: {failure_nodes}")

@dataclass(frozen=True)
class Edge:
    source: str
    target: str
    condition: str | None

edges_by_source: dict[str, list[Edge]] = {}
for source, target, attrs in EDGE_RE.findall(workflow):
    condition_match = CONDITION_RE.search(attrs or "")
    edge = Edge(source, target, condition_match.group(1) if condition_match else None)
    edges_by_source.setdefault(source, []).append(edge)


def condition_matches(condition: str, outcome: str, context: dict[str, str]) -> bool:
    # This focused simulator covers the condition shapes used on the audited
    # implementation success/failure paths. It intentionally fails if the graph
    # grows a condition this regression no longer understands.
    if "||" in condition or "&&" in condition or "internal.node_visit_count" in condition:
        raise AssertionError(f"condition not covered by routing regression: {condition}")
    if condition.startswith("outcome="):
        return outcome == condition.split("=", 1)[1]
    if condition.startswith("context."):
        key, expected = condition.split("=", 1)
        return context.get(key.removeprefix("context.")) == expected
    if condition.startswith("preferred_label="):
        return context.get("preferred_label") == condition.split("=", 1)[1]
    raise AssertionError(f"condition not covered by routing regression: {condition}")


def next_node(node: str, outcomes: dict[str, str], context: dict[str, str]) -> str | None:
    outgoing = edges_by_source.get(node, [])
    if not outgoing:
        return None
    outcome = outcomes.get(node, "succeeded")
    conditional = [edge for edge in outgoing if edge.condition is not None]
    for edge in conditional:
        if condition_matches(edge.condition or "", outcome, context):
            return edge.target
    unconditional = [edge for edge in outgoing if edge.condition is None]
    if unconditional:
        # Fabro uses lexical tiebreaks for equally weighted unconditional edges.
        # The audited nodes have a single unconditional fallback.
        return sorted(edge.target for edge in unconditional)[0]
    raise AssertionError(f"no route from {node} for outcome={outcome}")


def run_path(outcomes: dict[str, str], context: dict[str, str]) -> tuple[list[str], bool]:
    node = "start"
    path: list[str] = []
    for _ in range(80):
        path.append(node)
        if node == "exit":
            break
        node = next_node(node, outcomes, context)
        if node is None:
            raise AssertionError(f"dead end at {path[-1]}")
    else:
        raise AssertionError(f"path did not terminate: {path}")

    gates_satisfied = all(
        (outcomes.get(gate, "skipped") if gate in path else "skipped") in {"succeeded", "partially_succeeded"}
        for gate in goal_gates
    )
    return path, gates_satisfied

base_success_outcomes = {
    "verify_source_head": "succeeded",
    "read_plan": "succeeded",
    "wip_gate": "succeeded",
    "preflight_sandbox": "succeeded",
    "resume_gate": "succeeded",
    "sync_task_list": "succeeded",
    "todo_readable": "succeeded",
    # This command deliberately exits 1 when there are no unchecked tasks.
    "all_tasks_done": "failed",
    "dev_check": "succeeded",
    "collect_implementation_evidence": "succeeded",
    "plan_conformance_gate": "succeeded",
    "final_artifact_gate": "succeeded",
    "publish_to_main": "succeeded",
    "final_summary": "succeeded",
}
base_success_context = {"plan_conformant": "true"}

path, ok = run_path(base_success_outcomes, base_success_context)
if not ok or path[-3:] != ["publish_to_main", "final_summary", "exit"]:
    raise SystemExit(f"expected valid success path through publish_to_main to satisfy gates, got ok={ok}, path={path}")

artifact_failure_outcomes = dict(base_success_outcomes, final_artifact_gate="failed")
path, ok = run_path(artifact_failure_outcomes, base_success_context)
if ok or "publish_to_main" in path or path[-3:] != ["final_artifact_gate", "final_artifact_failed", "exit"]:
    raise SystemExit(
        "expected failed final_artifact_gate to avoid publish and fail via skipped publish gate, "
        f"got ok={ok}, path={path}"
    )

publish_failure_outcomes = dict(base_success_outcomes, publish_to_main="failed", publish_conflict_recovery_gate="failed")
path, ok = run_path(publish_failure_outcomes, base_success_context)
if ok or path[-4:] != ["publish_to_main", "publish_conflict_recovery_gate", "publish_failed", "exit"]:
    raise SystemExit(
        "expected failed publish_to_main to reach exit with unsatisfied publish gate, "
        f"got ok={ok}, path={path}"
    )

source_failure_outcomes = {"verify_source_head": "failed", "source_head_failed": "failed"}
path, ok = run_path(source_failure_outcomes, {})
if ok or path != ["start", "verify_source_head", "source_head_failed", "exit"]:
    raise SystemExit(f"expected wrong source HEAD to fail before reading the plan, got ok={ok}, path={path}")

read_failure_outcomes = {
    "verify_source_head": "succeeded",
    "read_plan": "failed",
    "read_failed": "failed",
}
path, ok = run_path(read_failure_outcomes, {})
if ok or path != ["start", "verify_source_head", "read_plan", "read_failed", "exit"]:
    raise SystemExit(f"expected early terminal failure to fail via skipped publish gate, got ok={ok}, path={path}")

print("iteration-implementation workflow routing tests passed")
PY
