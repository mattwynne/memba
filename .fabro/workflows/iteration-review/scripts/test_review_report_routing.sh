#!/usr/bin/env bash
set -euo pipefail

workflow_path=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/workflow.fabro

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

review_retry_count=$(grep -Fc 'retry_policy="patient"' "$workflow_path")
if [ "$review_retry_count" -lt 4 ]; then
  echo "Expected patient retry policy on the three review stages and synthesis; found $review_retry_count" >&2
  exit 1
fi

# Review synthesis requires all independent reviewer Markdown reports. A failed
# reviewer must not continue to synthesis with missing prior-stage context.
assert_contains 'script="bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh'
assert_contains 'claude_review -> codex_review [condition="outcome=succeeded"]'
assert_contains 'claude_review -> synthesis_unavailable'
assert_contains 'codex_review -> gemini_review [condition="outcome=succeeded"]'
assert_contains 'codex_review -> synthesis_unavailable'
assert_contains 'gemini_review -> synthesize_review [condition="outcome=succeeded"]'
assert_contains 'gemini_review -> synthesis_unavailable'
assert_contains 'synthesize_review -> review_gate [condition="outcome=succeeded"]'
assert_contains 'synthesize_review -> synthesis_unavailable [label="Synthesis unavailable"]'

assert_not_contains 'claude_review -> codex_review;'
assert_not_contains 'codex_review -> gemini_review;'
assert_not_contains 'gemini_review -> synthesize_review;'

# Review repair verification must fail closed when comparing the before/after
# patches. `cmp` is not available in all Fabro sandboxes and can fail open when
# used directly in an `if` condition.
assert_contains 'git diff --no-index --quiet \"$before\" \"$after\"'
assert_contains 'Could not compare ${kind} repair patches.'
assert_not_contains 'cmp -s \"$before\" \"$after\"'

# Code-health recording must have live repository access and must not silently
# continue to finalization when it reports or routes a recording failure.
assert_contains 'shape=box,'
assert_contains 'output_schema="routing",'
assert_contains 'record_code_health -> final_artifact_gate [condition="context.code_health_recording_ok=true"]'
assert_contains 'record_code_health -> code_health_recording_failed [label="Code-health recording failed"]'
assert_contains 'code_health_recording_failed -> exit'
assert_not_contains 'record_code_health -> final_artifact_gate;'

echo "iteration-review report routing tests passed"
