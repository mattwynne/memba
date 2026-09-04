#!/usr/bin/env bash
set -euo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/publish_polish_to_main.sh
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

cd "$workdir"
git init -q --initial-branch=main repo
git init -q --bare origin.git
cd repo
git config user.name Test
git config user.email test@example.com
mkdir -p .fabro/tmp docs/iterations/001-example docs web/lib
cat > docs/iterations/001-example/plan.md <<'PLAN'
# Example iteration

Status: reviewing
PLAN
cat > docs/code-health.md <<'HEALTH'
# Code Health

No findings yet.
HEALTH
cat > web/lib/example.ex <<'CODE'
defmodule Example do
  def value, do: :before
end
CODE
git add .
git commit -q -m initial
git remote add origin "$workdir/origin.git"
git push -q origin main
start_sha=$(git rev-parse HEAD)
printf '%s\n' "$start_sha" > .fabro/tmp/review-start-sha.txt

run_branch=fabro/run/REVIEW-RUN
git switch -q -c "$run_branch"
cat > docs/code-health.md <<'HEALTH'
# Code Health

- Prefer explicit publication-history tests for Fabro scripts.
HEALTH
git add docs/code-health.md
git commit -q -m 'fabro checkpoint review polish'
remote_run_checkpoint=$(git rev-parse HEAD)
git push -q origin HEAD:"$run_branch"

FABRO_RUN_ID=REVIEW-RUN "$script_path" docs/iterations/001-example/plan.md >/tmp/publish-polish.out 2>/tmp/publish-polish.err

git fetch -q origin main "$run_branch"
published=$(git rev-parse origin/main)
message=$(git log -1 --format=%B origin/main)

if ! grep -q 'review polish: iteration 001' <<<"$message"; then
  echo "Expected review polish commit subject on origin/main" >&2
  echo "$message" >&2
  exit 1
fi
if ! grep -q 'Fabro-Run-Id: REVIEW-RUN' <<<"$message"; then
  echo "Expected Fabro run id in review polish commit message" >&2
  echo "$message" >&2
  exit 1
fi
identity=$(git log -1 --format='%an <%ae>|%cn <%ce>' origin/main)
if [ "$identity" != 'Fabro <noreply@fabro.sh>|Fabro <noreply@fabro.sh>' ]; then
  echo "Expected published review commit to use the approved scoped Fabro identity" >&2
  echo "$identity" >&2
  exit 1
fi
if [ "$(git config --local user.name)" != "Test" ] || [ "$(git config --local user.email)" != "test@example.com" ]; then
  echo "Expected review publish script not to persistently change repo-local git identity" >&2
  git config --local --get-regexp '^user\.' >&2
  exit 1
fi
if ! git show "$published:docs/code-health.md" | grep -q 'publication-history tests'; then
  echo "Expected review polish to be published" >&2
  exit 1
fi
if ! git merge-base --is-ancestor "$remote_run_checkpoint" HEAD; then
  echo "Expected review publish not to rewrite the active Fabro run branch away from its pushed checkpoint" >&2
  git log --oneline --decorate --graph --all >&2
  exit 1
fi
git commit --allow-empty -q -m 'fabro automatic checkpoint after review publish'
if ! git push -q origin HEAD:"$run_branch"; then
  echo "Expected ordinary post-review-publish checkpoint push to active Fabro run branch to succeed" >&2
  exit 1
fi

echo "publish_polish_to_main tests passed"
