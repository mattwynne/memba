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
    ("preserve task scope when splitting", "You may not delete, weaken, or silently defer plan-required work." in implementation),
    ("unfinished checkpoint recovery", "A committed failed checkpoint is candidate work, not a completed task" in implementation),
    ("validator remains independent", "Decide from live repository state" in validation),
    ("independent validation retained", 'pre_validate_snapshot -> validate_task [condition="outcome=succeeded"]' in graph),
    ("full quality gate retained", 'script="PATH=\\\"$PWD/bin:$PATH\\\" dev ci"' in graph),
    ("conformance retained", "collect_implementation_evidence -> plan_conformance_gate" in graph),
    ("publish gate retained", "goal_gate=true" in graph),
]
failed = [name for name, ok in checks if not ok]
if failed:
    raise SystemExit("Missing task execution contract: " + ", ".join(failed))
print(f"task execution contract: {len(checks)} checks passed")
PY
