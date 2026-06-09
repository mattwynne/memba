#!/usr/bin/env bash
set -euo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/final_artifact_gate.sh
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
guard_source="$repo_root/.fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py"
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

setup_repo() {
  local repo=$1
  rm -rf "$repo"
  mkdir -p "$repo"
  cd "$repo"
  git init -q --initial-branch=main
  git config user.name Test
  git config user.email test@example.com
  mkdir -p .fabro/workflows/iteration-implementation/scripts docs/iterations/001-example acceptance-tests/features
  cp "$guard_source" .fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py
  cat > docs/iterations/001-example/plan.md <<'PLAN'
# Example plan

Status: implementing
PLAN
  cat > acceptance-tests/features/example.feature <<'FEATURE'
Feature: Example

  Scenario: Original scenario
    Given a fact
    Then an outcome
FEATURE
  echo original > app.txt
  git add .
  git commit -q -m initial

  rm -rf "$workdir/origin.git"
  git init -q --bare "$workdir/origin.git"
  git remote add origin "$workdir/origin.git"
  git push -q origin main
}

run_gate() {
  "$script_path" docs/iterations/001-example/plan.md >/tmp/implementation-final-gate.out 2>/tmp/implementation-final-gate.err
}

assert_passes() {
  if ! run_gate; then
    echo "Expected final artifact gate to pass" >&2
    cat /tmp/implementation-final-gate.out >&2 || true
    cat /tmp/implementation-final-gate.err >&2 || true
    exit 1
  fi
}

assert_fails() {
  if run_gate; then
    echo "Expected final artifact gate to fail" >&2
    cat /tmp/implementation-final-gate.out >&2 || true
    exit 1
  fi
}

setup_repo "$workdir/checkpointed"
cd "$workdir/checkpointed"
echo implemented > app.txt
git add app.txt
git commit -q -m 'implementation change'
# Simulate a Fabro checkpoint with no tree change after the implementation.
git commit -q --allow-empty -m 'fabro checkpoint after implementation'
assert_passes

grep -q 'Implementation base sha:' /tmp/implementation-final-gate.out
grep -q 'app.txt' /tmp/implementation-final-gate.out

setup_repo "$workdir/unchanged"
cd "$workdir/unchanged"
assert_fails
grep -q 'no artifact evidence' /tmp/implementation-final-gate.err

setup_repo "$workdir/uncommitted"
cd "$workdir/uncommitted"
echo implemented > app.txt
assert_passes

setup_repo "$workdir/feature-policy"
cd "$workdir/feature-policy"
python3 - <<'PY'
from pathlib import Path
path = Path('acceptance-tests/features/example.feature')
text = path.read_text()
path.write_text(text.replace('    Then an outcome', '    Then a different outcome'))
PY
git add acceptance-tests/features/example.feature
git commit -q -m 'implementation edits feature without permission'
assert_fails
grep -q 'locked acceptance feature policy failed' /tmp/implementation-final-gate.err

echo "implementation final_artifact_gate tests passed"
