Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01KVCWH9NWPSZ9YNM1X7JKREZQ
Pipeline progress: 9 of 33 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/035-obliterate-opened-delivery-status/plan.md'
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
  (62 lines omitted)
  
  ## Acceptance Criteria
  
  - No `opened`/`Opened` references remain in `lib/` **except** the documented ignore-on-replay shim (event module + no-op aggregate clause + minimal no-op projector clauses), each commented as retained-for-replay-only.
  - `ReportEmailDeliveryOpened`, the read-model `"opened"` normalization, the `"opened" -> "delivered"` presentation mapping, and the webhook `"opened"` rejection branch are gone.
  - No member or staff delivery surface (dashboard, message detail, staff diagnostics/deliveries) references an "opened" status or count.
  - A regression test persists/replays a historic `EmailDeliveryOpened` event and asserts projections and read models are unaffected and the rebuild succeeds.
  - All remaining tests no longer assert behaviour for the "opened" status; the acceptance JS step/support files no longer reference it.
  - `dev check` passes.
  
  ## Open Business Decisions
  
  None known. "Opened" is already not a tracked product status; this is cleanup.
  
  ## Implementation Plan
  
  1. Inventory every `opened`/`Opened` reference in `lib/`, `test/`, and `acceptance-tests/` (baseline grep) and classify each as remove vs retain-as-shim.
  2. Delete the `ReportEmailDeliveryOpened` command and any dispatch routing/registration for it.
  3. Remove the `"opened"` read-model normalization clauses in `messaging.ex`, the presentation `"opened" -> "delivered"` mapping, and the webhook `"opened"` rejection branch.
  4. Reduce the aggregate `apply/2` for `EmailDeliveryOpened` to a documented no-op; reduce the two projectors to documented no-op handling only where replay would otherwise fail, removing all active behaviour.
  5. Keep `events/email_delivery_opened.ex` as the deserialization tombstone with a deprecation comment.
  6. Update/remove `"opened"` assertions and fixtures across the affected ExUnit suites and acceptance JS step/support files.
  7. Add the historic-event replay-safety regression test.
  8. Re-run the baseline grep to confirm only the documented shim remains.
  9. Run `dev check`.
  
  ## Open Technical Decisions
  
  - Exact shape of replay safety in the Commanded projectors: whether each projector needs an explicit no-op `project` clause for `EmailDeliveryOpened` or whether the existing subscription/skip behaviour already tolerates an unhandled historic event. Decide per projector by exercising a rebuild in the regression test; keep the minimal clause that makes replay green.
  - Whether the aggregate's `EmailDeliveryOpened` alias can be dropped or must remain for the no-op clause to reference the struct.
  
  These are implementation details and should not need product decisions.
  
  ## New Capability
  
  Contributors, the design system, and the dev seeds/gallery have a single, consistent source of truth: Memba does not track an "opened" delivery status. The codebase no longer carries a misleading half-removed status, and projection rebuilds remain safe against historic events.
  
  ## Validation Plan
  
  - ExUnit suites updated to drop "opened" assertions, all green.
  - New regression test: a persisted historic `EmailDeliveryOpened` event replays/rebuilds without affecting member/staff projections or read models.
  - Baseline-vs-final grep showing no `opened`/`Opened` in `lib/` outside the documented shim, and none in `test/`/`acceptance-tests/` outside intentional shim coverage.
  - Full `dev check` before delivery is complete.
  
  ## Risks / Follow-ups
  
  - **Replay safety is the main risk.** If a projector cannot tolerate the historic event without an explicit clause, the no-op clause must stay; the regression test must actually exercise a rebuild, not just a forward dispatch, to prove it.
  - The shim is a deliberate tombstone, not dead code to be "cleaned up" later by a well-meaning contributor — comments must make its purpose explicit so it is not removed and break replays.
  - If, during inventory, the production event store can be confirmed to contain zero `EmailDeliveryOpened` events, a future iteration could drop the shim entirely; record that as a follow-up rather than widening this slice.
  - This plan can be validated now but cannot deliver until iteration 034 vacates the single implementation WIP slot.
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/035-obliterate-opened-delivery-status/plan.md'
PATH="$PWD/bin:$PATH" dev iteration check-predecessors "$PLAN_PATH"
PATH="$PWD/bin:$PATH" dev iteration check-clear "$PLAN_PATH" --allow-same-iteration`
- Output:
  ```
  (6 lines omitted)
  ✓ Evaluating shell in 1.18ms (cached)
  ✓ Configuring shell in 8.77ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 387µs (cached)
  ✓ Loading tasks in 1.43ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 11.3ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.2ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 102µs (no command)
  ✓ Running tasks in 23.8ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:1] [ds:8:1:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  • Validating lock
  ✓ Validating lock in 20.2ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 1.80ms
  • Evaluating shell
  ✓ Evaluating shell in 1.08ms (cached)
  ✓ Configuring shell in 7.11ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 324µs (cached)
  ✓ Loading tasks in 2.36ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.2ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 13.2ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 1.94µs (no command)
  ✓ Running tasks in 24.5ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:1] [ds:8:1:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Implementation WIP slot is clear.
  ```

## Stage: preflight_sandbox
- Status: succeeded
- Handler: command
- Script: `set -eu
for tool in nix python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required bare sandbox tool: $tool" >&2
    echo "The iteration workflow uses $tool before or outside bin/dev's devenv shell. Rebuild the Fabro sandbox image with this tool on the default PATH." >&2
    exit 1
  fi
done
if [ ! -x bin/dev ]; then
  echo "Missing or non-executable bin/dev" >&2
  exit 1
fi
rm -rf .fabro/tmp
PATH="$PWD/bin:$PATH" dev sandbox-check`
- Output:
  ```
  (266 lines omitted)
  ==> commanded
  Compiling 69 files (.ex)
  Generated commanded app
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
  ```

## Stage: resume_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/035-obliterate-opened-delivery-status/plan.md'
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
  HEAD: 54e6aea fabro(01KVCWH9NWPSZ9YNM1X7JKREZQ): preflight_sandbox (succeeded)
  Todo: docs/iterations/035-obliterate-opened-delivery-status/todo.md is absent; sync_task_list will create it from plan.md.
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/035-obliterate-opened-delivery-status/plan.md'
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
  Created docs/iterations/035-obliterate-opened-delivery-status/todo.md from docs/iterations/035-obliterate-opened-delivery-status/plan.md
  PLAN_PATH=docs/iterations/035-obliterate-opened-delivery-status/plan.md
  TODO_PATH=docs/iterations/035-obliterate-opened-delivery-status/todo.md
  # Implementation TODO
  
  - [ ] 001 Inventory every `opened`/`Opened` reference in `lib/`, `test/`, and `acceptance-tests/` (baseline grep) and classify each as remove vs retain-as-shim.
  - [ ] 002 Delete the `ReportEmailDeliveryOpened` command and any dispatch routing/registration for it.
  - [ ] 003 Remove the `"opened"` read-model normalization clauses in `messaging.ex`, the presentation `"opened" -> "delivered"` mapping, and the webhook `"opened"` rejection branch.
  - [ ] 004 Reduce the aggregate `apply/2` for `EmailDeliveryOpened` to a documented no-op; reduce the two projectors to documented no-op handling only where replay would otherwise fail, removing all active behaviour.
  - [ ] 005 Keep `events/email_delivery_opened.ex` as the deserialization tombstone with a deprecation comment.
  - [ ] 006 Update/remove `"opened"` assertions and fixtures across the affected ExUnit suites and acceptance JS step/support files.
  - [ ] 007 Add the historic-event replay-safety regression test.
  - [ ] 008 Re-run the baseline grep to confirm only the documented shim remains.
  - [ ] 009 Run `dev check`.
  ```

## Stage: todo_readable
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/035-obliterate-opened-delivery-status/plan.md'
case "$PLAN_PATH" in
  */plan.md) TODO_PATH=${PLAN_PATH%/plan.md}/todo.md ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
if [ ! -r "$TODO_PATH" ] || [ ! -s "$TODO_PATH" ]; then
  echo "BLOCKING: todo file missing, unreadable, or empty: $TODO_PATH" >&2
  exit 1
fi
echo "Todo file is present and readable: $TODO_PATH"`
- Output:
  ```
  Todo file is present and readable: docs/iterations/035-obliterate-opened-delivery-status/todo.md
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/035-obliterate-opened-delivery-status/plan.md'
TODO_PATH=${PLAN_PATH%/plan.md}/todo.md
if grep -Eq '^[[:space:]]*- \[ \] ' "$TODO_PATH"; then
  echo "UNCHECKED tasks remain in $TODO_PATH"
  grep -En '^[[:space:]]*- \[ \] ' "$TODO_PATH" | head -20
  exit 0
fi
echo "COMPLETE: no unchecked tasks remain in $TODO_PATH"
exit 1`
- Output:
  ```
  UNCHECKED tasks remain in docs/iterations/035-obliterate-opened-delivery-status/todo.md
  3:- [ ] 001 Inventory every `opened`/`Opened` reference in `lib/`, `test/`, and `acceptance-tests/` (baseline grep) and classify each as remove vs retain-as-shim.
  4:- [ ] 002 Delete the `ReportEmailDeliveryOpened` command and any dispatch routing/registration for it.
  5:- [ ] 003 Remove the `"opened"` read-model normalization clauses in `messaging.ex`, the presentation `"opened" -> "delivered"` mapping, and the webhook `"opened"` rejection branch.
  6:- [ ] 004 Reduce the aggregate `apply/2` for `EmailDeliveryOpened` to a documented no-op; reduce the two projectors to documented no-op handling only where replay would otherwise fail, removing all active behaviour.
  7:- [ ] 005 Keep `events/email_delivery_opened.ex` as the deserialization tombstone with a deprecation comment.
  8:- [ ] 006 Update/remove `"opened"` assertions and fixtures across the affected ExUnit suites and acceptance JS step/support files.
  9:- [ ] 007 Add the historic-event replay-safety regression test.
  10:- [ ] 008 Re-run the baseline grep to confirm only the documented shim remains.
  11:- [ ] 009 Run `dev check`.
  ```

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 166.0k in / 7.5k out
- Response:
  > 1. **Selected todo line**
  >    - `001 Inventory every opened/Opened reference in lib/, test/, and acceptance-tests/ (baseline grep) and classify each as remove vs retain-as-shim.`
  > 
  > 2. **Changes made**
  >    - Added `docs/iterations/035-obliterate-opened-delivery-status/inventory.md`.
  >      - Captures the baseline grep command.
  >      - Notes that the app paths are `web/lib` and `web/test`.
  >      - Classifies all 111 clean baseline references as:
  >        - remove,
  >        - retain-as-shim / replay regression coverage,
  >        - or unrelated non-status wording.
  >    - Updated `docs/iterations/035-obliterate-opened-delivery-status/todo.md` to check off only task 001.
  > 
  > 3. **Focused validation run**
  >    - `git log --oneline --decorate -20` — inspected recent Fabro checkpoints.
  >    - `git status --short` — confirmed clean tree before editing.
  >    - `grep -RInE 'opened|Opened' web/lib web/test acceptance-tests --exclude-dir=deps --exclude-dir=node_modules || true` — produced clean baseline inventory.
  >    - `grep -RInE 'opened|Opened' web/lib web/test acceptance-tests --exclude-dir=deps --exclude-dir=node_modules | wc -l` — confirmed 111 baseline references.
  >    - `grep -E '^\| \`[^\`]+:[0-9]+\` ' docs/iterations/035-obliterate-opened-delivery-status/inventory.md | wc -l` — confirmed 111 classified inventory entries.
  >    - `git diff --check` — passed.
  > 
  >    I did **not** run `dev check` because this task was docs/inventory-only and made no code, config, migration, test, or app-behaviour changes.
  > 
  > 4. **Exact todo check-off made**
  >    - Changed:
  >      - `- [ ] 001 Inventory every ...`
  >    - To:
  >      - `- [x] 001 Inventory every ...`
  > 
  > 5. **Todo splits/additions/reordering**
  >    - None.
  > 
  > 6. **ADR conformance evidence**
  >    - The plan does not explicitly reference any ADRs.
  >    - `docs/adr/*` is absent/empty in this repo, so there were no accepted ADRs to apply for this docs-only inventory task.

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/035-obliterate-opened-delivery-status/plan.md'
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
  b5f45f2
  b5f45f2 fabro(01KVCWH9NWPSZ9YNM1X7JKREZQ): implement_next_task (succeeded)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/035-obliterate-opened-delivery-status/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```


Validate the just-completed iteration task for `docs/iterations/035-obliterate-opened-delivery-status/plan.md`.

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
- Acceptance feature files (`*.feature`, including under `acceptance-tests/`) were not edited unless the plan has a `## Allowed acceptance feature changes` section naming the exact file and allowed kind of change; any permitted edit stays within that explicit permission and preserves/validates the coverage promised by the plan.
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