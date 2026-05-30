#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$ROOT/../../.." && pwd)"
WORKFLOW=".fabro/workflows/plan-validation/workflow.toml"
PASS_PLAN=".fabro/workflows/plan-validation/test/fixtures/unanimous-pass/plan.md"
FAIL_PLAN=".fabro/workflows/plan-validation/test/fixtures/definite-fail/plan.md"
VISIBLE_PATHS=(
  ".fabro/workflows/plan-validation/workflow.toml"
  ".fabro/workflows/plan-validation/workflow.fabro"
  ".fabro/workflows/plan-validation/prompts/review.md"
  ".fabro/workflows/plan-validation/prompts/synthesize.md"
  ".fabro/workflows/plan-validation/prompts/gemini_review.md"
  ".fabro/workflows/plan-validation/prompts/claude_review.md"
  ".fabro/workflows/plan-validation/prompts/codex_review.md"
  "$PASS_PLAN"
  "$FAIL_PLAN"
)

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_fabro_visible_inputs() {
  cd "$REPO_ROOT"

  for path in "${VISIBLE_PATHS[@]}"; do
    test -f "$path" || fail "missing required eval input: $path"
    git ls-files --error-unmatch "$path" >/dev/null 2>&1 || \
      fail "$path is not tracked. Commit and push eval inputs before running; Fabro sandboxes clone origin, not this dirty working tree."
  done

  git diff --quiet -- "${VISIBLE_PATHS[@]}" || \
    fail "eval inputs have unstaged changes. Commit and push them before running; Fabro sandboxes clone origin."

  git diff --cached --quiet -- "${VISIBLE_PATHS[@]}" || \
    fail "eval inputs have staged but uncommitted changes. Commit and push them before running; Fabro sandboxes clone origin."

  git fetch origin main --quiet
  git diff --quiet origin/main..HEAD -- "${VISIBLE_PATHS[@]}" || \
    fail "eval inputs differ from origin/main. Push them before running; Fabro sandboxes clone origin/main."
}

run_eval() {
  local name="$1"
  local plan_path="$2"
  local expected_exit="$3"
  local output run_id wait_status

  echo "== plan-validation eval: $name =="
  echo "fixture: $plan_path"

  set +e
  output="$(
    cd "$REPO_ROOT" && \
      fabro run "$WORKFLOW" \
        -I "plan_path=$plan_path" \
        -I "publish=false" \
        --label "kind=plan-validation-eval" \
        --label "fixture=$name" \
        --no-upgrade-check \
        -d 2>&1
  )"
  local create_status=$?
  set -e

  echo "$output"
  [[ $create_status -eq 0 ]] || fail "$name: fabro run -d failed"

  run_id="$(printf '%s\n' "$output" | grep -Eo '[0-9A-Z]{26}' | head -1 || true)"
  [[ -n "$run_id" ]] || fail "$name: could not parse Fabro run id"

  echo "run: $run_id"

  set +e
  fabro wait "$run_id" --no-upgrade-check
  wait_status=$?
  set -e

  if [[ "$expected_exit" == "success" ]]; then
    if [[ $wait_status -ne 0 ]]; then
      fabro inspect "$run_id" --no-upgrade-check || true
      fabro events "$run_id" --no-upgrade-check | tail -120 || true
      fail "$name: expected READY/success but run failed with exit $wait_status"
    fi
    echo "PASS: $name produced READY/success"
  else
    if [[ $wait_status -eq 0 ]]; then
      fabro inspect "$run_id" --no-upgrade-check || true
      fabro events "$run_id" --no-upgrade-check | tail -120 || true
      fail "$name: expected NOT READY/failure but run succeeded"
    fi
    echo "PASS: $name produced NOT READY/failure"
  fi
}

command -v fabro >/dev/null 2>&1 || fail "fabro CLI not found"

cd "$REPO_ROOT"
fabro validate "$WORKFLOW" --no-upgrade-check
require_fabro_visible_inputs

run_eval "unanimous-pass" "$PASS_PLAN" success
run_eval "definite-fail" "$FAIL_PLAN" failure

echo "plan-validation eval suite: OK"
