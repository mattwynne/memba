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
cp "$guard_source" .fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py.real
cat > .fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py <<'PY'
#!/usr/bin/env python3
import os
import subprocess
import sys

hook = os.environ.get("FABRO_TEST_AFTER_INITIAL_FETCH")
if hook:
    marker = hook + ".done"
    if not os.path.exists(marker):
        subprocess.run([hook], check=True)
        open(marker, "w").close()

os.execv(sys.executable, [sys.executable, sys.argv[0] + ".real", *sys.argv[1:]])
PY
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
run_branch=fabro/run/TEST-RUN
git switch -q -c "$run_branch"
remote_run_checkpoint=$(git rev-parse HEAD)
git push -q origin HEAD:"$run_branch"

move_main_script="$workdir/move-main-during-implementation-publish.sh"
cat > "$move_main_script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
clone="$workdir/main-move-implementation"
git clone -q "$workdir/origin.git" "\$clone"
(
  cd "\$clone"
  git config user.name Other
  git config user.email other@example.com
  printf 'origin/main moved while implementation publish was preparing.\n' > docs/main-moved-during-implementation-publish.md
  git add docs/main-moved-during-implementation-publish.md
  git commit -q -m 'main moved during implementation publish'
  git push -q origin main
)
EOF
chmod +x "$move_main_script"

FABRO_TEST_AFTER_INITIAL_FETCH="$move_main_script" FABRO_RUN_ID=TEST-RUN "$script_path" docs/iterations/001-example/plan.md >/tmp/publish-to-main.out 2>/tmp/publish-to-main.err

git fetch -q origin main "$run_branch"
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
identity=$(git log -1 --format='%an <%ae>|%cn <%ce>' origin/main)
if [ "$identity" != 'Fabro <noreply@fabro.sh>|Fabro <noreply@fabro.sh>' ]; then
  echo "Expected published commit to use the approved Fabro email without GitHub user attribution" >&2
  echo "$identity" >&2
  exit 1
fi
if [ "$(git config --local user.name)" != "Test" ] || [ "$(git config --local user.email)" != "test@example.com" ]; then
  echo "Expected publish script not to persistently change repo-local git identity" >&2
  git config --local --get-regexp '^user\.' >&2
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
if ! git show "$published:docs/main-moved-during-implementation-publish.md" | grep -q 'origin/main moved'; then
  echo "Expected implementation publish rebase to preserve unrelated origin/main movement" >&2
  exit 1
fi
if ! git merge-base --is-ancestor "$remote_run_checkpoint" HEAD; then
  echo "Expected publish not to rewrite the active Fabro run branch away from its pushed checkpoint" >&2
  git log --oneline --decorate --graph --all >&2
  exit 1
fi
git commit --allow-empty -q -m 'fabro automatic checkpoint after publish'
if ! git push -q origin HEAD:"$run_branch"; then
  echo "Expected ordinary post-publish checkpoint push to active Fabro run branch to succeed" >&2
  exit 1
fi

# If origin/main moves with an overlapping change after validation, the publish
# script should preserve the attempted implementation on a rescue branch and
# materialize a merge conflict on the active managed run branch. Resolving that
# merge and retrying publication must still allow an ordinary fast-forward
# checkpoint push of the managed run branch.
conflict_run_branch=fabro/run/CONFLICT-RUN
git switch -q -c "$conflict_run_branch" origin/main
cat > web/lib/example.ex <<'CODE'
defmodule Example do
  def value, do: :implementation
end
CODE
git add web/lib/example.ex
git commit -q -m 'fabro checkpoint conflicting implementation'
remote_conflict_checkpoint=$(git rev-parse HEAD)
git push -q origin HEAD:"$conflict_run_branch"

other_conflict="$workdir/other-conflict"
git clone -q "$workdir/origin.git" "$other_conflict"
(
  cd "$other_conflict"
  git config user.name Other
  git config user.email other@example.com
  cat > web/lib/example.ex <<'CODE'
defmodule Example do
  def value, do: :main_moved
end
CODE
  git add web/lib/example.ex
  git commit -q -m 'main moved with overlapping change'
  git push -q origin main
)

set +e
FABRO_RUN_ID=CONFLICT-RUN "$script_path" docs/iterations/001-example/plan.md >/tmp/publish-conflict.out 2>/tmp/publish-conflict.err
conflict_status=$?
set -e

if [ "$conflict_status" -eq 0 ]; then
  echo "Expected publish conflict to fail for agent-assisted recovery" >&2
  exit 1
fi
if ! grep -q 'Publish rebase conflicted' /tmp/publish-conflict.err; then
  echo "Expected conflict failure explanation" >&2
  cat /tmp/publish-conflict.err >&2
  exit 1
fi
if ! grep -q 'web/lib/example.ex' /tmp/publish-conflict.err; then
  echo "Expected conflicted file in publish failure output" >&2
  cat /tmp/publish-conflict.err >&2
  exit 1
fi
if ! git diff --name-only --diff-filter=U | grep -q 'web/lib/example.ex'; then
  echo "Expected publish conflict to leave active conflict markers for recovery routing" >&2
  git status --short --branch >&2
  exit 1
fi
if [ "$(git branch --show-current)" != "$conflict_run_branch" ]; then
  echo "Expected conflict recovery to stay on the managed run branch" >&2
  git status --short --branch >&2
  exit 1
fi
if ! git merge-base --is-ancestor "$remote_conflict_checkpoint" HEAD; then
  echo "Expected conflict recovery candidate to remain a descendant of the remote run checkpoint" >&2
  git log --oneline --decorate --graph --all >&2
  exit 1
fi
if ! git ls-remote --exit-code --heads origin fabro/rescue/CONFLICT-RUN-001-publish-conflict >/dev/null 2>&1; then
  echo "Expected publish conflict rescue branch to be pushed" >&2
  git ls-remote --heads origin >&2
  exit 1
fi
if ! git branch --list fabro/recover/CONFLICT-RUN-001-publish-conflict | grep -q 'fabro/recover/CONFLICT-RUN-001-publish-conflict'; then
  echo "Expected local recovery branch to identify the recoverable conflict candidate" >&2
  git branch --list 'fabro/*' >&2
  exit 1
fi
cat > web/lib/example.ex <<'CODE'
defmodule Example do
  def value, do: :resolved
end
CODE
git add web/lib/example.ex
GIT_EDITOR=true git commit --no-edit -q
if [ -n "$(git status --short)" ]; then
  echo "Expected resolved conflict merge to leave a clean tree before dev_check and retry publish" >&2
  git status --short --branch >&2
  exit 1
fi
if ! git merge-base --is-ancestor "$remote_conflict_checkpoint" HEAD; then
  echo "Expected resolved conflict merge to remain a descendant of the remote run checkpoint" >&2
  git log --oneline --decorate --graph --all >&2
  exit 1
fi

FABRO_RUN_ID=CONFLICT-RUN "$script_path" docs/iterations/001-example/plan.md >/tmp/publish-conflict-retry.out 2>/tmp/publish-conflict-retry.err

git fetch -q origin main "$conflict_run_branch"
retry_published=$(git rev-parse origin/main)
if ! git show "$retry_published:web/lib/example.ex" | grep -q ':resolved'; then
  echo "Expected retry publish to publish the resolved implementation" >&2
  git show "$retry_published:web/lib/example.ex" >&2
  exit 1
fi
git commit --allow-empty -q -m 'fabro automatic checkpoint after conflict recovery publish'
if ! git push -q origin HEAD:"$conflict_run_branch"; then
  echo "Expected ordinary post-conflict-recovery checkpoint push to active Fabro run branch to succeed" >&2
  git log --oneline --decorate --graph --all >&2
  exit 1
fi

echo "publish_to_main tests passed"
