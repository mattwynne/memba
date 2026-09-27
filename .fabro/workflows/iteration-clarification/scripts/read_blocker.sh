#!/usr/bin/env bash
set -euo pipefail
run_id=${1:?failed run ID required}
plan=${2:?plan path required}
if [[ ! "$run_id" =~ ^[0-9A-Z]{26}$ ]] || [[ "$plan" != docs/iterations/*/plan.md ]] || [[ ! -f "$plan" ]]; then
  echo 'Invalid run ID or iteration plan path' >&2
  exit 1
fi
ref="refs/remotes/origin/fabro/run/$run_id"
git fetch -q origin "refs/heads/fabro/run/$run_id:$ref"
review="${plan%/plan.md}/.delivery/latest-review.json"
echo "Failed implementation run: $run_id"
echo "Iteration plan: $plan"
echo 'This is a discussion, not approval to weaken the plan or publish code.'
echo 'Latest independent validator verdict:'
git show "$ref:$review" | python3 -c 'import json,sys; r=json.load(sys.stdin); print("Decision:",r.get("decision")); print("Task:",r.get("task")); print("Reason:",r.get("reason"))'
