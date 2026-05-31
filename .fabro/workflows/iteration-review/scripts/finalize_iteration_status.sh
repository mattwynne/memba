#!/usr/bin/env bash
set -euo pipefail

PLAN_PATH="${1:?plan path required}"

if [ ! -f "$PLAN_PATH" ]; then
  echo "Plan file not found: $PLAN_PATH" >&2
  exit 1
fi

case "$PLAN_PATH" in
  */plan.md) ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 2 ;;
esac

git config user.name "Fabro"
git config user.email "fabro@users.noreply.github.com"

git fetch origin main
git pull --rebase origin main

iteration_dir=${PLAN_PATH%/plan.md}
iteration_slug=$(basename "$iteration_dir")
iteration_number=${iteration_slug%%-*}
implementation_path="$iteration_dir/implementation.md"

.fabro/workflows/scripts/iteration_status.py mark "$PLAN_PATH" merged

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

git add -- "$PLAN_PATH" docs/iterations/README.md
if [ -f "$implementation_path" ]; then
  git add -- "$implementation_path"
fi

if git diff --cached --quiet; then
  echo "Iteration $iteration_number already marked merged; no finalization commit needed."
  exit 0
fi

git commit -m "iteration ${iteration_number}: mark merged"
git push origin HEAD:main

echo "Marked iteration $iteration_number as merged and pushed to main."
