#!/usr/bin/env bash
set -euo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/final_artifact_gate.sh
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
guard_source="$repo_root/.fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py"
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

run_gate() {
  "$script_path" docs/iterations/001-example/plan.md "$base_sha" >/tmp/review-final-gate.out 2>/tmp/review-final-gate.err
}

assert_fails() {
  if run_gate; then
    echo "Expected final artifact gate to fail" >&2
    cat /tmp/review-final-gate.out >&2 || true
    exit 1
  fi
}

assert_passes() {
  if ! run_gate; then
    echo "Expected final artifact gate to pass" >&2
    cat /tmp/review-final-gate.err >&2 || true
    exit 1
  fi
}

cd "$workdir"
git init -q
git config user.name Test
git config user.email test@example.com
mkdir -p .fabro/workflows/iteration-implementation/scripts .fabro/tmp acceptance-tests/features docs/iterations/001-example docs
cp "$guard_source" .fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py
cat > acceptance-tests/features/example.feature <<'FEATURE'
Feature: Example

  Scenario: Original scenario
    Given a fact
    Then an outcome
FEATURE
cat > docs/iterations/001-example/plan.md <<'PLAN'
# Example plan
PLAN
cat > docs/code-health.md <<'HEALTH'
# Code health
HEALTH
git add .
git commit -q -m initial
base_sha=$(git rev-parse HEAD)

# Implementation feature edits are rejected without explicit plan permission.
python3 - <<'PY'
from pathlib import Path
path = Path('acceptance-tests/features/example.feature')
text = path.read_text()
path.write_text(text.replace('    Then an outcome', '    Then a different outcome'))
PY
git add acceptance-tests/features/example.feature
git commit -q -m 'implementation edits feature without permission'
git rev-parse HEAD > .fabro/tmp/review-start-sha.txt
assert_fails

git reset -q --hard "$base_sha"

# Explicitly planned implementation feature edits are allowed at review finalization.
cat > docs/iterations/001-example/plan.md <<'PLAN'
# Example plan

## Allowed acceptance feature changes

- `acceptance-tests/features/example.feature`: tag-only change to add `@todo-web`; coverage remains in another runner.
PLAN
git add docs/iterations/001-example/plan.md
git commit -q -m 'plan permits tag-only feature edit'
base_sha=$(git rev-parse HEAD)
python3 - <<'PY'
from pathlib import Path
path = Path('acceptance-tests/features/example.feature')
text = path.read_text()
path.write_text(text.replace('  Scenario: Original scenario', '  @todo-web\n  Scenario: Original scenario'))
PY
git add acceptance-tests/features/example.feature
git commit -q -m 'implementation adds planned tag'
git rev-parse HEAD > .fabro/tmp/review-start-sha.txt
assert_passes

cat >> docs/code-health.md <<'HEALTH'

## Review finding: exact evidence

The final summary must report this exact finding.
HEALTH
git add docs/code-health.md
assert_passes
grep -Fq '## Review finding: exact evidence' /tmp/review-final-gate.out

# Review polish must not edit feature files, even when implementation edits were planned.
python3 - <<'PY'
from pathlib import Path
path = Path('acceptance-tests/features/example.feature')
text = path.read_text()
path.write_text(text.replace('    Then an outcome', '    Then another outcome'))
PY
assert_fails

echo "final_artifact_gate tests passed"
