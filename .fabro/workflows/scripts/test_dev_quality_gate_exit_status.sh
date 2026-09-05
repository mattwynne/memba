#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
dev_script="$repo_root/bin/dev"

# Load the real helper functions without executing argc's command dispatch.
# shellcheck disable=SC1090
source <(awk '
  /^case "\$\{1:-\}" in$/ {
    case_line = $0
    if ((getline next_line) <= 0) {
      print case_line
      next
    }
    if (next_line ~ /^[[:space:]]+test\)/) {
      exit
    }
    print case_line
    print next_line
    next
  }
  { print }
' "$dev_script")

start_postgres() { :; }
_setup() { :; }

acceptance_calls=0
acceptance() {
  acceptance_calls=$((acceptance_calls + 1))
}

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
