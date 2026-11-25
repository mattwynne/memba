#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
dev_script="$repo_root/bin/dev"

# Load the real helper functions without executing argc's command dispatch.
# Process substitution makes bin/dev resolve repo_root as /dev while sourced; mark
# that synthetic checkout as the active devenv so startup guards do not re-enter.
export MEMBA_DEVENV_SHELL=1
export DEVENV_ROOT=/dev
# shellcheck disable=SC1090
source <(sed -n '
  /^case "${1:-}" in$/ {
    N
    /\n[[:space:]]*test)/q
    P
    D
  }
  p
' "$dev_script")

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
repo_root="$tmpdir/repo"
invocations="$tmpdir/invocations.log"
mkdir -p \
  "$repo_root/acceptance-tests/node_modules/.bin" \
  "$repo_root/bin" \
  "$repo_root/dev-tests" \
  "$repo_root/packages/live_query" \
  "$repo_root/web" \
  "$tmpdir/toolchain"
touch \
  "$repo_root/acceptance-tests/package-lock.json" \
  "$repo_root/acceptance-tests/node_modules/.package-lock.json" \
  "$repo_root/acceptance-tests/node_modules/.bin/cucumber-js" \
  "$repo_root/acceptance-tests/node_modules/.bin/playwright"
chmod +x \
  "$repo_root/acceptance-tests/node_modules/.bin/cucumber-js" \
  "$repo_root/acceptance-tests/node_modules/.bin/playwright"

cat > "$tmpdir/toolchain/elixir" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$tmpdir/toolchain/elixir"

cat > "$tmpdir/toolchain/mix" <<SH
#!/usr/bin/env bash
set -euo pipefail
printf 'package cwd=%s args=%s\n' "\$PWD" "\$*" >> "$invocations"
exit "\${PACKAGE_MIX_STATUS:-0}"
SH
chmod +x "$tmpdir/toolchain/mix"

cat > "$repo_root/bin/mix" <<SH
#!/usr/bin/env bash
set -euo pipefail
printf 'web cwd=%s args=%s\n' "\$PWD" "\$*" >> "$invocations"
exit "\${WEB_MIX_STATUS:-0}"
SH
chmod +x "$repo_root/bin/mix"

cat > "$tmpdir/toolchain/node" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$tmpdir/toolchain/node"
export PATH="$repo_root/bin:$tmpdir/toolchain:$PATH"
export MIX_HOME="$tmpdir/mix-home"

export PACKAGE_MIX_STATUS=29
export WEB_MIX_STATUS=0
if _precommit; then
  echo "Expected _precommit to preserve the package-test failure" >&2
  exit 1
else
  status=$?
fi
if [ "$status" -ne 29 ]; then
  echo "Expected _precommit status 29, got $status" >&2
  exit 1
fi
if grep -q '^web .*args=precommit$' "$invocations"; then
  echo "Expected package-test failure to stop before web precommit" >&2
  exit 1
fi

: > "$invocations"
export PACKAGE_MIX_STATUS=31
if _setup; then
  echo "Expected _setup to preserve the package dependency failure" >&2
  exit 1
else
  status=$?
fi
if [ "$status" -ne 31 ]; then
  echo "Expected _setup status 31, got $status" >&2
  exit 1
fi
if grep -q '^web .*args=deps.get$' "$invocations"; then
  echo "Expected package dependency failure to stop before web dependency setup" >&2
  exit 1
fi

: > "$invocations"
export PACKAGE_MIX_STATUS=0
_setup
if ! grep -q 'args=local.hex --if-missing --force$' "$invocations" ||
   ! grep -q 'args=local.rebar --if-missing --force$' "$invocations"; then
  echo "Expected _setup to preserve installed Hex and Rebar" >&2
  exit 1
fi
if ! grep -q "^package cwd=$repo_root/packages/live_query args=deps.get$" "$invocations"; then
  echo "Expected _setup to fetch standalone package dependencies" >&2
  exit 1
fi
if ! grep -q "^web cwd=$repo_root/web args=deps.get$" "$invocations"; then
  echo "Expected _setup to retain web dependency setup" >&2
  exit 1
fi

: > "$invocations"
_precommit
if ! grep -q "^package cwd=$repo_root/packages/live_query args=test$" "$invocations"; then
  echo "Expected _precommit to run standalone package tests" >&2
  exit 1
fi
if ! grep -q "^web cwd=$repo_root/web args=precommit$" "$invocations"; then
  echo "Expected _precommit to retain web precommit" >&2
  exit 1
fi

# Exercise the public entry points with the real lock and run database wrapper.
source_repo="$repo_root"
export PGHOST="$tmpdir/postgres" PGPORT=15432 PGUSER=memba MEMBA_POSTGRES_OWNER=dev
start_postgres() { echo start >> "$invocations"; }
_setup() { echo setup >> "$invocations"; }

record_phase() {
  printf '%s %s %s %s\n' "$1" "$MEMBA_TEST_RUN_ID" "$MEMBA_POSTGRES_OWNER" "$PGPORT" >> "$invocations"
}
_precommit() { record_phase precommit; return "${PRECOMMIT_STATUS:-0}"; }
_responsive_check() { record_phase responsive; return "${RESPONSIVE_STATUS:-0}"; }
_acceptance() { record_phase acceptance; }
_dev_test() { record_phase test; }
dropdb() {
  [ "${*: -1}" = "memba_test_run_$MEMBA_TEST_RUN_ID" ] || return 1
  [[ " $* " == *" --host=$PGHOST --port=$PGPORT --username=$PGUSER "* ]] || return 1
  record_phase cleanup
  return "${DROP_STATUS:-0}"
}

assert_phases() {
  local run_id expected actual
  run_id=$(awk 'NR == 3 {print $2}' "$invocations")
  [[ "$run_id" =~ ^[0-9a-f]{32}$ ]]
  expected=$(printf 'start\nsetup\n'; printf "%s $run_id dev $PGPORT\n" "$@" cleanup)
  actual=$(cat "$invocations")
  if [ "$actual" != "$expected" ]; then
    printf 'Expected:\n%s\nActual:\n%s\n' "$expected" "$actual" >&2
    return 1
  fi
}

for command in precommit responsive_check acceptance dev_test ci check; do
  : > "$invocations"
  MEMBA_TEST_RUN_ID=inherited MEMBA_QUALITY_GATE_LOCK_HELD=1 "$command"
  case "$command" in
    responsive_check) assert_phases responsive ;;
    dev_test) assert_phases test ;;
    ci) assert_phases precommit acceptance ;;
    check) assert_phases precommit responsive acceptance ;;
    *) assert_phases "$command" ;;
  esac
done

: > "$invocations"
pg_isready() {
  [ "$*" = "--host=shared-postgres --port=15433" ] || return 1
  [ "$PGHOST:$PGPORT" = "shared-postgres:15433" ] || return 1
  echo start >> "$invocations"
}
MEMBA_TEST_POSTGRES_HOST=shared-postgres MEMBA_POSTGRES_PORT=15433 acceptance
(PGPORT=15433; assert_phases acceptance)

for command in ci check; do
  : > "$invocations"
  status=0
  PRECOMMIT_STATUS=23 DROP_STATUS=4 "$command" || status=$?
  [ "$status" -eq 23 ]
  assert_phases precommit
done

: > "$invocations"
# Invoke as a failing CLI would. Putting the call in a conditional disables
# errexit in Bash and would miss failures inside its EXIT trap.
set +e
(set -e; PRECOMMIT_STATUS=23 check)
status=$?
set -e
[ "$status" -eq 23 ]
assert_phases precommit

: > "$invocations"
status=0
RESPONSIVE_STATUS=24 check || status=$?
[ "$status" -eq 24 ]
assert_phases precommit responsive

: > "$invocations"
status=0
DROP_STATUS=4 acceptance || status=$?
[ "$status" -eq 1 ]
assert_phases acceptance

run_locked() (
  repo_root=$(canonical_directory "$1")
  export MEMBA_POSTGRES_PORT="$2"
  with_quality_gate_lock "${@:3}"
)

wait_for() {
  local deadline=$((SECONDS + 10))
  until "$@"; do
    if [ "$SECONDS" -ge "$deadline" ]; then
      printf 'Timed out waiting for %s\n' "$*" >&2
      return 1
    fi
    sleep 0.05
  done
}

hold_lock() {
  touch "$tmpdir/first-entered"
  wait_for test -f "$tmpdir/release-first"
}

other_repo="$tmpdir/other-repo"
mkdir "$other_repo"
ln -s "$source_repo" "$tmpdir/source-alias"

run_locked "$source_repo" 15432 hold_lock &
first=$!
wait_for test -f "$tmpdir/first-entered"

# Access through a symlink must queue on the same checkout, even with an
# inherited legacy marker and a different configured Postgres port.
MEMBA_QUALITY_GATE_LOCK_HELD=1 run_locked "$tmpdir/source-alias" 15433 \
  touch "$tmpdir/second-entered" 2>"$tmpdir/second.log" &
second=$!
wait_for grep -q 'waiting for lock' "$tmpdir/second.log"
test ! -e "$tmpdir/second-entered"

run_locked "$other_repo" 15432 touch "$tmpdir/other-entered" 2>"$tmpdir/other.log" &
other=$!
wait_for test -f "$tmpdir/other-entered"
test ! -s "$tmpdir/other.log"
wait "$other"

touch "$tmpdir/release-first"
wait "$first"
wait "$second"
test -f "$tmpdir/second-entered"

printf 'dev quality-gate locking, run ownership, and exit-status tests passed\n'
