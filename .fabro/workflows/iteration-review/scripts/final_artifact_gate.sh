#!/usr/bin/env bash
set -euo pipefail

PLAN_PATH="${1:?plan path required}"
BASE_SHA="${2:?base sha required}"
START_SHA_FILE=".fabro/tmp/review-start-sha.txt"

echo '=== Final Artifact Gate ==='
echo ''
echo 'Checking for implementation artifact evidence...'

if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Plan file not found: $PLAN_PATH" >&2
  exit 1
fi
if ! git cat-file -e "$BASE_SHA^{commit}" 2>/dev/null; then
  echo "ERROR: Base sha does not resolve: $BASE_SHA" >&2
  git log --oneline --decorate --max-count=40 --all >&2 || true
  exit 1
fi

status=$(git status --short)
if [ -n "$status" ]; then
  echo "Working tree changes still present:"
  printf '%s\n' "$status"
  echo ''
else
  echo "Working tree is clean (changes may have been checkpointed)."
  echo ''
fi

changed_files=$(git diff --name-only "$BASE_SHA"..HEAD 2>/dev/null || true)
if [ -n "$changed_files" ]; then
  echo "Files changed since base sha $BASE_SHA:"
  printf '%s\n' "$changed_files"
  echo ''
  echo "Change summary:"
  git diff --stat "$BASE_SHA"..HEAD || true
  echo ''
else
  echo "No differences found between $BASE_SHA and HEAD."
  echo ''
fi

recent_commits=$(git log --oneline -5 --format='%h %s')
if [ -n "$recent_commits" ]; then
  echo "Recent commits (may include Fabro checkpoints):"
  printf '%s\n' "$recent_commits"
  echo ''
fi

python3 .fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py "$PLAN_PATH" "$BASE_SHA"

if [ ! -f "$START_SHA_FILE" ]; then
  echo "ERROR: Missing review start SHA file: $START_SHA_FILE" >&2
  exit 1
fi
start_sha=$(cat "$START_SHA_FILE")
if ! git cat-file -e "$start_sha^{commit}" 2>/dev/null; then
  echo "ERROR: Review start SHA does not resolve: $start_sha" >&2
  exit 1
fi

review_feature_changes=$( { git diff --name-only "$start_sha"..HEAD; git diff --name-only; git diff --cached --name-only; } | grep -E '\.feature$' || true )
if [ -n "$review_feature_changes" ]; then
  echo 'ERROR: Review polish modified locked acceptance feature files:' >&2
  printf '%s\n' "$review_feature_changes" | sort -u >&2
  exit 1
fi

if ! git diff --quiet "$start_sha" -- docs/code-health.md; then
  echo 'Code-health changes recorded during this review:'
  git diff --unified=3 "$start_sha" -- docs/code-health.md
  echo ''
fi

if [ -z "$status" ] && [ -z "$changed_files" ]; then
  echo 'No review artifact changes detected; review can still complete without touching main.'
else
  echo 'Final artifact evidence confirmed.'
fi

echo 'Final artifact gate passed.'
