#!/usr/bin/env bash
set -euo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/publish_to_main.sh
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
iteration_status_source="$repo_root/.fabro/workflows/scripts/iteration_status.py"
guard_source="$repo_root/.fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py"
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

cd "$workdir"
git init -q --initial-branch=main repo
git init -q --bare origin.git
cd repo
git config user.name Test
git config user.email test@example.com
mkdir -p .fabro/workflows/scripts .fabro/workflows/iteration-implementation/scripts docs/iterations/001-example web/lib
cp "$iteration_status_source" .fabro/workflows/scripts/iteration_status.py
chmod +x .fabro/workflows/scripts/iteration_status.py
cp "$guard_source" .fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py
cat > docs/iterations/README.md <<'README'
# Iterations

| # | Date | Status | Title | Plan |
| --- | --- | --- | --- | --- |
| 001 | 2026-01-01 | implementing | Example iteration | [plan](001-example/plan.md) |
README
cat > docs/iterations/001-example/plan.md <<'PLAN'
# Example iteration

Status: implementing

## Goal

Ship an example implementation.
PLAN
cat > web/lib/example.ex <<'CODE'
defmodule Example do
  def value, do: :before
end
CODE
git add .
git commit -q -m initial
git remote add origin "$workdir/origin.git"
git push -q origin main

cat > web/lib/example.ex <<'CODE'
defmodule Example do
  def value, do: :after
end
CODE
git add web/lib/example.ex
git commit -q -m 'fabro checkpoint implementation'

FABRO_RUN_ID=TEST-RUN "$script_path" docs/iterations/001-example/plan.md >/tmp/publish-to-main.out 2>/tmp/publish-to-main.err

git fetch -q origin main
published=$(git rev-parse origin/main)
message=$(git log -1 --format=%B origin/main)

if ! grep -q 'iteration 001: Example iteration' <<<"$message"; then
  echo "Expected implementation commit subject on origin/main" >&2
  echo "$message" >&2
  exit 1
fi
if ! grep -q 'Fabro-Run-Id: TEST-RUN' <<<"$message"; then
  echo "Expected Fabro run id in commit message" >&2
  echo "$message" >&2
  exit 1
fi
if [ "$(git show "$published:docs/iterations/001-example/plan.md" | sed -n 's/^Status: //p')" != "merged" ]; then
  echo "Expected plan status to be merged on origin/main" >&2
  exit 1
fi
if ! git show "$published:docs/iterations/README.md" | grep -q '| 001 | 2026-01-01 | merged | Example iteration |'; then
  echo "Expected iteration index status to be merged on origin/main" >&2
  git show "$published:docs/iterations/README.md" >&2
  exit 1
fi
if ! git show "$published:web/lib/example.ex" | grep -q ':after'; then
  echo "Expected product implementation to be published" >&2
  exit 1
fi

echo "publish_to_main tests passed"
