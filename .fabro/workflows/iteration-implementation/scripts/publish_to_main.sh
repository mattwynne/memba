#!/usr/bin/env bash
set -euo pipefail

PLAN_PATH="${1:?plan path required}"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../scripts/git_identity.sh
source "$SCRIPT_DIR/../../scripts/git_identity.sh"

if [ ! -f "$PLAN_PATH" ]; then
  echo "Plan file not found: $PLAN_PATH" >&2
  exit 1
fi

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

python3 .fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py "$PLAN_PATH" "$base_sha"

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

# Publishing the implementation is the point at which the iteration's
# lifecycle metadata should stop blocking later iterations. Include the merged
# status in the same trunk commit as the implementation so the product artifact
# and iteration index cannot drift apart.
.fabro/workflows/scripts/iteration_status.py mark "$PLAN_PATH" merged

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

fabro_git_commit -F "$commit_msg"
rm -f "$commit_msg"

attempted_publish_sha=$(git rev-parse HEAD)
safe_run_id=$(printf '%s' "$run_id" | tr -c '[:alnum:]_.-' '-')
rescue_branch="fabro/rescue/${safe_run_id}-${iteration_number}-publish-conflict"
git branch -f "$rescue_branch" "$attempted_publish_sha"

# Rebase rather than force-push if main moved while this run was executing.
if ! git pull --rebase origin main; then
  conflicted_files=$(git diff --name-only --diff-filter=U || true)
  echo "Publish rebase conflicted while replaying attempted implementation commit onto origin/main." >&2
  echo "Attempted publish commit: $attempted_publish_sha" >&2
  echo "Local rescue branch: $rescue_branch" >&2
  if git push -f origin "$rescue_branch:$rescue_branch"; then
    echo "Pushed rescue branch: origin/$rescue_branch" >&2
  else
    echo "Could not push rescue branch origin/$rescue_branch; local branch still exists in this sandbox." >&2
  fi
  if [ -n "$conflicted_files" ]; then
    echo "Conflicted files:" >&2
    printf '%s\n' "$conflicted_files" >&2
  else
    echo "No unmerged files were reported; inspect git status for the publish failure state." >&2
  fi
  cat >&2 <<EOF

The workflow may route this state to resolve_publish_conflict. Conflict resolution
must produce a new candidate artifact and return through dev_check before push.
If resolving manually, inspect the rescue branch and current rebase state before
running git rebase --continue or git rebase --abort.
EOF
  exit 2
fi

git push origin HEAD:main

echo "Published implementation to main: $(git rev-parse HEAD)"
