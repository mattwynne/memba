#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$ROOT/../../.." && pwd)"
WORKFLOW=".fabro/workflows/fan-in-evidence-spike/workflow.toml"
TOKENS=(
  "FANOUT-EVIDENCE-ALPHA-71C3"
  "FANOUT-EVIDENCE-BRAVO-4A9E"
  "FANOUT-EVIDENCE-CHARLIE-8F2B"
)

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local token="$2"

  grep -Fq "$token" "$file" || fail "expected $file to contain $token"
}

command -v fabro >/dev/null 2>&1 || fail "fabro CLI not found"

cd "$REPO_ROOT"
fabro validate "$WORKFLOW" --no-upgrade-check

git diff --quiet -- "$WORKFLOW" "$ROOT/workflow.fabro" "$0" || \
  fail "spike inputs have unstaged changes; commit and push them before running"
git diff --cached --quiet -- "$WORKFLOW" "$ROOT/workflow.fabro" "$0" || \
  fail "spike inputs have staged but uncommitted changes; commit and push them before running"

echo "== Fabro fan-in evidence spike =="
output="$(fabro run "$WORKFLOW" --label "kind=fan-in-evidence-spike" --no-upgrade-check -d 2>&1)"
echo "$output"
run_id="$(printf '%s\n' "$output" | grep -Eo '[0-9A-Z]{26}' | head -1 || true)"
[[ -n "$run_id" ]] || fail "could not parse Fabro run ID"

echo "run: $run_id"
fabro wait "$run_id" --no-upgrade-check --timeout 900

dump_dir="$(mktemp -d "${TMPDIR:-/tmp}/fan-in-evidence-spike.XXXXXX")"
trap 'rm -rf "$dump_dir"' EXIT
fabro dump "$run_id" --output "$dump_dir" --no-upgrade-check

synthesis_prompt="$(find "$dump_dir" -path '*synthesize*' -name prompt.md -print -quit)"
synthesis_response="$(find "$dump_dir" -path '*synthesize*' -name response.md -print -quit)"
[[ -n "$synthesis_prompt" ]] || fail "could not find the synthesis prompt in Fabro dump"
[[ -n "$synthesis_response" ]] || fail "could not find the synthesis response in Fabro dump"

for token in "${TOKENS[@]}"; do
  assert_contains "$synthesis_prompt" "$token"
  assert_contains "$synthesis_response" "$token"
done

echo "PASS: fan-in synthesis received and used every branch response"
