#!/usr/bin/env bash
set -euo pipefail

PLAN_PATH="${1:?plan path required}"
START_SHA_FILE=".fabro/tmp/review-start-sha.txt"
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

if [ ! -f "$START_SHA_FILE" ]; then
  echo "Missing review start SHA file: $START_SHA_FILE" >&2
  exit 1
fi

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

stage_publish_artifact

# Collapse Fabro review checkpoint commits into one follow-up polish commit
# object without moving the active fabro/run/* branch. Fabro's next checkpoint
# can then push the still-descendant run branch normally.
if git diff --cached --quiet "$start_sha"; then
  echo 'No staged review diff remains after squash preparation; main remains unchanged.'
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

tree_sha=$(git write-tree)
attempted_publish_sha=$(fabro_git_commit_tree "$tree_sha" -p "$start_sha" -F "$commit_msg")
rm -f "$commit_msg"

safe_run_id=$(printf '%s' "$run_id" | tr -c '[:alnum:]_.-' '-')
rescue_branch="fabro/rescue/${safe_run_id}-${iteration_number}-review-polish-conflict"
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

if ! git -C "$publish_worktree" fetch --quiet origin main:refs/remotes/origin/main; then
  echo "Could not fetch origin/main before publishing review polish." >&2
  exit 1
fi
if ! git -C "$publish_worktree" rebase origin/main; then
  conflicted_files=$(git -C "$publish_worktree" diff --name-only --diff-filter=U || true)
  echo "Publish rebase conflicted while replaying attempted review polish commit onto origin/main." >&2
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
    echo "No unmerged files were reported; inspect the rescue branch for the publish failure state." >&2
  fi
  exit 2
fi

published_sha=$(git -C "$publish_worktree" rev-parse HEAD)
git push origin "$published_sha:main"

echo "Published review polish to main: $published_sha"
