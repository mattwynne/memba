#!/usr/bin/env bash
set -euo pipefail

scripts_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
script_path="$scripts_dir/publish_polish_to_main.sh"
preflight_path="$scripts_dir/preflight_sandbox.sh"
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
if [ "${1:-}" = sandbox-check ]; then
  exit 0
fi
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
  export FABRO_DEV_CHECK_LOG="$root/dev-check.log"
  export FABRO_RUN_ID="$name"
}

advance_main_to_b() {
  local name=$1 other="$workdir/$1/other"
  git clone -q "$workdir/$1/origin.git" "$other"
  (
    cd "$other"
    git config user.name Other
    git config user.email other@example.com
    printf 'concurrent B\n' > "docs/concurrent-$name.md"
    git add "docs/concurrent-$name.md"
    git commit -q -m "concurrent main B for $name"
    git push -q origin main
  )
}

new_fixture NOOP
"$preflight_path" "$(git rev-parse HEAD)"
before=$(git rev-parse origin/main)
"$script_path" docs/iterations/001-example/plan.md | grep -Fq 'main remains unchanged'
after=$(git rev-parse origin/main)
[ "$before" = "$after" ]
[ ! -e "$FABRO_DEV_CHECK_LOG" ]

new_fixture DOCS
candidate_a=$(git rev-parse HEAD)
advance_main_to_b DOCS
"$preflight_path" "$candidate_a"
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
git show origin/main:docs/concurrent-DOCS.md | grep -Fxq 'concurrent B'
[ "$(cat .fabro/tmp/code-review-published-sha.txt)" = "$(git rev-parse origin/main)" ]

new_fixture HEAL
candidate_a=$(git rev-parse HEAD)
advance_main_to_b HEAL
"$preflight_path" "$candidate_a"
printf 'after\n' > web/lib/example.ex
git add web/lib/example.ex && git commit -q -m checkpoint
"$script_path" docs/iterations/001-example/plan.md
git fetch -q origin main
published=$(git rev-parse origin/main)
message=$(git log -1 --format=%B origin/main)
grep -Fq 'code review: heal iteration 001' <<<"$message"
grep -Fq 'Fabro-Workflow: code-review' <<<"$message"
grep -Fxq "$published check" "$FABRO_DEV_CHECK_LOG"
git notes --ref=refs/notes/fabro-dev-check show "$published" | grep -Fxq "Validated-Commit: $published"
git show "$published:docs/concurrent-HEAL.md" | grep -Fxq 'concurrent B'
[ "$(cat .fabro/tmp/code-review-published-sha.txt)" = "$published" ]
observation=$("$scripts_dir/record_observability.sh" bounded_heal false true | tail -1)
python3 - "$published" "$observation" <<'PY'
import json, sys
published, raw = sys.argv[1:]
record = json.loads(raw)
assert record["review_disposition"] == "bounded_heal", record
assert record["human_paused"] is False, record
assert record["heal_commit_published"] is True, (published, record)
assert isinstance(record["elapsed_seconds"], int), record
PY

printf 'code-review stale-candidate publication/no-op, concurrent-main, and publication-observability tests passed\n'
