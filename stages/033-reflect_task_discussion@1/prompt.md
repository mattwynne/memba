Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01M41DJ0E4FYMRSH13KGBRRWKR
Pipeline progress: 31 of 48 stages completed

## Stage: verify_source_head
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-implementation/scripts/verify_source_head.sh 'e0f66950862b362ad6f255cd75c173031a4af02c'`
- Output:
  ```
  Expected source HEAD: e0f66950862b362ad6f255cd75c173031a4af02c
  Actual source HEAD:   e0f66950862b362ad6f255cd75c173031a4af02c
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
  ✓ Configuring shell in 8.50ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 296µs (cached)
  ✓ Loading tasks in 1.55ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 16.6ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.7ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 16.7µs (no command)
  ✓ Running tasks in 28.8ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:2] [ds:8:2:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  Entering Memba devenv for root=/repos/mattwynne/memba sha=7dd5a28.
  • Validating lock
  ✓ Validating lock in 20.1ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 2.31ms
  • Evaluating shell
  ✓ Evaluating shell in 1.06ms (cached)
  ✓ Configuring shell in 5.51ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 153µs (cached)
  ✓ Loading tasks in 1.17ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.1ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.4ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 71.2µs (no command)
  ✓ Running tasks in 22.1ms
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
  Tracked repository file writability OK (2462 regular files checked).
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
  ✓ Configuring cachix in 3.12ms
  • Configuring shell
  • Evaluating shell
  ✓ Evaluating shell in 3.05s
  ✓ Configuring shell in 3.36s
  • Evaluating Nix
  ✓ Evaluating Nix in 3.81ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 1.22ms
  ✓ Loading tasks in 1.36ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 8.29ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.2ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 5.09µs (no command)
  ✓ Running tasks in 20.3ms
  • Running processes
  • Evaluating Nix
  ✓ Evaluating Nix in 1.99ms
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
  HEAD: fb04a28 fabro(01M41DJ0E4FYMRSH13KGBRRWKR): preflight_sandbox (succeeded)
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
  Delivery planner baseline captured from b9987229e5bdcd20e7e0314a32d616766d88f16c in docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json
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
  >     "source_baseline": "59e50fa26a52a8d3376a356546c3ba9309d79681",
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
  >         "status": "prepared",
  >         "origin": "Adapter-completion portion of approved implementation step 4, corrected after review to distinguish valid broad scopes from malformed known notifications.",
  >         "coverage": [
  >           "All actual event families published by the eleven in-scope projectors",
  >           "Exact collection, identity and authorization invalidations for valid complete events",
  >           "Only evidenced broader scopes for valid events, including MessageSent club-conversation scope and role/permission fan-out",
  >           "Legacy MemberRemoved scope recovery from the retained membership row",
  >           "A stable application-owned exception for recognized malformed or unsupported projector/event pairings",
  >           "The same visible contract-violation behavior during ordinary notification handling and bind-window reconciliation",
  >           "Full publisher-envelope validation with structurally incomplete envelopes ignored",
  >           "ConversationFollow MessageSent true/default behavior and false no-op behavior",
  >           "Replay-only EmailDeliveryOpened no-op behavior for both delivery projectors",
  >           "Exact tuple matching and unrelated-projector isolation",
  >           "An eleven-row projector/event-family coverage table and fresh independent review"
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
  >           }
  >         ]
  >       },
  >       {
  >         "task_id": "task-008b",
  >         "todo_line": "- [ ] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
  >         "status": "pending",
  >         "origin": "Group-creation query portion of approved implementation step 4 and the former broad task 008.",
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
  >         "status": "pending",
  >         "origin": "Settings-query portion of approved implementation step 4 and the former broad task 008.",
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
  >         "status": "pending",
  >         "origin": "Message-compose query portion of approved implementation step 4 and the former broad task 008.",
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
  >         "status": "pending",
  >         "origin": "Delivery-detail query portion of approved implementation step 4 and the former broad task 008.",
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
  >         "status": "pending",
  >         "origin": "Member-invitation query portion of approved implementation step 4 and the former broad task 008.",
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
  >         "status": "pending",
  >         "origin": "Approved implementation step 5 after dashboard and conversation detail served as the accepted pre-freeze consumers.",
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
  >         "status": "pending",
  >         "origin": "Approved implementation step 6.",
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
  >         "status": "pending",
  >         "origin": "Remainder of approved implementation step 7 after the stakeholder scenario and committed-projector open-LiveView proof were split into accepted task 006A.",
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
  >       }
  >     ],
  >     "coverage_map": [
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, proof inventory and explicit exclusions."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted dashboard query boundary, fresh-authority prerequisite, coherent dashboard assign and connected subscribe-before-read ordering."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted provisional lifecycle, matching, route rebind, bind-window reconciliation, access-error and reconnect contract."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted dashboard binding, scoped invalidation and open-dashboard vertical behavior proof."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted conversation-detail binding, multi-projector convergence, fresh-access proof and frozen extraction contract."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted stakeholder scenario and committed-membership-projector-to-open-member-LiveView proof."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted standalone generic package and package-owned lifecycle, matching, race and cleanup tests."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted package adoption by dashboard and conversation detail while retaining application-owned policy."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-008a"
  >         ],
  >         "scope": "Correct and prove the app-owned notification adapter against actual projector/event families, evidenced broad scopes, no-op publications, full envelopes and lifecycle-visible malformed-event contract violations."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-008b",
  >           "task-008c",
  >           "task-008d",
  >           "task-008e",
  >           "task-008f"
  >         ],
  >         "scope": "Introduce the five remaining fresh-authorized one-result query boundaries from existing read APIs without absorbing transient LiveView state."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-009"
  >         ],
  >         "scope": "Migrate the five remaining member LiveViews while preserving routes, access transitions, transient state, navigation, UI and delivery/conversation convergence."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-010"
  >         ],
  >         "scope": "Complete production package, Docker release and repository quality-gate integration."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-011"
  >         ],
  >         "scope": "Close residual per-page and package lifecycle proof gaps and run final exact-state validation."
  >       }
  >     ],
  >     "planner_note": "The trusted checkpoint preserves tasks 001, 003, 004, 005, 006, 006A, 007A and 007B exactly as accepted. Task 008A remains the first unchecked line and retains both rejected candidate origins under the same task identity. The latest candidate corrected event-family dispatch, false auto-follow, replay-only delivery events and unsupported synthetic fallbacks, but independent review found that returning {:error, ...} violates the frozen Source classifier contract: ordinary handling wraps it as invalid_classification and bind-window reconciliation drops it. This revision adds a stable application-owned exception path, complete publisher-envelope filtering, focused proof through both binding paths and the omitted eleven-row coverage table without changing the generic package. No todo edit or further split is needed because these are bounded review gaps within task 008A. The sole approved acceptance scenario is already accepted and green; this adapter lifecycle revision has no separate agreed scenario, so scenario_focus is null and focused technical proof is used."
  >   },
  >   "planner_result": {
  >     "schema_version": 1,
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "59e50fa26a52a8d3376a356546c3ba9309d79681",
  >     "decision": "ready"
  >   },
  >   "current_worker_packet": {
  >     "schema_version": 1,
  >     "packet_id": "task-008a-59e50fa-contract-lifecycle-revision-3",
  >     "task_id": "task-008a",
  >     "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
  >     "attempt": "revision",
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "59e50fa26a52a8d3376a356546c3ba9309d79681",
  >     "outcome": "Make recognized Memba read-model publisher contract violations fail through one stable application-owned exception during both ordinary notification handling and bind-window reconciliation, while ignoring structurally incomplete outer envelopes and preserving the candidate’s corrected eleven-family invalidation behavior.",
  >     "scope": [
  >       "Add a dedicated application-owned exception module under `web/lib/memba_web/live_query/` with stable inspectable projector, source-event module and reason fields plus a deterministic message.",
  >       "Change `MembaWeb.LiveQuery.MembaReadModelSource` so recognized unsupported projector/event pairings and recognized events missing required identities raise that exception instead of returning a classifier result outside `LiveQuery.Source`’s frozen `:ignore | {:ok, invalidations}` contract.",
  >       "Require the complete publisher envelope before classification: projector, source_event, metadata and changes must all be present with the types published by `Memba.ReadModelChanges`; structurally incomplete or mistyped outer envelopes remain ignored.",
  >       "Keep complete notifications for unrelated projector modules ignored, while complete notifications for recognized projectors with unsupported event types or missing inner identities fail visibly.",
  >       "Update the existing adapter tests so all malformed-current-event, unrecoverable legacy MemberRemoved, malformed delivery, unsupported pairing and missing-identity cases assert the same stable application exception and its exact fields.",
  >       "Add focused ordinary-lifecycle proof by binding a minimal query to the Memba source, passing a complete malformed Membership notification through `LiveQuery.Binding.handle_notification/2`, and proving the application exception is raised rather than wrapped as invalid_classification.",
  >       "Add focused bind-window proof with a connected test socket and a query load that queues the same complete malformed Membership notification during its first read, proving reconciliation raises the same application exception instead of silently discarding it.",
  >       "Add focused outer-envelope cases for missing metadata, missing changes, non-map metadata and non-map changes, retaining existing unrelated-projector and unrelated-message isolation.",
  >       "Preserve the current candidate’s corrected actual-event dispatch, exact and evidenced broad invalidations, legacy retained-row recovery, false auto-follow no-op, EmailDeliveryOpened no-op and exact tuple matching.",
  >       "Return an eleven-row completion-evidence table covering Club, Membership, Person, Group, GroupMembership, Role, Message, ConversationGroupAccess, ConversationFollow, MemberEmailDelivery and MembaStaffEmailDelivery."
  >     ],
  >     "scope_exclusions": [
  >       "Do not modify `packages/live_query/**`; the generic Source and Binding contracts remain frozen.",
  >       "Do not modify the dashboard or conversation-detail LiveViews, query modules or accepted query-interest vocabulary.",
  >       "Do not add tasks 008B through 008F query modules or migrate any remaining LiveView.",
  >       "Do not change domain events, projectors, projection schemas, read APIs, routes, templates, forms or UI behavior.",
  >       "Do not edit the approved plan, todo, migration matrix, ADRs, acceptance feature or package documentation.",
  >       "Do not restore synthetic partial-event, arbitrary committed-change, delivery-row-lookup or global fallback behavior.",
  >       "Do not reactivate or rerun the already-green Bob-sees-Alice acceptance scenario.",
  >       "Do not perform tasks 010 or 011 and do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped repository suite.",
  >       "Do not mark task 008A complete; deterministic independent review owns acceptance."
  >     ],
  >     "references": [
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/plan.md",
  >         "facts": "The approved technical model permits broad invalidation only for valid events that genuinely lack exact scope and requires known malformed Membership notifications with unrecoverable Person identity to surface a contract violation rather than refresh a partial, club-wide or global scope."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/todo.md",
  >         "facts": "Task 008A is the first unchecked obligation and owns actual projector-family coverage, exact matching, visible malformed-Membership handling, fallback auditing and fresh independent review."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
  >         "facts": "The trusted baseline requires preservation of both task-008a candidate origins and binds this new packet to current HEAD rather than the artifact’s predecessor pre_planner_head."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
  >         "facts": "The latest candidate reported 25 adapter tests and 8 accepted query-vocabulary tests passing and correctly narrowed actual event dispatch, legacy recovery and projector no-ops, but it returned contract violations as an out-of-contract classifier tuple and omitted the required coverage table."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
  >         "facts": "Independent review requires one application-owned stable failure path visible during ordinary handling and bind-window reconciliation, full-envelope checks for metadata and changes, focused lifecycle proof, and the omitted eleven-row projector/event table."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
  >         "facts": "The normative matrix defines the eleven projector families, exact and legitimate broad interests, false auto-follow and replay-only opened no-ops, retained-row legacy MemberRemoved recovery, and the distinction between malformed payloads and valid broader event shapes."
  >       },
  >       {
  >         "path": "docs/adr/0021-publish-committed-read-model-changes.md",
  >         "facts": "The committed publisher envelope has four fields—projector, source_event, metadata and changes—and is emitted only after the projection transaction commits."
  >       },
  >       {
  >         "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
  >         "facts": "Memba owns notification translation and authorization policy while the generic local package owns only the reusable opaque query-binding mechanism."
  >       },
  >       {
  >         "path": "web/lib/memba/read_model_changes.ex",
  >         "facts": "`publish/4` always broadcasts projector, source_event, metadata and changes; its message type requires a module, event struct and map values for metadata and changes."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
  >         "facts": "Current classification accepts envelopes containing only projector and source_event, and `contract_violation/3` returns `{:error, ...}` even though the generic classifier contract does not allow that result."
  >       },
  >       {
  >         "path": "web/test/memba_web/live_query/memba_read_model_source_test.exs",
  >         "facts": "The focused suite covers the corrected eleven-family mappings but currently asserts out-of-contract error tuples directly and lacks Binding-level ordinary and bind-window visibility proof plus missing-metadata/missing-changes cases."
  >       },
  >       {
  >         "path": "packages/live_query/lib/live_query/source.ex",
  >         "facts": "The frozen generic classifier type is exactly `:ignore | {:ok, [term()]}`; no application-specific error result belongs in this package API."
  >       },
  >       {
  >         "path": "packages/live_query/lib/live_query/binding.ex",
  >         "facts": "Ordinary handling wraps any classifier result outside the frozen contract as invalid_classification, while bind-window reconciliation currently ignores every result except `{:ok, list}`; exceptions are not rescued by either path."
  >       },
  >       {
  >         "path": "packages/live_query/test/live_query/binding_test.exs",
  >         "facts": "Existing generic tests show how to create a connected socket and queue a notification during the first query read, providing the deterministic pattern for adapter-level bind-window proof without sleeps."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live/member_dashboard_live.ex",
  >         "facts": "The accepted dashboard consumer routes committed read-model notifications through `Binding.handle_notification/2`; an application classifier exception therefore remains visible through its ordinary LiveView lifecycle without a consumer change."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live/member_message_live/show.ex",
  >         "facts": "The accepted conversation-detail consumer also routes committed read-model notifications through `Binding.handle_notification/2`; no special LiveView error tuple or package API extension is needed."
  >       },
  >       {
  >         "path": "docs/reference/elixir-mix-tests.md",
  >         "facts": "Use a separate module file for the exception, keep process tests deterministic without sleeps or polling, and use supervised cleanup for any started process."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
  >         "facts": "The iteration’s sole approved acceptance scenario is already green with its prediction matched, so this technical revision must not fabricate another scenario-first cycle."
  >       }
  >     ],
  >     "constraints": [
  >       "Limit implementation changes to `web/lib/memba_web/live_query/read_model_contract_violation_error.ex`, `web/lib/memba_web/live_query/memba_read_model_source.ex` and `web/test/memba_web/live_query/memba_read_model_source_test.exs`; report an unavoidable compile conflict before expanding scope.",
  >       "Use a dedicated exception module rather than nesting another module in the adapter file.",
  >       "Keep the exception application-owned and stable: expose the projector module, source-event module and reason as inspectable fields and use a deterministic non-sensitive message.",
  >       "Do not include the full event payload in the exception; preserve the current event-module-level identity and reason.",
  >       "Require metadata and changes to be maps as defined by the actual publisher; missing or mistyped outer-envelope fields are ignored before projector dispatch.",
  >       "Once a complete envelope identifies a recognized projector, unsupported actual event pairings or missing required inner identities must raise the application exception and emit no invalidations.",
  >       "Use actual event structs and actual projector/event pairings as ground truth. Narrow maps may test malformed envelopes but must not establish invented valid event variants.",
  >       "Preserve exact tuple equality and every legitimate collection-entry/exit scope; do not replace precise invalidations with unconditional global invalidation.",
  >       "Keep the retained Membership projection row as the only evidenced legacy MemberRemoved recovery source and do not restore arbitrary changes-map recovery.",
  >       "Keep false `sender_follows_conversation` and replay-only `EmailDeliveryOpened` publications ignored.",
  >       "Both delivery projectors must retain identical exact keys for the five state-changing delivery event families.",
  >       "Use deterministic Binding-level tests with a connected socket and a queued mailbox notification; do not use sleeps or liveness polling.",
  >       "Prepare evidence for fresh independent review and leave the todo line unchecked."
  >     ],
  >     "focused_validation": [
  >       "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live_query/memba_read_model_source_test.exs",
  >       "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs"
  >     ],
  >     "completion_evidence_required": [
  >       "List every changed path and summarize the exception, envelope-classifier and focused-test changes.",
  >       "Report successful exit status and test count for the focused adapter command.",
  >       "Report successful exit status and test count for the accepted dashboard and conversation-detail query-vocabulary regression command.",
  >       "Show that a complete malformed Membership notification raises the same stable application exception, with exact fields, both through ordinary `Binding.handle_notification/2` and bind-window reconciliation.",
  >       "Show that notifications missing metadata or changes, or carrying non-map metadata or changes, return `:ignore` and do not reach recognized-projector dispatch.",
  >       "Show that unrelated projectors and unrelated messages remain ignored while a complete recognized unsupported pairing raises the application exception.",
  >       "Show that a Membership notification with club scope and unrecoverable Person identity raises the contract exception and emits no scoped or global Membership fallback.",
  >       "Confirm the corrected candidate behavior remains intact: retained-row-only legacy MemberRemoved recovery, exact tuple isolation, false auto-follow no-op, both delivery contributors’ exact five-family mappings and replay-only EmailDeliveryOpened no-op.",
  >       "Provide a concise eleven-row table naming each in-scope projector family, its actual source-event families, exact or evidenced broad invalidations, no-op events, any evidenced recovery source, and malformed/unsupported behavior.",
  >       "Confirm no file under `packages/live_query`, no accepted LiveView/query consumer, no projector/event/schema, and no plan, todo, matrix, ADR or feature file changed.",
  >       "Report formatting and `git diff --check` results in the worker summary without running an unscoped repository suite.",
  >       "Report any actual publisher shape that conflicts with the complete-envelope or exception contract and leave the todo unchecked if such a conflict remains."
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
  > Implemented packet `task-008a-59e50fa-contract-lifecycle-revision-3` with result `ready_for_review`.
  > 
  > Changes:
  > 
  > - Added the application-owned [`ReadModelContractViolationError`](/workspace/memba/web/lib/memba_web/live_query/read_model_contract_violation_error.ex:1), exposing projector, source-event module, and reason without retaining event payloads.
  > - Updated [`MembaReadModelSource`](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex:103) to require complete, correctly typed publisher envelopes and raise the stable exception for recognized malformed or unsupported events.
  > - Expanded [`memba_read_model_source_test.exs`](/workspace/memba/web/test/memba_web/live_query/memba_read_model_source_test.exs:107) with ordinary `Binding.handle_notification/2`, bind-window reconciliation, malformed-envelope, and exception field/message coverage.
  > - Wrote the required result artifact, including the eleven-projector-family evidence table, to [`latest-worker-result.json`](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1).
  > 
  > Validation passed:
  > 
  > - Focused adapter suite: 28 tests, 0 failures.
  > - Dashboard and conversation-detail query regressions: 8 tests, 0 failures.
  > - Formatting check passed.
  > - `git diff --check` passed.
  > - Generic package boundary check passed.
  > - No unresolved items or publisher-envelope conflicts found.
  > 
  > Task 008A remains unchecked as required. I did not run `dev check` or rerun the acceptance scenario because this packet explicitly reserves the full gate for the deterministic workflow node.

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
  > {"decision":"revise","task":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.","reason":"The current packet matches the first unchecked todo and the matching ready_for_review result, retains both prior candidate origins, stays within its three permitted implementation/test paths, and leaves the todo and acceptance features unchanged. Most prior gaps are closed: complete-envelope gating, stable application exception fields/message, ordinary and bind-window exception propagation, actual eleven-family dispatch, retained-row-only legacy MemberRemoved recovery, exact matching, false auto-follow no-op, and replay-only EmailDeliveryOpened no-op. One contract gap remains: false-auto-follow MessageSent returns :ignore before validating club_id/message_id/sender_id, and EmailDeliveryOpened returns :ignore before validating message_id/delivery_id. Consequently malformed recognized no-op events are silently ignored, contrary to the packet rule that recognized events missing required inner identities raise ReadModelContractViolationError and contrary to the worker table's malformed-event claim. Validate required identities before returning :ignore and add focused malformed-no-op tests for false auto-follow and EmailDeliveryOpened through both delivery projectors. Recorded validation passed 28 adapter and 8 query-vocabulary tests with exit 0; a supplementary current-HEAD rerun was used to determine whether existing coverage exposed this suspected path and also passed, confirming the gap is untested. No full suite or dev check was run."}

## Stage: apply_task_verdict
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/apply_task_verdict.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Task revise: - [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.
  The current packet matches the first unchecked todo and the matching ready_for_review result, retains both prior candidate origins, stays within its three permitted implementation/test paths, and leaves the todo and acceptance features unchanged. Most prior gaps are closed: complete-envelope gating, stable application exception fields/message, ordinary and bind-window exception propagation, actual eleven-family dispatch, retained-row-only legacy MemberRemoved recovery, exact matching, false auto-follow no-op, and replay-only EmailDeliveryOpened no-op. One contract gap remains: false-auto-follow MessageSent returns :ignore before validating club_id/message_id/sender_id, and EmailDeliveryOpened returns :ignore before validating message_id/delivery_id. Consequently malformed recognized no-op events are silently ignored, contrary to the packet rule that recognized events missing required inner identities raise ReadModelContractViolationError and contrary to the worker table's malformed-event claim. Validate required identities before returning :ignore and add focused malformed-no-op tests for false auto-follow and EmailDeliveryOpened through both delivery projectors. Recorded validation passed 28 adapter and 8 query-vocabulary tests with exit 0; a supplementary current-HEAD rerun was used to determine whether existing coverage exposed this suspected path and also passed, confirming the gap is untested. No full suite or dev check was run.
  {"preferred_next_label": "revise"}
  ```

## Stage: task_escalation
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/escalate_task_review.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Validator's current finding for - [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.: The current packet matches the first unchecked todo and the matching ready_for_review result, retains both prior candidate origins, stays within its three permitted implementation/test paths, and leaves the todo and acceptance features unchanged. Most prior gaps are closed: complete-envelope gating, stable application exception fields/message, ordinary and bind-window exception propagation, actual eleven-family dispatch, retained-row-only legacy MemberRemoved recovery, exact matching, false auto-follow no-op, and replay-only EmailDeliveryOpened no-op. One contract gap remains: false-auto-follow MessageSent returns :ignore before validating club_id/message_id/sender_id, and EmailDeliveryOpened returns :ignore before validating message_id/delivery_id. Consequently malformed recognized no-op events are silently ignored, contrary to the packet rule that recognized events missing required inner identities raise ReadModelContractViolationError and contrary to the worker table's malformed-event claim. Validate required identities before returning :ignore and add focused malformed-no-op tests for false auto-follow and EmailDeliveryOpened through both delivery projectors. Recorded validation passed 28 adapter and 8 query-vocabulary tests with exit 0; a supplementary current-HEAD rerun was used to determine whether existing coverage exposed this suspected path and also passed, confirming the gap is untested. No full suite or dev check was run.
  Escalating revise after 3 revision verdict(s) for task-008a.
  {"preferred_next_label": "discuss"}
  ```

## Stage: before_delivery_planner
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py before-planner 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Delivery planner baseline captured from b9987229e5bdcd20e7e0314a32d616766d88f16c in docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json
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
  >     "source_baseline": "59e50fa26a52a8d3376a356546c3ba9309d79681",
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
  >         "status": "prepared",
  >         "origin": "Adapter-completion portion of approved implementation step 4, corrected after review to distinguish valid broad scopes from malformed known notifications.",
  >         "coverage": [
  >           "All actual event families published by the eleven in-scope projectors",
  >           "Exact collection, identity and authorization invalidations for valid complete events",
  >           "Only evidenced broader scopes for valid events, including MessageSent club-conversation scope and role/permission fan-out",
  >           "Legacy MemberRemoved scope recovery from the retained membership row",
  >           "A stable application-owned exception for recognized malformed or unsupported projector/event pairings",
  >           "The same visible contract-violation behavior during ordinary notification handling and bind-window reconciliation",
  >           "Full publisher-envelope validation with structurally incomplete envelopes ignored",
  >           "ConversationFollow MessageSent true/default behavior and false no-op behavior",
  >           "Replay-only EmailDeliveryOpened no-op behavior for both delivery projectors",
  >           "Exact tuple matching and unrelated-projector isolation",
  >           "An eleven-row projector/event-family coverage table and fresh independent review"
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
  >           }
  >         ]
  >       },
  >       {
  >         "task_id": "task-008b",
  >         "todo_line": "- [ ] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
  >         "status": "pending",
  >         "origin": "Group-creation query portion of approved implementation step 4 and the former broad task 008.",
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
  >         "status": "pending",
  >         "origin": "Settings-query portion of approved implementation step 4 and the former broad task 008.",
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
  >         "status": "pending",
  >         "origin": "Message-compose query portion of approved implementation step 4 and the former broad task 008.",
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
  >         "status": "pending",
  >         "origin": "Delivery-detail query portion of approved implementation step 4 and the former broad task 008.",
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
  >         "status": "pending",
  >         "origin": "Member-invitation query portion of approved implementation step 4 and the former broad task 008.",
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
  >         "status": "pending",
  >         "origin": "Approved implementation step 5 after dashboard and conversation detail served as the accepted pre-freeze consumers.",
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
  >         "status": "pending",
  >         "origin": "Approved implementation step 6.",
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
  >         "status": "pending",
  >         "origin": "Remainder of approved implementation step 7 after the stakeholder scenario and committed-projector open-LiveView proof were split into accepted task 006A.",
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
  >       }
  >     ],
  >     "coverage_map": [
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, proof inventory and explicit exclusions."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted dashboard query boundary, fresh-authority prerequisite, coherent dashboard assign and connected subscribe-before-read ordering."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted provisional lifecycle, matching, route rebind, bind-window reconciliation, access-error and reconnect contract."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted dashboard binding, scoped invalidation and open-dashboard vertical behavior proof."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted conversation-detail binding, multi-projector convergence, fresh-access proof and frozen extraction contract."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted stakeholder scenario and committed-membership-projector-to-open-member-LiveView proof."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted standalone generic package and package-owned lifecycle, matching, race and cleanup tests."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted package adoption by dashboard and conversation detail while retaining application-owned policy."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-008a"
  >         ],
  >         "scope": "Correct and prove the app-owned notification adapter against actual projector/event families, evidenced broad scopes, no-op publications, full envelopes and lifecycle-visible malformed-event contract violations."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-008b",
  >           "task-008c",
  >           "task-008d",
  >           "task-008e",
  >           "task-008f"
  >         ],
  >         "scope": "Introduce the five remaining fresh-authorized one-result query boundaries from existing read APIs without absorbing transient LiveView state."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-009"
  >         ],
  >         "scope": "Migrate the five remaining member LiveViews while preserving routes, access transitions, transient state, navigation, UI and delivery/conversation convergence."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-010"
  >         ],
  >         "scope": "Complete production package, Docker release and repository quality-gate integration."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-011"
  >         ],
  >         "scope": "Close residual per-page and package lifecycle proof gaps and run final exact-state validation."
  >       }
  >     ],
  >     "planner_note": "The trusted checkpoint preserves tasks 001, 003, 004, 005, 006, 006A, 007A and 007B exactly as accepted. Task 008A remains the first unchecked line and retains both rejected candidate origins under the same task identity. The latest candidate corrected event-family dispatch, false auto-follow, replay-only delivery events and unsupported synthetic fallbacks, but independent review found that returning {:error, ...} violates the frozen Source classifier contract: ordinary handling wraps it as invalid_classification and bind-window reconciliation drops it. This revision adds a stable application-owned exception path, complete publisher-envelope filtering, focused proof through both binding paths and the omitted eleven-row coverage table without changing the generic package. No todo edit or further split is needed because these are bounded review gaps within task 008A. The sole approved acceptance scenario is already accepted and green; this adapter lifecycle revision has no separate agreed scenario, so scenario_focus is null and focused technical proof is used."
  >   },
  >   "planner_result": {
  >     "schema_version": 1,
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "59e50fa26a52a8d3376a356546c3ba9309d79681",
  >     "decision": "ready"
  >   },
  >   "current_worker_packet": {
  >     "schema_version": 1,
  >     "packet_id": "task-008a-59e50fa-contract-lifecycle-revision-3",
  >     "task_id": "task-008a",
  >     "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
  >     "attempt": "revision",
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "59e50fa26a52a8d3376a356546c3ba9309d79681",
  >     "outcome": "Make recognized Memba read-model publisher contract violations fail through one stable application-owned exception during both ordinary notification handling and bind-window reconciliation, while ignoring structurally incomplete outer envelopes and preserving the candidate’s corrected eleven-family invalidation behavior.",
  >     "scope": [
  >       "Add a dedicated application-owned exception module under `web/lib/memba_web/live_query/` with stable inspectable projector, source-event module and reason fields plus a deterministic message.",
  >       "Change `MembaWeb.LiveQuery.MembaReadModelSource` so recognized unsupported projector/event pairings and recognized events missing required identities raise that exception instead of returning a classifier result outside `LiveQuery.Source`’s frozen `:ignore | {:ok, invalidations}` contract.",
  >       "Require the complete publisher envelope before classification: projector, source_event, metadata and changes must all be present with the types published by `Memba.ReadModelChanges`; structurally incomplete or mistyped outer envelopes remain ignored.",
  >       "Keep complete notifications for unrelated projector modules ignored, while complete notifications for recognized projectors with unsupported event types or missing inner identities fail visibly.",
  >       "Update the existing adapter tests so all malformed-current-event, unrecoverable legacy MemberRemoved, malformed delivery, unsupported pairing and missing-identity cases assert the same stable application exception and its exact fields.",
  >       "Add focused ordinary-lifecycle proof by binding a minimal query to the Memba source, passing a complete malformed Membership notification through `LiveQuery.Binding.handle_notification/2`, and proving the application exception is raised rather than wrapped as invalid_classification.",
  >       "Add focused bind-window proof with a connected test socket and a query load that queues the same complete malformed Membership notification during its first read, proving reconciliation raises the same application exception instead of silently discarding it.",
  >       "Add focused outer-envelope cases for missing metadata, missing changes, non-map metadata and non-map changes, retaining existing unrelated-projector and unrelated-message isolation.",
  >       "Preserve the current candidate’s corrected actual-event dispatch, exact and evidenced broad invalidations, legacy retained-row recovery, false auto-follow no-op, EmailDeliveryOpened no-op and exact tuple matching.",
  >       "Return an eleven-row completion-evidence table covering Club, Membership, Person, Group, GroupMembership, Role, Message, ConversationGroupAccess, ConversationFollow, MemberEmailDelivery and MembaStaffEmailDelivery."
  >     ],
  >     "scope_exclusions": [
  >       "Do not modify `packages/live_query/**`; the generic Source and Binding contracts remain frozen.",
  >       "Do not modify the dashboard or conversation-detail LiveViews, query modules or accepted query-interest vocabulary.",
  >       "Do not add tasks 008B through 008F query modules or migrate any remaining LiveView.",
  >       "Do not change domain events, projectors, projection schemas, read APIs, routes, templates, forms or UI behavior.",
  >       "Do not edit the approved plan, todo, migration matrix, ADRs, acceptance feature or package documentation.",
  >       "Do not restore synthetic partial-event, arbitrary committed-change, delivery-row-lookup or global fallback behavior.",
  >       "Do not reactivate or rerun the already-green Bob-sees-Alice acceptance scenario.",
  >       "Do not perform tasks 010 or 011 and do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped repository suite.",
  >       "Do not mark task 008A complete; deterministic independent review owns acceptance."
  >     ],
  >     "references": [
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/plan.md",
  >         "facts": "The approved technical model permits broad invalidation only for valid events that genuinely lack exact scope and requires known malformed Membership notifications with unrecoverable Person identity to surface a contract violation rather than refresh a partial, club-wide or global scope."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/todo.md",
  >         "facts": "Task 008A is the first unchecked obligation and owns actual projector-family coverage, exact matching, visible malformed-Membership handling, fallback auditing and fresh independent review."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
  >         "facts": "The trusted baseline requires preservation of both task-008a candidate origins and binds this new packet to current HEAD rather than the artifact’s predecessor pre_planner_head."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
  >         "facts": "The latest candidate reported 25 adapter tests and 8 accepted query-vocabulary tests passing and correctly narrowed actual event dispatch, legacy recovery and projector no-ops, but it returned contract violations as an out-of-contract classifier tuple and omitted the required coverage table."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
  >         "facts": "Independent review requires one application-owned stable failure path visible during ordinary handling and bind-window reconciliation, full-envelope checks for metadata and changes, focused lifecycle proof, and the omitted eleven-row projector/event table."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
  >         "facts": "The normative matrix defines the eleven projector families, exact and legitimate broad interests, false auto-follow and replay-only opened no-ops, retained-row legacy MemberRemoved recovery, and the distinction between malformed payloads and valid broader event shapes."
  >       },
  >       {
  >         "path": "docs/adr/0021-publish-committed-read-model-changes.md",
  >         "facts": "The committed publisher envelope has four fields—projector, source_event, metadata and changes—and is emitted only after the projection transaction commits."
  >       },
  >       {
  >         "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
  >         "facts": "Memba owns notification translation and authorization policy while the generic local package owns only the reusable opaque query-binding mechanism."
  >       },
  >       {
  >         "path": "web/lib/memba/read_model_changes.ex",
  >         "facts": "`publish/4` always broadcasts projector, source_event, metadata and changes; its message type requires a module, event struct and map values for metadata and changes."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
  >         "facts": "Current classification accepts envelopes containing only projector and source_event, and `contract_violation/3` returns `{:error, ...}` even though the generic classifier contract does not allow that result."
  >       },
  >       {
  >         "path": "web/test/memba_web/live_query/memba_read_model_source_test.exs",
  >         "facts": "The focused suite covers the corrected eleven-family mappings but currently asserts out-of-contract error tuples directly and lacks Binding-level ordinary and bind-window visibility proof plus missing-metadata/missing-changes cases."
  >       },
  >       {
  >         "path": "packages/live_query/lib/live_query/source.ex",
  >         "facts": "The frozen generic classifier type is exactly `:ignore | {:ok, [term()]}`; no application-specific error result belongs in this package API."
  >       },
  >       {
  >         "path": "packages/live_query/lib/live_query/binding.ex",
  >         "facts": "Ordinary handling wraps any classifier result outside the frozen contract as invalid_classification, while bind-window reconciliation currently ignores every result except `{:ok, list}`; exceptions are not rescued by either path."
  >       },
  >       {
  >         "path": "packages/live_query/test/live_query/binding_test.exs",
  >         "facts": "Existing generic tests show how to create a connected socket and queue a notification during the first query read, providing the deterministic pattern for adapter-level bind-window proof without sleeps."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live/member_dashboard_live.ex",
  >         "facts": "The accepted dashboard consumer routes committed read-model notifications through `Binding.handle_notification/2`; an application classifier exception therefore remains visible through its ordinary LiveView lifecycle without a consumer change."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live/member_message_live/show.ex",
  >         "facts": "The accepted conversation-detail consumer also routes committed read-model notifications through `Binding.handle_notification/2`; no special LiveView error tuple or package API extension is needed."
  >       },
  >       {
  >         "path": "docs/reference/elixir-mix-tests.md",
  >         "facts": "Use a separate module file for the exception, keep process tests deterministic without sleeps or polling, and use supervised cleanup for any started process."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
  >         "facts": "The iteration’s sole approved acceptance scenario is already green with its prediction matched, so this technical revision must not fabricate another scenario-first cycle."
  >       }
  >     ],
  >     "constraints": [
  >       "Limit implementation changes to `web/lib/memba_web/live_query/read_model_contract_violation_error.ex`, `web/lib/memba_web/live_query/memba_read_model_source.ex` and `web/test/memba_web/live_query/memba_read_model_source_test.exs`; report an unavoidable compile conflict before expanding scope.",
  >       "Use a dedicated exception module rather than nesting another module in the adapter file.",
  >       "Keep the exception application-owned and stable: expose the projector module, source-event module and reason as inspectable fields and use a deterministic non-sensitive message.",
  >       "Do not include the full event payload in the exception; preserve the current event-module-level identity and reason.",
  >       "Require metadata and changes to be maps as defined by the actual publisher; missing or mistyped outer-envelope fields are ignored before projector dispatch.",
  >       "Once a complete envelope identifies a recognized projector, unsupported actual event pairings or missing required inner identities must raise the application exception and emit no invalidations.",
  >       "Use actual event structs and actual projector/event pairings as ground truth. Narrow maps may test malformed envelopes but must not establish invented valid event variants.",
  >       "Preserve exact tuple equality and every legitimate collection-entry/exit scope; do not replace precise invalidations with unconditional global invalidation.",
  >       "Keep the retained Membership projection row as the only evidenced legacy MemberRemoved recovery source and do not restore arbitrary changes-map recovery.",
  >       "Keep false `sender_follows_conversation` and replay-only `EmailDeliveryOpened` publications ignored.",
  >       "Both delivery projectors must retain identical exact keys for the five state-changing delivery event families.",
  >       "Use deterministic Binding-level tests with a connected socket and a queued mailbox notification; do not use sleeps or liveness polling.",
  >       "Prepare evidence for fresh independent review and leave the todo line unchecked."
  >     ],
  >     "focused_validation": [
  >       "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live_query/memba_read_model_source_test.exs",
  >       "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs"
  >     ],
  >     "completion_evidence_required": [
  >       "List every changed path and summarize the exception, envelope-classifier and focused-test changes.",
  >       "Report successful exit status and test count for the focused adapter command.",
  >       "Report successful exit status and test count for the accepted dashboard and conversation-detail query-vocabulary regression command.",
  >       "Show that a complete malformed Membership notification raises the same stable application exception, with exact fields, both through ordinary `Binding.handle_notification/2` and bind-window reconciliation.",
  >       "Show that notifications missing metadata or changes, or carrying non-map metadata or changes, return `:ignore` and do not reach recognized-projector dispatch.",
  >       "Show that unrelated projectors and unrelated messages remain ignored while a complete recognized unsupported pairing raises the application exception.",
  >       "Show that a Membership notification with club scope and unrecoverable Person identity raises the contract exception and emits no scoped or global Membership fallback.",
  >       "Confirm the corrected candidate behavior remains intact: retained-row-only legacy MemberRemoved recovery, exact tuple isolation, false auto-follow no-op, both delivery contributors’ exact five-family mappings and replay-only EmailDeliveryOpened no-op.",
  >       "Provide a concise eleven-row table naming each in-scope projector family, its actual source-event families, exact or evidenced broad invalidations, no-op events, any evidenced recovery source, and malformed/unsupported behavior.",
  >       "Confirm no file under `packages/live_query`, no accepted LiveView/query consumer, no projector/event/schema, and no plan, todo, matrix, ADR or feature file changed.",
  >       "Report formatting and `git diff --check` results in the worker summary without running an unscoped repository suite.",
  >       "Report any actual publisher shape that conflicts with the complete-envelope or exception contract and leave the todo unchecked if such a conflict remains."
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
  > Implemented packet `task-008a-59e50fa-contract-lifecycle-revision-3` with result `ready_for_review`.
  > 
  > Changes:
  > 
  > - Added the application-owned [`ReadModelContractViolationError`](/workspace/memba/web/lib/memba_web/live_query/read_model_contract_violation_error.ex:1), exposing projector, source-event module, and reason without retaining event payloads.
  > - Updated [`MembaReadModelSource`](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex:103) to require complete, correctly typed publisher envelopes and raise the stable exception for recognized malformed or unsupported events.
  > - Expanded [`memba_read_model_source_test.exs`](/workspace/memba/web/test/memba_web/live_query/memba_read_model_source_test.exs:107) with ordinary `Binding.handle_notification/2`, bind-window reconciliation, malformed-envelope, and exception field/message coverage.
  > - Wrote the required result artifact, including the eleven-projector-family evidence table, to [`latest-worker-result.json`](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1).
  > 
  > Validation passed:
  > 
  > - Focused adapter suite: 28 tests, 0 failures.
  > - Dashboard and conversation-detail query regressions: 8 tests, 0 failures.
  > - Formatting check passed.
  > - `git diff --check` passed.
  > - Generic package boundary check passed.
  > - No unresolved items or publisher-envelope conflicts found.
  > 
  > Task 008A remains unchecked as required. I did not run `dev check` or rerun the acceptance scenario because this packet explicitly reserves the full gate for the deterministic workflow node.

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
  > {"decision":"revise","task":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.","reason":"The current packet matches the first unchecked todo and the matching ready_for_review result, retains both prior candidate origins, stays within its three permitted implementation/test paths, and leaves the todo and acceptance features unchanged. Most prior gaps are closed: complete-envelope gating, stable application exception fields/message, ordinary and bind-window exception propagation, actual eleven-family dispatch, retained-row-only legacy MemberRemoved recovery, exact matching, false auto-follow no-op, and replay-only EmailDeliveryOpened no-op. One contract gap remains: false-auto-follow MessageSent returns :ignore before validating club_id/message_id/sender_id, and EmailDeliveryOpened returns :ignore before validating message_id/delivery_id. Consequently malformed recognized no-op events are silently ignored, contrary to the packet rule that recognized events missing required inner identities raise ReadModelContractViolationError and contrary to the worker table's malformed-event claim. Validate required identities before returning :ignore and add focused malformed-no-op tests for false auto-follow and EmailDeliveryOpened through both delivery projectors. Recorded validation passed 28 adapter and 8 query-vocabulary tests with exit 0; a supplementary current-HEAD rerun was used to determine whether existing coverage exposed this suspected path and also passed, confirming the gap is untested. No full suite or dev check was run."}

## Stage: apply_task_verdict
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/apply_task_verdict.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Task revise: - [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.
  The current packet matches the first unchecked todo and the matching ready_for_review result, retains both prior candidate origins, stays within its three permitted implementation/test paths, and leaves the todo and acceptance features unchanged. Most prior gaps are closed: complete-envelope gating, stable application exception fields/message, ordinary and bind-window exception propagation, actual eleven-family dispatch, retained-row-only legacy MemberRemoved recovery, exact matching, false auto-follow no-op, and replay-only EmailDeliveryOpened no-op. One contract gap remains: false-auto-follow MessageSent returns :ignore before validating club_id/message_id/sender_id, and EmailDeliveryOpened returns :ignore before validating message_id/delivery_id. Consequently malformed recognized no-op events are silently ignored, contrary to the packet rule that recognized events missing required inner identities raise ReadModelContractViolationError and contrary to the worker table's malformed-event claim. Validate required identities before returning :ignore and add focused malformed-no-op tests for false auto-follow and EmailDeliveryOpened through both delivery projectors. Recorded validation passed 28 adapter and 8 query-vocabulary tests with exit 0; a supplementary current-HEAD rerun was used to determine whether existing coverage exposed this suspected path and also passed, confirming the gap is untested. No full suite or dev check was run.
  {"preferred_next_label": "revise"}
  ```

## Stage: task_escalation
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/escalate_task_review.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Validator's current finding for - [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.: The current packet matches the first unchecked todo and the matching ready_for_review result, retains both prior candidate origins, stays within its three permitted implementation/test paths, and leaves the todo and acceptance features unchanged. Most prior gaps are closed: complete-envelope gating, stable application exception fields/message, ordinary and bind-window exception propagation, actual eleven-family dispatch, retained-row-only legacy MemberRemoved recovery, exact matching, false auto-follow no-op, and replay-only EmailDeliveryOpened no-op. One contract gap remains: false-auto-follow MessageSent returns :ignore before validating club_id/message_id/sender_id, and EmailDeliveryOpened returns :ignore before validating message_id/delivery_id. Consequently malformed recognized no-op events are silently ignored, contrary to the packet rule that recognized events missing required inner identities raise ReadModelContractViolationError and contrary to the worker table's malformed-event claim. Validate required identities before returning :ignore and add focused malformed-no-op tests for false auto-follow and EmailDeliveryOpened through both delivery projectors. Recorded validation passed 28 adapter and 8 query-vocabulary tests with exit 0; a supplementary current-HEAD rerun was used to determine whether existing coverage exposed this suspected path and also passed, confirming the gap is untested. No full suite or dev check was run.
  Escalating revise after 3 revision verdict(s) for task-008a.
  {"preferred_next_label": "discuss"}
  ```

## Stage: task_discussion
- Status: succeeded
- Handler: human

## Current context
| Key | Value |
|-----|-------|
| human.gate.label | repair as planned |
| human.gate.selected | freeform |
| human.gate.task_discussion.answer | repair as planned |
| human.gate.task_discussion.question | <@U0C3C6Y9ZAR> The validator has stopped this task; its finding is in the preceding run evidence. Should we repair the candidate to meet the approved plan, or is there a concrete business example or architectural constraint that changes the approach? Reply in this message's thread with 'repair as planned' or describe that constraint. This cannot approve publication. |
| human.gate.text | repair as planned |
| output.delivery_planner | {"execution_state":{"schema_version":1,"plan_path":"docs/iterations/067-live-projection-queries/plan.md","todo_path":"docs/iterations/067-live-projection-queries/todo.md","source_baseline":"59e50fa26a52a8d3376a356546c3ba9309d79681","accepted_tasks":["- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.","- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.","- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.","- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.","- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.","- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.","- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.","- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."],"pending_obligations":[{"task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.","status":"prepared","origin":"Adapter-completion portion of approved implementation step 4, corrected after review to distinguish valid broad scopes from malformed known notifications.","coverage":["All actual event families published by the eleven in-scope projectors","Exact collection, identity and authorization invalidations for valid complete events","Only evidenced broader scopes for valid events, including MessageSent club-conversation scope and role/permission fan-out","Legacy MemberRemoved scope recovery from the retained membership row","A stable application-owned exception for recognized malformed or unsupported projector/event pairings","The same visible contract-violation behavior during ordinary notification handling and bind-window reconciliation","Full publisher-envelope validation with structurally incomplete envelopes ignored","ConversationFollow MessageSent true/default behavior and false no-op behavior","Replay-only EmailDeliveryOpened no-op behavior for both delivery projectors","Exact tuple matching and unrelated-projector isolation","An eleven-row projector/event-family coverage table and fresh independent review"],"replaces":["- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.","- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."],"candidate_origins":[{"base_sha":"0b2466fc574c2110b09a5019d8c280658d035cd0","head_sha":"2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b","packet_id":"task-008a-0b2466f-adapter-matrix-1","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."},{"base_sha":"5a0be69826405522dbbc727b73e11cb5eac89784","head_sha":"b9987229e5bdcd20e7e0314a32d616766d88f16c","packet_id":"task-008a-5a0be69-projector-contract-revision-2","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."}]},{"task_id":"task-008b","todo_line":"- [ ] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.","status":"pending","origin":"Group-creation query portion of approved implementation step 4 and the former broad task 008.","coverage":["One coherent group-creation context result","Fresh active-club, current-member and manage-members authorization reads","Selected Club, current membership, Person, role and permission interests","No ownership of generated group identity, typed name, preview, errors or command state"],"replaces":["- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."],"candidate_origins":[]},{"task_id":"task-008c","todo_line":"- [ ] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.","status":"pending","origin":"Settings-query portion of approved implementation step 4 and the former broad task 008.","coverage":["One coherent settings result","Fresh selected-club membership and current-Person resolution","Current Person active-club membership and email-address collections","Selected and represented Club identities","No ownership of tab, add-email form, errors or command feedback"],"replaces":["- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."],"candidate_origins":[]},{"task_id":"task-008d","todo_line":"- [ ] 008D Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and recipient-eligibility interests.","status":"pending","origin":"Message-compose query portion of approved implementation step 4 and the former broad task 008.","coverage":["One coherent compose-context result","Fresh active-club, current-member and selected-audience participation reads","Club-member, participating-group and selected-group-member collection interests","Represented Person and primary-email eligibility interests","No ownership of subject, body, validation, retry or send state"],"replaces":["- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."],"candidate_origins":[]},{"task_id":"task-008e","todo_line":"- [ ] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests.","status":"pending","origin":"Delivery-detail query portion of approved implementation step 4 and the former broad task 008.","coverage":["One coherent authorized delivery-detail result","Fresh active-club, current-member, group-participation and conversation-access reads","Exact conversation, represented Person, delivery collection and delivery identity interests","Independent MemberEmailDelivery status and MembaStaffEmailDelivery reason convergence","No ownership of route, disclosure, flash or navigation state"],"replaces":["- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."],"candidate_origins":[]},{"task_id":"task-008f","todo_line":"- [ ] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.","status":"pending","origin":"Member-invitation query portion of approved implementation step 4 and the former broad task 008.","coverage":["One coherent invitation context result","Fresh active-club, current-member and manage-members authorization reads","Club-member collection entry and exit for the displayed count","Selected Club, current membership, Person, role and permission interests","No ownership of invitation email, validation, resend decision, delivery feedback or navigation"],"replaces":["- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."],"candidate_origins":[]},{"task_id":"task-009","todo_line":"- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.","status":"pending","origin":"Approved implementation step 5 after dashboard and conversation detail served as the accepted pre-freeze consumers.","coverage":["Group creation, settings, message composition, delivery detail and invitation LiveViews","One coherent result assign per remaining in-scope page","Preserved routes, access transitions, forms, commands, navigation and UI","Live delivery status and staff-reason convergence","Existing conversation and delivery behavior","No staff stream migration"],"replaces":["- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."],"candidate_origins":[]},{"task_id":"task-010","todo_line":"- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.","status":"pending","origin":"Approved implementation step 6.","coverage":["Path dependency integration in web/mix.exs","Production Docker build and release inclusion","Package tests exercised by dev check in supported environments"],"replaces":["- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."],"candidate_origins":[]},{"task_id":"task-011","todo_line":"- [ ] 011 Close the remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`.","status":"pending","origin":"Remainder of approved implementation step 7 after the stakeholder scenario and committed-projector open-LiveView proof were split into accepted task 006A.","coverage":["Focused proof for every migrated member page","Residual package lifecycle and bind/reconnect race coverage","Final full dev check on the exact clean or staged state"],"replaces":["- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`.","- [ ] 011 Implement the approved Bob-sees-Alice-join acceptance example, close remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`."],"candidate_origins":[]}],"candidate_origins":[{"base_sha":"0b2466fc574c2110b09a5019d8c280658d035cd0","head_sha":"2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b","packet_id":"task-008a-0b2466f-adapter-matrix-1","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."},{"base_sha":"5a0be69826405522dbbc727b73e11cb5eac89784","head_sha":"b9987229e5bdcd20e7e0314a32d616766d88f16c","packet_id":"task-008a-5a0be69-projector-contract-revision-2","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."}],"coverage_map":[{"accepted_task_lines":["- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."],"pending_task_ids":[],"scope":"Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, proof inventory and explicit exclusions."},{"accepted_task_lines":["- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."],"pending_task_ids":[],"scope":"Accepted dashboard query boundary, fresh-authority prerequisite, coherent dashboard assign and connected subscribe-before-read ordering."},{"accepted_task_lines":["- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."],"pending_task_ids":[],"scope":"Accepted provisional lifecycle, matching, route rebind, bind-window reconciliation, access-error and reconnect contract."},{"accepted_task_lines":["- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation."],"pending_task_ids":[],"scope":"Accepted dashboard binding, scoped invalidation and open-dashboard vertical behavior proof."},{"accepted_task_lines":["- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs."],"pending_task_ids":[],"scope":"Accepted conversation-detail binding, multi-projector convergence, fresh-access proof and frozen extraction contract."},{"accepted_task_lines":["- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green."],"pending_task_ids":[],"scope":"Accepted stakeholder scenario and committed-membership-projector-to-open-member-LiveView proof."},{"accepted_task_lines":["- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports."],"pending_task_ids":[],"scope":"Accepted standalone generic package and package-owned lifecycle, matching, race and cleanup tests."},{"accepted_task_lines":["- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."],"pending_task_ids":[],"scope":"Accepted package adoption by dashboard and conversation detail while retaining application-owned policy."},{"accepted_task_lines":[],"pending_task_ids":["task-008a"],"scope":"Correct and prove the app-owned notification adapter against actual projector/event families, evidenced broad scopes, no-op publications, full envelopes and lifecycle-visible malformed-event contract violations."},{"accepted_task_lines":[],"pending_task_ids":["task-008b","task-008c","task-008d","task-008e","task-008f"],"scope":"Introduce the five remaining fresh-authorized one-result query boundaries from existing read APIs without absorbing transient LiveView state."},{"accepted_task_lines":[],"pending_task_ids":["task-009"],"scope":"Migrate the five remaining member LiveViews while preserving routes, access transitions, transient state, navigation, UI and delivery/conversation convergence."},{"accepted_task_lines":[],"pending_task_ids":["task-010"],"scope":"Complete production package, Docker release and repository quality-gate integration."},{"accepted_task_lines":[],"pending_task_ids":["task-011"],"scope":"Close residual per-page and package lifecycle proof gaps and run final exact-state validation."}],"planner_note":"The trusted checkpoint preserves tasks 001, 003, 004, 005, 006, 006A, 007A and 007B exactly as accepted. Task 008A remains the first unchecked line and retains both rejected candidate origins under the same task identity. The latest candidate corrected event-family dispatch, false auto-follow, replay-only delivery events and unsupported synthetic fallbacks, but independent review found that returning {:error, ...} violates the frozen Source classifier contract: ordinary handling wraps it as invalid_classification and bind-window reconciliation drops it. This revision adds a stable application-owned exception path, complete publisher-envelope filtering, focused proof through both binding paths and the omitted eleven-row coverage table without changing the generic package. No todo edit or further split is needed because these are bounded review gaps within task 008A. The sole approved acceptance scenario is already accepted and green; this adapter lifecycle revision has no separate agreed scenario, so scenario_focus is null and focused technical proof is used."},"planner_result":{"schema_version":1,"plan_path":"docs/iterations/067-live-projection-queries/plan.md","todo_path":"docs/iterations/067-live-projection-queries/todo.md","source_baseline":"59e50fa26a52a8d3376a356546c3ba9309d79681","decision":"ready"},"current_worker_packet":{"schema_version":1,"packet_id":"task-008a-59e50fa-contract-lifecycle-revision-3","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.","attempt":"revision","plan_path":"docs/iterations/067-live-projection-queries/plan.md","todo_path":"docs/iterations/067-live-projection-queries/todo.md","source_baseline":"59e50fa26a52a8d3376a356546c3ba9309d79681","outcome":"Make recognized Memba read-model publisher contract violations fail through one stable application-owned exception during both ordinary notification handling and bind-window reconciliation, while ignoring structurally incomplete outer envelopes and preserving the candidate’s corrected eleven-family invalidation behavior.","scope":["Add a dedicated application-owned exception module under `web/lib/memba_web/live_query/` with stable inspectable projector, source-event module and reason fields plus a deterministic message.","Change `MembaWeb.LiveQuery.MembaReadModelSource` so recognized unsupported projector/event pairings and recognized events missing required identities raise that exception instead of returning a classifier result outside `LiveQuery.Source`’s frozen `:ignore | {:ok, invalidations}` contract.","Require the complete publisher envelope before classification: projector, source_event, metadata and changes must all be present with the types published by `Memba.ReadModelChanges`; structurally incomplete or mistyped outer envelopes remain ignored.","Keep complete notifications for unrelated projector modules ignored, while complete notifications for recognized projectors with unsupported event types or missing inner identities fail visibly.","Update the existing adapter tests so all malformed-current-event, unrecoverable legacy MemberRemoved, malformed delivery, unsupported pairing and missing-identity cases assert the same stable application exception and its exact fields.","Add focused ordinary-lifecycle proof by binding a minimal query to the Memba source, passing a complete malformed Membership notification through `LiveQuery.Binding.handle_notification/2`, and proving the application exception is raised rather than wrapped as invalid_classification.","Add focused bind-window proof with a connected test socket and a query load that queues the same complete malformed Membership notification during its first read, proving reconciliation raises the same application exception instead of silently discarding it.","Add focused outer-envelope cases for missing metadata, missing changes, non-map metadata and non-map changes, retaining existing unrelated-projector and unrelated-message isolation.","Preserve the current candidate’s corrected actual-event dispatch, exact and evidenced broad invalidations, legacy retained-row recovery, false auto-follow no-op, EmailDeliveryOpened no-op and exact tuple matching.","Return an eleven-row completion-evidence table covering Club, Membership, Person, Group, GroupMembership, Role, Message, ConversationGroupAccess, ConversationFollow, MemberEmailDelivery and MembaStaffEmailDelivery."],"scope_exclusions":["Do not modify `packages/live_query/**`; the generic Source and Binding contracts remain frozen.","Do not modify the dashboard or conversation-detail LiveViews, query modules or accepted query-interest vocabulary.","Do not add tasks 008B through 008F query modules or migrate any remaining LiveView.","Do not change domain events, projectors, projection schemas, read APIs, routes, templates, forms or UI behavior.","Do not edit the approved plan, todo, migration matrix, ADRs, acceptance feature or package documentation.","Do not restore synthetic partial-event, arbitrary committed-change, delivery-row-lookup or global fallback behavior.","Do not reactivate or rerun the already-green Bob-sees-Alice acceptance scenario.","Do not perform tasks 010 or 011 and do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped repository suite.","Do not mark task 008A complete; deterministic independent review owns acceptance."],"references":[{"path":"docs/iterations/067-live-projection-queries/plan.md","facts":"The approved technical model permits broad invalidation only for valid events that genuinely lack exact scope and requires known malformed Membership notifications with unrecoverable Person identity to surface a contract violation rather than refresh a partial, club-wide or global scope."},{"path":"docs/iterations/067-live-projection-queries/todo.md","facts":"Task 008A is the first unchecked obligation and owns actual projector-family coverage, exact matching, visible malformed-Membership handling, fallback auditing and fresh independent review."},{"path":"docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json","facts":"The trusted baseline requires preservation of both task-008a candidate origins and binds this new packet to current HEAD rather than the artifact’s predecessor pre_planner_head."},{"path":"docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json","facts":"The latest candidate reported 25 adapter tests and 8 accepted query-vocabulary tests passing and correctly narrowed actual event dispatch, legacy recovery and projector no-ops, but it returned contract violations as an out-of-contract classifier tuple and omitted the required coverage table."},{"path":"docs/iterations/067-live-projection-queries/.delivery/latest-review.json","facts":"Independent review requires one application-owned stable failure path visible during ordinary handling and bind-window reconciliation, full-envelope checks for metadata and changes, focused lifecycle proof, and the omitted eleven-row projector/event table."},{"path":"docs/iterations/067-live-projection-queries/migration-matrix.md","facts":"The normative matrix defines the eleven projector families, exact and legitimate broad interests, false auto-follow and replay-only opened no-ops, retained-row legacy MemberRemoved recovery, and the distinction between malformed payloads and valid broader event shapes."},{"path":"docs/adr/0021-publish-committed-read-model-changes.md","facts":"The committed publisher envelope has four fields—projector, source_event, metadata and changes—and is emitted only after the projection transaction commits."},{"path":"docs/adr/0027-use-live-projection-queries-for-liveview-reads.md","facts":"Memba owns notification translation and authorization policy while the generic local package owns only the reusable opaque query-binding mechanism."},{"path":"web/lib/memba/read_model_changes.ex","facts":"`publish/4` always broadcasts projector, source_event, metadata and changes; its message type requires a module, event struct and map values for metadata and changes."},{"path":"web/lib/memba_web/live_query/memba_read_model_source.ex","facts":"Current classification accepts envelopes containing only projector and source_event, and `contract_violation/3` returns `{:error, ...}` even though the generic classifier contract does not allow that result."},{"path":"web/test/memba_web/live_query/memba_read_model_source_test.exs","facts":"The focused suite covers the corrected eleven-family mappings but currently asserts out-of-contract error tuples directly and lacks Binding-level ordinary and bind-window visibility proof plus missing-metadata/missing-changes cases."},{"path":"packages/live_query/lib/live_query/source.ex","facts":"The frozen generic classifier type is exactly `:ignore | {:ok, [term()]}`; no application-specific error result belongs in this package API."},{"path":"packages/live_query/lib/live_query/binding.ex","facts":"Ordinary handling wraps any classifier result outside the frozen contract as invalid_classification, while bind-window reconciliation currently ignores every result except `{:ok, list}`; exceptions are not rescued by either path."},{"path":"packages/live_query/test/live_query/binding_test.exs","facts":"Existing generic tests show how to create a connected socket and queue a notification during the first query read, providing the deterministic pattern for adapter-level bind-window proof without sleeps."},{"path":"web/lib/memba_web/live/member_dashboard_live.ex","facts":"The accepted dashboard consumer routes committed read-model notifications through `Binding.handle_notification/2`; an application classifier exception therefore remains visible through its ordinary LiveView lifecycle without a consumer change."},{"path":"web/lib/memba_web/live/member_message_live/show.ex","facts":"The accepted conversation-detail consumer also routes committed read-model notifications through `Binding.handle_notification/2`; no special LiveView error tuple or package API extension is needed."},{"path":"docs/reference/elixir-mix-tests.md","facts":"Use a separate module file for the exception, keep process tests deterministic without sleeps or polling, and use supervised cleanup for any started process."},{"path":"docs/iterations/067-live-projection-queries/.delivery/wip-after.json","facts":"The iteration’s sole approved acceptance scenario is already green with its prediction matched, so this technical revision must not fabricate another scenario-first cycle."}],"constraints":["Limit implementation changes to `web/lib/memba_web/live_query/read_model_contract_violation_error.ex`, `web/lib/memba_web/live_query/memba_read_model_source.ex` and `web/test/memba_web/live_query/memba_read_model_source_test.exs`; report an unavoidable compile conflict before expanding scope.","Use a dedicated exception module rather than nesting another module in the adapter file.","Keep the exception application-owned and stable: expose the projector module, source-event module and reason as inspectable fields and use a deterministic non-sensitive message.","Do not include the full event payload in the exception; preserve the current event-module-level identity and reason.","Require metadata and changes to be maps as defined by the actual publisher; missing or mistyped outer-envelope fields are ignored before projector dispatch.","Once a complete envelope identifies a recognized projector, unsupported actual event pairings or missing required inner identities must raise the application exception and emit no invalidations.","Use actual event structs and actual projector/event pairings as ground truth. Narrow maps may test malformed envelopes but must not establish invented valid event variants.","Preserve exact tuple equality and every legitimate collection-entry/exit scope; do not replace precise invalidations with unconditional global invalidation.","Keep the retained Membership projection row as the only evidenced legacy MemberRemoved recovery source and do not restore arbitrary changes-map recovery.","Keep false `sender_follows_conversation` and replay-only `EmailDeliveryOpened` publications ignored.","Both delivery projectors must retain identical exact keys for the five state-changing delivery event families.","Use deterministic Binding-level tests with a connected socket and a queued mailbox notification; do not use sleeps or liveness polling.","Prepare evidence for fresh independent review and leave the todo line unchecked."],"focused_validation":["PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live_query/memba_read_model_source_test.exs","PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs"],"completion_evidence_required":["List every changed path and summarize the exception, envelope-classifier and focused-test changes.","Report successful exit status and test count for the focused adapter command.","Report successful exit status and test count for the accepted dashboard and conversation-detail query-vocabulary regression command.","Show that a complete malformed Membership notification raises the same stable application exception, with exact fields, both through ordinary `Binding.handle_notification/2` and bind-window reconciliation.","Show that notifications missing metadata or changes, or carrying non-map metadata or changes, return `:ignore` and do not reach recognized-projector dispatch.","Show that unrelated projectors and unrelated messages remain ignored while a complete recognized unsupported pairing raises the application exception.","Show that a Membership notification with club scope and unrecoverable Person identity raises the contract exception and emits no scoped or global Membership fallback.","Confirm the corrected candidate behavior remains intact: retained-row-only legacy MemberRemoved recovery, exact tuple isolation, false auto-follow no-op, both delivery contributors’ exact five-family mappings and replay-only EmailDeliveryOpened no-op.","Provide a concise eleven-row table naming each in-scope projector family, its actual source-event families, exact or evidenced broad invalidations, no-op events, any evidenced recovery source, and malformed/unsupported behavior.","Confirm no file under `packages/live_query`, no accepted LiveView/query consumer, no projector/event/schema, and no plan, todo, matrix, ADR or feature file changed.","Report formatting and `git diff --check` results in the worker summary without running an unscoped repository suite.","Report any actual publisher shape that conflicts with the complete-envelope or exception contract and leave the todo unchecked if such a conflict remains."],"candidate_origins":[{"base_sha":"0b2466fc574c2110b09a5019d8c280658d035cd0","head_sha":"2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b","packet_id":"task-008a-0b2466f-adapter-matrix-1","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."},{"base_sha":"5a0be69826405522dbbc727b73e11cb5eac89784","head_sha":"b9987229e5bdcd20e7e0314a32d616766d88f16c","packet_id":"task-008a-5a0be69-projector-contract-revision-2","reason":"review_revise","task_id":"task-008a","todo_line":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."}],"scenario_focus":null}} |
| output.validate_task | {"decision":"revise","task":"- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.","reason":"The current packet matches the first unchecked todo and the matching ready_for_review result, retains both prior candidate origins, stays within its three permitted implementation/test paths, and leaves the todo and acceptance features unchanged. Most prior gaps are closed: complete-envelope gating, stable application exception fields/message, ordinary and bind-window exception propagation, actual eleven-family dispatch, retained-row-only legacy MemberRemoved recovery, exact matching, false auto-follow no-op, and replay-only EmailDeliveryOpened no-op. One contract gap remains: false-auto-follow MessageSent returns :ignore before validating club_id/message_id/sender_id, and EmailDeliveryOpened returns :ignore before validating message_id/delivery_id. Consequently malformed recognized no-op events are silently ignored, contrary to the packet rule that recognized events missing required inner identities raise ReadModelContractViolationError and contrary to the worker table's malformed-event claim. Validate required identities before returning :ignore and add focused malformed-no-op tests for false auto-follow and EmailDeliveryOpened through both delivery projectors. Recorded validation passed 28 adapter and 8 query-vocabulary tests with exit 0; a supplementary current-HEAD rerun was used to determine whether existing coverage exposed this suspected path and also passed, confirming the gap is untested. No full suite or dev check was run."} |


Facilitate a short, generic clarification with Matt about the independent validator's latest task finding. The issue may need concrete business examples, an architectural decision, or another bounded technical repair. Do not assume it is example mapping. Do not edit files, waive security/plan constraints, check off tasks, or infer approval to resume/publish.

Read Matt's most recent reply from the immediately preceding human-gate stage and the validator evidence in this run's context. If the reply is missing, fail rather than inventing one. Preserve Matt's words and distinguish decisions from hypotheses. If material uncertainty remains, return one JSON routing object with `preferred_next_label` = `ask`, and include ONE focused follow-up question visible in the response for the next Slack message. If Matt explicitly says discussion is complete and guidance is clear, return `preferred_next_label` = `finish` with a concise decision summary. Never treat a single plausible answer as automatic approval. No other label is valid.


Fabro final-output contract

The following contract is trusted workflow configuration. It applies only to your final response, not to intermediate tool calls.
Return a single JSON object with at least one routing field: preferred_next_label, outcome, failure_reason, suggested_next_ids, context_updates.
The contract is complete. Do not ask the user to provide or choose the output shape.