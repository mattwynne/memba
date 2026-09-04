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

stage_publish_artifact() {
  local path
  while IFS= read -r -d '' path; do
    case "$path" in
      .fabro/tmp|.fabro/tmp/*) continue ;;
    esac
    git add -- "$path"
  done < <(git ls-files -z --modified --deleted --others --exclude-standard)
}

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

stage_publish_artifact

# Collapse Fabro checkpoint commits and any remaining working-tree changes into
# one trunk commit object that represents the delivered iteration, without
# moving the active fabro/run/* branch. Fabro will checkpoint this working tree
# after publication; preserving the branch ancestry keeps that ordinary push a
# fast-forward from the last remote run checkpoint.
if git diff --cached --quiet "$base_sha"; then
  echo 'No staged implementation diff remains after squash preparation.' >&2
  exit 1
fi

tree_sha=$(git write-tree)
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

attempted_publish_sha=$(fabro_git_commit_tree "$tree_sha" -p "$base_sha" -F "$commit_msg")
rm -f "$commit_msg"
safe_run_id=$(printf '%s' "$run_id" | tr -c '[:alnum:]_.-' '-')
rescue_branch="fabro/rescue/${safe_run_id}-${iteration_number}-publish-conflict"
git branch -f "$rescue_branch" "$attempted_publish_sha"

publish_tmp=$(mktemp -d)
publish_worktree="$publish_tmp/worktree"
cleanup_publish_worktree() {
  if [ -e "$publish_worktree/.git" ]; then
    git -C "$publish_worktree" rebase --abort >/dev/null 2>&1 || true
    git worktree remove -f "$publish_worktree" >/dev/null 2>&1 || true
  fi
  rm -rf "$publish_tmp"
}
trap cleanup_publish_worktree EXIT

git worktree add -q --detach "$publish_worktree" "$attempted_publish_sha"

# Rebase the candidate in a disposable worktree rather than force-pushing if
# main moved while this run was executing. The active run branch is left at its
# checkpoint history throughout.
if ! git -C "$publish_worktree" fetch --quiet origin main:refs/remotes/origin/main; then
  echo "Could not fetch origin/main before publishing implementation." >&2
  exit 1
fi
if ! fabro_git_with_identity -C "$publish_worktree" rebase origin/main; then
  # Preserve the existing conflict-recovery workflow by materializing the
  # conflict on the active run branch as a merge from origin/main. Do not detach
  # HEAD or rebase the managed branch: after the resolver commits the merge, the
  # branch still descends from its last remote checkpoint and Fabro's automatic
  # checkpoint push remains a fast-forward.
  recovery_msg=$(mktemp)
  {
    printf 'fabro recovery candidate: iteration %s publish conflict\n\n' "$iteration_number"
    printf 'Attempted-Publish-Sha: %s\n' "$attempted_publish_sha"
    printf 'Plan-Path: %s\n' "$PLAN_PATH"
    printf 'Fabro-Workflow: %s\n' "$workflow"
    printf 'Fabro-Run-Id: %s\n' "$run_id"
  } > "$recovery_msg"
  recovery_candidate_sha=$(fabro_git_commit_tree "$tree_sha" -p HEAD -F "$recovery_msg")
  rm -f "$recovery_msg"
  recovery_branch="fabro/recover/${safe_run_id}-${iteration_number}-publish-conflict"
  git branch -f "$recovery_branch" "$recovery_candidate_sha"

  materialized_conflict=false
  if git reset --hard "$recovery_candidate_sha" >/dev/null 2>&1; then
    if ! git merge --no-commit --no-ff origin/main >/dev/null 2>&1; then
      materialized_conflict=true
    fi
  fi
  if [ "$materialized_conflict" = true ]; then
    conflicted_files=$(git diff --name-only --diff-filter=U || true)
  else
    conflicted_files=$(git -C "$publish_worktree" diff --name-only --diff-filter=U || true)
  fi
  echo "Publish rebase conflicted while replaying attempted implementation commit onto origin/main." >&2
  echo "Attempted publish commit: $attempted_publish_sha" >&2
  echo "Local rescue branch: $rescue_branch" >&2
  echo "Local recovery branch: $recovery_branch" >&2
  if git push -f origin "$rescue_branch:$rescue_branch"; then
    echo "Pushed rescue branch: origin/$rescue_branch" >&2
  else
    echo "Could not push rescue branch origin/$rescue_branch; local branch still exists in this sandbox." >&2
  fi
  if [ -n "$conflicted_files" ]; then
    echo "Conflicted files:" >&2
    printf '%s\n' "$conflicted_files" >&2
  else
    echo "No unmerged files were reported; inspect the rescue branch for the publish failure state." >&2
  fi
  cat >&2 <<EOF

The workflow may route this state to resolve_publish_conflict. Conflict resolution
must produce a new candidate artifact and return through dev_check before push.
If resolving manually, inspect the rescue branch and current merge state before
committing the merge resolution or aborting the merge.
EOF
  exit 2
fi

published_sha=$(git -C "$publish_worktree" rev-parse HEAD)
git push origin "$published_sha:main"

echo "Published implementation to main: $published_sha"
