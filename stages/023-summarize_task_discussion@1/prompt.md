Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01M41R98D29R3GZC8SGJDKKF7B
Pipeline progress: 21 of 48 stages completed

## Stage: verify_source_head
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-implementation/scripts/verify_source_head.sh '4eb6228443ba65cab6222e74b36e1006adab730b'`
- Output:
  ```
  Expected source HEAD: 4eb6228443ba65cab6222e74b36e1006adab730b
  Actual source HEAD:   4eb6228443ba65cab6222e74b36e1006adab730b
  Source directory:     /repos/mattwynne/memba
  Source checkout matches the expected implementation commit.
  ```

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/067-live-projection-queries/plan.md'
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
  (72 lines omitted)
  ## Domain Vocabulary
  
  Reuse Club, club member, Person, group and conversation as in [the canonical lexicon](../../problem-domain-terms.md). “Live query”, “projection”, “view model”, “assign”, “invalidation” and “subscription” are solution-domain terms and are not added to the problem-domain lexicon. No vocabulary change proposed.
  
  ## Technical Model
  
  A view-specific query composes existing authorized read APIs, yielding one view model and a set of invalidation interests. Interests include collection scopes (to detect records entering/leaving a result) and identities of records actually represented. The binding layer holds the query, its current interests and one assign key inside the LiveView process, subscribes before the connected initial read, and refreshes only matching queries against committed projections. On each refresh it replaces the result and interests for that query; unrelated assigns and transient UI state remain untouched. A Memba adapter maps existing `ReadModelChanges` projector/event data to generic invalidation keys. A per-query migration matrix must list contributing projectors, event-to-interest mapping (including old and new scopes), fresh authorization sources and focused proof. For a valid published event that genuinely lacks an exact interest (for example, `MessageSent` has no audience group), use a documented conservative invalidation. Do not invent incomplete variants of known projector events to justify broad fallbacks. A known Membership notification with a club ID but no person ID recoverable from the event, committed changes or membership row violates the publisher contract: surface the violation, not a club-scoped or global Membership fallback. The same valid-event-versus-malformed-payload distinction applies to the other projector families; the migration matrix records which broader scopes are justified by actual current or legacy event shapes. Unsupported event types and missing required identities must not silently become new fallback cases. Multiple contributing projectors can commit separately; each must invalidate the query so later commits converge. The generic package cannot infer SQL predicates or user permissions. Loading must check fresh authorization both initially and on refresh; query access errors are handed back for the existing private-surface transition. No streams are part of this contract in 067.
  
  The package interface has three responsibilities: a query supplies a read callback returning either one view model plus interests or an access error; a source adapter subscribes the connected LiveView and converts a notification to invalidation keys; a binding installs the query under one assign, matches notifications against current interests, refreshes, and replaces the result plus interests. The adapter and query are passed in, never imported from Memba by the package. The LiveView owns navigation on an access error. The initial connected binding subscribes *before* reading, and a notification received across the first read/interest installation triggers conservative reconciliation. This is an interface contract, not a mandate for particular function names or a new OTP process.
  
  For club home, start with **one authorized dashboard query** returning a coherent view model under one assign (`selected_group`, member rows/count, conversations and access-dependent data together), replacing today's map of independently assigned values. The member-list portion records interests for the selected club's membership collection and the represented people. Do not split dashboard queries unless measured need justifies coordinating multiple results across route and access transitions. A membership added/removed in that club invalidates the collection even if the person was absent from the old result; a relevant Person update invalidates represented names and initials. When a query also depends on groups/roles, those projectors must contribute invalidation keys, even when they commit at different times. For conversation detail, the query loads permitted messages and author names; a change that withdraws access causes a fresh authorization failure, not a retained private result. Use a broader invalidation only for an evidenced valid event that cannot provide exact scope; surface a malformed known Membership notification as a contract violation instead of silently dropping it or refreshing unrelated queries.
  
  Implementation checkpoints before freezing the package API: specify the package query/binding API and Memba adapter, prove it first against a member list and a composed conversation detail query, verify connected mount and reconnection against Phoenix LiveView's actual lifecycle, inventory the member LiveViews with query/exception mappings and focused tests, and verify packaging/test integration against Docker and `bin/dev`. No stream adapter is required. Do not claim that a PubSub broadcast is a durable read-model changelog.
  
  ## Architecture Decisions
  
  Matt accepted [ADR 0027](../../adr/0027-use-live-projection-queries-for-liveview-reads.md), which extends ADR 0021 and sets the member LiveView live-query boundary.
  
  ## Implementation Plan
  
  1. Inventory club-member LiveViews and projection-backed reads, existing refresh predicates, fresh authorization sources and access transitions; record queries to migrate, event/interest mappings, focused test evidence and justified exceptions. Exclude staff streams explicitly.
  2. Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.
  3. Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports.
  4. Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use documented conservative invalidation only where a valid projector event cannot provide exact mapping; reject unsupported partial Membership scope visibly rather than adding fallback refreshes.
  5. Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.
  6. Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments.
  7. Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`.
  
  ## Open Technical Decisions
  
  Function names and the reconnect hook must be checked against the actual member LiveViews during implementation; the query/result/interest/source contract and the one-dashboard-view-model boundary are agreed. Streams are explicitly deferred. If a page cannot be adopted without changing a domain policy or its authorization semantics, stop and return that exception for decision rather than silently skipping it.
  
  ## New Capability
  
  A reusable, locally packaged live-query layer lets a LiveView bind one authorized, composable projection-backed view model to one assign and keep it current on relevant committed changes, without hand-writing separate event handling for each page.
  
  ## Validation Plan
  
  - Package unit tests: query binding and interest replacement, relevant/unrelated invalidations, rows entering/leaving collections, duplicate/out-of-order notifications, subscriber cleanup and relevant bind-time races.
  - Focused LiveView tests: Bob's already-open club Members page gains Alice after admission without navigation; existing conversation and delivery detail refreshes still work; member lists/counts/order update; delivered revocation invalidations use fresh authority and remove private data; query refresh leaves unrelated form assigns unchanged; remount/reconnect reconciles. At least one test runs from a committed projector through PubSub to an open page, not solely a synthetic notification.
  - Repository inventory/migration matrix: each in-scope club-member LiveView's projection-backed read either uses the live-query layer or has a documented exception, with scoped invalidations and focused regression evidence. Exercise actual projector event structs, distinguish evidenced valid missing scope from malformed known events, and prove that a Membership notification with a club ID but no recoverable person ID surfaces a contract violation without a fallback refresh. Verify that `MessageSent` with `sender_follows_conversation: false` does not invalidate the follow projection and replay-only `EmailDeliveryOpened` does not claim a new delivery status, while real club-wide or legacy-scope invalidations still work. Check every matrix fallback against the real projector paths; the package dependency graph cannot reference `Memba` or `Commanded`. Staff stream-backed pages are deferred.
  - Build/release proof: path dependency compiled and included in production release; package tests are part of `dev check`.
  - Final full `dev check` after implementation on the exact clean/staged state.
  
  ## Risks / Follow-ups
  
  - Member LiveView migration risks inconsistent authorization, extra database queries and invalidation over-broadcast; the migration matrix, focused tests and query-count checks should catch these.
  - A post-commit broadcast may be lost after a commit or while a process is unavailable; fresh reads/reconciliation mitigate but do not guarantee immediate durable delivery.
  - Staff streams remain outside 067; any future migration must resolve coherent query-result/stream-count replacement separately. Do not equate minimal HTML diffs with minimal database work.
  - Future name/photo iterations must express their query interests through this boundary rather than adding hand-written Person event handlers.
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/067-live-projection-queries/plan.md'
PATH="$PWD/bin:$PATH" dev iteration check-predecessors "$PLAN_PATH"
PATH="$PWD/bin:$PATH" dev iteration check-clear "$PLAN_PATH" --allow-same-iteration`
- Output:
  ```
  (8 lines omitted)
  ✓ Configuring shell in 6.75ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 5.10µs (cached)
  ✓ Loading tasks in 1.07ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.1ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 10.8ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 43.5µs (no command)
  ✓ Running tasks in 21.8ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:2] [ds:8:2:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  Entering Memba devenv for root=/repos/mattwynne/memba sha=ffbf97d.
  • Validating lock
  ✓ Validating lock in 19.3ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 2.17ms
  • Evaluating shell
  ✓ Evaluating shell in 937µs (cached)
  ✓ Configuring shell in 5.82ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 265µs (cached)
  ✓ Loading tasks in 2.52ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.6ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.0ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 4.81µs (no command)
  ✓ Running tasks in 22.0ms
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
  (35 lines omitted)
  DEVENV_PROFILE=/nix/store/12vc7wq60k49b2g5z5c1vybzwr5p6pac-devenv-profile
  DEVENV_DOTFILE=/repos/mattwynne/memba/.devenv
  PGHOST=/tmp/devenv-1d7df38/postgres
  PGPORT=15432
  PGDATA=/repos/mattwynne/memba/.devenv/state/postgres
  Tracked repository file writability OK (2463 regular files checked).
  Installing Hex...
  * creating /tmp/home/.mix/archives/hex-2.5.1
  Installing Rebar...
  * creating /tmp/home/.mix/elixir/1-18-otp-27/rebar3
  Fetching web dependencies...
  Checking acceptance-test dependencies...
  
  added 119 packages in 2s
  
  24 packages are looking for funding
    run `npm fund` for details
  npm notice
  npm notice New major version of npm available! 10.9.7 -> 12.2.0
  npm notice Changelog: https://github.com/npm/cli/releases/tag/v12.2.0
  npm notice To update run: npm install -g npm@12.2.0
  npm notice
  • Validating lock
  ✓ Validating lock in 19.0ms
  • Configuring cachix
  ✓ Configuring cachix in 2.93ms
  • Configuring shell
  • Evaluating shell
  ✓ Evaluating shell in 3.04s
  ✓ Configuring shell in 3.33s
  • Evaluating Nix
  ✓ Evaluating Nix in 2.37ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 1.87ms
  ✓ Loading tasks in 2.23ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 12.7ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.3ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 52.2µs (no command)
  ✓ Running tasks in 24.9ms
  • Running processes
  • Evaluating Nix
  ✓ Evaluating Nix in 1.89ms
  ✓ Running processes in 12.2s
  Starting test dependency compile smoke test...
  Sandbox runtime check passed.
  ```

## Stage: resume_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/067-live-projection-queries/plan.md'
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
  HEAD: 062bcfc fabro(01M41R98D29R3GZC8SGJDKKF7B): preflight_sandbox (succeeded)
  Todo: docs/iterations/067-live-projection-queries/todo.md (8 checked, 9 unchecked)
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/067-live-projection-queries/plan.md'
case "$PLAN_PATH" in
  */plan.md) ITERATION_DIR=${PLAN_PATH%/plan.md} ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
TODO_PATH="$ITERATION_DIR/todo.md"
mkdir -p .fabro/tmp
python3 -B .fabro/workflows/iteration-implementation/scripts/sync_task_list.py "$PLAN_PATH" "$TODO_PATH"
printf 'PLAN_PATH=%s\nTODO_PATH=%s\n' "$PLAN_PATH" "$TODO_PATH"
sed -n '1,160p' "$TODO_PATH"`
- Output:
  ```
  Using existing docs/iterations/067-live-projection-queries/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/067-live-projection-queries/plan.md
  TODO_PATH=docs/iterations/067-live-projection-queries/todo.md
  # Implementation TODO
  
  <!-- Matt's 2026-09-30 recovery guidance for task 005: repair as planned. A new conversation appears on an already-open club Conversations list without reload or navigation. Address the latest review's refresh and focused-test gaps; this does not accept task 005 or approve publication. -->
  
  <!-- Recovery direction after independently reviewed task 006: preserve all checked tasks and the candidate checkpoint. Before broad package extraction, the delivery planner should consider splitting and moving the already-approved Bob-sees-Alice-join open-member-list example from task 011 into one early, bounded scenario-led packet. Call the current and post-worker shots before running; activate only this permitted scenario as @wip, then keep it green. Preserve the remainder of task 011 and every other approved obligation. Do not invent a conversation-detail scenario or treat accepted implementation as retroactively test-first. -->
  
  - [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.
  - [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.
  - [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.
  - [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.
  - [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.
  - [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.
  - [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.
  - [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior.
  - [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.
  - [ ] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.
  - [ ] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.
  - [ ] 008D Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and recipient-eligibility interests.
  - [ ] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests.
  - [ ] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.
  - [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.
  - [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.
  - [ ] 011 Close the remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`.
  ```

## Stage: todo_readable
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/067-live-projection-queries/plan.md'
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
  Todo file is present and readable: docs/iterations/067-live-projection-queries/todo.md
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/067-live-projection-queries/plan.md'
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
  UNCHECKED tasks remain in docs/iterations/067-live-projection-queries/todo.md
  15:- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.
  16:- [ ] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.
  17:- [ ] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.
  18:- [ ] 008D Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and recipient-eligibility interests.
  19:- [ ] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests.
  20:- [ ] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.
  21:- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.
  22:- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.
  23:- [ ] 011 Close the remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`.
  ```

## Stage: before_delivery_planner
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py before-planner 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Delivery planner baseline captured from 8c4a977c448be4962a0fa520ab81f15319d840a3 in docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json
  ```

## Stage: delivery_planner
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > {
  >   "execution_state": {
  >     "schema_version": 1,
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "e881b12146435be4021c60cae3c5bab1647f6df7",
  >     "accepted_tasks": [
  >       "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
  >       "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
  >       "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.",
  >       "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >       "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
  >       "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.",
  >       "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.",
  >       "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."
  >     ],
  >     "pending_obligations": [
  >       {
  >         "task_id": "task-008a",
  >         "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
  >         "origin": "Adapter-completion portion of approved implementation step 4, corrected through review to distinguish changed projection dependencies, exact relationship scopes, valid no-op publications and malformed recognized notifications.",
  >         "status": "prepared",
  >         "coverage": [
  >           "All actual event families published by the eleven in-scope projectors",
  >           "Exact collection, relationship, identity and authorization invalidations for valid complete events",
  >           "No Person invalidation from Membership or GroupMembership relationship changes",
  >           "No conversation-wide invalidation from member-specific ConversationFollow changes",
  >           "No unchanged Group identity invalidation from ConversationGroupAccess changes",
  >           "No producerless generic fallback interests in the accepted dashboard or conversation-detail consumers",
  >           "Only evidenced broader scopes, including MessageSent club-conversation scope and role/permission fan-out",
  >           "Legacy MemberRemoved scope recovery from the retained membership row",
  >           "Stable lifecycle-visible contract violations for recognized malformed or unsupported projector/event pairings",
  >           "Refresh-count proof for same-conversation/different-member and same-Person/different-club isolation",
  >           "Corrected migration-matrix rows and fresh independent review"
  >         ],
  >         "replaces": [
  >           "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."
  >         ],
  >         "candidate_origins": [
  >           {
  >             "base_sha": "0b2466fc574c2110b09a5019d8c280658d035cd0",
  >             "head_sha": "2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b",
  >             "packet_id": "task-008a-0b2466f-adapter-matrix-1",
  >             "reason": "review_revise",
  >             "task_id": "task-008a",
  >             "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."
  >           },
  >           {
  >             "base_sha": "5a0be69826405522dbbc727b73e11cb5eac89784",
  >             "head_sha": "b9987229e5bdcd20e7e0314a32d616766d88f16c",
  >             "packet_id": "task-008a-5a0be69-projector-contract-revision-2",
  >             "reason": "review_revise",
  >             "task_id": "task-008a",
  >             "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
  >           },
  >           {
  >             "base_sha": "59e50fa26a52a8d3376a356546c3ba9309d79681",
  >             "head_sha": "c1af0f426158cc35e0e5c10c866a3d010ed9166a",
  >             "packet_id": "task-008a-59e50fa-contract-lifecycle-revision-3",
  >             "reason": "review_revise",
  >             "task_id": "task-008a",
  >             "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
  >           },
  >           {
  >             "base_sha": "0c2dbfb5cb423a4f20f8766e2826f156a3655c60",
  >             "head_sha": "8c4a977c448be4962a0fa520ab81f15319d840a3",
  >             "packet_id": "task-008a-0c2dbfb-noop-identity-revision-4",
  >             "reason": "review_revise",
  >             "task_id": "task-008a",
  >             "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
  >           }
  >         ]
  >       },
  >       {
  >         "task_id": "task-008b",
  >         "todo_line": "- [ ] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
  >         "origin": "Group-creation query portion of approved implementation step 4 and the former broad task 008.",
  >         "status": "pending",
  >         "coverage": [
  >           "One coherent group-creation context result",
  >           "Fresh active-club, current-member and manage-members authorization reads",
  >           "Selected Club, current membership, Person, role and permission interests",
  >           "No ownership of generated group identity, typed name, preview, errors or command state"
  >         ],
  >         "replaces": [
  >           "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-008c",
  >         "todo_line": "- [ ] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.",
  >         "origin": "Settings-query portion of approved implementation step 4 and the former broad task 008.",
  >         "status": "pending",
  >         "coverage": [
  >           "One coherent settings result",
  >           "Fresh selected-club membership and current-Person resolution",
  >           "Current Person active-club membership and email-address collections",
  >           "Selected and represented Club identities",
  >           "No ownership of tab, add-email form, errors or command feedback"
  >         ],
  >         "replaces": [
  >           "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-008d",
  >         "todo_line": "- [ ] 008D Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and recipient-eligibility interests.",
  >         "origin": "Message-compose query portion of approved implementation step 4 and the former broad task 008.",
  >         "status": "pending",
  >         "coverage": [
  >           "One coherent compose-context result",
  >           "Fresh active-club, current-member and selected-audience participation reads",
  >           "Club-member, participating-group and selected-group-member collection interests",
  >           "Represented Person and primary-email eligibility interests",
  >           "No ownership of subject, body, validation, retry or send state"
  >         ],
  >         "replaces": [
  >           "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-008e",
  >         "todo_line": "- [ ] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests.",
  >         "origin": "Delivery-detail query portion of approved implementation step 4 and the former broad task 008.",
  >         "status": "pending",
  >         "coverage": [
  >           "One coherent authorized delivery-detail result",
  >           "Fresh active-club, current-member, group-participation and conversation-access reads",
  >           "Exact conversation, represented Person, delivery collection and delivery identity interests",
  >           "Independent MemberEmailDelivery status and MembaStaffEmailDelivery reason convergence",
  >           "No ownership of route, disclosure, flash or navigation state"
  >         ],
  >         "replaces": [
  >           "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-008f",
  >         "todo_line": "- [ ] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
  >         "origin": "Member-invitation query portion of approved implementation step 4 and the former broad task 008.",
  >         "status": "pending",
  >         "coverage": [
  >           "One coherent invitation context result",
  >           "Fresh active-club, current-member and manage-members authorization reads",
  >           "Club-member collection entry and exit for the displayed count",
  >           "Selected Club, current membership, Person, role and permission interests",
  >           "No ownership of invitation email, validation, resend decision, delivery feedback or navigation"
  >         ],
  >         "replaces": [
  >           "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-009",
  >         "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
  >         "origin": "Approved implementation step 5 after dashboard and conversation detail served as the accepted pre-freeze consumers.",
  >         "status": "pending",
  >         "coverage": [
  >           "Group creation, settings, message composition, delivery detail and invitation LiveViews",
  >           "One coherent result assign per remaining in-scope page",
  >           "Preserved routes, access transitions, forms, commands, navigation and UI",
  >           "Live delivery status and staff-reason convergence",
  >           "Existing conversation and delivery behavior",
  >           "No staff stream migration"
  >         ],
  >         "replaces": [
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-010",
  >         "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
  >         "origin": "Approved implementation step 6.",
  >         "status": "pending",
  >         "coverage": [
  >           "Path dependency integration in web/mix.exs",
  >           "Production Docker build and release inclusion",
  >           "Package tests exercised by dev check in supported environments"
  >         ],
  >         "replaces": [
  >           "- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-011",
  >         "todo_line": "- [ ] 011 Close the remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`.",
  >         "origin": "Remainder of approved implementation step 7 after the stakeholder scenario and committed-projector open-LiveView proof were split into accepted task 006A.",
  >         "status": "pending",
  >         "coverage": [
  >           "Focused proof for every migrated member page",
  >           "Residual package lifecycle and bind/reconnect race coverage",
  >           "Final full dev check on the exact clean or staged state"
  >         ],
  >         "replaces": [
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`.",
  >           "- [ ] 011 Implement the approved Bob-sees-Alice-join acceptance example, close remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`."
  >         ],
  >         "candidate_origins": []
  >       }
  >     ],
  >     "candidate_origins": [
  >       {
  >         "base_sha": "0b2466fc574c2110b09a5019d8c280658d035cd0",
  >         "head_sha": "2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b",
  >         "packet_id": "task-008a-0b2466f-adapter-matrix-1",
  >         "reason": "review_revise",
  >         "task_id": "task-008a",
  >         "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."
  >       },
  >       {
  >         "base_sha": "5a0be69826405522dbbc727b73e11cb5eac89784",
  >         "head_sha": "b9987229e5bdcd20e7e0314a32d616766d88f16c",
  >         "packet_id": "task-008a-5a0be69-projector-contract-revision-2",
  >         "reason": "review_revise",
  >         "task_id": "task-008a",
  >         "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
  >       },
  >       {
  >         "base_sha": "59e50fa26a52a8d3376a356546c3ba9309d79681",
  >         "head_sha": "c1af0f426158cc35e0e5c10c866a3d010ed9166a",
  >         "packet_id": "task-008a-59e50fa-contract-lifecycle-revision-3",
  >         "reason": "review_revise",
  >         "task_id": "task-008a",
  >         "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
  >       },
  >       {
  >         "base_sha": "0c2dbfb5cb423a4f20f8766e2826f156a3655c60",
  >         "head_sha": "8c4a977c448be4962a0fa520ab81f15319d840a3",
  >         "packet_id": "task-008a-0c2dbfb-noop-identity-revision-4",
  >         "reason": "review_revise",
  >         "task_id": "task-008a",
  >         "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
  >       }
  >     ],
  >     "coverage_map": [
  >       {
  >         "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, generic lifecycle contract, package extraction and accepted consumer adoption.",
  >         "pending_task_ids": [],
  >         "accepted_task_lines": [
  >           "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
  >           "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
  >           "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.",
  >           "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >           "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
  >           "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.",
  >           "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.",
  >           "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."
  >         ]
  >       },
  >       {
  >         "scope": "Correct and prove the app-owned notification adapter and accepted consumers use only changed projection dependencies, exact relationship scopes and evidenced broader invalidations, with no inert fallback vocabulary.",
  >         "pending_task_ids": [
  >           "task-008a"
  >         ],
  >         "accepted_task_lines": []
  >       },
  >       {
  >         "scope": "Introduce the five remaining fresh-authorized one-result query boundaries from existing read APIs without absorbing transient LiveView state.",
  >         "pending_task_ids": [
  >           "task-008b",
  >           "task-008c",
  >           "task-008d",
  >           "task-008e",
  >           "task-008f"
  >         ],
  >         "accepted_task_lines": []
  >       },
  >       {
  >         "scope": "Migrate the five remaining member LiveViews while preserving routes, access transitions, transient state, navigation, UI and delivery/conversation convergence.",
  >         "pending_task_ids": [
  >           "task-009"
  >         ],
  >         "accepted_task_lines": []
  >       },
  >       {
  >         "scope": "Complete production package, Docker release and repository quality-gate integration.",
  >         "pending_task_ids": [
  >           "task-010"
  >         ],
  >         "accepted_task_lines": []
  >       },
  >       {
  >         "scope": "Close residual per-page and package lifecycle proof gaps and run final exact-state validation.",
  >         "pending_task_ids": [
  >           "task-011"
  >         ],
  >         "accepted_task_lines": []
  >       }
  >     ],
  >     "planner_note": "The trusted checkpoint preserves tasks 001, 003, 004, 005, 006, 006A, 007A and 007B exactly as accepted. Task 008A remains the first unchecked line and keeps the same task identity, todo wording and revision lineage; all four unaccepted candidate origins required by the baseline are retained. The latest candidate correctly closes the malformed recognized no-op gap and reports 30 focused adapter tests passing, but independent review found that relationship notifications still emit identity invalidations for projections they did not change: ConversationFollow emits a conversation identity, and Membership and GroupMembership emit a Person identity. Direct inspection also confirms ConversationGroupAccess emits an unchanged Group identity, both accepted queries register producerless generic fallback interests, and conversation detail retains two producerless broad follow interests. This bounded revision aligns those mappings and interests with the corrected matrix and adds loader-count proof that unrelated queries are not reread. No todo edit or semantic split is needed. The only approved acceptance scenario is already accepted and green; this adapter/query-vocabulary recovery has no appropriate new agreed scenario, so scenario_focus is null and focused technical proof is used."
  >   },
  >   "planner_result": {
  >     "schema_version": 1,
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "e881b12146435be4021c60cae3c5bab1647f6df7",
  >     "decision": "ready"
  >   },
  >   "current_worker_packet": {
  >     "schema_version": 1,
  >     "packet_id": "task-008a-e881b12-isolation-vocabulary-revision-5",
  >     "task_id": "task-008a",
  >     "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
  >     "attempt": "revision",
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "e881b12146435be4021c60cae3c5bab1647f6df7",
  >     "outcome": "Align committed-read-model invalidations and accepted consumer interests with actual changed projection dependencies so member-specific or cross-club relationship changes do not reread unrelated queries, while removing producerless fallback vocabulary and retaining every required exact, collection, authorization and evidenced broad scope.",
  >     "scope": [
  >       "Remove `{:conversation, conversation_id}` from explicit and auto-following ConversationFollow invalidations; retain only the exact `{:conversation_follow, conversation_id, member_id}` relationship key, while preserving complete false-auto-follow `:ignore` behavior and required-identity validation.",
  >       "Remove `{:person, person_id}` from Membership invalidations because membership events do not change the Person projection; retain `{:club_members, club_id}`, `{:membership, membership_id}` and `{:person_clubs, person_id}` for the changed collection, exact relationship and active-club authority dependency.",
  >       "Remove `{:person, person_id}` from GroupMembership invalidations; retain `{:group_members, group_id}`, `{:person_groups, club_id, person_id}` and `{:group_participation, club_id, group_id, person_id}`.",
  >       "Remove the unchanged `{:group, group_id}` identity from ConversationGroupAccess invalidations while retaining the group-conversation collection, exact access relationship and conversation-wide authorization invalidation.",
  >       "Remove the dashboard and conversation-detail `@fallback_families`, `fallback_interests/1` helpers and all `{:fallback, ...}` interests because the corrected source emits only concrete keys, `:ignore`, or a visible contract violation.",
  >       "Remove conversation detail's producerless `{:conversation_follows, conversation_id}` and `{:member_conversation_follows, person_id}` interests while retaining its exact current-member follow interest.",
  >       "Correct only the affected Membership, GroupMembership, ConversationFollow and ConversationGroupAccess rows of the migration matrix so documented logical interests match the actual changed projections and precise adapter output.",
  >       "Update exact invalidation-set and query-interest tests, and add Binding-level loader-count tests proving a same-conversation/different-member follow change and same-Person/different-club Membership or GroupMembership changes do not reread an unrelated registration.",
  >       "Include a loader-count isolation case for ConversationGroupAccess on an unselected represented group, while proving a relevant exact access or conversation-wide authorization change still refreshes where required.",
  >       "Preserve all previously reviewed envelope validation, eleven-family dispatch, valid no-op handling, retained-row legacy MemberRemoved recovery, contract-violation lifecycle behavior, MessageSent club-conversation scope, role/permission fan-out and independent delivery-projector convergence."
  >     ],
  >     "scope_exclusions": [
  >       "Do not modify `packages/live_query/**` or broaden the frozen generic Query, Source or Binding API.",
  >       "Do not change LiveViews, routes, templates, components, forms, navigation, commands, event structs, projectors, projection schemas, publishers or read APIs.",
  >       "Do not remove `{:conversation, conversation_id}` from ConversationGroupAccess; that key preserves conversation-wide fresh authorization when any access relationship for the conversation changes.",
  >       "Do not alter role/permission mappings, MessageSent's evidenced club-conversation collection, delivery mappings, legacy MemberRemoved retained-row recovery, complete-envelope gating or stable contract-violation behavior.",
  >       "Do not introduce new broad, global, family fallback, projection-row lookup or changes-map recovery behavior.",
  >       "Do not implement tasks 008B through 011 or migrate another LiveView.",
  >       "Do not edit the approved plan, todo, ADRs, extraction contract or acceptance feature; migration-matrix edits are limited to reconciling the four affected adapter rows.",
  >       "Do not reactivate or rerun the already-green Bob-sees-Alice scenario.",
  >       "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped repository suite; the deterministic iteration gate owns full validation.",
  >       "Do not mark task 008A complete; fresh independent review owns acceptance."
  >     ],
  >     "references": [
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/plan.md",
  >         "facts": "The approved technical model requires refreshing only affected query results, exact collection and relationship scopes where available, evidenced broader invalidation only for valid events lacking exact scope, and no silent fallback for malformed recognized notifications."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/todo.md",
  >         "facts": "Task 008A is the first unchecked obligation and owns exact scoped matching, unrelated-projector isolation, actual projector/event-family auditing, corrected matrix fallbacks, focused proof and fresh independent review."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
  >         "facts": "The binding checkpoint is current HEAD and requires preservation of all four task-008a review-revise candidate origins, including the latest no-op identity revision."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
  >         "facts": "The latest worker changed only the adapter and its focused tests, reported 30 adapter tests passing, and correctly moved required-field validation ahead of false-auto-follow and EmailDeliveryOpened no-op decisions."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
  >         "facts": "Independent review accepted the no-op identity correction but requires removal of conversation-wide follow and cross-scope Person invalidations, loader-count isolation proof, and completion of the consumer fallback audit."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
  >         "facts": "The current adapter rows still describe Person identity for Membership and GroupMembership, conversation identity for ConversationFollow, and Group identity for ConversationGroupAccess; those claims must be reconciled with the projections actually changed."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
  >         "facts": "The frozen package contract uses opaque exact source matching, refreshes only matching registrations, and atomically replaces a query's result and interests; this revision changes only app-owned vocabulary and proof."
  >       },
  >       {
  >         "path": "docs/adr/0021-publish-committed-read-model-changes.md",
  >         "facts": "Projectors publish their source event and committed changes after projection transactions, providing the boundary from which the app adapter must derive precise affected read-model keys."
  >       },
  >       {
  >         "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
  >         "facts": "The accepted architecture says a relevant committed change triggers a fresh authorized read, while imprecise invalidation creates unnecessary database work; Memba mapping remains in the app."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
  >         "facts": "Current Membership and GroupMembership mappings emit `{:person, person_id}`, current ConversationFollow mappings emit both exact follow and conversation identity, and ConversationGroupAccess emits an unchanged Group identity. Matching itself is strict tuple equality and the source emits no generic fallback tuple."
  >       },
  >       {
  >         "path": "web/test/memba_web/live_query/memba_read_model_source_test.exs",
  >         "facts": "The focused suite currently asserts the over-broad invalidation sets and already contains Binding/query helpers suitable for direct loader-count proof without relying on unchanged rendered HTML."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_query.ex",
  >         "facts": "The dashboard registers concrete collection, represented-identity and authorization interests but also appends sixteen producerless global and club-scoped fallback interests from eight fallback families."
  >       },
  >       {
  >         "path": "web/test/memba_web/member_dashboard_query_test.exs",
  >         "facts": "The dashboard query test enumerates required concrete interests and can assert that no `{:fallback, ...}` interest remains after cleanup."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_message_detail_query.ex",
  >         "facts": "Conversation detail registers the required exact current-member follow key, but also appends sixteen generic fallback interests and two broad follow interests for which the source has no producer."
  >       },
  >       {
  >         "path": "web/test/memba_web/member_message_detail_query_test.exs",
  >         "facts": "The detail query test currently positively asserts `{:fallback, :delivery}` and both producerless broad follow interests, so it must be corrected while retaining exact conversation, access, author, follow and delivery coverage."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/group_membership.ex",
  >         "facts": "GroupMembership events update only the group-membership projection relationship; they do not modify a Person projection, supporting removal of the Person identity invalidation."
  >       },
  >       {
  >         "path": "web/lib/memba/messaging/projectors/conversation_follow.ex",
  >         "facts": "ConversationFollow events and auto-following MessageSent update one conversation/member follow row, while false-auto-follow MessageSent is a projector no-op; the changed dependency is the exact follow relationship."
  >       },
  >       {
  >         "path": "web/lib/memba/messaging/projectors/conversation_group_access.ex",
  >         "facts": "Conversation access events upsert or delete one conversation/group relationship and do not modify the Group projection; group-collection, exact-access and conversation-wide authorization keys remain sufficient."
  >       },
  >       {
  >         "path": "docs/reference/elixir-mix-tests.md",
  >         "facts": "Focused process tests must avoid sleeps and process-liveness polling; direct loader counters or messages and deterministic synchronization should prove absence of an unrelated reread."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
  >         "facts": "The iteration's sole approved acceptance scenario is already green with its prediction matched, so this technical recovery must not fabricate another scenario-first cycle."
  >       }
  >     ],
  >     "constraints": [
  >       "Limit changes to the app-owned adapter, the two accepted query modules, their three focused test files, and the four affected rows in `migration-matrix.md`; report an unavoidable conflict before expanding scope.",
  >       "Treat projector implementation and actual query reads as ground truth: a relationship event must not emit an identity key for an unchanged projection merely because a query also represents that identity.",
  >       "Keep exact tuple equality in `MembaReadModelSource.matches?/2`; solve isolation by correcting emitted invalidations and consumer interests, not by adding asymmetric wildcard matching.",
  >       "Preserve `{:person_clubs, person_id}` for Membership because active-club authority genuinely changes, and preserve club/group-scoped participation keys for GroupMembership.",
  >       "Preserve the exact current-member follow key and remove only conversation-wide follow invalidation; another member's follow state must not reread the open member's detail or a dashboard representing the same conversation.",
  >       "For ConversationGroupAccess, preserve `{:group_conversations, group_id}`, exact `{:conversation_access, group_id, conversation_id}` and `{:conversation, conversation_id}`; remove only the unchanged Group identity.",
  >       "Remove producerless fallback and broad-follow interests rather than inventing source emissions to justify them.",
  >       "Add read-count evidence at the Binding boundary: the new tests must distinguish no reread from a reread that happens to render unchanged output.",
  >       "Before the initial focused red run, record a concrete expected diagnostic showing the loader count increased from one to two for an unrelated notification or that an unexpected broad/fallback tuple remained; after the correction, predict the focused commands will be green.",
  >       "Use actual event structs and complete committed-change envelopes in adapter tests; do not reintroduce synthetic partial maps as valid variants.",
  >       "Prepare evidence for fresh independent review and leave the todo line unchecked."
  >     ],
  >     "focused_validation": [
  >       "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live_query/memba_read_model_source_test.exs",
  >       "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs"
  >     ],
  >     "completion_evidence_required": [
  >       "List every changed path and summarize the precise invalidation or interest removed from each.",
  >       "Report the initial focused-red diagnostic and confirm it matched the predicted extra loader invocation or unexpected tuple.",
  >       "Report successful exit status, test count and failure count for both focused validation commands after implementation.",
  >       "Show exact invalidation sets for Membership, GroupMembership, ConversationFollow and ConversationGroupAccess after the correction.",
  >       "Show loader-count evidence that same-conversation/different-member follow changes and same-Person/different-club Membership and GroupMembership changes leave the unrelated query at its initial load count.",
  >       "Show loader-count evidence that access changes for an unselected represented group do not reread through an unchanged Group identity, while relevant access or conversation authorization invalidation still refreshes.",
  >       "Show that both accepted queries contain no `{:fallback, ...}` interests and that conversation detail contains only the exact follow relationship it can receive from the source.",
  >       "Confirm the migration-matrix rows now match actual emitted keys and distinguish changed projection identities from relationship and collection dependencies.",
  >       "Confirm false-auto-follow MessageSent and EmailDeliveryOpened remain valid no-ops after complete identity validation, and malformed recognized notifications retain their stable lifecycle-visible exception behavior.",
  >       "Confirm all other previously reviewed adapter behavior remains green, including complete-envelope gating, eleven-family dispatch, MessageSent's club-conversation scope, retained-row legacy recovery, role/permission fan-out and both delivery projectors.",
  >       "Report `bin/mix format --check-formatted` and `git diff --check` results in the worker summary without running an unscoped repository suite.",
  >       "Confirm no package, LiveView, route, template, form, event, projector, projection schema, publisher, approved plan, todo, ADR or acceptance feature changed."
  >     ],
  >     "candidate_origins": [
  >       {
  >         "base_sha": "0b2466fc574c2110b09a5019d8c280658d035cd0",
  >         "head_sha": "2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b",
  >         "packet_id": "task-008a-0b2466f-adapter-matrix-1",
  >         "reason": "review_revise",
  >         "task_id": "task-008a",
  >         "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."
  >       },
  >       {
  >         "base_sha": "5a0be69826405522dbbc727b73e11cb5eac89784",
  >         "head_sha": "b9987229e5bdcd20e7e0314a32d616766d88f16c",
  >         "packet_id": "task-008a-5a0be69-projector-contract-revision-2",
  >         "reason": "review_revise",
  >         "task_id": "task-008a",
  >         "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
  >       },
  >       {
  >         "base_sha": "59e50fa26a52a8d3376a356546c3ba9309d79681",
  >         "head_sha": "c1af0f426158cc35e0e5c10c866a3d010ed9166a",
  >         "packet_id": "task-008a-59e50fa-contract-lifecycle-revision-3",
  >         "reason": "review_revise",
  >         "task_id": "task-008a",
  >         "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
  >       },
  >       {
  >         "base_sha": "0c2dbfb5cb423a4f20f8766e2826f156a3655c60",
  >         "head_sha": "8c4a977c448be4962a0fa520ab81f15319d840a3",
  >         "packet_id": "task-008a-0c2dbfb-noop-identity-revision-4",
  >         "reason": "review_revise",
  >         "task_id": "task-008a",
  >         "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
  >       }
  >     ],
  >     "scenario_focus": null
  >   }
  > }

## Stage: write_planner_output
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py write-planner-output 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Wrote validated planner output for ready to docs/iterations/067-live-projection-queries/.delivery
  ```

## Stage: guard_delivery_packet
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py guard-planner 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  {"preferred_next_label": "revise"}
  ```

## Stage: call_shot_and_run_scenario
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/wip_scenario.py before 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  {"preferred_next_label": "revise"}
  ```

## Stage: revise_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > Implemented packet `task-008a-e881b12-isolation-vocabulary-revision-5` with result `ready_for_review`.
  > 
  > Changes:
  > 
  > - Tightened invalidations in [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex:275):
  >   - Membership and GroupMembership no longer emit unchanged Person identities.
  >   - ConversationFollow emits only the exact member-follow relationship.
  >   - ConversationGroupAccess retains collection, exact-access, and conversation-wide authorization keys without unchanged Group identity.
  > - Removed producerless fallback interests from [member_dashboard_query.ex](/workspace/memba/web/lib/memba_web/member_dashboard_query.ex:15).
  > - Removed fallback and broad-follow interests from [member_message_detail_query.ex](/workspace/memba/web/lib/memba_web/member_message_detail_query.ex:15).
  > - Added Binding-level loader-count isolation tests proving unrelated notifications do not reread queries while relevant notifications do.
  > - Reconciled the four permitted rows in [migration-matrix.md](/workspace/memba/docs/iterations/067-live-projection-queries/migration-matrix.md:161).
  > - Wrote the required [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1). The todo remains unchecked.
  > 
  > Validation passed:
  > 
  > - Adapter and Binding tests: 34 tests, 0 failures.
  > - Dashboard and conversation-detail query tests: 8 tests, 0 failures.
  > - `bin/mix format --check-formatted`: passed.
  > - `git diff --check`: passed.
  > - Worker result JSON parses successfully.
  > 
  > The initial red runs matched the prediction: unrelated notifications caused loader counts to rise from one to two, and consumer tests exposed the fallback/broad-follow interests. No unresolved items remain. Per packet instructions, I did not run `dev check`; the deterministic workflow’s `dev_check` node owns that full gate.

## Stage: route_worker_result
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py route-worker 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  {"preferred_next_label": "review"}
  ```

## Stage: observe_scenario_after_worker
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/wip_scenario.py after 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  {"preferred_next_label": "review"}
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > {"decision":"revise","task":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.","reason":"The current packet and ready_for_review result match this first unchecked todo, the worktree is clean, and revision 5 closes the previously reported fallback, malformed-event, and four-family isolation gaps. However, affected-query isolation is still incomplete. Role permission and assignment/removal events emit {:role, role_id} even though those projectors do not change the Role projection; the matrix and tests currently encode that unchanged-identity invalidation, contrary to the packet rule for relationship events. MemberMessageDetailQuery also registers {:club_members, club_id} and {:group_members, group_id}, so another member changing in the same club or audience group rereads an unrelated open detail even though exact membership/person-clubs/group-participation interests cover the current actor. Revise the Role mapping/matrix/tests, remove those two detail interests, and add Binding loader-count proof for unrelated and relevant cases; the next repair packet must explicitly reconcile its current preserve-role exclusion with this correction. The recorded focused runs are current, and review-side scoped confirmation passed 34/0 and 8/0 while investigating isolation, but those tests presently assert the broad keys and therefore do not establish the required behavior; no full suite was run."}

## Stage: apply_task_verdict
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/apply_task_verdict.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Task revise: - [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.
  The current packet and ready_for_review result match this first unchecked todo, the worktree is clean, and revision 5 closes the previously reported fallback, malformed-event, and four-family isolation gaps. However, affected-query isolation is still incomplete. Role permission and assignment/removal events emit {:role, role_id} even though those projectors do not change the Role projection; the matrix and tests currently encode that unchanged-identity invalidation, contrary to the packet rule for relationship events. MemberMessageDetailQuery also registers {:club_members, club_id} and {:group_members, group_id}, so another member changing in the same club or audience group rereads an unrelated open detail even though exact membership/person-clubs/group-participation interests cover the current actor. Revise the Role mapping/matrix/tests, remove those two detail interests, and add Binding loader-count proof for unrelated and relevant cases; the next repair packet must explicitly reconcile its current preserve-role exclusion with this correction. The recorded focused runs are current, and review-side scoped confirmation passed 34/0 and 8/0 while investigating isolation, but those tests presently assert the broad keys and therefore do not establish the required behavior; no full suite was run.
  {"preferred_next_label": "revise"}
  ```

## Stage: task_escalation
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/escalate_task_review.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Validator's current finding for - [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.: The current packet and ready_for_review result match this first unchecked todo, the worktree is clean, and revision 5 closes the previously reported fallback, malformed-event, and four-family isolation gaps. However, affected-query isolation is still incomplete. Role permission and assignment/removal events emit {:role, role_id} even though those projectors do not change the Role projection; the matrix and tests currently encode that unchanged-identity invalidation, contrary to the packet rule for relationship events. MemberMessageDetailQuery also registers {:club_members, club_id} and {:group_members, group_id}, so another member changing in the same club or audience group rereads an unrelated open detail even though exact membership/person-clubs/group-participation interests cover the current actor. Revise the Role mapping/matrix/tests, remove those two detail interests, and add Binding loader-count proof for unrelated and relevant cases; the next repair packet must explicitly reconcile its current preserve-role exclusion with this correction. The recorded focused runs are current, and review-side scoped confirmation passed 34/0 and 8/0 while investigating isolation, but those tests presently assert the broad keys and therefore do not establish the required behavior; no full suite was run.
  Escalating revise after 5 revision verdict(s) for task-008a.
  {"preferred_next_label": "discuss"}
  ```

## Stage: task_discussion
- Status: succeeded
- Handler: human

## Stage: reflect_task_discussion
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > {"preferred_next_label":"finish","outcome":"succeeded","failure_reason":"","suggested_next_ids":["delivery_planner"],"context_updates":{"task_id":"task-008a","decision":"repair_as_planned","decision_summary":"Matt explicitly said discussion is complete and directed a bounded technical repair.","required_repairs":["Audit the full producer → invalidation → query-interest mapping, including Role and conversation detail.","Remove the prior “do not alter role mappings” exclusion.","Add loader-count tests proving relevant refreshes and unrelated non-refreshes."],"approval_limits":["Task 008A remains unchecked and unaccepted.","No publication approval was given."]}}

## Current context
| Key | Value |
|-----|-------|
| approval_limits | ["Task 008A remains unchecked and unaccepted.","No publication approval was given."] |
| decision | repair_as_planned |
| decision_summary | Matt explicitly said discussion is complete and directed a bounded technical repair. |
| human.gate.label | Repair as planned. Before another worker attempt, audit the full producer → invalidation → query-interest mapping, including Role and conversation detail. Remove the prior “do not alter role mappings” exclusion. Prove relevant refreshes and unrelated non-refreshes with loader-count tests. Discussion complete. This is not acceptance or publication approval. |
| human.gate.selected | freeform |
| human.gate.task_discussion.answer | Repair as planned. Before another worker attempt, audit the full producer → invalidation → query-interest mapping, including Role and conversation detail. Remove the prior “do not alter role mappings” exclusion. Prove relevant refreshes and unrelated non-refreshes with loader-count tests. Discussion complete. This is not acceptance or publication approval. |
| human.gate.task_discussion.question | <@U0C3C6Y9ZAR> The validator has stopped this task; its finding is in the preceding run evidence. Should we repair the candidate to meet the approved plan, or is there a concrete business example or architectural constraint that changes the approach? Reply in this message's thread with 'repair as planned' or describe that constraint. This cannot approve publication. |
| human.gate.text | Repair as planned. Before another worker attempt, audit the full producer → invalidation → query-interest mapping, including Role and conversation detail. Remove the prior “do not alter role mappings” exclusion. Prove relevant refreshes and unrelated non-refreshes with loader-count tests. Discussion complete. This is not acceptance or publication approval. |
| output.delivery_planner | {"execution_state":{"schema_version":1,"plan_path":"docs/iterations/067-live-projection-queries/plan.md","todo_path":"docs/iterations/067-live-projection-queries/todo.md","source_baseline":"e881b12146435be4021c60cae3c5bab1647f6df7","accepted_tasks":["- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.","- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.","- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.","- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.","- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.","- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.","- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.","- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."],"pending_obligations":[{"task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.","origin":"Adapter-completion portion of approved implementation step 4, corrected through review to distinguish changed projection dependencies, exact relationship scopes, valid no-op publications and malformed recognized notifications.","status":"prepared","coverage":["All actual event families published by the eleven in-scope projectors","Exact collection, relationship, identity and authorization invalidations for valid complete events","No Person invalidation from Membership or GroupMembership relationship changes","No conversation-wide invalidation from member-specific ConversationFollow changes","No unchanged Group identity invalidation from ConversationGroupAccess changes","No producerless generic fallback interests in the accepted dashboard or conversation-detail consumers","Only evidenced broader scopes, including MessageSent club-conversation scope and role/permission fan-out","Legacy MemberRemoved scope recovery from the retained membership row","Stable lifecycle-visible contract violations for recognized malformed or unsupported projector/event pairings","Refresh-count proof for same-conversation/different-member and same-Person/different-club isolation","Corrected migration-matrix rows and fresh independent review"],"replaces":["- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.","- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."],"candidate_origins":[{"base_sha":"0b2466fc574c2110b09a5019d8c280658d035cd0","head_sha":"2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b","packet_id":"task-008a-0b2466f-adapter-matrix-1","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."},{"base_sha":"5a0be69826405522dbbc727b73e11cb5eac89784","head_sha":"b9987229e5bdcd20e7e0314a32d616766d88f16c","packet_id":"task-008a-5a0be69-projector-contract-revision-2","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."},{"base_sha":"59e50fa26a52a8d3376a356546c3ba9309d79681","head_sha":"c1af0f426158cc35e0e5c10c866a3d010ed9166a","packet_id":"task-008a-59e50fa-contract-lifecycle-revision-3","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."},{"base_sha":"0c2dbfb5cb423a4f20f8766e2826f156a3655c60","head_sha":"8c4a977c448be4962a0fa520ab81f15319d840a3","packet_id":"task-008a-0c2dbfb-noop-identity-revision-4","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."}]},{"task_id":"task-008b","todo_line":"- [ ] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.","origin":"Group-creation query portion of approved implementation step 4 and the former broad task 008.","status":"pending","coverage":["One coherent group-creation context result","Fresh active-club, current-member and manage-members authorization reads","Selected Club, current membership, Person, role and permission interests","No ownership of generated group identity, typed name, preview, errors or command state"],"replaces":["- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."],"candidate_origins":[]},{"task_id":"task-008c","todo_line":"- [ ] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.","origin":"Settings-query portion of approved implementation step 4 and the former broad task 008.","status":"pending","coverage":["One coherent settings result","Fresh selected-club membership and current-Person resolution","Current Person active-club membership and email-address collections","Selected and represented Club identities","No ownership of tab, add-email form, errors or command feedback"],"replaces":["- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."],"candidate_origins":[]},{"task_id":"task-008d","todo_line":"- [ ] 008D Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and recipient-eligibility interests.","origin":"Message-compose query portion of approved implementation step 4 and the former broad task 008.","status":"pending","coverage":["One coherent compose-context result","Fresh active-club, current-member and selected-audience participation reads","Club-member, participating-group and selected-group-member collection interests","Represented Person and primary-email eligibility interests","No ownership of subject, body, validation, retry or send state"],"replaces":["- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."],"candidate_origins":[]},{"task_id":"task-008e","todo_line":"- [ ] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests.","origin":"Delivery-detail query portion of approved implementation step 4 and the former broad task 008.","status":"pending","coverage":["One coherent authorized delivery-detail result","Fresh active-club, current-member, group-participation and conversation-access reads","Exact conversation, represented Person, delivery collection and delivery identity interests","Independent MemberEmailDelivery status and MembaStaffEmailDelivery reason convergence","No ownership of route, disclosure, flash or navigation state"],"replaces":["- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."],"candidate_origins":[]},{"task_id":"task-008f","todo_line":"- [ ] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.","origin":"Member-invitation query portion of approved implementation step 4 and the former broad task 008.","status":"pending","coverage":["One coherent invitation context result","Fresh active-club, current-member and manage-members authorization reads","Club-member collection entry and exit for the displayed count","Selected Club, current membership, Person, role and permission interests","No ownership of invitation email, validation, resend decision, delivery feedback or navigation"],"replaces":["- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."],"candidate_origins":[]},{"task_id":"task-009","todo_line":"- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.","origin":"Approved implementation step 5 after dashboard and conversation detail served as the accepted pre-freeze consumers.","status":"pending","coverage":["Group creation, settings, message composition, delivery detail and invitation LiveViews","One coherent result assign per remaining in-scope page","Preserved routes, access transitions, forms, commands, navigation and UI","Live delivery status and staff-reason convergence","Existing conversation and delivery behavior","No staff stream migration"],"replaces":["- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."],"candidate_origins":[]},{"task_id":"task-010","todo_line":"- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.","origin":"Approved implementation step 6.","status":"pending","coverage":["Path dependency integration in web/mix.exs","Production Docker build and release inclusion","Package tests exercised by dev check in supported environments"],"replaces":["- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."],"candidate_origins":[]},{"task_id":"task-011","todo_line":"- [ ] 011 Close the remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`.","origin":"Remainder of approved implementation step 7 after the stakeholder scenario and committed-projector open-LiveView proof were split into accepted task 006A.","status":"pending","coverage":["Focused proof for every migrated member page","Residual package lifecycle and bind/reconnect race coverage","Final full dev check on the exact clean or staged state"],"replaces":["- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`.","- [ ] 011 Implement the approved Bob-sees-Alice-join acceptance example, close remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`."],"candidate_origins":[]}],"candidate_origins":[{"base_sha":"0b2466fc574c2110b09a5019d8c280658d035cd0","head_sha":"2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b","packet_id":"task-008a-0b2466f-adapter-matrix-1","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."},{"base_sha":"5a0be69826405522dbbc727b73e11cb5eac89784","head_sha":"b9987229e5bdcd20e7e0314a32d616766d88f16c","packet_id":"task-008a-5a0be69-projector-contract-revision-2","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."},{"base_sha":"59e50fa26a52a8d3376a356546c3ba9309d79681","head_sha":"c1af0f426158cc35e0e5c10c866a3d010ed9166a","packet_id":"task-008a-59e50fa-contract-lifecycle-revision-3","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."},{"base_sha":"0c2dbfb5cb423a4f20f8766e2826f156a3655c60","head_sha":"8c4a977c448be4962a0fa520ab81f15319d840a3","packet_id":"task-008a-0c2dbfb-noop-identity-revision-4","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."}],"coverage_map":[{"scope":"Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, generic lifecycle contract, package extraction and accepted consumer adoption.","pending_task_ids":[],"accepted_task_lines":["- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.","- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.","- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.","- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.","- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.","- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.","- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.","- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."]},{"scope":"Correct and prove the app-owned notification adapter and accepted consumers use only changed projection dependencies, exact relationship scopes and evidenced broader invalidations, with no inert fallback vocabulary.","pending_task_ids":["task-008a"],"accepted_task_lines":[]},{"scope":"Introduce the five remaining fresh-authorized one-result query boundaries from existing read APIs without absorbing transient LiveView state.","pending_task_ids":["task-008b","task-008c","task-008d","task-008e","task-008f"],"accepted_task_lines":[]},{"scope":"Migrate the five remaining member LiveViews while preserving routes, access transitions, transient state, navigation, UI and delivery/conversation convergence.","pending_task_ids":["task-009"],"accepted_task_lines":[]},{"scope":"Complete production package, Docker release and repository quality-gate integration.","pending_task_ids":["task-010"],"accepted_task_lines":[]},{"scope":"Close residual per-page and package lifecycle proof gaps and run final exact-state validation.","pending_task_ids":["task-011"],"accepted_task_lines":[]}],"planner_note":"The trusted checkpoint preserves tasks 001, 003, 004, 005, 006, 006A, 007A and 007B exactly as accepted. Task 008A remains the first unchecked line and keeps the same task identity, todo wording and revision lineage; all four unaccepted candidate origins required by the baseline are retained. The latest candidate correctly closes the malformed recognized no-op gap and reports 30 focused adapter tests passing, but independent review found that relationship notifications still emit identity invalidations for projections they did not change: ConversationFollow emits a conversation identity, and Membership and GroupMembership emit a Person identity. Direct inspection also confirms ConversationGroupAccess emits an unchanged Group identity, both accepted queries register producerless generic fallback interests, and conversation detail retains two producerless broad follow interests. This bounded revision aligns those mappings and interests with the corrected matrix and adds loader-count proof that unrelated queries are not reread. No todo edit or semantic split is needed. The only approved acceptance scenario is already accepted and green; this adapter/query-vocabulary recovery has no appropriate new agreed scenario, so scenario_focus is null and focused technical proof is used."},"planner_result":{"schema_version":1,"plan_path":"docs/iterations/067-live-projection-queries/plan.md","todo_path":"docs/iterations/067-live-projection-queries/todo.md","source_baseline":"e881b12146435be4021c60cae3c5bab1647f6df7","decision":"ready"},"current_worker_packet":{"schema_version":1,"packet_id":"task-008a-e881b12-isolation-vocabulary-revision-5","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.","attempt":"revision","plan_path":"docs/iterations/067-live-projection-queries/plan.md","todo_path":"docs/iterations/067-live-projection-queries/todo.md","source_baseline":"e881b12146435be4021c60cae3c5bab1647f6df7","outcome":"Align committed-read-model invalidations and accepted consumer interests with actual changed projection dependencies so member-specific or cross-club relationship changes do not reread unrelated queries, while removing producerless fallback vocabulary and retaining every required exact, collection, authorization and evidenced broad scope.","scope":["Remove `{:conversation, conversation_id}` from explicit and auto-following ConversationFollow invalidations; retain only the exact `{:conversation_follow, conversation_id, member_id}` relationship key, while preserving complete false-auto-follow `:ignore` behavior and required-identity validation.","Remove `{:person, person_id}` from Membership invalidations because membership events do not change the Person projection; retain `{:club_members, club_id}`, `{:membership, membership_id}` and `{:person_clubs, person_id}` for the changed collection, exact relationship and active-club authority dependency.","Remove `{:person, person_id}` from GroupMembership invalidations; retain `{:group_members, group_id}`, `{:person_groups, club_id, person_id}` and `{:group_participation, club_id, group_id, person_id}`.","Remove the unchanged `{:group, group_id}` identity from ConversationGroupAccess invalidations while retaining the group-conversation collection, exact access relationship and conversation-wide authorization invalidation.","Remove the dashboard and conversation-detail `@fallback_families`, `fallback_interests/1` helpers and all `{:fallback, ...}` interests because the corrected source emits only concrete keys, `:ignore`, or a visible contract violation.","Remove conversation detail's producerless `{:conversation_follows, conversation_id}` and `{:member_conversation_follows, person_id}` interests while retaining its exact current-member follow interest.","Correct only the affected Membership, GroupMembership, ConversationFollow and ConversationGroupAccess rows of the migration matrix so documented logical interests match the actual changed projections and precise adapter output.","Update exact invalidation-set and query-interest tests, and add Binding-level loader-count tests proving a same-conversation/different-member follow change and same-Person/different-club Membership or GroupMembership changes do not reread an unrelated registration.","Include a loader-count isolation case for ConversationGroupAccess on an unselected represented group, while proving a relevant exact access or conversation-wide authorization change still refreshes where required.","Preserve all previously reviewed envelope validation, eleven-family dispatch, valid no-op handling, retained-row legacy MemberRemoved recovery, contract-violation lifecycle behavior, MessageSent club-conversation scope, role/permission fan-out and independent delivery-projector convergence."],"scope_exclusions":["Do not modify `packages/live_query/**` or broaden the frozen generic Query, Source or Binding API.","Do not change LiveViews, routes, templates, components, forms, navigation, commands, event structs, projectors, projection schemas, publishers or read APIs.","Do not remove `{:conversation, conversation_id}` from ConversationGroupAccess; that key preserves conversation-wide fresh authorization when any access relationship for the conversation changes.","Do not alter role/permission mappings, MessageSent's evidenced club-conversation collection, delivery mappings, legacy MemberRemoved retained-row recovery, complete-envelope gating or stable contract-violation behavior.","Do not introduce new broad, global, family fallback, projection-row lookup or changes-map recovery behavior.","Do not implement tasks 008B through 011 or migrate another LiveView.","Do not edit the approved plan, todo, ADRs, extraction contract or acceptance feature; migration-matrix edits are limited to reconciling the four affected adapter rows.","Do not reactivate or rerun the already-green Bob-sees-Alice scenario.","Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped repository suite; the deterministic iteration gate owns full validation.","Do not mark task 008A complete; fresh independent review owns acceptance."],"references":[{"path":"docs/iterations/067-live-projection-queries/plan.md","facts":"The approved technical model requires refreshing only affected query results, exact collection and relationship scopes where available, evidenced broader invalidation only for valid events lacking exact scope, and no silent fallback for malformed recognized notifications."},{"path":"docs/iterations/067-live-projection-queries/todo.md","facts":"Task 008A is the first unchecked obligation and owns exact scoped matching, unrelated-projector isolation, actual projector/event-family auditing, corrected matrix fallbacks, focused proof and fresh independent review."},{"path":"docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json","facts":"The binding checkpoint is current HEAD and requires preservation of all four task-008a review-revise candidate origins, including the latest no-op identity revision."},{"path":"docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json","facts":"The latest worker changed only the adapter and its focused tests, reported 30 adapter tests passing, and correctly moved required-field validation ahead of false-auto-follow and EmailDeliveryOpened no-op decisions."},{"path":"docs/iterations/067-live-projection-queries/.delivery/latest-review.json","facts":"Independent review accepted the no-op identity correction but requires removal of conversation-wide follow and cross-scope Person invalidations, loader-count isolation proof, and completion of the consumer fallback audit."},{"path":"docs/iterations/067-live-projection-queries/migration-matrix.md","facts":"The current adapter rows still describe Person identity for Membership and GroupMembership, conversation identity for ConversationFollow, and Group identity for ConversationGroupAccess; those claims must be reconciled with the projections actually changed."},{"path":"docs/iterations/067-live-projection-queries/extraction-contract.md","facts":"The frozen package contract uses opaque exact source matching, refreshes only matching registrations, and atomically replaces a query's result and interests; this revision changes only app-owned vocabulary and proof."},{"path":"docs/adr/0021-publish-committed-read-model-changes.md","facts":"Projectors publish their source event and committed changes after projection transactions, providing the boundary from which the app adapter must derive precise affected read-model keys."},{"path":"docs/adr/0027-use-live-projection-queries-for-liveview-reads.md","facts":"The accepted architecture says a relevant committed change triggers a fresh authorized read, while imprecise invalidation creates unnecessary database work; Memba mapping remains in the app."},{"path":"web/lib/memba_web/live_query/memba_read_model_source.ex","facts":"Current Membership and GroupMembership mappings emit `{:person, person_id}`, current ConversationFollow mappings emit both exact follow and conversation identity, and ConversationGroupAccess emits an unchanged Group identity. Matching itself is strict tuple equality and the source emits no generic fallback tuple."},{"path":"web/test/memba_web/live_query/memba_read_model_source_test.exs","facts":"The focused suite currently asserts the over-broad invalidation sets and already contains Binding/query helpers suitable for direct loader-count proof without relying on unchanged rendered HTML."},{"path":"web/lib/memba_web/member_dashboard_query.ex","facts":"The dashboard registers concrete collection, represented-identity and authorization interests but also appends sixteen producerless global and club-scoped fallback interests from eight fallback families."},{"path":"web/test/memba_web/member_dashboard_query_test.exs","facts":"The dashboard query test enumerates required concrete interests and can assert that no `{:fallback, ...}` interest remains after cleanup."},{"path":"web/lib/memba_web/member_message_detail_query.ex","facts":"Conversation detail registers the required exact current-member follow key, but also appends sixteen generic fallback interests and two broad follow interests for which the source has no producer."},{"path":"web/test/memba_web/member_message_detail_query_test.exs","facts":"The detail query test currently positively asserts `{:fallback, :delivery}` and both producerless broad follow interests, so it must be corrected while retaining exact conversation, access, author, follow and delivery coverage."},{"path":"web/lib/memba/membership/projectors/group_membership.ex","facts":"GroupMembership events update only the group-membership projection relationship; they do not modify a Person projection, supporting removal of the Person identity invalidation."},{"path":"web/lib/memba/messaging/projectors/conversation_follow.ex","facts":"ConversationFollow events and auto-following MessageSent update one conversation/member follow row, while false-auto-follow MessageSent is a projector no-op; the changed dependency is the exact follow relationship."},{"path":"web/lib/memba/messaging/projectors/conversation_group_access.ex","facts":"Conversation access events upsert or delete one conversation/group relationship and do not modify the Group projection; group-collection, exact-access and conversation-wide authorization keys remain sufficient."},{"path":"docs/reference/elixir-mix-tests.md","facts":"Focused process tests must avoid sleeps and process-liveness polling; direct loader counters or messages and deterministic synchronization should prove absence of an unrelated reread."},{"path":"docs/iterations/067-live-projection-queries/.delivery/wip-after.json","facts":"The iteration's sole approved acceptance scenario is already green with its prediction matched, so this technical recovery must not fabricate another scenario-first cycle."}],"constraints":["Limit changes to the app-owned adapter, the two accepted query modules, their three focused test files, and the four affected rows in `migration-matrix.md`; report an unavoidable conflict before expanding scope.","Treat projector implementation and actual query reads as ground truth: a relationship event must not emit an identity key for an unchanged projection merely because a query also represents that identity.","Keep exact tuple equality in `MembaReadModelSource.matches?/2`; solve isolation by correcting emitted invalidations and consumer interests, not by adding asymmetric wildcard matching.","Preserve `{:person_clubs, person_id}` for Membership because active-club authority genuinely changes, and preserve club/group-scoped participation keys for GroupMembership.","Preserve the exact current-member follow key and remove only conversation-wide follow invalidation; another member's follow state must not reread the open member's detail or a dashboard representing the same conversation.","For ConversationGroupAccess, preserve `{:group_conversations, group_id}`, exact `{:conversation_access, group_id, conversation_id}` and `{:conversation, conversation_id}`; remove only the unchanged Group identity.","Remove producerless fallback and broad-follow interests rather than inventing source emissions to justify them.","Add read-count evidence at the Binding boundary: the new tests must distinguish no reread from a reread that happens to render unchanged output.","Before the initial focused red run, record a concrete expected diagnostic showing the loader count increased from one to two for an unrelated notification or that an unexpected broad/fallback tuple remained; after the correction, predict the focused commands will be green.","Use actual event structs and complete committed-change envelopes in adapter tests; do not reintroduce synthetic partial maps as valid variants.","Prepare evidence for fresh independent review and leave the todo line unchecked."],"focused_validation":["PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live_query/memba_read_model_source_test.exs","PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs"],"completion_evidence_required":["List every changed path and summarize the precise invalidation or interest removed from each.","Report the initial focused-red diagnostic and confirm it matched the predicted extra loader invocation or unexpected tuple.","Report successful exit status, test count and failure count for both focused validation commands after implementation.","Show exact invalidation sets for Membership, GroupMembership, ConversationFollow and ConversationGroupAccess after the correction.","Show loader-count evidence that same-conversation/different-member follow changes and same-Person/different-club Membership and GroupMembership changes leave the unrelated query at its initial load count.","Show loader-count evidence that access changes for an unselected represented group do not reread through an unchanged Group identity, while relevant access or conversation authorization invalidation still refreshes.","Show that both accepted queries contain no `{:fallback, ...}` interests and that conversation detail contains only the exact follow relationship it can receive from the source.","Confirm the migration-matrix rows now match actual emitted keys and distinguish changed projection identities from relationship and collection dependencies.","Confirm false-auto-follow MessageSent and EmailDeliveryOpened remain valid no-ops after complete identity validation, and malformed recognized notifications retain their stable lifecycle-visible exception behavior.","Confirm all other previously reviewed adapter behavior remains green, including complete-envelope gating, eleven-family dispatch, MessageSent's club-conversation scope, retained-row legacy recovery, role/permission fan-out and both delivery projectors.","Report `bin/mix format --check-formatted` and `git diff --check` results in the worker summary without running an unscoped repository suite.","Confirm no package, LiveView, route, template, form, event, projector, projection schema, publisher, approved plan, todo, ADR or acceptance feature changed."],"candidate_origins":[{"base_sha":"0b2466fc574c2110b09a5019d8c280658d035cd0","head_sha":"2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b","packet_id":"task-008a-0b2466f-adapter-matrix-1","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."},{"base_sha":"5a0be69826405522dbbc727b73e11cb5eac89784","head_sha":"b9987229e5bdcd20e7e0314a32d616766d88f16c","packet_id":"task-008a-5a0be69-projector-contract-revision-2","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."},{"base_sha":"59e50fa26a52a8d3376a356546c3ba9309d79681","head_sha":"c1af0f426158cc35e0e5c10c866a3d010ed9166a","packet_id":"task-008a-59e50fa-contract-lifecycle-revision-3","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."},{"base_sha":"0c2dbfb5cb423a4f20f8766e2826f156a3655c60","head_sha":"8c4a977c448be4962a0fa520ab81f15319d840a3","packet_id":"task-008a-0c2dbfb-noop-identity-revision-4","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."}],"scenario_focus":null}} |
| output.validate_task | {"decision":"revise","task":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.","reason":"The current packet and ready_for_review result match this first unchecked todo, the worktree is clean, and revision 5 closes the previously reported fallback, malformed-event, and four-family isolation gaps. However, affected-query isolation is still incomplete. Role permission and assignment/removal events emit {:role, role_id} even though those projectors do not change the Role projection; the matrix and tests currently encode that unchanged-identity invalidation, contrary to the packet rule for relationship events. MemberMessageDetailQuery also registers {:club_members, club_id} and {:group_members, group_id}, so another member changing in the same club or audience group rereads an unrelated open detail even though exact membership/person-clubs/group-participation interests cover the current actor. Revise the Role mapping/matrix/tests, remove those two detail interests, and add Binding loader-count proof for unrelated and relevant cases; the next repair packet must explicitly reconcile its current preserve-role exclusion with this correction. The recorded focused runs are current, and review-side scoped confirmation passed 34/0 and 8/0 while investigating isolation, but those tests presently assert the broad keys and therefore do not establish the required behavior; no full suite was run."} |
| required_repairs | ["Audit the full producer → invalidation → query-interest mapping, including Role and conversation detail.","Remove the prior “do not alter role mappings” exclusion.","Add loader-count tests proving relevant refreshes and unrelated non-refreshes."] |
| task_id | task-008a |


Summarize this Slack clarification as the final run output. Include Matt's agreed guidance, concrete examples, any unresolved business or architectural questions, the selected task and validator finding, and a safe proposed next step. Do not edit files, approve an incomplete candidate, publish, or launch recovery. A separate explicit decision and validation are required before resuming implementation from the saved checkpoint.
