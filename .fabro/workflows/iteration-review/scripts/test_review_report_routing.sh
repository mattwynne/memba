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

echo "iteration-review report routing tests passed"
