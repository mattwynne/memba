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

echo "iteration-review report routing tests passed"
