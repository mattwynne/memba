#!/usr/bin/env bash
set -euo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/finalize_iteration_status.sh
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
iteration_status_source="$repo_root/.fabro/workflows/scripts/iteration_status.py"
repo_dir=$(mktemp -d)
trap 'rm -rf "$repo_dir"' EXIT

cd "$repo_dir"
mkdir -p docs/kaizen
printf '# Problem: example\n' > docs/kaizen/example.md

output_path=$repo_dir/finalize-output.txt
bash "$script_path" docs/kaizen/example.md > "$output_path"

if ! grep -Fq 'not an iteration plan; skipping iteration status finalization' "$output_path"; then
  echo 'Expected non-iteration plan paths to skip finalization successfully.' >&2
  cat "$output_path" >&2
  exit 1
fi

if grep -Fq 'must end with /plan.md' "$output_path"; then
  echo 'Expected non-iteration plan paths not to fail with /plan.md requirement.' >&2
  cat "$output_path" >&2
  exit 1
fi

workdir=$repo_dir/finalize-repo
mkdir -p "$workdir"
git init -q --initial-branch=main "$workdir/repo"
git init -q --bare "$workdir/origin.git"
cd "$workdir/repo"
git config user.name Test
git config user.email test@example.com
mkdir -p .fabro/workflows/scripts docs/iterations/001-example docs
cp "$iteration_status_source" .fabro/workflows/scripts/iteration_status.py
chmod +x .fabro/workflows/scripts/iteration_status.py
cat > docs/iterations/README.md <<'README'
# Iterations

| # | Date | Status | Title | Plan |
| --- | --- | --- | --- | --- |
| 001 | 2026-01-01 | reviewing | Example iteration | [plan](001-example/plan.md) |
README
cat > docs/iterations/001-example/plan.md <<'PLAN'
# Example iteration

Status: reviewing
PLAN
cat > docs/iterations/001-example/implementation.md <<'IMPLEMENTATION'
# Implementation

Status: reviewing
IMPLEMENTATION
cat > docs/code-health.md <<'HEALTH'
# Code Health

No findings yet.
HEALTH
git add .
git commit -q -m initial
git remote add origin "$workdir/origin.git"
git push -q origin main

run_branch=fabro/run/FINALIZE-RUN
git switch -q -c "$run_branch"
cat > docs/code-health.md <<'HEALTH'
# Code Health

- Review checkpoint preserved.
HEALTH
git add docs/code-health.md
git commit -q -m 'fabro checkpoint before finalization'
remote_run_checkpoint=$(git rev-parse HEAD)
git push -q origin HEAD:"$run_branch"

other="$workdir/other"
git clone -q "$workdir/origin.git" "$other"
(
  cd "$other"
  git config user.name Other
  git config user.email other@example.com
  printf 'Review polish was already published.\n' > docs/main-moved.md
  git add docs/main-moved.md
  git commit -q -m 'review polish published to main'
  git push -q origin main
)

cat > .git/hooks/post-commit <<EOF
#!/usr/bin/env bash
set -euo pipefail
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
marker="$workdir/finalize-main-move-hook.done"
if [ -f "\$marker" ]; then
  exit 0
fi
touch "\$marker"
clone="$workdir/finalize-main-moved-during-rebase"
git clone -q "$workdir/origin.git" "\$clone"
(
  cd "\$clone"
  git fetch -q origin main
  git switch -q -C main origin/main
  git config user.name Other
  git config user.email other@example.com
  printf 'origin/main moved during finalization rebase.\n' > docs/main-moved-during-finalization.md
  git add docs/main-moved-during-finalization.md
  git commit -q -m 'main moved during finalization rebase'
  git push -q origin main
)
EOF
chmod +x .git/hooks/post-commit

FABRO_RUN_ID=FINALIZE-RUN "$script_path" docs/iterations/001-example/plan.md >/tmp/finalize-iteration.out 2>/tmp/finalize-iteration.err

git fetch -q origin main "$run_branch"
published=$(git rev-parse origin/main)
if [ "$(git show "$published:docs/iterations/001-example/plan.md" | sed -n 's/^Status: //p')" != "merged" ]; then
  echo "Expected plan status to be merged on origin/main" >&2
  exit 1
fi
if [ "$(git show "$published:docs/iterations/001-example/implementation.md" | sed -n 's/^Status: //p')" != "merged" ]; then
  echo "Expected implementation status to be merged on origin/main" >&2
  exit 1
fi
if ! git show "$published:docs/iterations/README.md" | grep -q '| 001 | 2026-01-01 | merged | Example iteration |'; then
  echo "Expected iteration index status to be merged on origin/main" >&2
  git show "$published:docs/iterations/README.md" >&2
  exit 1
fi
if ! git show "$published:docs/main-moved.md" | grep -q 'Review polish was already published'; then
  echo "Expected finalization commit to preserve existing origin/main content" >&2
  exit 1
fi
if ! git show "$published:docs/main-moved-during-finalization.md" | grep -q 'origin/main moved during finalization rebase'; then
  echo "Expected finalization rebase to preserve origin/main movement that happened after the finalization commit" >&2
  exit 1
fi
message=$(git log -1 --format=%B origin/main)
if ! grep -q 'iteration 001: mark merged' <<<"$message"; then
  echo "Expected finalization commit subject on origin/main" >&2
  echo "$message" >&2
  exit 1
fi
identity=$(git log -1 --format='%an <%ae>|%cn <%ce>' origin/main)
if [ "$identity" != 'Fabro <noreply@fabro.sh>|Fabro <noreply@fabro.sh>' ]; then
  echo "Expected rebased finalization commit to use the approved scoped Fabro identity" >&2
  echo "$identity" >&2
  exit 1
fi
if ! git merge-base --is-ancestor "$remote_run_checkpoint" HEAD; then
  echo "Expected finalization not to rewrite the active Fabro run branch away from its pushed checkpoint" >&2
  git log --oneline --decorate --graph --all >&2
  exit 1
fi
git commit --allow-empty -q -m 'fabro automatic checkpoint after finalization'
if ! git push -q origin HEAD:"$run_branch"; then
  echo "Expected ordinary post-finalization checkpoint push to active Fabro run branch to succeed" >&2
  exit 1
fi

echo 'iteration-review finalization tests passed'
