#!/usr/bin/env bash
set -euo pipefail

workflow_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Prompt instructions and graph edges are part of the delivery contract. This
# regression checks ownership boundaries, deterministic routing, and final gates;
# real delivery runs are still required to measure effectiveness.
python3 - "$workflow_dir" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
planner = (root / "prompts/delivery_planner.md").read_text()
implementation = (root / "prompts/implement_next_task.md").read_text()
validation = (root / "prompts/validate_task.md").read_text()
graph = (root / "workflow.fabro").read_text()

checks = [
    ("planner owns task selection", "You own task selection, semantic splitting/reordering" in planner),
    ("planner cannot edit code", "You may edit only this iteration's `todo.md` and files under the iteration's `.delivery/` directory." in planner),
    ("planner writes durable state", ".delivery/execution-state.json" in planner and ".delivery/current-worker-packet.json" in planner),
    ("planner uses binding checkpoint rather than predecessor", "Use that `git rev-parse HEAD` value as `source_baseline`" in planner and "Do not copy the baseline JSON's `pre_planner_head`" in planner and "guard will reject it" in planner),
    ("planner requires exact coverage key", "Each `coverage_map` item must use the exact key `scope`" in planner and "Do not use aliases such as `scope_or_acceptance_layer`" in planner),
    ("planner shows execution-state coverage schema", '"coverage_map": [' in planner and '{"scope": "approved scope or acceptance layer", "pending_task_ids": ["001"], "accepted_task_lines": []}' in planner),
    ("ordinary planner packets exclude the full gate", "For an ordinary implementation or revision packet, `focused_validation` must not include `dev check`" in planner and "deterministic `dev_check` node owns the iteration-wide gate" in planner),
    ("worker reads packet", "Read the current packet" in implementation),
    ("worker does not split/select", "Do not choose a different todo line, split tasks, reorder `todo.md`" in implementation),
    ("single-owner task", "Do not spawn subagents in this per-task node." in implementation),
    ("no duplicate review", "Do not commission an extra independent review" in implementation),
    ("focused validation still required", "Run the packet's focused validation" in implementation),
    ("acceptance owns task check-off", "Only the workflow's `apply_task_verdict` command checks it off after independent acceptance." in implementation),
    ("revision preserves candidate", "Preserve useful candidate work and earlier accepted tasks" in implementation),
    ("worker replan contract", "`replan`" in implementation and "missing preparation" in implementation),
    ("worker result notes match the guard schema", "one non-empty concise string" in implementation and "do not write an array" in implementation),
    ("ready worker result contains only passing validation", "For `ready_for_review`, include only successful final validation runs" in implementation and "every `exit_status` must be `0`" in implementation and "superseded failing TDD/diagnostic runs in `notes`" in implementation),
    ("browser tasks use focused checks", "For browser-facing tasks, run targeted browser scenarios or a focused browser harness" in implementation),
    ("ordinary tasks prohibit every broad gate form", "Do not run `dev check`, `dev check --quick`, `dev ci`, or any other unscoped full-suite command in ordinary implementation tasks." in implementation),
    ("explicit final-validation work preserved", "If the packet explicitly requires a full final-validation task" in implementation),
    ("timeouts do not trigger detached reruns", "Do not launch detached/background full-suite retries" in implementation),
    ("validator remains independent", "Decide from live repository state" in validation),
    ("validator checks packet provenance", "packet provenance" in validation and "ready_for_review" in validation),
    ("validator consumes successful evidence by default", "Do not rerun the worker's successful tests by default." in validation),
    ("validator limits exceptional reruns", "missing, stale, contradictory, or inadequate" in validation and "state the reason" in validation),
    ("validator prohibits every broad gate form", "Do not run `dev check`, `dev check --quick`, `dev ci`, or any other unscoped full-suite command in ordinary validation." in validation),
    ("validator does not reintroduce browser full gate", "do not require a duplicate full `dev check` solely because the task changes UI" in validation),
    ("explicit gate requires successful exit evidence", "require its successful exit evidence before accepting the task" in validation),
    ("planner before worker", "delivery_planner -> guard_delivery_packet" in graph and "guard_delivery_packet -> implement_next_task" in graph),
    ("worker result routing", "route_worker_result -> validate_task" in graph and "route_worker_result -> before_delivery_planner" in graph),
    ("review acceptance returns to planner", "apply_task_verdict -> before_delivery_planner" in graph),
    ("revision goes through planner", 'apply_task_verdict -> before_delivery_planner [condition="outcome=succeeded && preferred_label=revise"]' in graph),
    ("bounded revision worker retained", "revise_task [" in graph and "max_visits=3" in graph),
    ("typed task verdict", 'output_schema="@schemas/task-verdict.json"' in graph),
    ("native structured handoff", 'stdin_source="output.validate_task"' in graph),
    ("minimal task-loop fidelity", re.search(r"delivery_planner \[.*?fidelity=\"truncate\"", graph, re.S) is not None and re.search(r"implement_next_task \[.*?fidelity=\"truncate\"", graph, re.S) is not None and re.search(r"validate_task \[.*?fidelity=\"truncate\"", graph, re.S) is not None),
    ("no reset machinery", "reset_task_attempt" not in graph and "pre_validate_snapshot" not in graph),
    ("no contradictory validation routing", "context_updates" not in validation and "task_retry_available" not in graph),
    ("failure does not reach normal exit", "task_stopped ->" not in graph),
    ("full quality gate retained", 'dev ci' in graph and 'Run Dev Check' in graph),
    ("task loop still enters final gate", 'all_tasks_done -> dev_check [label="No unchecked tasks", condition="outcome=failed"]' in graph),
    ("final gate failure still requires repair", 'dev_check -> fix_dev_check [label="Fix failures"]' in graph),
    ("repaired gate runs again", 'fix_dev_check -> dev_check' in graph),
    ("conformance retained", "collect_implementation_evidence -> plan_conformance_gate" in graph),
    ("publish gate retained", "goal_gate=true" in graph),
]
failed = [name for name, ok in checks if not ok]
if failed:
    raise SystemExit("Missing task execution contract: " + ", ".join(failed))
print(f"task execution contract: {len(checks)} checks passed")
PY

python3 -B "$workflow_dir/scripts/test_delivery_planner_state.py"
python3 -B "$workflow_dir/scripts/test_apply_task_verdict.py"
