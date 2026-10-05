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

export PATH="$repo_root/bin:$tmpdir/toolchain:$PATH"

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

start_postgres() { :; }
_setup() { :; }

acceptance_calls=0
acceptance() {
  acceptance_calls=$((acceptance_calls + 1))
}

responsive_check() { :; }

precommit() {
  return 23
}

if _ci; then
  echo "Expected _ci to preserve the precommit failure" >&2
  exit 1
else
  status=$?
fi
if [ "$status" -ne 23 ]; then
  echo "Expected _ci status 23, got $status" >&2
  exit 1
fi
if [ "$acceptance_calls" -ne 0 ]; then
  echo "Expected _ci not to run acceptance after precommit failed" >&2
  exit 1
fi

argc_quick=0
if _check; then
  echo "Expected _check to preserve the precommit failure" >&2
  exit 1
else
  status=$?
fi
if [ "$status" -ne 23 ]; then
  echo "Expected _check status 23, got $status" >&2
  exit 1
fi
if [ "$acceptance_calls" -ne 0 ]; then
  echo "Expected _check not to run acceptance after precommit failed" >&2
  exit 1
fi

precommit() { :; }
_ci
_check
if [ "$acceptance_calls" -ne 2 ]; then
  echo "Expected successful _ci and _check to run acceptance once each" >&2
  exit 1
fi

printf 'dev quality-gate exit-status tests passed\n'
