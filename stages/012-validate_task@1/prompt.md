Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01M2DRQG6MC40SWT7ZFK58QT5W
Pipeline progress: 10 of 36 stages completed

## Stage: verify_source_head
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-implementation/scripts/verify_source_head.sh 'f1ab7c4101f66ab27db7e3953d9eb5818631ad4a'`
- Output:
  ```
  Expected source HEAD: f1ab7c4101f66ab27db7e3953d9eb5818631ad4a
  Actual source HEAD:   f1ab7c4101f66ab27db7e3953d9eb5818631ad4a
  Source directory:     /repos/mattwynne/memba
  Source checkout matches the expected implementation commit.
  ```

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/061-discover-club-groups/plan.md'
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
  (56 lines omitted)
  Reviewed local HTML accompanies these plans:
  
  - `design-system/templates/club-groups.html`: final rail and shared group frame.
  - `design-system/templates/club-group-non-member.html`: regular non-member and outside-admin views.
  - `design-system/explorations/custom-groups-prototype.html`: interactive final behaviour.
  
  Omit creation, membership mutation and Request access controls until their slices. Regular non-members see the group name and Admin contact, not member counts, group email, conversation previews/activity or member names. Outside admins can see membership metadata. These are the reviewed prototype's presentation choices, not new public-reading grants.
  
  Use `MemberDashboardGroupTabs.group_tabs/1` for the single active-tab action position; group headers contain metadata only. Reuse `Layouts.club_site`, `MemberComponents` rows and the current Canada/open-source footer. The local designs were browser-rendered; cloud DesignSync remains unsynchronised. Existing local sources are sufficient for implementation; do not invent a replacement design.
  
  ## Acceptance Criteria
  
  - All active club members see all current-club group names; visibility never widens to another club or signed-out visitors.
  - A regular non-member opening a group gets access guidance, not not-found, but receives no private rows even in initial render, LiveView diffs or direct data/action requests.
  - A club admin outside a custom group sees only its Members surface, with no conversation content, compose action or implicit email membership.
  - Direct conversation/detail/reply/follow/delivery routes still require actual effective conversation access.
  - Valid explicitly selected groups, including non-member placeholders, remain selected. A remembered existing same-club group opens its current permitted surface; missing/foreign selections fall back to Everyone. No membership or access is inferred from browser storage.
  - Existing system-group membership and last-Admin rules are unchanged.
  
  ## Open Business Decisions
  
  None known. Matt approved the email-only placeholder until 065 and the prototype's access distinctions.
  
  ## Implementation Plan
  
  1. Separate discovery from participation in the Membership public query API. Add a club-scoped discovery summary for an authenticated active club member. Preserve `list_active_groups_for_member/2` as the actual-membership API: Messaging uses it for access, so broadening it would expose conversations.
  2. Update `MemberDashboardPresentation` to resolve group identity within the authorised club, then load only the permitted surface. Explicitly distinguish ordinary non-member, outside admin and participating member. Do not fetch private message/member rows and merely hide them in HEEx.
  3. Extend the existing stateless tabs/frame/list composition in `page_html/club.html.heex` and `member_dashboard_group_tabs.ex`. Keep one contextual action slot, correct tab/panel ARIA and keyboard behaviour. Do not restore the removed single-member promotional blank slate.
  4. Preserve selected-group routing and remembered selection through `MemberDashboardLive` and its existing browser hook. Refresh discovery/access state on relevant read-model changes; reject direct actions after access loss. Keep conversation access in public Membership/Messaging APIs, not projection joins in the web layer.
  5. Implement the tagged domain/browser examples and focused presentation, component and routed LiveView regressions. Verify no disclosure on guessed URLs, cross-club IDs or stale browser state; run `dev check` on the exact delivered state.
  
  ## Open Technical Decisions
  
  None expected to block implementation. Use opaque existing group IDs and existing club-host/query routing helpers. Keep read-model changes and privacy decisions server-authoritative. No new aggregate or generic permission framework is needed.
  
  ## New Capability
  
  Members can find a group's name and know how to ask for access. Club admins can inspect who belongs without subscribing to conversations.
  
  ## Validation Plan
  
  - Parse shared Gherkin and confirm runner-debt exclusions while planning.
  - Test discovery separately from conversation access, including direct URLs and already-open LiveView updates.
  - Run both runners' new scenarios as their implementation lands and retain existing 058/system-group regressions. Update the historical 058 scenario-inventory assertion in `acceptance-tests/test/cucumber_config.test.js` to recognize scenarios evolving in later iterations without losing provenance or hiding runnable regressions.
  - Manually review Eve's email-only placeholder and Dan's Members-only view on desktop/mobile.
  - Run `dev check` for delivery and report its exact checked commit/state.
  
  ## Risks / Follow-ups
  
  The highest risk is reusing the new discovery list as a conversation access grant. Keep the existing active-membership query separate. Do not turn metadata visibility into access to conversation subject lines or member lists. Request access is intentionally absent until 065; membership actions arrive in 063–064. No problem-note status updates, app-wide error redesign or unrelated refactor belongs here.
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/061-discover-club-groups/plan.md'
PATH="$PWD/bin:$PATH" dev iteration check-predecessors "$PLAN_PATH"
PATH="$PWD/bin:$PATH" dev iteration check-clear "$PLAN_PATH" --allow-same-iteration`
- Output:
  ```
  (8 lines omitted)
  ✓ Configuring shell in 5.60ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 258µs (cached)
  ✓ Loading tasks in 1.92ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.4ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 10.7ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 23.3µs (no command)
  ✓ Running tasks in 21.8ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:2] [ds:8:2:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  Entering Memba devenv for root=/repos/mattwynne/memba sha=e330994.
  • Validating lock
  ✓ Validating lock in 19.0ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 2.15ms
  • Evaluating shell
  ✓ Evaluating shell in 212µs (cached)
  ✓ Configuring shell in 5.41ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 3.68µs (cached)
  ✓ Loading tasks in 1.14ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 12.2ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 10.7ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 78.6µs (no command)
  ✓ Running tasks in 23.3ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:2] [ds:8:2:10] [async-threads:1] [jit:ns]
  
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
  (385 lines omitted)
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
PLAN_PATH='docs/iterations/061-discover-club-groups/plan.md'
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
  HEAD: 807648a fabro(01M2DRQG6MC40SWT7ZFK58QT5W): preflight_sandbox (succeeded)
  Todo: docs/iterations/061-discover-club-groups/todo.md (8 checked, 3 unchecked)
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/061-discover-club-groups/plan.md'
case "$PLAN_PATH" in
  */plan.md) ITERATION_DIR=${PLAN_PATH%/plan.md} ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
TODO_PATH="$ITERATION_DIR/todo.md"
mkdir -p .fabro/tmp
python3 .fabro/workflows/iteration-implementation/scripts/sync_task_list.py "$PLAN_PATH" "$TODO_PATH"
printf 'PLAN_PATH=%s\nTODO_PATH=%s\n' "$PLAN_PATH" "$TODO_PATH"
sed -n '1,160p' "$TODO_PATH"`
- Output:
  ```
  Using existing docs/iterations/061-discover-club-groups/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/061-discover-club-groups/plan.md
  TODO_PATH=docs/iterations/061-discover-club-groups/todo.md
  # Implementation TODO
  
  - [x] 001 Separate discovery from participation in the Membership public query API.
  - [x] 002 Add a club-scoped discovery summary for an authenticated active club member.
  - [x] 003 Preserve `list_active_groups_for_member/2` as the actual-membership API: Messaging uses it for access, so broadening it would expose conversations.
  - [x] 004 Update `MemberDashboardPresentation` to resolve group identity within the authorised club, then load only the permitted surface.
  - [x] 005 Explicitly distinguish ordinary non-member, outside admin and participating member.
  - [x] 006 Extend the existing stateless tabs/frame/list composition in `page_html/club.html.heex` and `member_dashboard_group_tabs.ex`.
  - [x] 007 Keep one contextual action slot, correct tab/panel ARIA and keyboard behaviour.
  - [x] 008 Preserve selected-group routing and remembered selection through `MemberDashboardLive` and its existing browser hook.
  - [ ] 009 Refresh discovery/access state on relevant read-model changes; reject direct actions after access loss.
    - Recovery note: previous validation found this partial. Cover already-open MemberMessageLive.Show and MemberMessageDeliveryLive.Show after group membership/conversation-access revocation, and clear private group metadata on open compose screens after access loss, not only dashboard refresh and submit rejection.
  - [ ] 010 Keep conversation access in public Membership/Messaging APIs, not projection joins in the web layer.
  - [ ] 011 Implement the tagged domain/browser examples and focused presentation, component and routed LiveView regressions. Verify no disclosure on guessed URLs, cross-club IDs or stale browser state; run `dev check` on the exact delivered state.
  ```

## Stage: todo_readable
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/061-discover-club-groups/plan.md'
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
  Todo file is present and readable: docs/iterations/061-discover-club-groups/todo.md
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/061-discover-club-groups/plan.md'
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
  UNCHECKED tasks remain in docs/iterations/061-discover-club-groups/todo.md
  11:- [ ] 009 Refresh discovery/access state on relevant read-model changes; reject direct actions after access loss.
  13:- [ ] 010 Keep conversation access in public Membership/Messaging APIs, not projection joins in the web layer.
  14:- [ ] 011 Implement the tagged domain/browser examples and focused presentation, component and routed LiveView regressions. Verify no disclosure on guessed URLs, cross-club IDs or stale browser state; run `dev check` on the exact delivered state.
  ```

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > Implemented and checked off task 009. Already-open compose, conversation-detail, and delivery-detail LiveViews now stop exposing private data when membership or conversation access is revoked.
  > 
  > 1. Selected task
  > 
  > `009 Refresh discovery/access state on relevant read-model changes; reject direct actions after access loss.`
  > 
  > 2. Changes made
  > 
  > - [member_message_live/new.ex](/workspace/memba/web/lib/memba_web/live/member_message_live/new.ex:21)
  >   - Subscribes compose screens to committed group, group-membership, and club-membership projection changes.
  >   - Reloads the server-authoritative compose context after relevant changes and immediately before submission.
  >   - Clears private audience metadata and navigates to the selected group’s safe surface when access is lost.
  >   - Retains the existing final submission authorization check.
  > 
  > - [member_message_live/show.ex](/workspace/memba/web/lib/memba_web/live/member_message_live/show.ex:17)
  >   - Rechecks effective conversation access after current-member membership changes or matching conversation grant changes.
  >   - Navigates away from inaccessible conversation details while preserving selected-group context.
  > 
  > - [member_message_delivery_live/show.ex](/workspace/memba/web/lib/memba_web/live/member_message_delivery_live/show.ex:14)
  >   - Now subscribes to committed read-model changes.
  >   - Applies the same reauthorization and safe navigation behavior to delivery details.
  > 
  > - Added routed LiveView regressions covering:
  >   - Compose metadata after membership removal.
  >   - Compose submission during the notification race.
  >   - Open message detail after membership removal and conversation-access revocation.
  >   - Open delivery detail after both forms of revocation.
  > 
  > 3. Validation
  > 
  > - TDD red phase: the new focused regressions produced five expected missing-navigation failures before implementation.
  > - Focused LiveView suite:
  >   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_message_live/new_send_test.exs test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_message_live/show_reply_test.exs test/memba_web/live/member_message_delivery_live/show_test.exs test/memba_web/live/member_dashboard_live_test.exs`
  >   - Result: 97 tests, 0 failures.
  > - Formatting verification:
  >   - `devenv shell -- mix format --check-formatted ...`
  >   - Result: passed for every touched Elixir file.
  > - Broad quick gate:
  >   - `PATH="$PWD/bin:$PATH" dev check --quick`
  >   - Result: 1,277 tests, 0 failures.
  > - Targeted real-browser scenario:
  >   - `PATH="$PWD/bin:$PATH" dev acceptance --name '^Bob starts an Admin conversation in the web app$'`
  >   - Result: 1 scenario, 7 steps, all passed.
  > - `git diff --check`: passed.
  > 
  > The full `dev check` was not run in this per-task node because task 011 explicitly owns the final full delivery gate.
  > 
  > 4. Todo check-off
  > 
  > Changed only [todo.md](/workspace/memba/docs/iterations/061-discover-club-groups/todo.md:11):
  > 
  > `- [x] 009 Refresh discovery/access state on relevant read-model changes; reject direct actions after access loss.`
  > 
  > 5. Todo structure
  > 
  > No tasks were split, added, removed, or reordered. Tasks 010 and 011 remain unchecked.
  > 
  > 6. ADR conformance
  > 
  > - ADR 0015: behavior remains implemented through member-facing LiveViews.
  > - ADR 0021: refreshes are triggered by committed `ReadModelChanges` projection notifications.
  > - ADR 0007: authorization is reloaded through Membership and Messaging public APIs, including `MemberMessageDetail`; no cross-context projection joins were added to the web layer.
  > - ADR 0023: access-loss navigation preserves the selected group in the URL.
  > - ADRs 0022 and 0024 remain unaffected: no projection-barrier semantics or membership consistency boundaries were changed.

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/061-discover-club-groups/plan.md'
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
  b68ad4c
  b68ad4c fabro(01M2DRQG6MC40SWT7ZFK58QT5W): implement_next_task (succeeded)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/061-discover-club-groups/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```


Validate the just-completed iteration task for `docs/iterations/061-discover-club-groups/plan.md`.

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
- Ordinary browser-facing tasks have focused browser/component/JS/CSS evidence appropriate to the change; do not require a duplicate full `dev check` solely because the task changes UI, routing, or acceptance support. The deterministic final gate still must pass before publication. If this selected task explicitly requires a full final-validation run, require its successful exit evidence before accepting the check-off; passing scenario counts without a final exit status do not prove that gate passed.
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

Fabro final-output contract

The following contract is trusted workflow configuration. It applies only to your final response, not to intermediate tool calls.
Return a single JSON object with at least one routing field: preferred_next_label, outcome, failure_reason, suggested_next_ids, context_updates.
The contract is complete. Do not ask the user to provide or choose the output shape.