#!/usr/bin/env bash
set -euo pipefail

PLAN_PATH="${1:?plan path required}"

if [ ! -f "$PLAN_PATH" ]; then
  echo "Plan file not found: $PLAN_PATH" >&2
  exit 1
fi

git config user.name "Fabro"
git config user.email "fabro@users.noreply.github.com"

git fetch --quiet origin main:refs/remotes/origin/main
base_sha=$(git merge-base HEAD origin/main)
head_sha=$(git rev-parse HEAD)

status=$(git status --short)
committed_changed=$(git diff --name-only "$base_sha"..HEAD)
working_changed=$(git diff --name-only)
staged_changed=$(git diff --cached --name-only)
changed_paths=$( { printf '%s\n' "$committed_changed"; printf '%s\n' "$working_changed"; printf '%s\n' "$staged_changed"; } | sed '/^$/d' | sed '/^\.fabro\/tmp\//d' | sort -u )

if [ -z "$changed_paths" ] && [ -z "$status" ]; then
  echo 'No implementation changes found to publish.' >&2
  exit 1
fi

if printf '%s\n' "$changed_paths" | grep -E '\.feature$'; then
  echo 'Refusing to publish implementation: locked acceptance feature files changed.' >&2
  printf '%s\n' "$changed_paths" | grep -E '\.feature$' >&2
  exit 1
fi

iteration_dir=${PLAN_PATH%/plan.md}
iteration_slug=$(basename "$iteration_dir")
iteration_number=$(printf '%s' "$iteration_slug" | sed -n 's/^\([0-9][0-9][0-9]\).*/\1/p')
if [ -z "$iteration_number" ]; then
  iteration_number="unknown"
fi
plan_title=$(sed -n 's/^# *//p' "$PLAN_PATH" | head -1)
if [ -z "$plan_title" ]; then
  plan_title="$iteration_slug"
fi
subject="iteration ${iteration_number}: ${plan_title}"
run_id="${FABRO_RUN_ID:-${FABRO_RUN:-unknown}}"
workflow="iteration-implementation"
validation="dev check passed; plan conformance passed"

git add -A -- . ':!.fabro/tmp' ':!.fabro/tmp/**'

# Collapse Fabro checkpoint commits and any remaining working-tree changes into
# one trunk commit that represents the delivered iteration.
git reset --soft "$base_sha"

if git diff --cached --quiet; then
  echo 'No staged implementation diff remains after squash reset.' >&2
  exit 1
fi

commit_msg=$(mktemp)
{
  printf '%s\n\n' "$subject"
  printf 'Plan-Path: %s\n' "$PLAN_PATH"
  printf 'Fabro-Workflow: %s\n' "$workflow"
  printf 'Fabro-Run-Id: %s\n' "$run_id"
  printf 'Implementation-Base-Sha: %s\n' "$base_sha"
  printf 'Implementation-Head-Sha: %s\n' "$head_sha"
  printf 'Validation: %s\n' "$validation"
} > "$commit_msg"

git commit -F "$commit_msg"
rm -f "$commit_msg"

# Rebase rather than force-push if main moved while this run was executing.
git pull --rebase origin main
git push origin HEAD:main

echo "Published implementation to main: $(git rev-parse HEAD)"
