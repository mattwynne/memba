#!/usr/bin/env bash
set -euo pipefail

workflow_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workflow_path=$workflow_dir/workflow.fabro
review_prompt_path=$workflow_dir/prompts/review.md
synthesis_prompt_path=$workflow_dir/prompts/synthesize_review.md
collector_path=$workflow_dir/scripts/collect_implementation_evidence.sh

assert_contains() {
  local expected=$1

  if ! grep -Fq "$expected" "$workflow_path"; then
    echo "Expected iteration-review workflow to contain: $expected" >&2
    exit 1
  fi
}

assert_not_contains() {
  local unexpected=$1

  if grep -Fq "$unexpected" "$workflow_path"; then
    echo "Expected iteration-review workflow not to contain: $unexpected" >&2
    exit 1
  fi
}

assert_file_contains() {
  local file=$1
  local expected=$2

  if ! grep -Fq "$expected" "$file"; then
    echo "Expected $file to contain: $expected" >&2
    exit 1
  fi
}

review_retry_count=$(grep -Fc 'retry_policy="patient"' "$workflow_path")
if [ "$review_retry_count" -lt 4 ]; then
  echo "Expected patient retry policy on the three review stages and synthesis; found $review_retry_count" >&2
  exit 1
fi

# Review synthesis requires all independent reviewer Markdown reports. Reviewers
# must fan out in parallel, fan in through Fabro's merge node, and fail closed
# through the infrastructure route if the merged evidence is incomplete.
assert_contains 'script="bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh'
assert_contains 'review_fork ['
assert_contains 'shape=component,'
assert_contains 'max_parallel=3'
assert_contains 'review_merge ['
assert_contains 'shape=tripleoctagon'
assert_contains 'collect_implementation_evidence -> review_fork [condition="outcome=succeeded"]'
assert_contains 'review_fork -> claude_review'
assert_contains 'review_fork -> codex_review'
assert_contains 'review_fork -> gemini_review'
assert_contains 'claude_review -> review_merge'
assert_contains 'codex_review -> review_merge'
assert_contains 'gemini_review -> review_merge'
assert_contains 'review_merge -> synthesize_review [condition="outcome=succeeded"]'
assert_contains 'review_merge -> synthesis_unavailable [label="Reviewer evidence unavailable"]'
assert_contains 'synthesize_review -> review_gate [condition="outcome=succeeded"]'
assert_contains 'synthesize_review -> synthesis_unavailable [label="Synthesis unavailable"]'

assert_not_contains 'claude_review -> codex_review'
assert_not_contains 'codex_review -> gemini_review'
assert_not_contains 'gemini_review -> synthesize_review'

assert_file_contains "$synthesis_prompt_path" 'parallel.results'
assert_file_contains "$synthesis_prompt_path" 'claude_review'
assert_file_contains "$synthesis_prompt_path" 'codex_review'
assert_file_contains "$synthesis_prompt_path" 'gemini_review'
assert_file_contains "$synthesis_prompt_path" 'Fail closed if you cannot see usable, substantive reviewer evidence for all three required branches in `parallel.results`.'
assert_file_contains "$synthesis_prompt_path" '{"outcome":"failed","failure_reason":"parallel fan-in did not expose usable review evidence for every required reviewer"}'

# Review repair verification must fail closed when comparing the before/after
# patches. `cmp` is not available in all Fabro sandboxes and can fail open when
# used directly in an `if` condition.
assert_contains 'git diff --no-index --quiet \"$before\" \"$after\"'
assert_contains 'Could not compare ${kind} repair patches.'
assert_not_contains 'cmp -s \"$before\" \"$after\"'

# Reviewer prompts and collected evidence must keep Memba's chosen domain,
# CQRS/event-sourcing, and responsibility-driven design references visible.
for reference_doc in \
  'docs/reference/domain-driven-design.md' \
  'docs/reference/cqrs.md' \
  'docs/reference/event-sourcing.md' \
  'docs/reference/responsibility-driven-design.md'; do
  assert_file_contains "$review_prompt_path" "$reference_doc"
  assert_file_contains "$synthesis_prompt_path" "$reference_doc"
  assert_file_contains "$collector_path" "$reference_doc"
done

# Code-health recording must have live repository access and must not silently
# continue to finalization when it reports or routes a recording failure.
assert_contains 'shape=box,'
assert_contains 'output_schema="routing",'
assert_contains 'record_code_health -> final_artifact_gate [condition="context.code_health_recording_ok=true"]'
assert_contains 'record_code_health -> code_health_recording_failed [label="Code-health recording failed"]'
assert_contains 'code_health_recording_failed -> exit'
assert_not_contains 'record_code_health -> final_artifact_gate;'

# Review preflight must capture origin/main, not Fabro's checkpointed HEAD, as
# the squash base for review polish publication.
assert_contains 'script="bash .fabro/workflows/iteration-review/scripts/preflight_sandbox.sh"'
assert_not_contains 'git rev-parse HEAD > .fabro/tmp/review-start-sha.txt'

python3 - "$workflow_path" <<'PY'
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

workflow = Path(sys.argv[1]).read_text()

NODE_BLOCK_RE = re.compile(
    r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*\[\s*\n(.*?)^\s*\]\s*$",
    re.MULTILINE | re.DOTALL,
)
EDGE_RE = re.compile(
    r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*->\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?:\[(.*?)\])?\s*$",
    re.MULTILINE,
)
CONDITION_RE = re.compile(r'condition="([^"]+)"')

nodes = {name: body for name, body in NODE_BLOCK_RE.findall(workflow)}
goal_gates = {name for name, body in nodes.items() if "goal_gate=true" in body}
expected_goal_gates = {"finalize_iteration_status"}
if goal_gates != expected_goal_gates:
    raise SystemExit(
        f"expected only positive review finalization goal gate {expected_goal_gates}, "
        f"found {sorted(goal_gates)}"
    )

failure_nodes = sorted(name for name, body in nodes.items() if 'label="Fail:' in body)
if any(name in goal_gates for name in failure_nodes):
    raise SystemExit(
        f"failure-message terminal nodes must not be goal gates under skipped-gate semantics: {failure_nodes}"
    )

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
    if "||" in condition or "&&" in condition or "internal.node_visit_count" in condition:
        raise AssertionError(f"condition not covered by routing regression: {condition}")
    if condition.startswith("outcome="):
        return outcome == condition.split("=", 1)[1]
    if condition.startswith("context."):
        key, expected = condition.split("=", 1)
        return context.get(key.removeprefix("context.")) == expected
    raise AssertionError(f"condition not covered by routing regression: {condition}")


def next_node(node: str, outcomes: dict[str, str], context: dict[str, str]) -> str | None:
    # Collapse the parallel review fan-out deterministically while preserving
    # evidence that all three reviewer branches feed the merge before synthesis.
    if node == "review_fork":
        return "claude_review"
    if node == "claude_review":
        return "codex_review"
    if node == "codex_review":
        return "gemini_review"
    if node == "gemini_review":
        return "review_merge"

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
        if len(unconditional) > 1:
            raise AssertionError(f"ambiguous unconditional fallback from {node}: {unconditional}")
        return unconditional[0].target
    raise AssertionError(f"no route from {node} for outcome={outcome}")


def run_path(outcomes: dict[str, str], context: dict[str, str]) -> tuple[list[str], bool]:
    node = "start"
    path: list[str] = []
    for _ in range(80):
        path.append(node)
        if node == "exit":
            break
        next_ = next_node(node, outcomes, context)
        if next_ is None:
            raise AssertionError(f"dead end at {path[-1]}")
        node = next_
    else:
        raise AssertionError(f"path did not terminate: {path}")

    gates_satisfied = all(
        gate in path and outcomes.get(gate, "succeeded") in {"succeeded", "partially_succeeded"}
        for gate in goal_gates
    )
    return path, gates_satisfied


base_success_outcomes = {
    "read_plan": "succeeded",
    "preflight_sandbox": "succeeded",
    "dev_check": "succeeded",
    "collect_implementation_evidence": "succeeded",
    "review_merge": "succeeded",
    "synthesize_review": "succeeded",
    "record_code_health": "succeeded",
    "final_artifact_gate": "succeeded",
    "publish_polish_to_main": "succeeded",
    "finalize_iteration_status": "succeeded",
    "final_summary": "succeeded",
}
base_success_context = {
    "implementation_accepted": "true",
    "code_health_recording_ok": "true",
}

path, ok = run_path(base_success_outcomes, base_success_context)
expected_tail = ["record_code_health", "final_artifact_gate", "publish_polish_to_main", "finalize_iteration_status", "final_summary", "exit"]
if not ok or path[-6:] != expected_tail:
    raise SystemExit(
        "expected accepted review with successful code-health recording to publish/finalize and satisfy gates, "
        f"got ok={ok}, path={path}"
    )

recorder_failure_context = dict(base_success_context, code_health_recording_ok="false")
path, ok = run_path(base_success_outcomes, recorder_failure_context)
if ok or "finalize_iteration_status" in path or path[-3:] != ["record_code_health", "code_health_recording_failed", "exit"]:
    raise SystemExit(
        "expected genuine code-health recorder failure to route to the failure message and fail via skipped finalization gate, "
        f"got ok={ok}, path={path}"
    )

print("iteration-review workflow routing simulation tests passed")
PY

echo "iteration-review report routing tests passed"
