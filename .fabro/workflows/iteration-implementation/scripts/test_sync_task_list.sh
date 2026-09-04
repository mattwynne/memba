#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/../../../.." && pwd)
helper="$repo_root/.fabro/workflows/iteration-implementation/scripts/sync_task_list.py"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

assert_contains() {
  local file=$1
  local expected=$2
  if ! grep -Fq -- "$expected" "$file"; then
    echo "Expected $file to contain: $expected" >&2
    echo "--- $file ---" >&2
    cat "$file" >&2
    exit 1
  fi
}

cat > "$tmpdir/plan.md" <<'PLAN'
# 999 — Test plan

## Implementation Plan

1. `PageHTML.message` (`message.html.heex`):
   - Replace the follow card with a toggle, preserving the existing events.
   - Move the reply composer below replies and keep the actor pill.
2. `MemberMessageLive.Show`: add the delivery-expanded assign.
3. No changes to commands, projections, or follow/reply behaviour.

## Open Technical Decisions

None.
PLAN

python3 "$helper" "$tmpdir/plan.md" "$tmpdir/todo.md"
assert_contains "$tmpdir/todo.md" '- [ ] 001 `PageHTML.message` (`message.html.heex`): Replace the follow card with a toggle, preserving the existing events.'
assert_contains "$tmpdir/todo.md" '- [ ] 002 `PageHTML.message` (`message.html.heex`): Move the reply composer below replies and keep the actor pill.'
assert_contains "$tmpdir/todo.md" '- [ ] 003 `MemberMessageLive.Show`: add the delivery-expanded assign.'
if grep -Fq 'No changes to commands' "$tmpdir/todo.md"; then
  echo "Expected non-implementation constraint to be omitted from todo.md" >&2
  cat "$tmpdir/todo.md" >&2
  exit 1
fi

cat > "$tmpdir/prerequisite-plan.md" <<'PLAN'
# 999 — Prerequisite and scope guards

## Implementation Plan

1. Verify iteration 998's event-sourced foundation is merged and passing before starting this plan. Do not recreate that foundation in iteration 999.
2. Add the new routing behaviour and its focused tests.
3. Do not add a persisted policy or a policy editor.

## Open Technical Decisions

None.
PLAN

python3 "$helper" "$tmpdir/prerequisite-plan.md" "$tmpdir/prerequisite-todo.md"
assert_contains "$tmpdir/prerequisite-todo.md" '- [ ] 001 Add the new routing behaviour and its focused tests.'
if grep -Eq 'Verify iteration 998|Do not recreate|Do not add a persisted policy' "$tmpdir/prerequisite-todo.md"; then
  echo "Expected verification prerequisites and negative scope guards to be omitted from todo.md" >&2
  cat "$tmpdir/prerequisite-todo.md" >&2
  exit 1
fi

echo '# Implementation TODO

- [x] 001 Already done
- [ ] 002 Existing split' > "$tmpdir/todo.md"
python3 "$helper" "$tmpdir/plan.md" "$tmpdir/todo.md"
assert_contains "$tmpdir/todo.md" '- [x] 001 Already done'
assert_contains "$tmpdir/todo.md" '- [ ] 002 Existing split'

cat > "$tmpdir/wrapped-plan.md" <<'PLAN'
# 999 — Wrapped plan

## Implementation Plan

1. `PageHTML.message` (`message.html.heex`):
   - Replace the follow card with a toggle, preserving the existing events and
     data attributes.
2. Update tests so they cover the visible state and
   the interaction path.

## Open Technical Decisions

None.
PLAN

python3 "$helper" "$tmpdir/wrapped-plan.md" "$tmpdir/wrapped-todo.md"
assert_contains "$tmpdir/wrapped-todo.md" 'data attributes.'
assert_contains "$tmpdir/wrapped-todo.md" '- [ ] 002 Update tests so they cover the visible state and the interaction path.'

cat > "$tmpdir/sentence-plan.md" <<'PLAN'
# 999 — Sentence plan

## Implementation Plan

1. This deliberately long implementation step starts with a first sentence that can stand alone as one execution task and remains comfortably below the task limit. This second sentence can also stand alone as another execution task and should be split before implementation starts.

## Open Technical Decisions

None.
PLAN

python3 "$helper" "$tmpdir/sentence-plan.md" "$tmpdir/sentence-todo.md"
assert_contains "$tmpdir/sentence-todo.md" '- [ ] 001 This deliberately long implementation step starts with a first sentence that can stand alone as one execution task and remains comfortably below the task limit.'
assert_contains "$tmpdir/sentence-todo.md" '- [ ] 002 This second sentence can also stand alone as another execution task and should be split before implementation starts.'

cat > "$tmpdir/broad-plan.md" <<'PLAN'
# 999 — Broad plan

## Implementation Plan

1. `PageHTML.message` (`message.html.heex`):

## Open Technical Decisions

None.
PLAN

if python3 "$helper" "$tmpdir/broad-plan.md" "$tmpdir/broad-todo.md" > "$tmpdir/broad.out" 2>&1; then
  echo "Expected broad plan to fail" >&2
  cat "$tmpdir/broad.out" >&2
  exit 1
fi
assert_contains "$tmpdir/broad.out" "Generated todo list is too coarse"
assert_contains "$tmpdir/broad.out" "ends with ':'"

echo "sync_task_list tests passed"
