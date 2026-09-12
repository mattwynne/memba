#!/usr/bin/env bash
set -euo pipefail

workflow_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Prompt instructions are part of the delivery contract. This regression checks
# that bounded ownership does not remove the independent or final quality gates;
# the next real run is the experiment that measures agent adherence.
python3 - "$workflow_dir" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
implementation = (root / "prompts/implement_next_task.md").read_text()
validation = (root / "prompts/validate_task.md").read_text()
graph = (root / "workflow.fabro").read_text()

checks = [
    ("single-owner task", "Do not spawn subagents in this per-task node." in implementation),
    ("reuse checkpoint evidence", "Read existing implementation notes, reviews, and recovery handoffs" in implementation),
    ("no duplicate review", "Do not commission an extra independent review" in implementation),
    ("focused validation still required", "Run focused validation appropriate to the selected task" in implementation),
    ("no premature task check-off", "When the implementation and focused validation are complete" in implementation),
    ("browser tasks use focused checks", "For browser-facing tasks, run targeted browser scenarios or a focused browser harness" in implementation),
    ("ordinary tasks do not run full gates", "Do not run full `dev check` or `dev ci` in ordinary implementation tasks" in implementation),
    ("explicit final-validation work preserved", "If the selected task explicitly requires the full final validation, preserve that requirement" in implementation),
    ("timeouts do not trigger detached reruns", "Do not launch a detached/background full-suite retry to evade a tool timeout" in implementation),
    ("browser exception removed", "Run full `PATH=\"$PWD/bin:$PATH\" dev check` during a task only when that task changes browser-facing behaviour" not in implementation),
    ("preserve task scope when splitting", "You may not delete, weaken, or silently defer plan-required work." in implementation),
    ("unfinished checkpoint recovery", "A committed failed checkpoint is candidate work, not a completed task" in implementation),
    ("validator remains independent", "Decide from live repository state" in validation),
    ("validator does not reintroduce browser full gate", "do not require a duplicate full `dev check` solely because the task changes UI" in validation),
    ("explicit gate requires successful exit evidence", "require its successful exit evidence before accepting the check-off" in validation),
    ("independent validation retained", 'pre_validate_snapshot -> validate_task [condition="outcome=succeeded"]' in graph),
    ("full quality gate retained", 'script="PATH=\\\"$PWD/bin:$PATH\\\" dev ci"' in graph),
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
