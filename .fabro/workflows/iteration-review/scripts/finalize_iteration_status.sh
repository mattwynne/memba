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

case "$PLAN_PATH" in
  docs/iterations/*/plan.md) ;;
  */plan.md)
    echo "Plan path is not under docs/iterations; skipping iteration status finalization: $PLAN_PATH"
    exit 0
    ;;
  *)
    echo "Plan path is not an iteration plan; skipping iteration status finalization: $PLAN_PATH"
    exit 0
    ;;
esac

git fetch origin main:refs/remotes/origin/main

iteration_dir=${PLAN_PATH%/plan.md}
iteration_slug=$(basename "$iteration_dir")
iteration_number=${iteration_slug%%-*}
implementation_path="$iteration_dir/implementation.md"

mark_iteration_merged() {
  local plan_path=$1
  local implementation_path=$2

  .fabro/workflows/scripts/iteration_status.py mark "$plan_path" merged

  if [ -f "$implementation_path" ]; then
    python3 - "$implementation_path" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
if re.search(r"^Status:\s*.*$", text, flags=re.MULTILINE):
    text = re.sub(r"^Status:\s*.*$", "Status: merged", text, count=1, flags=re.MULTILINE)
else:
    text = text.rstrip() + "\nStatus: merged\n"
path.write_text(text)
PY
  fi
}

publish_tmp=$(mktemp -d)
publish_worktree="$publish_tmp/worktree"
noop_file="$publish_tmp/no-finalization-commit"
cleanup_publish_worktree() {
  if [ -e "$publish_worktree/.git" ]; then
    git -C "$publish_worktree" rebase --abort >/dev/null 2>&1 || true
    git worktree remove -f "$publish_worktree" >/dev/null 2>&1 || true
  fi
  rm -rf "$publish_tmp"
}
trap cleanup_publish_worktree EXIT

git worktree add -q --detach "$publish_worktree" origin/main

(
  cd "$publish_worktree"

  if [ ! -f "$PLAN_PATH" ]; then
    echo "Plan file not found on origin/main: $PLAN_PATH" >&2
    exit 1
  fi

  mark_iteration_merged "$PLAN_PATH" "$implementation_path"

  git add -- "$PLAN_PATH" docs/iterations/README.md
  if [ -f "$implementation_path" ]; then
    git add -- "$implementation_path"
  fi

  if git diff --cached --quiet; then
    echo "Iteration $iteration_number already marked merged; no finalization commit needed."
    touch "$noop_file"
    exit 0
  fi

  fabro_git_commit -m "iteration ${iteration_number}: mark merged"

  # Rebase the finalization candidate in the disposable worktree so origin/main
  # can move during review without ever rewriting the active Fabro run branch.
  fabro_git_with_identity pull --rebase origin main
  git push origin HEAD:main
)

# Keep the active sandbox artifact consistent for the final summary and Fabro's
# subsequent checkpoint, but do not commit or rebase this run branch here.
mark_iteration_merged "$PLAN_PATH" "$implementation_path"
git add -- "$PLAN_PATH" docs/iterations/README.md
if [ -f "$implementation_path" ]; then
  git add -- "$implementation_path"
fi

if [ ! -f "$noop_file" ]; then
  echo "Marked iteration $iteration_number as merged and pushed to main."
fi
