#!/usr/bin/env bash
set -euo pipefail

scripts_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
script_path="$scripts_dir/publish_polish_to_main.sh"
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

new_fixture() {
  local name=$1 root="$workdir/$1"
  git init -q --initial-branch=main "$root/repo"
  git init -q --bare "$root/origin.git"
  cd "$root/repo"
  git config user.name Test
  git config user.email test@example.com
  mkdir -p bin .fabro/tmp .fabro/workflows/scripts docs/iterations/001-example docs web/lib
  cp "$scripts_dir/../../scripts/attest_dev_check.sh" .fabro/workflows/scripts/attest_dev_check.sh
  cat > bin/dev <<'DEV'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "$(git rev-parse HEAD)" "$*" >> "$FABRO_DEV_CHECK_LOG"
DEV
  chmod +x bin/dev
  cat > docs/iterations/001-example/plan.md <<'PLAN'
# Example
Status: merged
PLAN
  printf '# Code Health\n' > docs/code-health.md
  printf 'before\n' > web/lib/example.ex
  git add . && git commit -q -m initial
  git remote add origin "$root/origin.git"
  git push -q origin main
  git -C "$root/origin.git" symbolic-ref HEAD refs/heads/main
  git switch -q -c "fabro/run/$name"
  git rev-parse HEAD > .fabro/tmp/review-start-sha.txt
  export FABRO_DEV_CHECK_LOG="$root/dev-check.log"
  export FABRO_RUN_ID="$name"
}

new_fixture NOOP
before=$(git rev-parse origin/main)
"$script_path" docs/iterations/001-example/plan.md | grep -Fq 'main remains unchanged'
after=$(git rev-parse origin/main)
[ "$before" = "$after" ]
[ ! -e "$FABRO_DEV_CHECK_LOG" ]

new_fixture DOCS
printf '\n## Finding\nEvidence.\n' >> docs/code-health.md
git add docs/code-health.md && git commit -q -m checkpoint
"$script_path" docs/iterations/001-example/plan.md
if [ -e "$FABRO_DEV_CHECK_LOG" ]; then
  echo 'Docs-only finding publication must not run dev check.' >&2
  exit 1
fi
git fetch -q origin main
message=$(git log -1 --format=%B origin/main)
grep -Fq 'code review: record iteration 001 finding' <<<"$message"
grep -Fq 'docs-only code-health record' <<<"$message"

new_fixture HEAL
printf 'after\n' > web/lib/example.ex
git add web/lib/example.ex && git commit -q -m checkpoint
other="$workdir/HEAL/other"
git clone -q "$workdir/HEAL/origin.git" "$other"
(
  cd "$other"
  git config user.name Other
  git config user.email other@example.com
  printf 'concurrent\n' > docs/concurrent.md
  git add docs/concurrent.md && git commit -q -m concurrent
  git push -q origin main
)
"$script_path" docs/iterations/001-example/plan.md
git fetch -q origin main
published=$(git rev-parse origin/main)
message=$(git log -1 --format=%B origin/main)
grep -Fq 'code review: heal iteration 001' <<<"$message"
grep -Fq 'Fabro-Workflow: code-review' <<<"$message"
grep -Fxq "$published check" "$FABRO_DEV_CHECK_LOG"
git notes --ref=refs/notes/fabro-dev-check show "$published" | grep -Fxq "Validated-Commit: $published"
git show "$published:docs/concurrent.md" | grep -Fxq concurrent

printf 'code-review publication/no-op and concurrent-main tests passed\n'
