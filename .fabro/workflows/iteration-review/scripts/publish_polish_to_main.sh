#!/usr/bin/env bash
set -euo pipefail

PLAN_PATH="${1:?plan path required}"
START_SHA_FILE=".fabro/tmp/review-start-sha.txt"

if [ ! -f "$PLAN_PATH" ]; then
  echo "Plan file not found: $PLAN_PATH" >&2
  exit 1
fi
if [ ! -f "$START_SHA_FILE" ]; then
  echo "Missing review start SHA file: $START_SHA_FILE" >&2
  exit 1
fi

git config user.name "Fabro"
git config user.email "fabro@users.noreply.github.com"
grep -qxF '.fabro/tmp/' .git/info/exclude 2>/dev/null || printf '.fabro/tmp/\n' >> .git/info/exclude

start_sha=$(cat "$START_SHA_FILE")
if ! git cat-file -e "$start_sha^{commit}" 2>/dev/null; then
  echo "Review start SHA does not resolve: $start_sha" >&2
  exit 1
fi
head_sha=$(git rev-parse HEAD)

status=$(git status --short)
committed_changed=$(git diff --name-only "$start_sha"..HEAD)
working_changed=$(git diff --name-only)
staged_changed=$(git diff --cached --name-only)
changed_paths=$( { printf '%s\n' "$committed_changed"; printf '%s\n' "$working_changed"; printf '%s\n' "$staged_changed"; } | sed '/^$/d' | sed '/^\.fabro\/tmp\//d' | sort -u )

if [ -z "$changed_paths" ] && [ -z "$status" ]; then
  echo 'No review polish or code-health changes to publish; main remains unchanged.'
  exit 0
fi

if printf '%s\n' "$changed_paths" | grep -E '\.feature$'; then
  echo 'Refusing to publish review polish: locked acceptance feature files changed.' >&2
  printf '%s\n' "$changed_paths" | grep -E '\.feature$' >&2
  exit 1
fi

git add -A -- . ':!.fabro/tmp' ':!.fabro/tmp/**'

# Collapse Fabro review checkpoint commits into one follow-up polish commit.
git reset --soft "$start_sha"

if git diff --cached --quiet; then
  echo 'No staged review diff remains after squash reset; main remains unchanged.'
  exit 0
fi

iteration_dir=${PLAN_PATH%/plan.md}
iteration_slug=$(basename "$iteration_dir")
iteration_number=$(printf '%s' "$iteration_slug" | sed -n 's/^\([0-9][0-9][0-9]\).*/\1/p')
if [ -z "$iteration_number" ]; then
  iteration_number="unknown"
fi
run_id="${FABRO_RUN_ID:-${FABRO_RUN:-unknown}}"
commit_msg=$(mktemp)
{
  printf 'review polish: iteration %s\n\n' "$iteration_number"
  printf 'Plan-Path: %s\n' "$PLAN_PATH"
  printf 'Fabro-Workflow: iteration-review\n'
  printf 'Fabro-Run-Id: %s\n' "$run_id"
  printf 'Review-Start-Sha: %s\n' "$start_sha"
  printf 'Review-Head-Sha: %s\n' "$head_sha"
  printf 'Validation: dev check passed after review changes\n'
} > "$commit_msg"

git commit -F "$commit_msg"
rm -f "$commit_msg"

git pull --rebase origin main
git push origin HEAD:main

echo "Published review polish to main: $(git rev-parse HEAD)"
