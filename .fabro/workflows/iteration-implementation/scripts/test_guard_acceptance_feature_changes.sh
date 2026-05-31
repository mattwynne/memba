#!/usr/bin/env bash
set -euo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/guard_acceptance_feature_changes.py
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

run_guard() {
  python3 "$script_path" plan.md "$base_sha" >/tmp/guard.out 2>/tmp/guard.err
}

assert_fails() {
  if run_guard; then
    echo "Expected guard to fail" >&2
    cat /tmp/guard.out >&2 || true
    exit 1
  fi
}

assert_passes() {
  if ! run_guard; then
    echo "Expected guard to pass" >&2
    cat /tmp/guard.err >&2 || true
    exit 1
  fi
}

cd "$workdir"
git init -q
git config user.name Test
git config user.email test@example.com
mkdir -p acceptance-tests/features
cat > acceptance-tests/features/example.feature <<'FEATURE'
Feature: Example

  Scenario: Original scenario
    Given a fact
    Then an outcome
FEATURE
cat > plan.md <<'PLAN'
# Example plan
PLAN
git add .
git commit -q -m initial
base_sha=$(git rev-parse HEAD)

# Feature edits are rejected without an explicit allowed-change section.
python3 - <<'PY'
from pathlib import Path
path = Path('acceptance-tests/features/example.feature')
text = path.read_text()
path.write_text(text.replace('    Then an outcome', '    Then a different outcome'))
PY
assert_fails

git reset -q --hard "$base_sha"

# Tag-only permission allows tag-only diffs.
cat > plan.md <<'PLAN'
# Example plan

## Allowed acceptance feature changes

- `acceptance-tests/features/example.feature`: tag-only change to add `@todo-web`; coverage remains in another runner.
PLAN
python3 - <<'PY'
from pathlib import Path
path = Path('acceptance-tests/features/example.feature')
text = path.read_text()
path.write_text(text.replace('  Scenario: Original scenario', '  @todo-web\n  Scenario: Original scenario'))
PY
assert_passes

git reset -q --hard "$base_sha"

# Tag-only permission still rejects non-tag scenario text changes.
cat > plan.md <<'PLAN'
# Example plan

## Allowed acceptance feature changes

- `acceptance-tests/features/example.feature`: tag-only change to add `@todo-web`; coverage remains in another runner.
PLAN
python3 - <<'PY'
from pathlib import Path
path = Path('acceptance-tests/features/example.feature')
text = path.read_text()
path.write_text(text.replace('    Then an outcome', '    Then a different outcome'))
PY
assert_fails

git reset -q --hard "$base_sha"

# Explicit non-tag permission allows a named feature file to change.
cat > plan.md <<'PLAN'
# Example plan

## Allowed acceptance feature changes

- `acceptance-tests/features/example.feature`: update scenario language for the approved model change; coverage is preserved by dev check.
PLAN
python3 - <<'PY'
from pathlib import Path
path = Path('acceptance-tests/features/example.feature')
text = path.read_text()
path.write_text(text.replace('    Then an outcome', '    Then a different outcome'))
PY
assert_passes

echo "guard_acceptance_feature_changes tests passed"
