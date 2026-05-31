Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01KSY8MQXVG1X7C57PEYPXJX5N
Pipeline progress: 13 of 30 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/007-deliveries-overview/plan.md'
if [ ! -f "$PLAN_PATH" ]; then
  echo "Iteration plan not found: $PLAN_PATH" >&2
  exit 1
fi
printf 'PLAN_PATH=%s\n\n' "$PLAN_PATH"
line_count=0
while IFS= read -r line && [ "$line_count" -lt 320 ]; do
  printf '%s\n' "$line"
  line_count=$((line_count + 1))
done < "$PLAN_PATH"`
- Output:
  ```
  (53 lines omitted)
  - Delayed, bounced, and spam complaint rows preserve the provider/channel reason text.
  - Opened deliveries are visible as `opened` after a delivered email is opened.
  - Delivered/opened rows do not show stale problem reasons.
  - `operator_email_deliverability.feature` uses deliveries-overview language and passes through the browser acceptance harness without `@todo-web` deferral.
  - `homepage.feature` and `member_message_deliverability.feature` continue to pass through the browser acceptance harness.
  - The Elixir/domain acceptance path used by `dev check` still runs the shared scenarios.
  - `dev check` passes.
  
  ## Open Business Decisions
  
  None known.
  
  ## Implementation Plan
  
  1. Update the operator feature language around the rule "Operators monitor detailed delivery records across messages", keeping scenarios BRIEF and focused on cross-message visibility, reason preservation, and opened status.
  2. Write failing PhoenixTest coverage for `/deliveries`, including records from more than one message and problem reason text.
  3. Reshape the public Messaging operator-deliverability query toward a deliveries-overview API, for example an options-shaped list function. Preserve any existing message-scoped needs through options or a compatibility wrapper only if still required by current code.
  4. Add the `/deliveries` LiveView route under the browser pipeline.
  5. Build the deliveries LiveView as a simple read-only table with stable accessible labels or IDs for browser acceptance.
  6. Update browser Cucumber step definitions for `operator_email_deliverability.feature` so operator assertions inspect `/deliveries`.
  7. Remove `@todo-web` tags from operator scenarios once they are browser-backed.
  8. Verify browser Cucumber still defaults to excluding `@todo-web`, while now including the operator scenarios because they are no longer tagged.
  9. Run the browser acceptance suite and `dev check`, fixing any issues.
  
  ## Open Technical Decisions
  
  None known. The intended technical shape is:
  
  - `/deliveries` is the operator overview route for delivery records across messages.
  - The query API is deliveries-overview oriented and options-shaped for later filtering/pagination.
  - This iteration may return an unpaginated list if that is the smallest working slice, and should order by event timestamp descending (newest first).
  - Pagination/infinite scroll is explicitly deferred, not half-implemented.
  
  ## New Capability
  
  Operators can inspect a single browser page showing detailed delivery records across messages, including problem reasons, instead of relying only on domain-level tests or message-scoped read models.
  
  ## Validation Plan
  
  - Run `npm test` from `acceptance-tests/` and confirm operator deliverability scenarios now run and pass through the browser acceptance harness.
  - Run PhoenixTest-based LiveView tests for the deliveries page/table.
  - Run the Elixir/domain acceptance path used by `dev check` and confirm it still runs the shared scenarios.
  - Run `dev check` and fix any failures.
  - Manual demo: start the Phoenix app, create a club with members, send at least two messages, POST Postmark-style delayed/bounced/spam/opened events, visit `/deliveries`, and see all delivery records in one table with statuses and reason text.
  
  ## Risks / Follow-ups
  
  - The unfiltered table is intentionally minimal; filtering, search, pagination, infinite scroll, and exports should be planned as later slices once the overview shape proves useful.
  - The existing projection may not contain message title/subject in the most convenient form for an all-deliveries view; keep any projection/query changes narrow and backward-compatible with existing domain behaviour.
  - Authentication and operator permissions remain deferred and must be addressed before exposing this surface in a real multi-user setting.
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/007-deliveries-overview/plan.md'
case "$PLAN_PATH" in
  */plan.md) iteration_dir=${PLAN_PATH%/plan.md} ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
iteration_slug=${iteration_dir##*/}
iteration_number=${iteration_slug%%-*}
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}
active=""
while IFS='|' read -r _ number date status title plan rest; do
  case "$plan" in *'[plan]'*) ;; *) continue ;; esac
  number=$(trim "$number")
  status=$(trim "$status")
  title=$(trim "$title")
  plan=$(trim "$plan")
  if [ "$number" != "$iteration_number" ]; then
    case "$status" in
      implementing|ready-for-review|in-review|reviewing|finalizing)
        active="${active}- ${number} ${title} (${status}) ${plan}\n"
        ;;
    esac
  fi
done < docs/iterations/README.md
if [ -n "$active" ]; then
  echo 'Implementation WIP limit is occupied by active iteration(s):' >&2
  printf '%b' "$active" >&2
  echo 'Plan validation may run in parallel, but starting another implementation is blocked until the active iteration is merged or otherwise resolved.' >&2
  exit 1
fi
echo 'Implementation WIP slot is clear.'`
- Output:
  ```
  Implementation WIP slot is clear.
  ```

## Stage: preflight_sandbox
- Status: succeeded
- Handler: command
- Script: `set -eu
if [ ! -x bin/dev ]; then
  echo "Missing or non-executable bin/dev" >&2
  exit 1
fi
rm -rf .fabro/tmp
PATH="$PWD/bin:$PATH" dev sandbox-check`
- Output:
  ```
  (214 lines omitted)
  ==> commanded_eventstore_adapter
  Compiling 2 files (.ex)
  Generated commanded_eventstore_adapter app
  ==> commanded_ecto_projections
  Compiling 1 file (.ex)
  Generated commanded_ecto_projections app
  ==> tailwind
  Compiling 3 files (.ex)
  Generated tailwind app
  ==> elixir_make
  Compiling 8 files (.ex)
  Generated elixir_make app
  ==> cc_precompiler
  Compiling 3 files (.ex)
  Generated cc_precompiler app
  ==> lazy_html
  Downloading precompiled NIF to /tmp/cache/elixir_make/lazy_html-nif-2.16-x86_64-linux-gnu-0.1.11.tar.gz
  Compiling 3 files (.ex)
  Generated lazy_html app
  ==> websock
  Compiling 1 file (.ex)
  Generated websock app
  ==> bandit
  Compiling 54 files (.ex)
  Generated bandit app
  ==> swoosh
  Compiling 59 files (.ex)
  Generated swoosh app
  ==> websock_adapter
  Compiling 4 files (.ex)
  Generated websock_adapter app
  ==> phoenix
  Compiling 74 files (.ex)
  Generated phoenix app
  ==> phoenix_live_view
  Compiling 49 files (.ex)
  Generated phoenix_live_view app
  ==> phoenix_live_dashboard
  Compiling 36 files (.ex)
  Generated phoenix_live_dashboard app
  ==> phoenix_test
  Compiling 31 files (.ex)
  Generated phoenix_test app
  ==> phoenix_ecto
  Compiling 7 files (.ex)
  Generated phoenix_ecto app
  Sandbox runtime check passed.
  • Validating lock
  ✓ Validating lock in 24.1ms
  Manager did not shut down within 30 seconds, sending SIGKILL
  ```

## Stage: resume_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/007-deliveries-overview/plan.md'
case "$PLAN_PATH" in
  */plan.md) ITERATION_DIR=${PLAN_PATH%/plan.md} ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
TODO_PATH="$ITERATION_DIR/todo.md"
echo '=== Iteration resume gate ==='
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  printf 'HEAD: ' && git log -1 --format='%h %s'
else
  echo 'HEAD: unavailable'
fi
if [ -f "$TODO_PATH" ]; then
  checked=$(grep -E '^[[:space:]]*- \[x\] ' "$TODO_PATH" | wc -l | tr -d ' ')
  unchecked=$(grep -E '^[[:space:]]*- \[ \] ' "$TODO_PATH" | wc -l | tr -d ' ')
  printf 'Todo: %s (%s checked, %s unchecked)\n' "$TODO_PATH" "${checked:-0}" "${unchecked:-0}"
else
  printf 'Todo: %s is absent; sync_task_list will create it from plan.md.\n' "$TODO_PATH"
fi
status=$(git status --short)
if [ -n "$status" ]; then
  echo 'Uncommitted changes present:'
  printf '%s\n' "$status"
  echo 'Refusing to resume with a dirty working tree. Commit, stash, or run git reset --hard HEAD (and clean untracked files if appropriate), then rerun iteration-implementation.' >&2
  exit 1
fi
echo 'Working tree clean; safe to resume from durable Fabro checkpoint commits.'`
- Output:
  ```
  === Iteration resume gate ===
  HEAD: 511bdd1 fabro(01KSY8MQXVG1X7C57PEYPXJX5N): preflight_sandbox (succeeded)
  Todo: docs/iterations/007-deliveries-overview/todo.md is absent; sync_task_list will create it from plan.md.
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/007-deliveries-overview/plan.md'
case "$PLAN_PATH" in
  */plan.md) ITERATION_DIR=${PLAN_PATH%/plan.md} ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
TODO_PATH="$ITERATION_DIR/todo.md"
mkdir -p .fabro/tmp
# Resume contract: once todo.md exists, it is the execution-state source of truth.
# Preserve existing check-offs, splits, and reorderings across runs. Regenerate
# from plan.md only when todo.md is absent.
if [ ! -f "$TODO_PATH" ]; then
  tmp=.fabro/tmp/generated-todo.md
  {
    printf '# Implementation TODO\n\n'
    in_plan=0
    count=0
    while IFS= read -r line; do
      case "$line" in
        '## Implementation Plan') in_plan=1; continue ;;
        '## '*) if [ "$in_plan" -eq 1 ]; then break; fi ;;
      esac
      if [ "$in_plan" -eq 1 ]; then
        case "$line" in
          [0-9]*'. '*)
            count=$((count + 1))
            task=${line#*. }
            printf -- '- [ ] %03d %s\n' "$count" "$task"
            ;;
        esac
      fi
    done < "$PLAN_PATH"
    if [ "${count:-0}" -eq 0 ]; then
      echo "No numbered tasks found under ## Implementation Plan in $PLAN_PATH" >&2
      exit 1
    fi
  } > "$tmp"
  mkdir -p "$ITERATION_DIR"
  mv "$tmp" "$TODO_PATH"
  echo "Created $TODO_PATH from $PLAN_PATH"
else
  echo "Using existing $TODO_PATH; preserving existing check-offs, splits, and ordering."
fi
printf 'PLAN_PATH=%s\nTODO_PATH=%s\n' "$PLAN_PATH" "$TODO_PATH"
sed -n '1,120p' "$TODO_PATH"`
- Output:
  ```
  Created docs/iterations/007-deliveries-overview/todo.md from docs/iterations/007-deliveries-overview/plan.md
  PLAN_PATH=docs/iterations/007-deliveries-overview/plan.md
  TODO_PATH=docs/iterations/007-deliveries-overview/todo.md
  # Implementation TODO
  
  - [ ] 001 Update the operator feature language around the rule "Operators monitor detailed delivery records across messages", keeping scenarios BRIEF and focused on cross-message visibility, reason preservation, and opened status.
  - [ ] 002 Write failing PhoenixTest coverage for `/deliveries`, including records from more than one message and problem reason text.
  - [ ] 003 Reshape the public Messaging operator-deliverability query toward a deliveries-overview API, for example an options-shaped list function. Preserve any existing message-scoped needs through options or a compatibility wrapper only if still required by current code.
  - [ ] 004 Add the `/deliveries` LiveView route under the browser pipeline.
  - [ ] 005 Build the deliveries LiveView as a simple read-only table with stable accessible labels or IDs for browser acceptance.
  - [ ] 006 Update browser Cucumber step definitions for `operator_email_deliverability.feature` so operator assertions inspect `/deliveries`.
  - [ ] 007 Remove `@todo-web` tags from operator scenarios once they are browser-backed.
  - [ ] 008 Verify browser Cucumber still defaults to excluding `@todo-web`, while now including the operator scenarios because they are no longer tagged.
  - [ ] 009 Run the browser acceptance suite and `dev check`, fixing any issues.
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 3.8k in / 173 out
- Response:
  > {"cmd": "sed -n '1,160p' docs/iterations/007-deliveries-overview/todo.md"}{"context_updates":{"task_list_complete":false,"task_list_needs_human":false}}

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 649.4k in / 13.9k out
- Response:
  > 1. **Selected todo line**
  >    - `002 Write failing PhoenixTest coverage for /deliveries, including records from more than one message and problem reason text.`
  > 
  > 2. **Changes made**
  >    - Added `web/test/memba_web/live/deliveries_live_test.exs`.
  >    - The new PhoenixTest:
  >      - Seeds two projected messages.
  >      - Reports one delayed delivery and one bounced delivery.
  >      - Visits `/deliveries`.
  >      - Expects a deliveries overview/table.
  >      - Asserts stable `data-test-id="delivery-row-<delivery_id>"` rows include:
  >        - message subject
  >        - recipient name
  >        - recipient email
  >        - channel
  >        - detailed status
  >        - provider/problem reason text
  >    - Did not edit any `*.feature` files.
  > 
  > 3. **Focused validation**
  >    - Formatting:
  >      - `cd web && mix format --check-formatted test/memba_web/live/deliveries_live_test.exs`
  >      - Result: passed.
  >    - Focused PhoenixTest:
  >      - Ran the new test file inside `devenv` with Postgres.
  >      - Result: expected red test:
  >        - `1 test, 1 failure`
  >        - Failure: `"/deliveries" path doesn't exist`
  >    - Required gate:
  >      - `PATH="$PWD/bin:$PATH" dev check`
  >      - Result: expected failure from the same new red test:
  >        - `110 tests, 1 failure`
  >        - Failure: `"/deliveries" path doesn't exist`
  >      - I did not fix this by adding the route/LiveView because those are later todo tasks `004` and `005`.
  > 
  > 4. **Todo check-off made**
  >    - Changed exactly:
  >      - `- [ ] 002 Write failing PhoenixTest coverage for /deliveries...`
  >    - To:
  >      - `- [x] 002 Write failing PhoenixTest coverage for /deliveries...`
  > 
  > 5. **Todo splits/additions/reordering**
  >    - None.
  > 
  > 6. **ADR conformance evidence**
  >    - ADR 0004: Test setup uses the existing one-message-aggregate-per-message flow by dispatching `SendMessage` commands for two messages.
  >    - ADR 0006: Assertions require operator-facing detailed delivery statuses and provider/channel reason text.
  >    - ADR 0009: Test exercises projected read-model behaviour through the existing Commanded/Ecto projection path with strong consistency.
  >    - ADR 0013: Uses PhoenixTest through `MembaWeb.FeatureCase` for feature-style web coverage.

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/007-deliveries-overview/plan.md'
case "$PLAN_PATH" in
  */plan.md) ITERATION_DIR=${PLAN_PATH%/plan.md} ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
TODO_PATH="$ITERATION_DIR/todo.md"
SNAPSHOT=/tmp/fabro-pre-validate-snapshot.md
{
  echo '# Pre-validation repository snapshot'
  echo
  echo 'Validation-time contract: Fabro checkpoints after every node. The just-completed task may appear either as uncommitted working-tree changes or as the latest/recent Fabro checkpoint commit on HEAD.'
  echo
  echo '## HEAD'
  git rev-parse --short HEAD || true
  git log -1 --format='%h %s' || true
  echo
  echo '## git status --short'
  git status --short || true
  echo
  echo '## git diff --stat'
  git diff --stat || true
  echo
  echo "## Working-tree diff for $TODO_PATH"
  if [ -f "$TODO_PATH" ]; then
    git diff -- "$TODO_PATH" || true
  else
    echo "Todo file missing: $TODO_PATH"
  fi
  echo
  echo '## git diff --name-only'
  git diff --name-only || true
  echo
  echo '## Untracked files'
  git ls-files --others --exclude-standard || true
  echo
  echo '## Combined changed path list from git status --porcelain'
  git status --porcelain || true
} > "$SNAPSHOT"
echo "Wrote $SNAPSHOT"
sed -n '1,220p' "$SNAPSHOT"`
- Output:
  ```
  Wrote /tmp/fabro-pre-validate-snapshot.md
  # Pre-validation repository snapshot
  
  Validation-time contract: Fabro checkpoints after every node. The just-completed task may appear either as uncommitted working-tree changes or as the latest/recent Fabro checkpoint commit on HEAD.
  
  ## HEAD
  6a4379a
  6a4379a fabro(01KSY8MQXVG1X7C57PEYPXJX5N): implement_next_task (succeeded)
  
  ## git status --short
  ?? .fabro/tmp/
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/007-deliveries-overview/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  .fabro/tmp/discarded-attempts/20260531T054814Z-a945549/staged.diff
  .fabro/tmp/discarded-attempts/20260531T054814Z-a945549/status-short.txt
  .fabro/tmp/discarded-attempts/20260531T054814Z-a945549/working-tree.diff
  
  ## Combined changed path list from git status --porcelain
  ?? .fabro/tmp/
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 114.6k in / 4.4k out
- Response:
  > ### Decision
  > **RETRY**
  > 
  > ### Evidence
  > - Completed todo/check-off evidence found:
  >   - `docs/iterations/007-deliveries-overview/todo.md` has task `001` checked.
  >   - Recent checkpoint `1a18a8a fabro(...): implement_next_task` changed exactly one ordinary todo line from `- [ ] 001` to `- [x] 001`.
  >   - Task `001` was the first unchecked task from the generated todo list.
  > - Implementation artifacts found:
  >   - Live working tree is clean.
  >   - `git show --name-only 1a18a8a` shows the implement checkpoint changed only `docs/iterations/007-deliveries-overview/todo.md`.
  >   - `acceptance-tests/features/operator_email_deliverability.feature` currently contains deliveries-overview language, but repository history shows that content pre-existed this task; the just-completed checkpoint did not add or update it.
  >   - No concrete code/config/test/documentation artifact was changed for the task beyond the todo check-off.
  > - Tests run/results found:
  >   - The implementation summary reports Cucumber dry-run and `dev check` passed, but the repository evidence for the completed task is still todo-only.
  > - ADR/plan conformance notes:
  >   - No acceptance `*.feature` files were edited, satisfying that validation constraint.
  >   - The current feature language appears consistent with ADR 0004, ADR 0006, ADR 0009, and ADR 0010.
  >   - However, the validation contract explicitly rejects todo-only completion evidence.
  > 
  > ### Retry brief
  > Rejected because live repository evidence shows the just-completed task checkpoint only checked off `todo.md`; there was no concrete code/config/test/documentation change tied to task 001. On the next clean attempt, do not mark the task complete with a todo-only change. Either produce a legitimate plan-conforming evidence artifact for the feature-language verification/update while still avoiding `*.feature` edits, or report the task as blocked/no-op due the feature language already being present and the feature-file edit prohibition.
  > 
  > {"context_updates":{"task_valid":false,"task_retry_available":true}}

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: reset_task_attempt
- Status: succeeded
- Handler: command
- Script: `set -eu
attempt_dir=.fabro/tmp/discarded-attempts/$(date -u +%Y%m%dT%H%M%SZ)-$(git rev-parse --short HEAD)
mkdir -p "$attempt_dir/files"
echo "Snapshotting failed task attempt before reset: $attempt_dir"
git status --short > "$attempt_dir/status-short.txt" || true
git diff > "$attempt_dir/working-tree.diff" || true
git diff --cached > "$attempt_dir/staged.diff" || true
git status --short
git ls-files --modified --others --exclude-standard | grep -v '^.fabro/tmp/' | while IFS= read -r path; do
  if [ -f "$path" ]; then
    mkdir -p "$attempt_dir/files/$(dirname "$path")"
    cp "$path" "$attempt_dir/files/$path"
  fi
done
echo "Discarding failed task attempt and resetting to last successful checkpoint: $(git rev-parse --short HEAD)"
git reset --hard HEAD
git clean -fd -e .fabro/tmp/ -e web/deps/ -e web/_build/ -e node_modules/ -e acceptance-tests/node_modules/ -e .devenv/ -e .direnv/
echo "Discarded attempt snapshot preserved at $attempt_dir"
git status --short`
- Output:
  ```
  Snapshotting failed task attempt before reset: .fabro/tmp/discarded-attempts/20260531T054814Z-a945549
  ?? .fabro/tmp/
  Discarding failed task attempt and resetting to last successful checkpoint: a945549
  HEAD is now at a945549 fabro(01KSY8MQXVG1X7C57PEYPXJX5N): task_gate (succeeded)
  Discarded attempt snapshot preserved at .fabro/tmp/discarded-attempts/20260531T054814Z-a945549
  ?? .fabro/tmp/
  ```

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 649.4k in / 13.9k out
- Response:
  > 1. **Selected todo line**
  >    - `002 Write failing PhoenixTest coverage for /deliveries, including records from more than one message and problem reason text.`
  > 
  > 2. **Changes made**
  >    - Added `web/test/memba_web/live/deliveries_live_test.exs`.
  >    - The new PhoenixTest:
  >      - Seeds two projected messages.
  >      - Reports one delayed delivery and one bounced delivery.
  >      - Visits `/deliveries`.
  >      - Expects a deliveries overview/table.
  >      - Asserts stable `data-test-id="delivery-row-<delivery_id>"` rows include:
  >        - message subject
  >        - recipient name
  >        - recipient email
  >        - channel
  >        - detailed status
  >        - provider/problem reason text
  >    - Did not edit any `*.feature` files.
  > 
  > 3. **Focused validation**
  >    - Formatting:
  >      - `cd web && mix format --check-formatted test/memba_web/live/deliveries_live_test.exs`
  >      - Result: passed.
  >    - Focused PhoenixTest:
  >      - Ran the new test file inside `devenv` with Postgres.
  >      - Result: expected red test:
  >        - `1 test, 1 failure`
  >        - Failure: `"/deliveries" path doesn't exist`
  >    - Required gate:
  >      - `PATH="$PWD/bin:$PATH" dev check`
  >      - Result: expected failure from the same new red test:
  >        - `110 tests, 1 failure`
  >        - Failure: `"/deliveries" path doesn't exist`
  >      - I did not fix this by adding the route/LiveView because those are later todo tasks `004` and `005`.
  > 
  > 4. **Todo check-off made**
  >    - Changed exactly:
  >      - `- [ ] 002 Write failing PhoenixTest coverage for /deliveries...`
  >    - To:
  >      - `- [x] 002 Write failing PhoenixTest coverage for /deliveries...`
  > 
  > 5. **Todo splits/additions/reordering**
  >    - None.
  > 
  > 6. **ADR conformance evidence**
  >    - ADR 0004: Test setup uses the existing one-message-aggregate-per-message flow by dispatching `SendMessage` commands for two messages.
  >    - ADR 0006: Assertions require operator-facing detailed delivery statuses and provider/channel reason text.
  >    - ADR 0009: Test exercises projected read-model behaviour through the existing Commanded/Ecto projection path with strong consistency.
  >    - ADR 0013: Uses PhoenixTest through `MembaWeb.FeatureCase` for feature-style web coverage.

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/007-deliveries-overview/plan.md'
case "$PLAN_PATH" in
  */plan.md) ITERATION_DIR=${PLAN_PATH%/plan.md} ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
TODO_PATH="$ITERATION_DIR/todo.md"
SNAPSHOT=/tmp/fabro-pre-validate-snapshot.md
{
  echo '# Pre-validation repository snapshot'
  echo
  echo 'Validation-time contract: Fabro checkpoints after every node. The just-completed task may appear either as uncommitted working-tree changes or as the latest/recent Fabro checkpoint commit on HEAD.'
  echo
  echo '## HEAD'
  git rev-parse --short HEAD || true
  git log -1 --format='%h %s' || true
  echo
  echo '## git status --short'
  git status --short || true
  echo
  echo '## git diff --stat'
  git diff --stat || true
  echo
  echo "## Working-tree diff for $TODO_PATH"
  if [ -f "$TODO_PATH" ]; then
    git diff -- "$TODO_PATH" || true
  else
    echo "Todo file missing: $TODO_PATH"
  fi
  echo
  echo '## git diff --name-only'
  git diff --name-only || true
  echo
  echo '## Untracked files'
  git ls-files --others --exclude-standard || true
  echo
  echo '## Combined changed path list from git status --porcelain'
  git status --porcelain || true
} > "$SNAPSHOT"
echo "Wrote $SNAPSHOT"
sed -n '1,220p' "$SNAPSHOT"`
- Output:
  ```
  Wrote /tmp/fabro-pre-validate-snapshot.md
  # Pre-validation repository snapshot
  
  Validation-time contract: Fabro checkpoints after every node. The just-completed task may appear either as uncommitted working-tree changes or as the latest/recent Fabro checkpoint commit on HEAD.
  
  ## HEAD
  6a4379a
  6a4379a fabro(01KSY8MQXVG1X7C57PEYPXJX5N): implement_next_task (succeeded)
  
  ## git status --short
  ?? .fabro/tmp/
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/007-deliveries-overview/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  .fabro/tmp/discarded-attempts/20260531T054814Z-a945549/staged.diff
  .fabro/tmp/discarded-attempts/20260531T054814Z-a945549/status-short.txt
  .fabro/tmp/discarded-attempts/20260531T054814Z-a945549/working-tree.diff
  
  ## Combined changed path list from git status --porcelain
  ?? .fabro/tmp/
  ```

## Current context
| Key | Value |
|-----|-------|
| task_list_complete | false |
| task_list_needs_human | false |
| task_retry_available | true |
| task_valid | false |


Validate the just-completed iteration task for `docs/iterations/007-deliveries-overview/plan.md`.

You have tool access. Use it. Decide from live repository state, not from summarized context alone. Read `/tmp/fabro-pre-validate-snapshot.md`, run `git status --short`, inspect `git diff`, inspect recent commits with `git log --oneline -5`, and read changed files as needed.

Important workflow contract: Fabro checkpoints after every node. Therefore, at validation time the just-completed task may appear either as uncommitted working-tree changes or as the latest/recent Fabro checkpoint commit on HEAD. A clean working tree is not, by itself, a failure.

Validate the task evidence, not a single storage mechanism. Prefer live working-tree diff/status when present; when the working tree is clean, corroborate the task using recent checkpoint commits and their diffs. Do not infer infrastructure faults unless live repository evidence proves the expected files or diffs are genuinely absent.

Do not rely on a selected-task temp file. Instead inspect the plan, `todo.md`, relevant ADRs, current repository diff/status, recent checkpoint diffs, test evidence, and the preceding implementation summary. Identify the completed task by the `todo.md` diff from the working tree or latest/recent checkpoint: exactly one ordinary task line should have changed from unchecked (`- [ ]`) to checked (`- [x]`) unless there is a clear plan-preserving split/reorder rationale.

## Validate

Accept the task only if all are true:

- The checked-off task is the first unchecked task that existed when the implementor started, or a clearly justified first slice after a plan-preserving split.
- The same task that was implemented has been checked off in `todo.md`.
- The task has concrete code/config/test/documentation evidence as appropriate; a todo-only change is invalid.
- The work stays within the approved plan and preserves plan-required scope.
- Any todo changes split/add/reorder only to satisfy the plan; no plan-required work was deleted, weakened, or silently deferred.
- Relevant automated tests were added/updated and focused tests were run, or a justified blocker was reported.
- Accepted ADR constraints relevant to this task are respected.
- No acceptance feature files (`*.feature`, including under `acceptance-tests/`) were edited.
- The task is small enough to stand independently with a useful Fabro checkpoint evidence trail.

If validation fails but the task is still clear and safe to attempt again, request a clean retry from the last successful checkpoint. Do not ask for in-place repair. Only request human input when the task, plan, or repository state is ambiguous, unsafe, repeatedly failing for the same non-transient reason, or blocked by a decision/tooling issue that another clean attempt is unlikely to solve.

## Output format

Return concise Markdown with:

### Decision
One of: **VALID**, **RETRY**, or **HUMAN_INPUT**

### Evidence
- Completed todo/check-off evidence found.
- Implementation artifacts found.
- Tests run/results found.
- ADR/plan conformance notes.

### Retry brief
Only if RETRY: exact reason the attempt was rejected from live repository evidence, plus concise guidance for the next clean attempt. The workflow will snapshot the failed working tree before resetting and trying again.

### Human input
Only if HUMAN_INPUT: exact blocker/question.

End your response with exactly one JSON object for Fabro routing, not in a code fence:

- Valid:
  {"context_updates":{"task_valid":true,"task_retry_available":false}}
- Clean retry needed:
  {"context_updates":{"task_valid":false,"task_retry_available":true}}
- Human input required:
  {"context_updates":{"task_valid":false,"task_retry_available":false}}