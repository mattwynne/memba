#!/usr/bin/env bash
set -euo pipefail

scripts_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$scripts_dir/../../../.." && pwd)
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
fixture="$workdir/repo"
origin="$workdir/origin.git"
fakebin="$workdir/fakebin"
mkdir -p "$fixture/bin" "$fixture/docs/iterations/001-example" "$fakebin" "$workdir/worktrees"
cp "$repo_root/bin/dev" "$fixture/bin/dev"
chmod +x "$fixture/bin/dev"
printf '# Plan\n' > "$fixture/docs/iterations/001-example/plan.md"
git init -q --bare "$origin"
git init -q --initial-branch=main "$fixture"
git -C "$fixture" config user.name Test
git -C "$fixture" config user.email test@example.com
git -C "$fixture" add .
git -C "$fixture" commit -qm candidate-A
git -C "$fixture" remote add origin "$origin"
git -C "$fixture" push -q -u origin main
git -C "$origin" symbolic-ref HEAD refs/heads/main
candidate=$(git -C "$fixture" rev-parse HEAD)

cat > "$fakebin/argc" <<'ARGC'
#!/usr/bin/env bash
set -euo pipefail
[ "$1" = --argc-eval ]
shift 2
printf '%q' "$1"
shift
printf ' %q' "$@"
printf '\n'
ARGC
cat > "$fakebin/fabro" <<'FABRO'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  run)
    printf '%s\n' "$*" > "$FAKE_FABRO_ARGS"
    if [ -n "${FAKE_RUN_SLEEP:-}" ]; then sleep "$FAKE_RUN_SLEEP"; fi
    printf 'Run: %s\n' "$FAKE_RUN_ID"
    exit "${FAKE_RUN_EXIT:-0}"
    ;;
  inspect)
    printf '{"status":{"kind":"%s"}}\n' "${FAKE_RUN_STATUS:-running}"
    ;;
  *) echo "unexpected fake fabro command: $*" >&2; exit 90 ;;
esac
FABRO
chmod +x "$fakebin/argc" "$fakebin/fabro"

assert_rejected_plan_path() {
  local name=$1 plan_path=$2
  local out="$workdir/$name.out" err="$workdir/$name.err"
  export FAKE_FABRO_ARGS="$workdir/$name.args"
  rm -f "$FAKE_FABRO_ARGS"
  set +e
  PATH="$fakebin:$PATH" MEMBA_DEVENV_SHELL=1 DEVENV_ROOT="$fixture" MEMBA_REVIEW_WORKTREE_ROOT="$workdir/worktrees" \
    "$fixture/bin/dev" fabro code-review origin/main "$plan_path" "$candidate" >"$out" 2>"$err"
  actual=$?
  set -e
  [ "$actual" -eq 2 ]
  grep -Fq 'Unsupported plan_path' "$err"
  [ ! -e "$FAKE_FABRO_ARGS" ] || { echo "$name unexpectedly launched Fabro" >&2; exit 1; }
}

assert_rejected_plan_path apostrophe "docs/iterations/001-example/plan'md"
assert_rejected_plan_path newline $'docs/iterations/001-example/plan.md\nuntrusted'

run_case() {
  local name=$1 status=$2 expected_exit=$3
  local out="$workdir/$name.out" err="$workdir/$name.err"
  export FAKE_RUN_ID="01JTEST${name^^}00000000000000"
  FAKE_RUN_ID=${FAKE_RUN_ID:0:26}
  while [ "${#FAKE_RUN_ID}" -lt 26 ]; do FAKE_RUN_ID="${FAKE_RUN_ID}X"; done
  export FAKE_RUN_ID FAKE_RUN_STATUS="$status" FAKE_RUN_EXIT=17
  export FAKE_FABRO_ARGS="$workdir/$name.args"
  set +e
  PATH="$fakebin:$PATH" MEMBA_DEVENV_SHELL=1 DEVENV_ROOT="$fixture" MEMBA_REVIEW_WORKTREE_ROOT="$workdir/worktrees" \
    "$fixture/bin/dev" fabro code-review origin/main docs/iterations/001-example/plan.md "$candidate" >"$out" 2>"$err"
  actual=$?
  set -e
  [ "$actual" -eq "$expected_exit" ] || {
    echo "$name: expected exit $expected_exit, got $actual" >&2
    cat "$out" "$err" >&2
    exit 1
  }
  grep -Fq -- '--detach' "$FAKE_FABRO_ARGS"
  grep -Fq -- "-I candidate_sha=$candidate" "$FAKE_FABRO_ARGS"
  [ ! -e "$workdir/worktrees/memba-code-review-code-review-tmp-main-"* ] || {
    echo "$name: asynchronous launch leaked its temporary worktree" >&2
    exit 1
  }
  while IFS= read -r temporary_branch; do
    [ -n "$temporary_branch" ] || continue
    git -C "$fixture" branch -D "$temporary_branch" >/dev/null
  done < <(git -C "$fixture" for-each-ref --format='%(refname:short)' refs/heads/code-review/tmp)
}

run_case active running 0
grep -Fq 'may still be active' "$workdir/active.err"
grep -Fq 'do not launch a duplicate' "$workdir/active.err"

run_case unknown mystery 0
grep -Fq 'status is' "$workdir/unknown.err"
grep -Fq 'do not launch a duplicate while it may be active' "$workdir/unknown.err"

run_case success succeeded 0
grep -Fq 'remote code-review run' "$workdir/success.err"
grep -Fq 'succeeded' "$workdir/success.err"

run_case failed failed 17
grep -Fq 'Review its evidence before deciding whether to retry' "$workdir/failed.err"

# An explicit base must itself be an ancestor; a merge base must not silently
# replace a caller-supplied unrelated commit.
nonancestor=$(printf 'unrelated\n' | git -C "$fixture" commit-tree "$candidate^{tree}")
export FAKE_FABRO_ARGS="$workdir/nonancestor.args"
rm -f "$FAKE_FABRO_ARGS"
set +e
PATH="$fakebin:$PATH" MEMBA_DEVENV_SHELL=1 DEVENV_ROOT="$fixture" MEMBA_REVIEW_WORKTREE_ROOT="$workdir/worktrees" \
  "$fixture/bin/dev" fabro code-review origin/main docs/iterations/001-example/plan.md "$nonancestor" \
  >"$workdir/nonancestor.out" 2>"$workdir/nonancestor.err"
nonancestor_status=$?
set -e
[ "$nonancestor_status" -eq 1 ]
grep -Fq 'review base is not an ancestor of the launch candidate' "$workdir/nonancestor.err"
[ ! -e "$FAKE_FABRO_ARGS" ] || { echo 'non-ancestor base unexpectedly launched Fabro' >&2; exit 1; }
[ ! -e "$workdir/worktrees/memba-code-review-code-review-tmp-main-"* ] || {
  echo 'non-ancestor rejection leaked its temporary worktree' >&2
  exit 1
}
while IFS= read -r temporary_branch; do
  [ -n "$temporary_branch" ] || continue
  git -C "$fixture" branch -D "$temporary_branch" >/dev/null
  git -C "$fixture" push -q origin --delete "$temporary_branch" || true
done < <(git -C "$fixture" for-each-ref --format='%(refname:short)' refs/heads/code-review/tmp)

# Interrupting the local launch must not strand the isolated worktree.
export FAKE_FABRO_ARGS="$workdir/interrupted.args" FAKE_RUN_SLEEP=30 FAKE_RUN_EXIT=0
PATH="$fakebin:$PATH" MEMBA_DEVENV_SHELL=1 DEVENV_ROOT="$fixture" MEMBA_REVIEW_WORKTREE_ROOT="$workdir/worktrees" \
  "$fixture/bin/dev" fabro code-review origin/main docs/iterations/001-example/plan.md "$candidate" \
  >"$workdir/interrupted.out" 2>"$workdir/interrupted.err" &
interrupted_pid=$!
for _ in $(seq 1 100); do [ -e "$FAKE_FABRO_ARGS" ] && break; sleep 0.05; done
[ -e "$FAKE_FABRO_ARGS" ] || { echo 'interruption fixture never launched Fabro' >&2; exit 1; }
kill -TERM "$interrupted_pid"
set +e
wait "$interrupted_pid"
interrupted_status=$?
set -e
unset FAKE_RUN_SLEEP
[ "$interrupted_status" -ne 0 ]
[ ! -e "$workdir/worktrees/memba-code-review-code-review-tmp-main-"* ] || {
  echo 'interrupted launch leaked its temporary worktree' >&2
  exit 1
}

# Run-ID extraction must work despite nonzero launch, and every case must retain
# monitoring guidance rather than treating a locally failed command as no run.
for name in active unknown success failed; do
  grep -Fq 'Code-review run ID:' "$workdir/$name.out"
  grep -Fq 'fabro inspect' "$workdir/$name.out"
done

printf 'code-review detached launch/status/cleanup tests passed\n'
