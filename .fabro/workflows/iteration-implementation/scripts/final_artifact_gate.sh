#!/usr/bin/env bash
set -euo pipefail

PLAN_PATH="${1:?plan path required}"

echo '=== Final Artifact Gate ==='
echo ''
echo 'Checking for implementation artifact evidence...'
echo ''

if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Plan file not found: $PLAN_PATH" >&2
  exit 1
fi

git fetch --quiet origin main:refs/remotes/origin/main || true
base_ref=''
for ref in origin/main main; do
  if git rev-parse --verify "$ref" >/dev/null 2>&1; then
    base_ref=$ref
    break
  fi
done
if [ -z "$base_ref" ]; then
  echo 'ERROR: Could not determine implementation base. Tried origin/main and main.' >&2
  git branch -a -vv >&2 || true
  git show-ref >&2 || true
  exit 1
fi

merge_base_err="${TMPDIR:-/tmp}/memba-final-artifact-merge-base-$$.err"
if ! base_sha=$(git merge-base HEAD "$base_ref" 2>"$merge_base_err"); then
  echo "ERROR: Could not compute merge base between HEAD and $base_ref." >&2
  cat "$merge_base_err" >&2 || true
  shallow=$(git rev-parse --is-shallow-repository 2>/dev/null || echo unknown)
  echo "Repository shallow: $shallow" >&2
  if [ "$shallow" = true ]; then
    echo 'Trying to unshallow repository before failing...' >&2
    git fetch --quiet --unshallow origin || true
  fi
  if ! base_sha=$(git merge-base HEAD "$base_ref" 2>"$merge_base_err"); then
    echo "ERROR: Still could not compute merge base between HEAD and $base_ref." >&2
    cat "$merge_base_err" >&2 || true
    git log --oneline --decorate --max-count=40 --all >&2 || true
    git branch -a -vv >&2 || true
    git show-ref >&2 || true
    exit 1
  fi
fi
rm -f "$merge_base_err"

echo "Base ref: $base_ref"
echo "Implementation base sha: $base_sha"
echo "HEAD: $(git rev-parse HEAD)"
echo ''

status=$(git status --short)
if [ -n "$status" ]; then
  echo 'Working tree changes still present:'
  printf '%s\n' "$status"
  echo ''
else
  echo 'Working tree is clean (changes may have been checkpointed).'
  echo ''
fi

committed_changed=$(git diff --name-only "$base_sha"..HEAD)
working_changed=$(git diff --name-only)
staged_changed=$(git diff --cached --name-only)
changed_paths=$( { printf '%s\n' "$committed_changed"; printf '%s\n' "$working_changed"; printf '%s\n' "$staged_changed"; } | sed '/^$/d' | sed '/^\.fabro\/tmp\//d' | sort -u )

if [ -n "$changed_paths" ]; then
  echo "Files changed since implementation base $base_sha, including working tree/staged changes:"
  printf '%s\n' "$changed_paths"
  echo ''
  echo 'Committed change summary:'
  git diff --stat "$base_sha"..HEAD || true
  echo ''
  if [ -n "$working_changed" ] || [ -n "$staged_changed" ]; then
    echo 'Uncommitted change summary:'
    git diff --stat || true
    git diff --cached --stat || true
    echo ''
  fi
else
  echo "No implementation differences found against $base_sha."
  echo ''
fi

recent_commits=$(git log --oneline -5 --format='%h %s')
if [ -n "$recent_commits" ]; then
  echo 'Recent commits (may include Fabro checkpoints):'
  printf '%s\n' "$recent_commits"
  echo ''
fi

python3 .fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py "$PLAN_PATH" "$base_sha"

if [ -z "$changed_paths" ] && [ -z "$status" ]; then
  echo 'ERROR: Implementation workflow reached finalization with no artifact evidence.' >&2
  echo "No working tree changes, no base-head diff from $base_sha, and no staged changes." >&2
  echo 'Refusing to report success without implementation artifacts.' >&2
  exit 1
fi

echo 'Final artifact evidence confirmed.'
echo 'Final artifact gate passed.'
