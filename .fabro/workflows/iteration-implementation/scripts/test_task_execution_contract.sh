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
planner_schema = (root / "schemas/planner-output.json").read_text()
writer = (root / "scripts/delivery_planner_state.py").read_text()
launcher = (root.parents[2] / "bin/dev").read_text()

checks = [
    ("planner owns task selection", "You own task selection, semantic splitting/reordering" in planner),
    ("planner cannot edit code or artifacts", "You may edit only this iteration's `todo.md`." in planner and "Do not write `.delivery/` files" in planner),
    ("planner emits typed state and packet", 'output_schema="@schemas/planner-output.json"' in graph and '"execution_state"' in planner_schema and '"current_worker_packet"' in planner_schema),
    ("typed output writer consumes planner response", 'stdin_source="output.delivery_planner"' in graph and 'write-planner-output' in graph and 'write_planner_output(plan)' in writer),
    ("reference shape defined in schema", '"required": ["path", "facts"]' in planner_schema and '"type": "object"' in planner_schema),
    ("planner uses binding checkpoint rather than predecessor", "Use that `git rev-parse HEAD` value as `source_baseline`" in planner and "Do not copy the baseline JSON's `pre_planner_head`" in planner and "guard will reject it" in planner),
    ("planner requires exact coverage key", "with the exact `scope` key" in planner and "(no aliases)" in planner),
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
    ("planner before worker", "delivery_planner -> write_planner_output" in graph and "write_planner_output -> guard_delivery_packet" in graph and "guard_delivery_packet -> implement_next_task" in graph),
    ("worker result routing", "route_worker_result -> validate_task" in graph and "route_worker_result -> before_delivery_planner" in graph),
    ("review acceptance returns to planner", "apply_task_verdict -> before_delivery_planner" in graph),
    ("revision checks escalation before planner", 'apply_task_verdict -> task_escalation [condition="outcome=succeeded && preferred_label=revise"]' in graph and 'task_escalation -> before_delivery_planner [condition="outcome=succeeded && preferred_label=continue"]' in graph),
    ("delivery launcher does not auto-answer Slack gates", '--auto-approve \\\n      --no-upgrade-check' not in launcher),
    ("blocked and repeated revisions reach Slack", 'apply_task_verdict -> task_escalation [condition="outcome=succeeded && preferred_label=blocked"]' in graph and 'task_escalation -> task_discussion [condition="outcome=succeeded && preferred_label=discuss"]' in graph and 'provider = "slack"' in (root / "workflow.toml").read_text()),
    ("discussion never publishes automatically", 'summarize_task_discussion -> task_clarification_complete' in graph and 'task_clarification_complete ->' not in graph),
    ("Slack pings the replying user by ID", '<@U0C3C6Y9ZAR>' in graph and 'task_discussion_follow_up' in graph),
    ("unfinished discussion still reaches follow-up", 'reflect_task_discussion -> task_discussion_follow_up [condition="outcome=partially_succeeded && preferred_label=ask"]' in graph and 'task_discussion_follow_up -> reflect_task_discussion [freeform=true]' in graph),
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
python3 -B "$workflow_dir/scripts/test_escalate_task_review.py"
