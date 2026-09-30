Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01M3R0GGQHYQH093N9J0JG543V
Pipeline progress: 60 of 46 stages completed

## Stage: verify_source_head
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-implementation/scripts/verify_source_head.sh 'f7fc8267eac6ab8c4c50caf0471da56c6764bfef'`
- Output:
  ```
  Expected source HEAD: f7fc8267eac6ab8c4c50caf0471da56c6764bfef
  Actual source HEAD:   f7fc8267eac6ab8c4c50caf0471da56c6764bfef
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
  
  A view-specific query composes existing authorized read APIs, yielding one view model and a set of invalidation interests. Interests include collection scopes (to detect records entering/leaving a result) and identities of records actually represented. The binding layer holds the query, its current interests and one assign key inside the LiveView process, subscribes before the connected initial read, and refreshes only matching queries against committed projections. On each refresh it replaces the result and interests for that query; unrelated assigns and transient UI state remain untouched. A Memba adapter maps existing `ReadModelChanges` projector/event data to generic invalidation keys. A per-query migration matrix must list contributing projectors, event-to-interest mapping (including old and new scopes), fresh authorization sources and focused proof. When an event lacks precise scope, use a documented conservative invalidation rather than silently missing an update. Multiple contributing projectors can commit separately; each must invalidate the query so later commits converge. The generic package cannot infer SQL predicates or user permissions. Loading must check fresh authorization both initially and on refresh; query access errors are handed back for the existing private-surface transition. No streams are part of this contract in 067.
  
  The package interface has three responsibilities: a query supplies a read callback returning either one view model plus interests or an access error; a source adapter subscribes the connected LiveView and converts a notification to invalidation keys; a binding installs the query under one assign, matches notifications against current interests, refreshes, and replaces the result plus interests. The adapter and query are passed in, never imported from Memba by the package. The LiveView owns navigation on an access error. The initial connected binding subscribes *before* reading, and a notification received across the first read/interest installation triggers conservative reconciliation. This is an interface contract, not a mandate for particular function names or a new OTP process.
  
  For club home, start with **one authorized dashboard query** returning a coherent view model under one assign (`selected_group`, member rows/count, conversations and access-dependent data together), replacing today's map of independently assigned values. The member-list portion records interests for the selected club's membership collection and the represented people. Do not split dashboard queries unless measured need justifies coordinating multiple results across route and access transitions. A membership added/removed in that club invalidates the collection even if the person was absent from the old result; a relevant Person update invalidates represented names and initials. When a query also depends on groups/roles, those projectors must contribute invalidation keys, even when they commit at different times. For conversation detail, the query loads permitted messages and author names; a change that withdraws access causes a fresh authorization failure, not a retained private result. Mapping missing event scope falls back to broader invalidation, never silence.
  
  Implementation checkpoints before freezing the package API: specify the package query/binding API and Memba adapter, prove it first against a member list and a composed conversation detail query, verify connected mount and reconnection against Phoenix LiveView's actual lifecycle, inventory the member LiveViews with query/exception mappings and focused tests, and verify packaging/test integration against Docker and `bin/dev`. No stream adapter is required. Do not claim that a PubSub broadcast is a durable read-model changelog.
  
  ## Architecture Decisions
  
  Matt accepted [ADR 0027](../../adr/0027-use-live-projection-queries-for-liveview-reads.md), which extends ADR 0021 and sets the member LiveView live-query boundary.
  
  ## Implementation Plan
  
  1. Inventory club-member LiveViews and projection-backed reads, existing refresh predicates, fresh authorization sources and access transitions; record queries to migrate, event/interest mappings, focused test evidence and justified exceptions. Exclude staff streams explicitly.
  2. Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.
  3. Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports.
  4. Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.
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
  - Repository inventory/migration matrix: each in-scope club-member LiveView's projection-backed read either uses the live-query layer or has a documented exception, with scoped invalidations and focused regression evidence; package dependency graph cannot reference `Memba` or `Commanded`. Staff stream-backed pages are deferred.
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
  ✓ Configuring shell in 7.40ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 212µs (cached)
  ✓ Loading tasks in 1.30ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 9.97ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 12.0ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 3.83µs (no command)
  ✓ Running tasks in 22.9ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:2] [ds:8:2:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  Entering Memba devenv for root=/repos/mattwynne/memba sha=b7d8463.
  • Validating lock
  ✓ Validating lock in 19.1ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 3.31ms
  • Evaluating shell
  ✓ Evaluating shell in 940µs (cached)
  ✓ Configuring shell in 6.94ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 5.63µs (cached)
  ✓ Loading tasks in 1.14ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 9.98ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.0ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 5.23µs (no command)
  ✓ Running tasks in 21.5ms
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
  Tracked repository file writability OK (2422 regular files checked).
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
  npm notice New major version of npm available! 10.9.7 -> 12.1.0
  npm notice Changelog: https://github.com/npm/cli/releases/tag/v12.1.0
  npm notice To update run: npm install -g npm@12.1.0
  npm notice
  • Validating lock
  ✓ Validating lock in 31.7ms
  • Configuring cachix
  ✓ Configuring cachix in 3.23ms
  • Configuring shell
  • Evaluating shell
  ✓ Evaluating shell in 3.03s
  ✓ Configuring shell in 3.33s
  • Evaluating Nix
  ✓ Evaluating Nix in 2.83ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 2.05ms
  ✓ Loading tasks in 2.58ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 8.43ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.4ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 76.4µs (no command)
  ✓ Running tasks in 20.7ms
  • Running processes
  • Evaluating Nix
  ✓ Evaluating Nix in 2.04ms
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
  HEAD: 5c74ac3 fabro(01M3R0GGQHYQH093N9J0JG543V): preflight_sandbox (succeeded)
  Todo: docs/iterations/067-live-projection-queries/todo.md is absent; sync_task_list will create it from plan.md.
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
  Created docs/iterations/067-live-projection-queries/todo.md from docs/iterations/067-live-projection-queries/plan.md
  PLAN_PATH=docs/iterations/067-live-projection-queries/plan.md
  TODO_PATH=docs/iterations/067-live-projection-queries/todo.md
  # Implementation TODO
  
  - [ ] 001 Inventory club-member LiveViews and projection-backed reads, existing refresh predicates, fresh authorization sources and access transitions; record queries to migrate, event/interest mappings, focused test evidence and justified exceptions.
  - [ ] 002 Exclude staff streams explicitly.
  - [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.
  - [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports.
  - [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.
  - [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.
  - [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments.
  - [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`.
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
  3:- [ ] 001 Inventory club-member LiveViews and projection-backed reads, existing refresh predicates, fresh authorization sources and access transitions; record queries to migrate, event/interest mappings, focused test evidence and justified exceptions.
  4:- [ ] 002 Exclude staff streams explicitly.
  5:- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.
  6:- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports.
  7:- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.
  8:- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.
  9:- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments.
  10:- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`.
  ```

## Stage: before_delivery_planner
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py before-planner 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Delivery planner baseline captured from 44a595703dd8120dab79bcabaf98e85132fa1bdf in docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json
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
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "accepted_tasks": [
  >       "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
  >       "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
  >       "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >     ],
  >     "pending_obligations": [
  >       {
  >         "task_id": "task-005",
  >         "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >         "status": "prepared",
  >         "origin": "Dashboard vertical proof split from approved plan tasks 2, 4 and 5, using the accepted provisional lifecycle contract before public API freeze.",
  >         "replaces": [
  >           "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "Dashboard registration through the provisional binding",
  >           "Dashboard-specific Memba ReadModelChanges subscription and translation",
  >           "Scoped dashboard collection, identity and authorization interests",
  >           "Club-member and selected-group member entry and exit",
  >           "Member ordering and derived counts",
  >           "Represented Person and role-label refresh",
  >           "Current-actor role, route and access transitions using fresh authority",
  >           "Message and conversation-access invalidation required by the existing dashboard model",
  >           "Unrelated-club and unrelated-notification isolation",
  >           "Transient dashboard state preservation"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-006",
  >         "todo_line": "- [ ] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
  >         "status": "pending",
  >         "origin": "Conversation-detail vertical proof and API-freeze gate split from approved plan tasks 2, 4, 5 and 7. It follows the dashboard proof so the generic contract is justified by two materially different consumers.",
  >         "replaces": [
  >           "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "One coherent conversation-detail result assign",
  >           "Conversation-message collection and represented-author interests",
  >           "Exact follow identity",
  >           "Member delivery status and staff delivery reason contributors",
  >           "Independent projector commit-order convergence",
  >           "Fresh membership, group and conversation authorization",
  >           "Unrelated conversation, message, delivery, club and Person isolation",
  >           "Reply and disclosure state preservation",
  >           "Generic contract freeze only after both vertical proofs"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-007",
  >         "todo_line": "- [ ] 007 Extract, implement and test the frozen generic contract as a local Mix package, replace the two provisional consumers with it, and cover interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, subscriber cleanup and lifecycle without Memba or Commanded imports.",
  >         "status": "pending",
  >         "origin": "Remaining generic-package implementation from approved plan task 3, reordered after the two pre-freeze vertical proofs required by the approved technical model.",
  >         "replaces": [
  >           "- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports."
  >         ],
  >         "coverage": [
  >           "Extractable local Mix application",
  >           "Replacement of app-private binding use in dashboard and conversation detail",
  >           "Generic query registration, interest replacement, matching and refresh",
  >           "Duplicate and out-of-order notification behavior",
  >           "Subscriber cleanup and lifecycle tests",
  >           "No Memba or Commanded imports in package source or tests"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-008",
  >         "todo_line": "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
  >         "status": "pending",
  >         "origin": "Remaining application-adapter and query work from approved plan task 4 after the dashboard and conversation proof mappings are implemented.",
  >         "replaces": [
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
  >         ],
  >         "coverage": [
  >           "Every projector/event mapping recorded in the accepted migration matrix",
  >           "Collection, identity and authorization interests",
  >           "Old and new scopes where available",
  >           "Conservative club, family or global fallbacks when exact scope is unavailable",
  >           "Remaining fresh authorized view-specific queries",
  >           "No app-specific policy in the generic package"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-009",
  >         "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
  >         "status": "pending",
  >         "origin": "Remaining migration work from approved plan task 5 after dashboard and conversation detail serve as the pre-freeze proof consumers.",
  >         "replaces": [
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress."
  >         ],
  >         "coverage": [
  >           "Group creation, settings, message composition, delivery detail and invitation LiveViews",
  >           "One coherent result assign per remaining in-scope page",
  >           "Preserved routes, access transitions, forms, commands, navigation and UI",
  >           "Live delivery status and staff reason convergence",
  >           "Existing conversation and delivery behavior",
  >           "No staff stream migration"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-010",
  >         "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
  >         "status": "pending",
  >         "origin": "Approved plan task 6, retained after minimum development-time package consumption and separated from production release and quality-gate completion.",
  >         "replaces": [
  >           "- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."
  >         ],
  >         "coverage": [
  >           "Supported path dependency in web/mix.exs",
  >           "Docker dependency-copy and compilation ordering",
  >           "Production release inclusion",
  >           "Explicit package test execution in the repository quality gate",
  >           "Supported local and CI environments"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-011",
  >         "todo_line": "- [ ] 011 Add the focused acceptance example, close the focused proof gaps for every migrated member page and a real committed-projector-to-open-LiveView path, complete package lifecycle/race coverage, and run final `dev check`.",
  >         "status": "pending",
  >         "origin": "Approved plan task 7 retained as the final acceptance, proof-gap and exact-state validation obligation after implementation slices complete.",
  >         "replaces": [
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "Stakeholder-readable club-member live-update example",
  >           "Focused regression proof for every migrated member page",
  >           "At least one real committed-projector-to-open-LiveView path",
  >           "Remaining package mount, change, reconnect and race coverage",
  >           "Final full dev check on the exact delivered state"
  >         ],
  >         "candidate_origins": []
  >       }
  >     ],
  >     "candidate_origins": [],
  >     "coverage_map": [
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, focused-proof inventory and explicit exclusions."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted dashboard query/view-model boundary, fresh-authority prerequisite, coherent dashboard result assign, connected subscribe-before-read ordering and provisional predicates."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted provisional generic lifecycle, opaque-interest matching, route rebind, bind-window reconciliation, access-error and reconnect contract."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-005"
  >         ],
  >         "scope": "Dashboard binding, dashboard-scoped Memba invalidation and vertical behavior proof."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-006"
  >         ],
  >         "scope": "Conversation-detail binding, multi-projector/access proof and API freeze."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-007"
  >         ],
  >         "scope": "Frozen generic local package extraction and hardening."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-008"
  >         ],
  >         "scope": "Complete Memba notification adapter and remaining authorized queries."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-009"
  >         ],
  >         "scope": "Migration of the five remaining in-scope member LiveViews."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-010"
  >         ],
  >         "scope": "Production package, Docker release and quality-gate integration."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-011"
  >         ],
  >         "scope": "Acceptance example, remaining focused proof and final exact-state validation."
  >       }
  >     ],
  >     "planner_note": "The accepted review for task 004 is reflected by preserving its exact checked todo line and removing that completed obligation from pending work. Task 005 is now the first unchecked line and is prepared as the dashboard vertical proof without further splitting or reordering. The accepted provisional Binding, Query and Source modules supply the lifecycle prerequisite; this packet adds only dashboard-specific query interests, Memba notification translation and consumer proof. Conversation detail and API freeze remain task 006, package extraction remains task 007, full adapter completion remains task 008, and the acceptance feature plus full dev check remain task 011. No todo line was edited during this planner visit, and there is no unaccepted candidate origin to preserve."
  >   },
  >   "planner_result": {
  >     "schema_version": 1,
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "decision": "ready"
  >   },
  >   "current_worker_packet": {
  >     "schema_version": 1,
  >     "packet_id": "task-005-bcf5640-dashboard-binding-1",
  >     "task_id": "task-005",
  >     "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >     "attempt": "implementation",
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "outcome": "Make the existing member dashboard a real consumer of the provisional LiveView-owned query binding: one fresh-authorized dashboard result and its replacement interests must drive scoped refreshes from committed Memba projection notifications, while unrelated changes are ignored and route, access and transient UI behavior remain intact.",
  >     "scope": [
  >       "Add an app-private, explicitly provisional Memba ReadModelChanges source adapter that subscribes to the shared PubSub topic, classifies dashboard-relevant projector notifications into opaque invalidations, and performs scoped interest matching without moving Memba knowledge into the generic Binding or Source modules.",
  >       "Adapt `MembaWeb.MemberDashboardQuery` to provide a provisional query descriptor or loader returning the existing coherent dashboard view model plus replacement interests. Preserve `load/3` as the fresh-authority boundary, or retain an equivalent directly tested public contract, so every bind, rebind and notification refresh normalizes the authenticated email and rereads active-club authority.",
  >       "Register only one dashboard live query under the existing `:dashboard` assign. Do not recreate separate projection-backed compatibility assigns; internal binding metadata and shell-derived `:page_title` are not additional query results.",
  >       "Register dashboard collection interests for selected-club members, discoverable groups, current-person participating groups, selected-group members, selected-group conversations and represented-membership role assignments so rows absent from the old result can enter and existing rows can leave.",
  >       "Register exact or represented interests for the selected Club and Group, current membership and Person, represented member and conversation participant Persons, represented groups, conversations/messages, selected-group access, current-actor permissions and role data. Keep current-actor authorization interests distinct from represented-member badge interests.",
  >       "Translate dashboard-relevant Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess projector notifications according to the accepted migration matrix. Scope known club, group, person, membership and conversation identities; use the documented family, club or global conservative fallback when required scope is unavailable instead of silently ignoring a potentially relevant event.",
  >       "For `MessageSent`, emit exact or derived conversation invalidations and a conservative club-conversation invalidation because the event does not contain its audience group. Preserve existing dashboard conversation and reply convergence while removing the current unscoped MemberEmailDelivery refresh, since the dashboard no longer displays delivery data.",
  >       "Replace the dashboard's manual PubSub subscription and hand-written projector predicates with `Binding.bind/4` during mount, `Binding.rebind/3` for route-dependent selected-group changes and explicit command-driven rereads, and `Binding.handle_notification/2` for source messages. Connected bind must subscribe before reading; disconnected mount must read without subscribing.",
  >       "After each successful bind, rebind or notification refresh, synchronize only LiveView-owned shell or route coordination derived from the new dashboard, including `:page_title` and targeted-member resolution where applicable. Keep active section, picker state/query/form, admission and removal operation state, access-request state, targeted success/focus, flash and navigation outside the query result.",
  >       "Map dashboard binding errors back to the LiveView's existing `:forbidden` and `:not_found` owner policy. A failed refresh must not retain private dashboard data or teach the generic binding about redirects, exceptions or Memba authorization.",
  >       "Add focused source/query tests for interest construction, classification, matching, missing-scope fallbacks and unrelated-club isolation. Keep the interest representation app-private and provisional; this task must not claim a frozen package vocabulary.",
  >       "Add focused LiveView proof that club members and selected-group members enter and leave already-open lists, counts and name ordering converge, represented Person invalidation rereads only matching dashboards, represented role assignment/removal and role-definition changes update badges, current-actor role or membership loss rechecks authority, and route patches replace old selected-group interests.",
  >       "Retain and extend proof that relevant dashboard replacement preserves transient picker and command state, that unrelated club/person/group notifications do not expose deliberately changed projection data, and that existing admission, targeted-add, conversation-access and route behavior still works through the binding."
  >     ],
  >     "scope_exclusions": [
  >       "Do not migrate conversation detail, delivery detail, settings, message composition, group creation, invitations or any staff, public or auth surface; tasks 006, 008 and 009 retain those obligations.",
  >       "Do not freeze the provisional API or interest vocabulary. Conversation detail must provide the second materially different vertical proof before task 006 freezes the contract.",
  >       "Do not extract a local Mix package, add a path dependency, or change Docker, release or quality-gate integration; tasks 007 and 010 own those changes.",
  >       "Do not complete projector mappings needed only by non-dashboard consumers or implement delivery-row lookup fallbacks for conversation and delivery detail; task 008 retains the complete adapter obligation.",
  >       "Do not add or change domain events, aggregates, commands, projector writes, projection schemas, migrations, authorization policy or read-model persistence just to drive invalidation.",
  >       "Do not introduce `PersonRenamed`, name editing or profile-photo behavior. Prove the dashboard's exact represented-Person invalidation with existing Person projector envelopes and controlled projection state; iterations 068 and 069 remain out of scope.",
  >       "Do not require exact represented role IDs if the dashboard result does not expose them. Exact membership role-assignment interests plus the accepted conservative club role/permission invalidation are sufficient for this provisional slice.",
  >       "Do not retain the broad MemberEmailDelivery dashboard handler as compatibility behavior; delivery state is not part of the accepted dashboard result.",
  >       "Do not add a GenServer, process per query, global cache, durable notification log, projector replay, event-driven field patching or a claim that PubSub is durable.",
  >       "Do not edit the approved plan, todo line, migration matrix, ADRs, acceptance feature or design sources, and do not mark task 005 complete."
  >     ],
  >     "references": [
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/plan.md",
  >         "facts": "The approved technical model requires one authorized dashboard query under one assign, collection interests for absent-row entry and exit, represented identity interests, fresh authorization on every refresh, subscribe-before-read, bind-window reconciliation and rereading rather than patching fields from events. Dashboard and conversation detail must prove the provisional contract before API freeze."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/todo.md",
  >         "facts": "Task 005 is the first unchecked obligation. It owns dashboard wiring and proof; task 006 retains conversation detail and API freeze, task 007 retains package extraction, task 008 retains complete adapter coverage, and task 011 retains the acceptance feature and final full gate."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
  >         "facts": "The accepted dashboard matrix identifies selected-club members, discoverable and participating groups, selected-group members and conversations, represented Persons and role assignments, current permissions and access as dependencies. Its projector table defines scoped Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess mappings, including conservative fallbacks and the remaining dashboard proof gaps."
  >       },
  >       {
  >         "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
  >         "facts": "The accepted decision requires each view-specific query to return one coherent view model for one assign, with the LiveView owning subscription and relevant committed changes triggering a fresh authorized read. Memba concerns remain outside the generic mechanism, and staff streams are deferred."
  >       },
  >       {
  >         "path": "docs/adr/0021-publish-committed-read-model-changes.md",
  >         "facts": "Committed projector updates are published as `{:read_model_changed, %{projector: ..., source_event: ..., metadata: ..., changes: ...}}` on the shared application PubSub topic after projection transactions commit."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/binding.ex",
  >         "facts": "The accepted provisional binding already supports disconnected reads, connected subscription before the initial read, one shared source, bind-window reconciliation, relevant-only refresh, replacement interests, route rebind and owner-visible access errors while keeping state in the LiveView process. Dashboard integration should consume this behavior rather than create a second lifecycle."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/query.ex",
  >         "facts": "A provisional query has a stable identity, one public assign and a one-argument loader returning either one result plus opaque interests or an access error. Its callback shape remains app-private until both vertical proofs are complete."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/source.ex",
  >         "facts": "The provisional source separates subscription, raw-notification classification and opaque interest matching. It deliberately contains no Memba projector mapping, so dashboard-specific translation belongs in an injected app adapter."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live/member_dashboard_live.ex",
  >         "facts": "The accepted dashboard already stores projection-backed output only in `:dashboard` and derives `:page_title`, but it still manually subscribes, broadly refreshes for every MemberEmailDelivery change and handles only a same-club projector allowlist. `handle_params/3` and command paths call the old direct refresh helper, while picker, targeted-member, operation and access-request assigns remain LiveView-owned."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_query.ex",
  >         "facts": "The accepted query starts from routed club ID, authenticated email and selected group ID; every call normalizes the email, rereads active clubs and delegates to the established presentation boundary, preserving `:forbidden` and `:not_found` distinctions."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_presentation.ex",
  >         "facts": "The coherent dashboard result composes club members, discoverable and participating groups, current authorization, selected-group members, conversations, represented names and role labels. Conversation rows include reply-derived data but deliberately omit delivery glance fields, so MemberEmailDelivery is no longer a dashboard dependency."
  >       },
  >       {
  >         "path": "web/lib/memba/read_model_changes.ex",
  >         "facts": "The existing publisher exposes the single shared topic and ADR-defined post-commit envelope. The dashboard adapter should subscribe through this API; no publisher or projector write change is required."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/person.ex",
  >         "facts": "Current Person projector notifications cover creation and email-address changes and carry Person identity but no club scope. Task 005 must match represented Person identities without inventing a club or introducing the out-of-scope PersonRenamed event."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/role.ex",
  >         "facts": "Role projection handles role definitions, permissions, exact assignments/removals and membership-removal compatibility events. Exact assignment events carry club, membership, person and role IDs, while compatibility removals may require conservative membership, club-permission or global family invalidation."
  >       },
  >       {
  >         "path": "web/lib/memba/messaging/projectors/message.ex",
  >         "facts": "MessageSent projects roots and replies using a derivable conversation ID. The event carries club and conversation/message identity but no audience group, requiring a conservative club-conversation invalidation for dashboard collection entry and reply-derived changes."
  >       },
  >       {
  >         "path": "web/test/memba_web/live/member_dashboard_live_test.exs",
  >         "facts": "Existing tests establish the sole `:dashboard` result assign, group discovery refresh, selected-group access loss, current-actor role loss, conversation-access removal, route rechecks and picker-state preservation. Missing proof includes club-member entry/exit and ordering, represented Person isolation, live represented-member badge changes and old-interest replacement after route patches."
  >       },
  >       {
  >         "path": "web/test/memba_web/live/member_dashboard_admission_live_test.exs",
  >         "facts": "This suite protects the strongest existing real command/projector-to-open-dashboard group-admission behavior and command-owned state. It should remain passing while the manual handler is replaced by the provisional binding."
  >       },
  >       {
  >         "path": "docs/reference/liveview.md",
  >         "facts": "LiveView state changes belong in socket assigns and behavioral tests should use framework APIs. Query refresh must replace the dashboard assign without disturbing transient form, picker or navigation state."
  >       },
  >       {
  >         "path": "docs/reference/elixir-mix-tests.md",
  >         "facts": "Focused tests must avoid `Process.sleep/1`, use deterministic synchronization, and start test processes with `start_supervised!/1` where applicable."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
  >         "facts": "The task-004 worker reported the provisional Query, Source and Binding implementation with seven focused tests passing, including relevant-only refresh, interest replacement, route rebind, access errors, bind-window reconciliation and fresh connected remounts. It explicitly left dashboard wiring and Memba mapping for task 005."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
  >         "facts": "The latest review accepted task 004 and confirmed that dashboard wiring, scoped Memba translation and vertical behavior proof remain later work. There is no rejected task-005 candidate to revise, so this packet is a fresh implementation attempt."
  >       }
  >     ],
  >     "constraints": [
  >       "Keep all dashboard interest and invalidation types app-private and provisional; do not present names or tuple shapes as the frozen package API.",
  >       "Keep the dashboard query result coherent under only `:dashboard`; do not mirror projection fields into separate public socket assigns.",
  >       "Continue to execute reads, subscription handling and refreshes in the owning LiveView process.",
  >       "Use the accepted provisional Binding, Query and Source responsibilities. Change their generic behavior only if dashboard integration reveals a concrete contract defect, and document that defect and its focused regression proof.",
  >       "Subscribe only during connected binding and before the initial connected read. Preserve disconnected initial rendering without a PubSub subscription.",
  >       "On every bind, route rebind and relevant notification, use the authenticated email to reread current active-club and page-specific authority; never authorize from `current_identity_clubs` captured at mount.",
  >       "Replace successful dashboard result and interests together. Do not patch dashboard fields from source events or retain old interests after route rebind.",
  >       "Scope notifications using carried IDs whenever available. Unknown or legacy dashboard-relevant events must use the matrix's conservative family, club or global fallback rather than being silently ignored.",
  >       "Keep represented-member role-label invalidation distinct from current-actor permission invalidation, even when one Role event produces both invalidations.",
  >       "Treat MessageSent roots and replies as dashboard dependencies, but do not restore delivery-status interests or the old all-deliveries refresh.",
  >       "Preserve existing forbidden versus not-found owner behavior and clear private query data on an access error before leaving or raising from the private surface.",
  >       "Preserve route state, targeted-member coordination, picker/form contents, command operation state, flash and navigation across successful query refreshes.",
  >       "Do not use `Process.sleep/1` in tests, do not run an unscoped full-suite command as focused validation, and do not mark the todo line complete."
  >     ],
  >     "focused_validation": [
  >       "bin/dev test test/memba_web/live_query test/memba_web/member_dashboard_query_test.exs",
  >       "bin/dev test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_dashboard_admission_live_test.exs test/memba_web/live/member_dashboard_targeted_add_live_test.exs",
  >       "bin/mix format --check-formatted",
  >       "git diff --check"
  >     ],
  >     "completion_evidence_required": [
  >       "List every changed path and state whether it implements dashboard query interests, Memba source translation, LiveView integration or focused proof.",
  >       "Document the final provisional dashboard query input, success and access-error shapes and show that fresh active-club authority is reread for bind, rebind and notification refresh.",
  >       "Enumerate the dashboard collection, represented identity and authorization interests produced from a successful result, including absent-row entry scopes and replacement after a selected-group route change.",
  >       "Provide a projector/event-to-invalidation summary for Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess, including the conservative behavior used when exact scope is missing.",
  >       "Show that the dashboard no longer manually subscribes or uses its old projector allowlist and broad MemberEmailDelivery handler, and that its notifications flow through the provisional binding.",
  >       "Identify focused tests proving club-member entry/removal, selected-group member entry/removal, member ordering and derived count updates in an already-open dashboard.",
  >       "Identify focused tests proving exact represented-Person matching and isolation without introducing PersonRenamed or another out-of-scope domain event.",
  >       "Identify focused tests proving represented-member role badge assignment/removal or role-definition refresh independently from current-actor permission and access transitions.",
  >       "Show that route patching replaces old selected-group interests, preserves not-found semantics and prevents an old-group-only notification from refreshing the rebound dashboard.",
  >       "Show that selected-club membership, current-actor role or selected-group participation loss performs a fresh authorized read and does not retain private rows.",
  >       "Show unrelated-club and unrelated-Person/group notifications are ignored through the real source matching path rather than merely by a hand-written LiveView clause.",
  >       "Show a relevant dashboard replacement preserves picker/query state and the existing admission, targeted-add, operation, access-request, active-section, flash and navigation behavior.",
  >       "Confirm that no conversation-detail migration, API freeze, package extraction, complete cross-surface adapter, domain event, projector write, acceptance feature or staff-stream change was introduced.",
  >       "Report every focused validation command with exit status and concise pass evidence, plus any unresolved issue; missing entry/exit, role, access, route-isolation or transient-state proof must remain unresolved rather than being treated as complete."
  >     ],
  >     "candidate_origins": []
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
  {"preferred_next_label": "implement"}
  ```

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > Implemented packet `task-005-bcf5640-dashboard-binding-1` with result `ready_for_review`.
  > 
  > Key changes:
  > 
  > - Added the provisional scoped Memba notification adapter in [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex), covering Club, Membership, Person, Group, GroupMembership, Role, Message, and ConversationGroupAccess notifications with exact scopes and conservative fallbacks.
  > - Extended [member_dashboard_query.ex](/workspace/memba/web/lib/memba_web/member_dashboard_query.ex) with a single `:dashboard` query descriptor and replacement interests for collections, represented identities, role badges, permissions, participation, conversations, and access.
  > - Migrated [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex) from manual subscription/projector filtering to `Binding.bind/4`, `Binding.rebind/3`, and `Binding.handle_notification/2`. The broad MemberEmailDelivery refresh was removed.
  > - Added focused proof for member entry/removal/order/counts, represented Person and Group isolation, role assignment/definition/removal, route-interest replacement, current membership loss, and transient-state preservation.
  > - Wrote the required artifact at [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json). The task remains unchecked in `todo.md`.
  > 
  > Validation passed:
  > 
  > - Live-query and dashboard-query tests: 18 tests, 0 failures.
  > - Dashboard presentation, LiveView, admission, and targeted-add tests: 89 tests, 0 failures.
  > - `bin/mix format --check-formatted`: passed.
  > - `git diff --check`: passed.
  > - Worker result JSON parsed successfully.
  > 
  > No unresolved issues. The full `dev check` was intentionally not run because this packet delegates that unscoped gate to the workflow’s deterministic `dev_check` node.

## Stage: route_worker_result
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py route-worker 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  {"preferred_next_label": "review"}
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > {"decision":"revise","task":"- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.","reason":"Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard."}

## Stage: apply_task_verdict
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/apply_task_verdict.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Task revise: - [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.
  Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard.
  {"preferred_next_label": "revise"}
  ```

## Stage: task_escalation
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/escalate_task_review.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Validator's current finding for - [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.: Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard.
  Escalating revise after 3 revision verdict(s) before the iteration-wide worker limit.
  {"preferred_next_label": "discuss"}
  ```

## Stage: before_delivery_planner
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py before-planner 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Delivery planner baseline captured from 44a595703dd8120dab79bcabaf98e85132fa1bdf in docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json
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
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "accepted_tasks": [
  >       "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
  >       "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
  >       "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >     ],
  >     "pending_obligations": [
  >       {
  >         "task_id": "task-005",
  >         "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >         "status": "prepared",
  >         "origin": "Dashboard vertical proof split from approved plan tasks 2, 4 and 5, using the accepted provisional lifecycle contract before public API freeze.",
  >         "replaces": [
  >           "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "Dashboard registration through the provisional binding",
  >           "Dashboard-specific Memba ReadModelChanges subscription and translation",
  >           "Scoped dashboard collection, identity and authorization interests",
  >           "Club-member and selected-group member entry and exit",
  >           "Member ordering and derived counts",
  >           "Represented Person and role-label refresh",
  >           "Current-actor role, route and access transitions using fresh authority",
  >           "Message and conversation-access invalidation required by the existing dashboard model",
  >           "Unrelated-club and unrelated-notification isolation",
  >           "Transient dashboard state preservation"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-006",
  >         "todo_line": "- [ ] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
  >         "status": "pending",
  >         "origin": "Conversation-detail vertical proof and API-freeze gate split from approved plan tasks 2, 4, 5 and 7. It follows the dashboard proof so the generic contract is justified by two materially different consumers.",
  >         "replaces": [
  >           "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "One coherent conversation-detail result assign",
  >           "Conversation-message collection and represented-author interests",
  >           "Exact follow identity",
  >           "Member delivery status and staff delivery reason contributors",
  >           "Independent projector commit-order convergence",
  >           "Fresh membership, group and conversation authorization",
  >           "Unrelated conversation, message, delivery, club and Person isolation",
  >           "Reply and disclosure state preservation",
  >           "Generic contract freeze only after both vertical proofs"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-007",
  >         "todo_line": "- [ ] 007 Extract, implement and test the frozen generic contract as a local Mix package, replace the two provisional consumers with it, and cover interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, subscriber cleanup and lifecycle without Memba or Commanded imports.",
  >         "status": "pending",
  >         "origin": "Remaining generic-package implementation from approved plan task 3, reordered after the two pre-freeze vertical proofs required by the approved technical model.",
  >         "replaces": [
  >           "- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports."
  >         ],
  >         "coverage": [
  >           "Extractable local Mix application",
  >           "Replacement of app-private binding use in dashboard and conversation detail",
  >           "Generic query registration, interest replacement, matching and refresh",
  >           "Duplicate and out-of-order notification behavior",
  >           "Subscriber cleanup and lifecycle tests",
  >           "No Memba or Commanded imports in package source or tests"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-008",
  >         "todo_line": "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
  >         "status": "pending",
  >         "origin": "Remaining application-adapter and query work from approved plan task 4 after the dashboard and conversation proof mappings are implemented.",
  >         "replaces": [
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
  >         ],
  >         "coverage": [
  >           "Every projector/event mapping recorded in the accepted migration matrix",
  >           "Collection, identity and authorization interests",
  >           "Old and new scopes where available",
  >           "Conservative club, family or global fallbacks when exact scope is unavailable",
  >           "Remaining fresh authorized view-specific queries",
  >           "No app-specific policy in the generic package"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-009",
  >         "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
  >         "status": "pending",
  >         "origin": "Remaining migration work from approved plan task 5 after dashboard and conversation detail serve as the pre-freeze proof consumers.",
  >         "replaces": [
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress."
  >         ],
  >         "coverage": [
  >           "Group creation, settings, message composition, delivery detail and invitation LiveViews",
  >           "One coherent result assign per remaining in-scope page",
  >           "Preserved routes, access transitions, forms, commands, navigation and UI",
  >           "Live delivery status and staff reason convergence",
  >           "Existing conversation and delivery behavior",
  >           "No staff stream migration"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-010",
  >         "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
  >         "status": "pending",
  >         "origin": "Approved plan task 6, retained after minimum development-time package consumption and separated from production release and quality-gate completion.",
  >         "replaces": [
  >           "- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."
  >         ],
  >         "coverage": [
  >           "Supported path dependency in web/mix.exs",
  >           "Docker dependency-copy and compilation ordering",
  >           "Production release inclusion",
  >           "Explicit package test execution in the repository quality gate",
  >           "Supported local and CI environments"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-011",
  >         "todo_line": "- [ ] 011 Add the focused acceptance example, close the focused proof gaps for every migrated member page and a real committed-projector-to-open-LiveView path, complete package lifecycle/race coverage, and run final `dev check`.",
  >         "status": "pending",
  >         "origin": "Approved plan task 7 retained as the final acceptance, proof-gap and exact-state validation obligation after implementation slices complete.",
  >         "replaces": [
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "Stakeholder-readable club-member live-update example",
  >           "Focused regression proof for every migrated member page",
  >           "At least one real committed-projector-to-open-LiveView path",
  >           "Remaining package mount, change, reconnect and race coverage",
  >           "Final full dev check on the exact delivered state"
  >         ],
  >         "candidate_origins": []
  >       }
  >     ],
  >     "candidate_origins": [],
  >     "coverage_map": [
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, focused-proof inventory and explicit exclusions."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted dashboard query/view-model boundary, fresh-authority prerequisite, coherent dashboard result assign, connected subscribe-before-read ordering and provisional predicates."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted provisional generic lifecycle, opaque-interest matching, route rebind, bind-window reconciliation, access-error and reconnect contract."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-005"
  >         ],
  >         "scope": "Dashboard binding, dashboard-scoped Memba invalidation and vertical behavior proof."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-006"
  >         ],
  >         "scope": "Conversation-detail binding, multi-projector/access proof and API freeze."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-007"
  >         ],
  >         "scope": "Frozen generic local package extraction and hardening."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-008"
  >         ],
  >         "scope": "Complete Memba notification adapter and remaining authorized queries."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-009"
  >         ],
  >         "scope": "Migration of the five remaining in-scope member LiveViews."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-010"
  >         ],
  >         "scope": "Production package, Docker release and quality-gate integration."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-011"
  >         ],
  >         "scope": "Acceptance example, remaining focused proof and final exact-state validation."
  >       }
  >     ],
  >     "planner_note": "The accepted review for task 004 is reflected by preserving its exact checked todo line and removing that completed obligation from pending work. Task 005 is now the first unchecked line and is prepared as the dashboard vertical proof without further splitting or reordering. The accepted provisional Binding, Query and Source modules supply the lifecycle prerequisite; this packet adds only dashboard-specific query interests, Memba notification translation and consumer proof. Conversation detail and API freeze remain task 006, package extraction remains task 007, full adapter completion remains task 008, and the acceptance feature plus full dev check remain task 011. No todo line was edited during this planner visit, and there is no unaccepted candidate origin to preserve."
  >   },
  >   "planner_result": {
  >     "schema_version": 1,
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "decision": "ready"
  >   },
  >   "current_worker_packet": {
  >     "schema_version": 1,
  >     "packet_id": "task-005-bcf5640-dashboard-binding-1",
  >     "task_id": "task-005",
  >     "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >     "attempt": "implementation",
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "outcome": "Make the existing member dashboard a real consumer of the provisional LiveView-owned query binding: one fresh-authorized dashboard result and its replacement interests must drive scoped refreshes from committed Memba projection notifications, while unrelated changes are ignored and route, access and transient UI behavior remain intact.",
  >     "scope": [
  >       "Add an app-private, explicitly provisional Memba ReadModelChanges source adapter that subscribes to the shared PubSub topic, classifies dashboard-relevant projector notifications into opaque invalidations, and performs scoped interest matching without moving Memba knowledge into the generic Binding or Source modules.",
  >       "Adapt `MembaWeb.MemberDashboardQuery` to provide a provisional query descriptor or loader returning the existing coherent dashboard view model plus replacement interests. Preserve `load/3` as the fresh-authority boundary, or retain an equivalent directly tested public contract, so every bind, rebind and notification refresh normalizes the authenticated email and rereads active-club authority.",
  >       "Register only one dashboard live query under the existing `:dashboard` assign. Do not recreate separate projection-backed compatibility assigns; internal binding metadata and shell-derived `:page_title` are not additional query results.",
  >       "Register dashboard collection interests for selected-club members, discoverable groups, current-person participating groups, selected-group members, selected-group conversations and represented-membership role assignments so rows absent from the old result can enter and existing rows can leave.",
  >       "Register exact or represented interests for the selected Club and Group, current membership and Person, represented member and conversation participant Persons, represented groups, conversations/messages, selected-group access, current-actor permissions and role data. Keep current-actor authorization interests distinct from represented-member badge interests.",
  >       "Translate dashboard-relevant Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess projector notifications according to the accepted migration matrix. Scope known club, group, person, membership and conversation identities; use the documented family, club or global conservative fallback when required scope is unavailable instead of silently ignoring a potentially relevant event.",
  >       "For `MessageSent`, emit exact or derived conversation invalidations and a conservative club-conversation invalidation because the event does not contain its audience group. Preserve existing dashboard conversation and reply convergence while removing the current unscoped MemberEmailDelivery refresh, since the dashboard no longer displays delivery data.",
  >       "Replace the dashboard's manual PubSub subscription and hand-written projector predicates with `Binding.bind/4` during mount, `Binding.rebind/3` for route-dependent selected-group changes and explicit command-driven rereads, and `Binding.handle_notification/2` for source messages. Connected bind must subscribe before reading; disconnected mount must read without subscribing.",
  >       "After each successful bind, rebind or notification refresh, synchronize only LiveView-owned shell or route coordination derived from the new dashboard, including `:page_title` and targeted-member resolution where applicable. Keep active section, picker state/query/form, admission and removal operation state, access-request state, targeted success/focus, flash and navigation outside the query result.",
  >       "Map dashboard binding errors back to the LiveView's existing `:forbidden` and `:not_found` owner policy. A failed refresh must not retain private dashboard data or teach the generic binding about redirects, exceptions or Memba authorization.",
  >       "Add focused source/query tests for interest construction, classification, matching, missing-scope fallbacks and unrelated-club isolation. Keep the interest representation app-private and provisional; this task must not claim a frozen package vocabulary.",
  >       "Add focused LiveView proof that club members and selected-group members enter and leave already-open lists, counts and name ordering converge, represented Person invalidation rereads only matching dashboards, represented role assignment/removal and role-definition changes update badges, current-actor role or membership loss rechecks authority, and route patches replace old selected-group interests.",
  >       "Retain and extend proof that relevant dashboard replacement preserves transient picker and command state, that unrelated club/person/group notifications do not expose deliberately changed projection data, and that existing admission, targeted-add, conversation-access and route behavior still works through the binding."
  >     ],
  >     "scope_exclusions": [
  >       "Do not migrate conversation detail, delivery detail, settings, message composition, group creation, invitations or any staff, public or auth surface; tasks 006, 008 and 009 retain those obligations.",
  >       "Do not freeze the provisional API or interest vocabulary. Conversation detail must provide the second materially different vertical proof before task 006 freezes the contract.",
  >       "Do not extract a local Mix package, add a path dependency, or change Docker, release or quality-gate integration; tasks 007 and 010 own those changes.",
  >       "Do not complete projector mappings needed only by non-dashboard consumers or implement delivery-row lookup fallbacks for conversation and delivery detail; task 008 retains the complete adapter obligation.",
  >       "Do not add or change domain events, aggregates, commands, projector writes, projection schemas, migrations, authorization policy or read-model persistence just to drive invalidation.",
  >       "Do not introduce `PersonRenamed`, name editing or profile-photo behavior. Prove the dashboard's exact represented-Person invalidation with existing Person projector envelopes and controlled projection state; iterations 068 and 069 remain out of scope.",
  >       "Do not require exact represented role IDs if the dashboard result does not expose them. Exact membership role-assignment interests plus the accepted conservative club role/permission invalidation are sufficient for this provisional slice.",
  >       "Do not retain the broad MemberEmailDelivery dashboard handler as compatibility behavior; delivery state is not part of the accepted dashboard result.",
  >       "Do not add a GenServer, process per query, global cache, durable notification log, projector replay, event-driven field patching or a claim that PubSub is durable.",
  >       "Do not edit the approved plan, todo line, migration matrix, ADRs, acceptance feature or design sources, and do not mark task 005 complete."
  >     ],
  >     "references": [
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/plan.md",
  >         "facts": "The approved technical model requires one authorized dashboard query under one assign, collection interests for absent-row entry and exit, represented identity interests, fresh authorization on every refresh, subscribe-before-read, bind-window reconciliation and rereading rather than patching fields from events. Dashboard and conversation detail must prove the provisional contract before API freeze."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/todo.md",
  >         "facts": "Task 005 is the first unchecked obligation. It owns dashboard wiring and proof; task 006 retains conversation detail and API freeze, task 007 retains package extraction, task 008 retains complete adapter coverage, and task 011 retains the acceptance feature and final full gate."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
  >         "facts": "The accepted dashboard matrix identifies selected-club members, discoverable and participating groups, selected-group members and conversations, represented Persons and role assignments, current permissions and access as dependencies. Its projector table defines scoped Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess mappings, including conservative fallbacks and the remaining dashboard proof gaps."
  >       },
  >       {
  >         "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
  >         "facts": "The accepted decision requires each view-specific query to return one coherent view model for one assign, with the LiveView owning subscription and relevant committed changes triggering a fresh authorized read. Memba concerns remain outside the generic mechanism, and staff streams are deferred."
  >       },
  >       {
  >         "path": "docs/adr/0021-publish-committed-read-model-changes.md",
  >         "facts": "Committed projector updates are published as `{:read_model_changed, %{projector: ..., source_event: ..., metadata: ..., changes: ...}}` on the shared application PubSub topic after projection transactions commit."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/binding.ex",
  >         "facts": "The accepted provisional binding already supports disconnected reads, connected subscription before the initial read, one shared source, bind-window reconciliation, relevant-only refresh, replacement interests, route rebind and owner-visible access errors while keeping state in the LiveView process. Dashboard integration should consume this behavior rather than create a second lifecycle."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/query.ex",
  >         "facts": "A provisional query has a stable identity, one public assign and a one-argument loader returning either one result plus opaque interests or an access error. Its callback shape remains app-private until both vertical proofs are complete."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/source.ex",
  >         "facts": "The provisional source separates subscription, raw-notification classification and opaque interest matching. It deliberately contains no Memba projector mapping, so dashboard-specific translation belongs in an injected app adapter."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live/member_dashboard_live.ex",
  >         "facts": "The accepted dashboard already stores projection-backed output only in `:dashboard` and derives `:page_title`, but it still manually subscribes, broadly refreshes for every MemberEmailDelivery change and handles only a same-club projector allowlist. `handle_params/3` and command paths call the old direct refresh helper, while picker, targeted-member, operation and access-request assigns remain LiveView-owned."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_query.ex",
  >         "facts": "The accepted query starts from routed club ID, authenticated email and selected group ID; every call normalizes the email, rereads active clubs and delegates to the established presentation boundary, preserving `:forbidden` and `:not_found` distinctions."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_presentation.ex",
  >         "facts": "The coherent dashboard result composes club members, discoverable and participating groups, current authorization, selected-group members, conversations, represented names and role labels. Conversation rows include reply-derived data but deliberately omit delivery glance fields, so MemberEmailDelivery is no longer a dashboard dependency."
  >       },
  >       {
  >         "path": "web/lib/memba/read_model_changes.ex",
  >         "facts": "The existing publisher exposes the single shared topic and ADR-defined post-commit envelope. The dashboard adapter should subscribe through this API; no publisher or projector write change is required."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/person.ex",
  >         "facts": "Current Person projector notifications cover creation and email-address changes and carry Person identity but no club scope. Task 005 must match represented Person identities without inventing a club or introducing the out-of-scope PersonRenamed event."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/role.ex",
  >         "facts": "Role projection handles role definitions, permissions, exact assignments/removals and membership-removal compatibility events. Exact assignment events carry club, membership, person and role IDs, while compatibility removals may require conservative membership, club-permission or global family invalidation."
  >       },
  >       {
  >         "path": "web/lib/memba/messaging/projectors/message.ex",
  >         "facts": "MessageSent projects roots and replies using a derivable conversation ID. The event carries club and conversation/message identity but no audience group, requiring a conservative club-conversation invalidation for dashboard collection entry and reply-derived changes."
  >       },
  >       {
  >         "path": "web/test/memba_web/live/member_dashboard_live_test.exs",
  >         "facts": "Existing tests establish the sole `:dashboard` result assign, group discovery refresh, selected-group access loss, current-actor role loss, conversation-access removal, route rechecks and picker-state preservation. Missing proof includes club-member entry/exit and ordering, represented Person isolation, live represented-member badge changes and old-interest replacement after route patches."
  >       },
  >       {
  >         "path": "web/test/memba_web/live/member_dashboard_admission_live_test.exs",
  >         "facts": "This suite protects the strongest existing real command/projector-to-open-dashboard group-admission behavior and command-owned state. It should remain passing while the manual handler is replaced by the provisional binding."
  >       },
  >       {
  >         "path": "docs/reference/liveview.md",
  >         "facts": "LiveView state changes belong in socket assigns and behavioral tests should use framework APIs. Query refresh must replace the dashboard assign without disturbing transient form, picker or navigation state."
  >       },
  >       {
  >         "path": "docs/reference/elixir-mix-tests.md",
  >         "facts": "Focused tests must avoid `Process.sleep/1`, use deterministic synchronization, and start test processes with `start_supervised!/1` where applicable."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
  >         "facts": "The task-004 worker reported the provisional Query, Source and Binding implementation with seven focused tests passing, including relevant-only refresh, interest replacement, route rebind, access errors, bind-window reconciliation and fresh connected remounts. It explicitly left dashboard wiring and Memba mapping for task 005."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
  >         "facts": "The latest review accepted task 004 and confirmed that dashboard wiring, scoped Memba translation and vertical behavior proof remain later work. There is no rejected task-005 candidate to revise, so this packet is a fresh implementation attempt."
  >       }
  >     ],
  >     "constraints": [
  >       "Keep all dashboard interest and invalidation types app-private and provisional; do not present names or tuple shapes as the frozen package API.",
  >       "Keep the dashboard query result coherent under only `:dashboard`; do not mirror projection fields into separate public socket assigns.",
  >       "Continue to execute reads, subscription handling and refreshes in the owning LiveView process.",
  >       "Use the accepted provisional Binding, Query and Source responsibilities. Change their generic behavior only if dashboard integration reveals a concrete contract defect, and document that defect and its focused regression proof.",
  >       "Subscribe only during connected binding and before the initial connected read. Preserve disconnected initial rendering without a PubSub subscription.",
  >       "On every bind, route rebind and relevant notification, use the authenticated email to reread current active-club and page-specific authority; never authorize from `current_identity_clubs` captured at mount.",
  >       "Replace successful dashboard result and interests together. Do not patch dashboard fields from source events or retain old interests after route rebind.",
  >       "Scope notifications using carried IDs whenever available. Unknown or legacy dashboard-relevant events must use the matrix's conservative family, club or global fallback rather than being silently ignored.",
  >       "Keep represented-member role-label invalidation distinct from current-actor permission invalidation, even when one Role event produces both invalidations.",
  >       "Treat MessageSent roots and replies as dashboard dependencies, but do not restore delivery-status interests or the old all-deliveries refresh.",
  >       "Preserve existing forbidden versus not-found owner behavior and clear private query data on an access error before leaving or raising from the private surface.",
  >       "Preserve route state, targeted-member coordination, picker/form contents, command operation state, flash and navigation across successful query refreshes.",
  >       "Do not use `Process.sleep/1` in tests, do not run an unscoped full-suite command as focused validation, and do not mark the todo line complete."
  >     ],
  >     "focused_validation": [
  >       "bin/dev test test/memba_web/live_query test/memba_web/member_dashboard_query_test.exs",
  >       "bin/dev test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_dashboard_admission_live_test.exs test/memba_web/live/member_dashboard_targeted_add_live_test.exs",
  >       "bin/mix format --check-formatted",
  >       "git diff --check"
  >     ],
  >     "completion_evidence_required": [
  >       "List every changed path and state whether it implements dashboard query interests, Memba source translation, LiveView integration or focused proof.",
  >       "Document the final provisional dashboard query input, success and access-error shapes and show that fresh active-club authority is reread for bind, rebind and notification refresh.",
  >       "Enumerate the dashboard collection, represented identity and authorization interests produced from a successful result, including absent-row entry scopes and replacement after a selected-group route change.",
  >       "Provide a projector/event-to-invalidation summary for Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess, including the conservative behavior used when exact scope is missing.",
  >       "Show that the dashboard no longer manually subscribes or uses its old projector allowlist and broad MemberEmailDelivery handler, and that its notifications flow through the provisional binding.",
  >       "Identify focused tests proving club-member entry/removal, selected-group member entry/removal, member ordering and derived count updates in an already-open dashboard.",
  >       "Identify focused tests proving exact represented-Person matching and isolation without introducing PersonRenamed or another out-of-scope domain event.",
  >       "Identify focused tests proving represented-member role badge assignment/removal or role-definition refresh independently from current-actor permission and access transitions.",
  >       "Show that route patching replaces old selected-group interests, preserves not-found semantics and prevents an old-group-only notification from refreshing the rebound dashboard.",
  >       "Show that selected-club membership, current-actor role or selected-group participation loss performs a fresh authorized read and does not retain private rows.",
  >       "Show unrelated-club and unrelated-Person/group notifications are ignored through the real source matching path rather than merely by a hand-written LiveView clause.",
  >       "Show a relevant dashboard replacement preserves picker/query state and the existing admission, targeted-add, operation, access-request, active-section, flash and navigation behavior.",
  >       "Confirm that no conversation-detail migration, API freeze, package extraction, complete cross-surface adapter, domain event, projector write, acceptance feature or staff-stream change was introduced.",
  >       "Report every focused validation command with exit status and concise pass evidence, plus any unresolved issue; missing entry/exit, role, access, route-isolation or transient-state proof must remain unresolved rather than being treated as complete."
  >     ],
  >     "candidate_origins": []
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
  {"preferred_next_label": "implement"}
  ```

## Stage: revise_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > Packet `task-003-ca07fef-page-title-revision-2` is `ready_for_review`.
  > 
  > Implemented:
  > 
  > - Added a shared `install_dashboard/2` path used by both initial mount and refresh in [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:562).
  > - The helper keeps `:dashboard` as the sole projection-query result and derives only shell metadata `:page_title` from `dashboard.page_title`.
  > - Added the exact regression assertion in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:59):
  >   `assert page_title(view) == "Alpine Club · Memba"`
  > - Preserved all existing authorization, route, transient-state, and provisional notification behavior.
  > - Left the task unchecked as required.
  > - Recorded the result in [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json).
  > 
  > Validation passed:
  > 
  > - `bin/dev test test/memba_web/live/member_dashboard_live_test.exs` — 48 tests, 0 failures
  > - `bin/mix format --check-formatted lib/memba_web/live/member_dashboard_live.ex test/memba_web/live/member_dashboard_live_test.exs` — exit 0
  > - `git diff --check` — exit 0
  > - Worker-result JSON syntax validation — exit 0
  > 
  > The initial TDD run reproduced the defect as `"Memba · Memba"` before the implementation. No unresolved issues remain. Per the packet, the full `dev check` was not run in this worker node; the workflow’s deterministic gate handles it later.

## Stage: route_worker_result
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py route-worker 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  {"preferred_next_label": "review"}
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > {"decision":"revise","task":"- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.","reason":"Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard."}

## Stage: apply_task_verdict
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/apply_task_verdict.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Task revise: - [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.
  Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard.
  {"preferred_next_label": "revise"}
  ```

## Stage: before_delivery_planner
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py before-planner 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Delivery planner baseline captured from 44a595703dd8120dab79bcabaf98e85132fa1bdf in docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json
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
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "accepted_tasks": [
  >       "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
  >       "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
  >       "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >     ],
  >     "pending_obligations": [
  >       {
  >         "task_id": "task-005",
  >         "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >         "status": "prepared",
  >         "origin": "Dashboard vertical proof split from approved plan tasks 2, 4 and 5, using the accepted provisional lifecycle contract before public API freeze.",
  >         "replaces": [
  >           "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "Dashboard registration through the provisional binding",
  >           "Dashboard-specific Memba ReadModelChanges subscription and translation",
  >           "Scoped dashboard collection, identity and authorization interests",
  >           "Club-member and selected-group member entry and exit",
  >           "Member ordering and derived counts",
  >           "Represented Person and role-label refresh",
  >           "Current-actor role, route and access transitions using fresh authority",
  >           "Message and conversation-access invalidation required by the existing dashboard model",
  >           "Unrelated-club and unrelated-notification isolation",
  >           "Transient dashboard state preservation"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-006",
  >         "todo_line": "- [ ] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
  >         "status": "pending",
  >         "origin": "Conversation-detail vertical proof and API-freeze gate split from approved plan tasks 2, 4, 5 and 7. It follows the dashboard proof so the generic contract is justified by two materially different consumers.",
  >         "replaces": [
  >           "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "One coherent conversation-detail result assign",
  >           "Conversation-message collection and represented-author interests",
  >           "Exact follow identity",
  >           "Member delivery status and staff delivery reason contributors",
  >           "Independent projector commit-order convergence",
  >           "Fresh membership, group and conversation authorization",
  >           "Unrelated conversation, message, delivery, club and Person isolation",
  >           "Reply and disclosure state preservation",
  >           "Generic contract freeze only after both vertical proofs"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-007",
  >         "todo_line": "- [ ] 007 Extract, implement and test the frozen generic contract as a local Mix package, replace the two provisional consumers with it, and cover interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, subscriber cleanup and lifecycle without Memba or Commanded imports.",
  >         "status": "pending",
  >         "origin": "Remaining generic-package implementation from approved plan task 3, reordered after the two pre-freeze vertical proofs required by the approved technical model.",
  >         "replaces": [
  >           "- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports."
  >         ],
  >         "coverage": [
  >           "Extractable local Mix application",
  >           "Replacement of app-private binding use in dashboard and conversation detail",
  >           "Generic query registration, interest replacement, matching and refresh",
  >           "Duplicate and out-of-order notification behavior",
  >           "Subscriber cleanup and lifecycle tests",
  >           "No Memba or Commanded imports in package source or tests"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-008",
  >         "todo_line": "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
  >         "status": "pending",
  >         "origin": "Remaining application-adapter and query work from approved plan task 4 after the dashboard and conversation proof mappings are implemented.",
  >         "replaces": [
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
  >         ],
  >         "coverage": [
  >           "Every projector/event mapping recorded in the accepted migration matrix",
  >           "Collection, identity and authorization interests",
  >           "Old and new scopes where available",
  >           "Conservative club, family or global fallbacks when exact scope is unavailable",
  >           "Remaining fresh authorized view-specific queries",
  >           "No app-specific policy in the generic package"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-009",
  >         "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
  >         "status": "pending",
  >         "origin": "Remaining migration work from approved plan task 5 after dashboard and conversation detail serve as the pre-freeze proof consumers.",
  >         "replaces": [
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress."
  >         ],
  >         "coverage": [
  >           "Group creation, settings, message composition, delivery detail and invitation LiveViews",
  >           "One coherent result assign per remaining in-scope page",
  >           "Preserved routes, access transitions, forms, commands, navigation and UI",
  >           "Live delivery status and staff reason convergence",
  >           "Existing conversation and delivery behavior",
  >           "No staff stream migration"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-010",
  >         "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
  >         "status": "pending",
  >         "origin": "Approved plan task 6, retained after minimum development-time package consumption and separated from production release and quality-gate completion.",
  >         "replaces": [
  >           "- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."
  >         ],
  >         "coverage": [
  >           "Supported path dependency in web/mix.exs",
  >           "Docker dependency-copy and compilation ordering",
  >           "Production release inclusion",
  >           "Explicit package test execution in the repository quality gate",
  >           "Supported local and CI environments"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-011",
  >         "todo_line": "- [ ] 011 Add the focused acceptance example, close the focused proof gaps for every migrated member page and a real committed-projector-to-open-LiveView path, complete package lifecycle/race coverage, and run final `dev check`.",
  >         "status": "pending",
  >         "origin": "Approved plan task 7 retained as the final acceptance, proof-gap and exact-state validation obligation after implementation slices complete.",
  >         "replaces": [
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "Stakeholder-readable club-member live-update example",
  >           "Focused regression proof for every migrated member page",
  >           "At least one real committed-projector-to-open-LiveView path",
  >           "Remaining package mount, change, reconnect and race coverage",
  >           "Final full dev check on the exact delivered state"
  >         ],
  >         "candidate_origins": []
  >       }
  >     ],
  >     "candidate_origins": [],
  >     "coverage_map": [
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, focused-proof inventory and explicit exclusions."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted dashboard query/view-model boundary, fresh-authority prerequisite, coherent dashboard result assign, connected subscribe-before-read ordering and provisional predicates."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted provisional generic lifecycle, opaque-interest matching, route rebind, bind-window reconciliation, access-error and reconnect contract."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-005"
  >         ],
  >         "scope": "Dashboard binding, dashboard-scoped Memba invalidation and vertical behavior proof."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-006"
  >         ],
  >         "scope": "Conversation-detail binding, multi-projector/access proof and API freeze."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-007"
  >         ],
  >         "scope": "Frozen generic local package extraction and hardening."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-008"
  >         ],
  >         "scope": "Complete Memba notification adapter and remaining authorized queries."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-009"
  >         ],
  >         "scope": "Migration of the five remaining in-scope member LiveViews."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-010"
  >         ],
  >         "scope": "Production package, Docker release and quality-gate integration."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-011"
  >         ],
  >         "scope": "Acceptance example, remaining focused proof and final exact-state validation."
  >       }
  >     ],
  >     "planner_note": "The accepted review for task 004 is reflected by preserving its exact checked todo line and removing that completed obligation from pending work. Task 005 is now the first unchecked line and is prepared as the dashboard vertical proof without further splitting or reordering. The accepted provisional Binding, Query and Source modules supply the lifecycle prerequisite; this packet adds only dashboard-specific query interests, Memba notification translation and consumer proof. Conversation detail and API freeze remain task 006, package extraction remains task 007, full adapter completion remains task 008, and the acceptance feature plus full dev check remain task 011. No todo line was edited during this planner visit, and there is no unaccepted candidate origin to preserve."
  >   },
  >   "planner_result": {
  >     "schema_version": 1,
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "decision": "ready"
  >   },
  >   "current_worker_packet": {
  >     "schema_version": 1,
  >     "packet_id": "task-005-bcf5640-dashboard-binding-1",
  >     "task_id": "task-005",
  >     "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >     "attempt": "implementation",
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "outcome": "Make the existing member dashboard a real consumer of the provisional LiveView-owned query binding: one fresh-authorized dashboard result and its replacement interests must drive scoped refreshes from committed Memba projection notifications, while unrelated changes are ignored and route, access and transient UI behavior remain intact.",
  >     "scope": [
  >       "Add an app-private, explicitly provisional Memba ReadModelChanges source adapter that subscribes to the shared PubSub topic, classifies dashboard-relevant projector notifications into opaque invalidations, and performs scoped interest matching without moving Memba knowledge into the generic Binding or Source modules.",
  >       "Adapt `MembaWeb.MemberDashboardQuery` to provide a provisional query descriptor or loader returning the existing coherent dashboard view model plus replacement interests. Preserve `load/3` as the fresh-authority boundary, or retain an equivalent directly tested public contract, so every bind, rebind and notification refresh normalizes the authenticated email and rereads active-club authority.",
  >       "Register only one dashboard live query under the existing `:dashboard` assign. Do not recreate separate projection-backed compatibility assigns; internal binding metadata and shell-derived `:page_title` are not additional query results.",
  >       "Register dashboard collection interests for selected-club members, discoverable groups, current-person participating groups, selected-group members, selected-group conversations and represented-membership role assignments so rows absent from the old result can enter and existing rows can leave.",
  >       "Register exact or represented interests for the selected Club and Group, current membership and Person, represented member and conversation participant Persons, represented groups, conversations/messages, selected-group access, current-actor permissions and role data. Keep current-actor authorization interests distinct from represented-member badge interests.",
  >       "Translate dashboard-relevant Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess projector notifications according to the accepted migration matrix. Scope known club, group, person, membership and conversation identities; use the documented family, club or global conservative fallback when required scope is unavailable instead of silently ignoring a potentially relevant event.",
  >       "For `MessageSent`, emit exact or derived conversation invalidations and a conservative club-conversation invalidation because the event does not contain its audience group. Preserve existing dashboard conversation and reply convergence while removing the current unscoped MemberEmailDelivery refresh, since the dashboard no longer displays delivery data.",
  >       "Replace the dashboard's manual PubSub subscription and hand-written projector predicates with `Binding.bind/4` during mount, `Binding.rebind/3` for route-dependent selected-group changes and explicit command-driven rereads, and `Binding.handle_notification/2` for source messages. Connected bind must subscribe before reading; disconnected mount must read without subscribing.",
  >       "After each successful bind, rebind or notification refresh, synchronize only LiveView-owned shell or route coordination derived from the new dashboard, including `:page_title` and targeted-member resolution where applicable. Keep active section, picker state/query/form, admission and removal operation state, access-request state, targeted success/focus, flash and navigation outside the query result.",
  >       "Map dashboard binding errors back to the LiveView's existing `:forbidden` and `:not_found` owner policy. A failed refresh must not retain private dashboard data or teach the generic binding about redirects, exceptions or Memba authorization.",
  >       "Add focused source/query tests for interest construction, classification, matching, missing-scope fallbacks and unrelated-club isolation. Keep the interest representation app-private and provisional; this task must not claim a frozen package vocabulary.",
  >       "Add focused LiveView proof that club members and selected-group members enter and leave already-open lists, counts and name ordering converge, represented Person invalidation rereads only matching dashboards, represented role assignment/removal and role-definition changes update badges, current-actor role or membership loss rechecks authority, and route patches replace old selected-group interests.",
  >       "Retain and extend proof that relevant dashboard replacement preserves transient picker and command state, that unrelated club/person/group notifications do not expose deliberately changed projection data, and that existing admission, targeted-add, conversation-access and route behavior still works through the binding."
  >     ],
  >     "scope_exclusions": [
  >       "Do not migrate conversation detail, delivery detail, settings, message composition, group creation, invitations or any staff, public or auth surface; tasks 006, 008 and 009 retain those obligations.",
  >       "Do not freeze the provisional API or interest vocabulary. Conversation detail must provide the second materially different vertical proof before task 006 freezes the contract.",
  >       "Do not extract a local Mix package, add a path dependency, or change Docker, release or quality-gate integration; tasks 007 and 010 own those changes.",
  >       "Do not complete projector mappings needed only by non-dashboard consumers or implement delivery-row lookup fallbacks for conversation and delivery detail; task 008 retains the complete adapter obligation.",
  >       "Do not add or change domain events, aggregates, commands, projector writes, projection schemas, migrations, authorization policy or read-model persistence just to drive invalidation.",
  >       "Do not introduce `PersonRenamed`, name editing or profile-photo behavior. Prove the dashboard's exact represented-Person invalidation with existing Person projector envelopes and controlled projection state; iterations 068 and 069 remain out of scope.",
  >       "Do not require exact represented role IDs if the dashboard result does not expose them. Exact membership role-assignment interests plus the accepted conservative club role/permission invalidation are sufficient for this provisional slice.",
  >       "Do not retain the broad MemberEmailDelivery dashboard handler as compatibility behavior; delivery state is not part of the accepted dashboard result.",
  >       "Do not add a GenServer, process per query, global cache, durable notification log, projector replay, event-driven field patching or a claim that PubSub is durable.",
  >       "Do not edit the approved plan, todo line, migration matrix, ADRs, acceptance feature or design sources, and do not mark task 005 complete."
  >     ],
  >     "references": [
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/plan.md",
  >         "facts": "The approved technical model requires one authorized dashboard query under one assign, collection interests for absent-row entry and exit, represented identity interests, fresh authorization on every refresh, subscribe-before-read, bind-window reconciliation and rereading rather than patching fields from events. Dashboard and conversation detail must prove the provisional contract before API freeze."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/todo.md",
  >         "facts": "Task 005 is the first unchecked obligation. It owns dashboard wiring and proof; task 006 retains conversation detail and API freeze, task 007 retains package extraction, task 008 retains complete adapter coverage, and task 011 retains the acceptance feature and final full gate."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
  >         "facts": "The accepted dashboard matrix identifies selected-club members, discoverable and participating groups, selected-group members and conversations, represented Persons and role assignments, current permissions and access as dependencies. Its projector table defines scoped Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess mappings, including conservative fallbacks and the remaining dashboard proof gaps."
  >       },
  >       {
  >         "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
  >         "facts": "The accepted decision requires each view-specific query to return one coherent view model for one assign, with the LiveView owning subscription and relevant committed changes triggering a fresh authorized read. Memba concerns remain outside the generic mechanism, and staff streams are deferred."
  >       },
  >       {
  >         "path": "docs/adr/0021-publish-committed-read-model-changes.md",
  >         "facts": "Committed projector updates are published as `{:read_model_changed, %{projector: ..., source_event: ..., metadata: ..., changes: ...}}` on the shared application PubSub topic after projection transactions commit."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/binding.ex",
  >         "facts": "The accepted provisional binding already supports disconnected reads, connected subscription before the initial read, one shared source, bind-window reconciliation, relevant-only refresh, replacement interests, route rebind and owner-visible access errors while keeping state in the LiveView process. Dashboard integration should consume this behavior rather than create a second lifecycle."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/query.ex",
  >         "facts": "A provisional query has a stable identity, one public assign and a one-argument loader returning either one result plus opaque interests or an access error. Its callback shape remains app-private until both vertical proofs are complete."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/source.ex",
  >         "facts": "The provisional source separates subscription, raw-notification classification and opaque interest matching. It deliberately contains no Memba projector mapping, so dashboard-specific translation belongs in an injected app adapter."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live/member_dashboard_live.ex",
  >         "facts": "The accepted dashboard already stores projection-backed output only in `:dashboard` and derives `:page_title`, but it still manually subscribes, broadly refreshes for every MemberEmailDelivery change and handles only a same-club projector allowlist. `handle_params/3` and command paths call the old direct refresh helper, while picker, targeted-member, operation and access-request assigns remain LiveView-owned."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_query.ex",
  >         "facts": "The accepted query starts from routed club ID, authenticated email and selected group ID; every call normalizes the email, rereads active clubs and delegates to the established presentation boundary, preserving `:forbidden` and `:not_found` distinctions."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_presentation.ex",
  >         "facts": "The coherent dashboard result composes club members, discoverable and participating groups, current authorization, selected-group members, conversations, represented names and role labels. Conversation rows include reply-derived data but deliberately omit delivery glance fields, so MemberEmailDelivery is no longer a dashboard dependency."
  >       },
  >       {
  >         "path": "web/lib/memba/read_model_changes.ex",
  >         "facts": "The existing publisher exposes the single shared topic and ADR-defined post-commit envelope. The dashboard adapter should subscribe through this API; no publisher or projector write change is required."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/person.ex",
  >         "facts": "Current Person projector notifications cover creation and email-address changes and carry Person identity but no club scope. Task 005 must match represented Person identities without inventing a club or introducing the out-of-scope PersonRenamed event."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/role.ex",
  >         "facts": "Role projection handles role definitions, permissions, exact assignments/removals and membership-removal compatibility events. Exact assignment events carry club, membership, person and role IDs, while compatibility removals may require conservative membership, club-permission or global family invalidation."
  >       },
  >       {
  >         "path": "web/lib/memba/messaging/projectors/message.ex",
  >         "facts": "MessageSent projects roots and replies using a derivable conversation ID. The event carries club and conversation/message identity but no audience group, requiring a conservative club-conversation invalidation for dashboard collection entry and reply-derived changes."
  >       },
  >       {
  >         "path": "web/test/memba_web/live/member_dashboard_live_test.exs",
  >         "facts": "Existing tests establish the sole `:dashboard` result assign, group discovery refresh, selected-group access loss, current-actor role loss, conversation-access removal, route rechecks and picker-state preservation. Missing proof includes club-member entry/exit and ordering, represented Person isolation, live represented-member badge changes and old-interest replacement after route patches."
  >       },
  >       {
  >         "path": "web/test/memba_web/live/member_dashboard_admission_live_test.exs",
  >         "facts": "This suite protects the strongest existing real command/projector-to-open-dashboard group-admission behavior and command-owned state. It should remain passing while the manual handler is replaced by the provisional binding."
  >       },
  >       {
  >         "path": "docs/reference/liveview.md",
  >         "facts": "LiveView state changes belong in socket assigns and behavioral tests should use framework APIs. Query refresh must replace the dashboard assign without disturbing transient form, picker or navigation state."
  >       },
  >       {
  >         "path": "docs/reference/elixir-mix-tests.md",
  >         "facts": "Focused tests must avoid `Process.sleep/1`, use deterministic synchronization, and start test processes with `start_supervised!/1` where applicable."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
  >         "facts": "The task-004 worker reported the provisional Query, Source and Binding implementation with seven focused tests passing, including relevant-only refresh, interest replacement, route rebind, access errors, bind-window reconciliation and fresh connected remounts. It explicitly left dashboard wiring and Memba mapping for task 005."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
  >         "facts": "The latest review accepted task 004 and confirmed that dashboard wiring, scoped Memba translation and vertical behavior proof remain later work. There is no rejected task-005 candidate to revise, so this packet is a fresh implementation attempt."
  >       }
  >     ],
  >     "constraints": [
  >       "Keep all dashboard interest and invalidation types app-private and provisional; do not present names or tuple shapes as the frozen package API.",
  >       "Keep the dashboard query result coherent under only `:dashboard`; do not mirror projection fields into separate public socket assigns.",
  >       "Continue to execute reads, subscription handling and refreshes in the owning LiveView process.",
  >       "Use the accepted provisional Binding, Query and Source responsibilities. Change their generic behavior only if dashboard integration reveals a concrete contract defect, and document that defect and its focused regression proof.",
  >       "Subscribe only during connected binding and before the initial connected read. Preserve disconnected initial rendering without a PubSub subscription.",
  >       "On every bind, route rebind and relevant notification, use the authenticated email to reread current active-club and page-specific authority; never authorize from `current_identity_clubs` captured at mount.",
  >       "Replace successful dashboard result and interests together. Do not patch dashboard fields from source events or retain old interests after route rebind.",
  >       "Scope notifications using carried IDs whenever available. Unknown or legacy dashboard-relevant events must use the matrix's conservative family, club or global fallback rather than being silently ignored.",
  >       "Keep represented-member role-label invalidation distinct from current-actor permission invalidation, even when one Role event produces both invalidations.",
  >       "Treat MessageSent roots and replies as dashboard dependencies, but do not restore delivery-status interests or the old all-deliveries refresh.",
  >       "Preserve existing forbidden versus not-found owner behavior and clear private query data on an access error before leaving or raising from the private surface.",
  >       "Preserve route state, targeted-member coordination, picker/form contents, command operation state, flash and navigation across successful query refreshes.",
  >       "Do not use `Process.sleep/1` in tests, do not run an unscoped full-suite command as focused validation, and do not mark the todo line complete."
  >     ],
  >     "focused_validation": [
  >       "bin/dev test test/memba_web/live_query test/memba_web/member_dashboard_query_test.exs",
  >       "bin/dev test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_dashboard_admission_live_test.exs test/memba_web/live/member_dashboard_targeted_add_live_test.exs",
  >       "bin/mix format --check-formatted",
  >       "git diff --check"
  >     ],
  >     "completion_evidence_required": [
  >       "List every changed path and state whether it implements dashboard query interests, Memba source translation, LiveView integration or focused proof.",
  >       "Document the final provisional dashboard query input, success and access-error shapes and show that fresh active-club authority is reread for bind, rebind and notification refresh.",
  >       "Enumerate the dashboard collection, represented identity and authorization interests produced from a successful result, including absent-row entry scopes and replacement after a selected-group route change.",
  >       "Provide a projector/event-to-invalidation summary for Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess, including the conservative behavior used when exact scope is missing.",
  >       "Show that the dashboard no longer manually subscribes or uses its old projector allowlist and broad MemberEmailDelivery handler, and that its notifications flow through the provisional binding.",
  >       "Identify focused tests proving club-member entry/removal, selected-group member entry/removal, member ordering and derived count updates in an already-open dashboard.",
  >       "Identify focused tests proving exact represented-Person matching and isolation without introducing PersonRenamed or another out-of-scope domain event.",
  >       "Identify focused tests proving represented-member role badge assignment/removal or role-definition refresh independently from current-actor permission and access transitions.",
  >       "Show that route patching replaces old selected-group interests, preserves not-found semantics and prevents an old-group-only notification from refreshing the rebound dashboard.",
  >       "Show that selected-club membership, current-actor role or selected-group participation loss performs a fresh authorized read and does not retain private rows.",
  >       "Show unrelated-club and unrelated-Person/group notifications are ignored through the real source matching path rather than merely by a hand-written LiveView clause.",
  >       "Show a relevant dashboard replacement preserves picker/query state and the existing admission, targeted-add, operation, access-request, active-section, flash and navigation behavior.",
  >       "Confirm that no conversation-detail migration, API freeze, package extraction, complete cross-surface adapter, domain event, projector write, acceptance feature or staff-stream change was introduced.",
  >       "Report every focused validation command with exit status and concise pass evidence, plus any unresolved issue; missing entry/exit, role, access, route-isolation or transient-state proof must remain unresolved rather than being treated as complete."
  >     ],
  >     "candidate_origins": []
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
  {"preferred_next_label": "implement"}
  ```

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > Implemented packet `task-005-bcf5640-dashboard-binding-1` with result `ready_for_review`.
  > 
  > Key changes:
  > 
  > - Added the provisional scoped Memba notification adapter in [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex), covering Club, Membership, Person, Group, GroupMembership, Role, Message, and ConversationGroupAccess notifications with exact scopes and conservative fallbacks.
  > - Extended [member_dashboard_query.ex](/workspace/memba/web/lib/memba_web/member_dashboard_query.ex) with a single `:dashboard` query descriptor and replacement interests for collections, represented identities, role badges, permissions, participation, conversations, and access.
  > - Migrated [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex) from manual subscription/projector filtering to `Binding.bind/4`, `Binding.rebind/3`, and `Binding.handle_notification/2`. The broad MemberEmailDelivery refresh was removed.
  > - Added focused proof for member entry/removal/order/counts, represented Person and Group isolation, role assignment/definition/removal, route-interest replacement, current membership loss, and transient-state preservation.
  > - Wrote the required artifact at [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json). The task remains unchecked in `todo.md`.
  > 
  > Validation passed:
  > 
  > - Live-query and dashboard-query tests: 18 tests, 0 failures.
  > - Dashboard presentation, LiveView, admission, and targeted-add tests: 89 tests, 0 failures.
  > - `bin/mix format --check-formatted`: passed.
  > - `git diff --check`: passed.
  > - Worker result JSON parsed successfully.
  > 
  > No unresolved issues. The full `dev check` was intentionally not run because this packet delegates that unscoped gate to the workflow’s deterministic `dev_check` node.

## Stage: route_worker_result
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py route-worker 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  {"preferred_next_label": "review"}
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > {"decision":"revise","task":"- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.","reason":"Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard."}

## Stage: apply_task_verdict
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/apply_task_verdict.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Task revise: - [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.
  Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard.
  {"preferred_next_label": "revise"}
  ```

## Stage: task_escalation
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/escalate_task_review.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Validator's current finding for - [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.: Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard.
  Escalating revise after 3 revision verdict(s) before the iteration-wide worker limit.
  {"preferred_next_label": "discuss"}
  ```

## Stage: before_delivery_planner
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py before-planner 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Delivery planner baseline captured from 44a595703dd8120dab79bcabaf98e85132fa1bdf in docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json
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
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "accepted_tasks": [
  >       "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
  >       "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
  >       "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >     ],
  >     "pending_obligations": [
  >       {
  >         "task_id": "task-005",
  >         "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >         "status": "prepared",
  >         "origin": "Dashboard vertical proof split from approved plan tasks 2, 4 and 5, using the accepted provisional lifecycle contract before public API freeze.",
  >         "replaces": [
  >           "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "Dashboard registration through the provisional binding",
  >           "Dashboard-specific Memba ReadModelChanges subscription and translation",
  >           "Scoped dashboard collection, identity and authorization interests",
  >           "Club-member and selected-group member entry and exit",
  >           "Member ordering and derived counts",
  >           "Represented Person and role-label refresh",
  >           "Current-actor role, route and access transitions using fresh authority",
  >           "Message and conversation-access invalidation required by the existing dashboard model",
  >           "Unrelated-club and unrelated-notification isolation",
  >           "Transient dashboard state preservation"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-006",
  >         "todo_line": "- [ ] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
  >         "status": "pending",
  >         "origin": "Conversation-detail vertical proof and API-freeze gate split from approved plan tasks 2, 4, 5 and 7. It follows the dashboard proof so the generic contract is justified by two materially different consumers.",
  >         "replaces": [
  >           "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "One coherent conversation-detail result assign",
  >           "Conversation-message collection and represented-author interests",
  >           "Exact follow identity",
  >           "Member delivery status and staff delivery reason contributors",
  >           "Independent projector commit-order convergence",
  >           "Fresh membership, group and conversation authorization",
  >           "Unrelated conversation, message, delivery, club and Person isolation",
  >           "Reply and disclosure state preservation",
  >           "Generic contract freeze only after both vertical proofs"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-007",
  >         "todo_line": "- [ ] 007 Extract, implement and test the frozen generic contract as a local Mix package, replace the two provisional consumers with it, and cover interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, subscriber cleanup and lifecycle without Memba or Commanded imports.",
  >         "status": "pending",
  >         "origin": "Remaining generic-package implementation from approved plan task 3, reordered after the two pre-freeze vertical proofs required by the approved technical model.",
  >         "replaces": [
  >           "- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports."
  >         ],
  >         "coverage": [
  >           "Extractable local Mix application",
  >           "Replacement of app-private binding use in dashboard and conversation detail",
  >           "Generic query registration, interest replacement, matching and refresh",
  >           "Duplicate and out-of-order notification behavior",
  >           "Subscriber cleanup and lifecycle tests",
  >           "No Memba or Commanded imports in package source or tests"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-008",
  >         "todo_line": "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
  >         "status": "pending",
  >         "origin": "Remaining application-adapter and query work from approved plan task 4 after the dashboard and conversation proof mappings are implemented.",
  >         "replaces": [
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
  >         ],
  >         "coverage": [
  >           "Every projector/event mapping recorded in the accepted migration matrix",
  >           "Collection, identity and authorization interests",
  >           "Old and new scopes where available",
  >           "Conservative club, family or global fallbacks when exact scope is unavailable",
  >           "Remaining fresh authorized view-specific queries",
  >           "No app-specific policy in the generic package"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-009",
  >         "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
  >         "status": "pending",
  >         "origin": "Remaining migration work from approved plan task 5 after dashboard and conversation detail serve as the pre-freeze proof consumers.",
  >         "replaces": [
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress."
  >         ],
  >         "coverage": [
  >           "Group creation, settings, message composition, delivery detail and invitation LiveViews",
  >           "One coherent result assign per remaining in-scope page",
  >           "Preserved routes, access transitions, forms, commands, navigation and UI",
  >           "Live delivery status and staff reason convergence",
  >           "Existing conversation and delivery behavior",
  >           "No staff stream migration"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-010",
  >         "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
  >         "status": "pending",
  >         "origin": "Approved plan task 6, retained after minimum development-time package consumption and separated from production release and quality-gate completion.",
  >         "replaces": [
  >           "- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."
  >         ],
  >         "coverage": [
  >           "Supported path dependency in web/mix.exs",
  >           "Docker dependency-copy and compilation ordering",
  >           "Production release inclusion",
  >           "Explicit package test execution in the repository quality gate",
  >           "Supported local and CI environments"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-011",
  >         "todo_line": "- [ ] 011 Add the focused acceptance example, close the focused proof gaps for every migrated member page and a real committed-projector-to-open-LiveView path, complete package lifecycle/race coverage, and run final `dev check`.",
  >         "status": "pending",
  >         "origin": "Approved plan task 7 retained as the final acceptance, proof-gap and exact-state validation obligation after implementation slices complete.",
  >         "replaces": [
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "Stakeholder-readable club-member live-update example",
  >           "Focused regression proof for every migrated member page",
  >           "At least one real committed-projector-to-open-LiveView path",
  >           "Remaining package mount, change, reconnect and race coverage",
  >           "Final full dev check on the exact delivered state"
  >         ],
  >         "candidate_origins": []
  >       }
  >     ],
  >     "candidate_origins": [],
  >     "coverage_map": [
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, focused-proof inventory and explicit exclusions."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted dashboard query/view-model boundary, fresh-authority prerequisite, coherent dashboard result assign, connected subscribe-before-read ordering and provisional predicates."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted provisional generic lifecycle, opaque-interest matching, route rebind, bind-window reconciliation, access-error and reconnect contract."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-005"
  >         ],
  >         "scope": "Dashboard binding, dashboard-scoped Memba invalidation and vertical behavior proof."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-006"
  >         ],
  >         "scope": "Conversation-detail binding, multi-projector/access proof and API freeze."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-007"
  >         ],
  >         "scope": "Frozen generic local package extraction and hardening."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-008"
  >         ],
  >         "scope": "Complete Memba notification adapter and remaining authorized queries."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-009"
  >         ],
  >         "scope": "Migration of the five remaining in-scope member LiveViews."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-010"
  >         ],
  >         "scope": "Production package, Docker release and quality-gate integration."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-011"
  >         ],
  >         "scope": "Acceptance example, remaining focused proof and final exact-state validation."
  >       }
  >     ],
  >     "planner_note": "The accepted review for task 004 is reflected by preserving its exact checked todo line and removing that completed obligation from pending work. Task 005 is now the first unchecked line and is prepared as the dashboard vertical proof without further splitting or reordering. The accepted provisional Binding, Query and Source modules supply the lifecycle prerequisite; this packet adds only dashboard-specific query interests, Memba notification translation and consumer proof. Conversation detail and API freeze remain task 006, package extraction remains task 007, full adapter completion remains task 008, and the acceptance feature plus full dev check remain task 011. No todo line was edited during this planner visit, and there is no unaccepted candidate origin to preserve."
  >   },
  >   "planner_result": {
  >     "schema_version": 1,
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "decision": "ready"
  >   },
  >   "current_worker_packet": {
  >     "schema_version": 1,
  >     "packet_id": "task-005-bcf5640-dashboard-binding-1",
  >     "task_id": "task-005",
  >     "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >     "attempt": "implementation",
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "outcome": "Make the existing member dashboard a real consumer of the provisional LiveView-owned query binding: one fresh-authorized dashboard result and its replacement interests must drive scoped refreshes from committed Memba projection notifications, while unrelated changes are ignored and route, access and transient UI behavior remain intact.",
  >     "scope": [
  >       "Add an app-private, explicitly provisional Memba ReadModelChanges source adapter that subscribes to the shared PubSub topic, classifies dashboard-relevant projector notifications into opaque invalidations, and performs scoped interest matching without moving Memba knowledge into the generic Binding or Source modules.",
  >       "Adapt `MembaWeb.MemberDashboardQuery` to provide a provisional query descriptor or loader returning the existing coherent dashboard view model plus replacement interests. Preserve `load/3` as the fresh-authority boundary, or retain an equivalent directly tested public contract, so every bind, rebind and notification refresh normalizes the authenticated email and rereads active-club authority.",
  >       "Register only one dashboard live query under the existing `:dashboard` assign. Do not recreate separate projection-backed compatibility assigns; internal binding metadata and shell-derived `:page_title` are not additional query results.",
  >       "Register dashboard collection interests for selected-club members, discoverable groups, current-person participating groups, selected-group members, selected-group conversations and represented-membership role assignments so rows absent from the old result can enter and existing rows can leave.",
  >       "Register exact or represented interests for the selected Club and Group, current membership and Person, represented member and conversation participant Persons, represented groups, conversations/messages, selected-group access, current-actor permissions and role data. Keep current-actor authorization interests distinct from represented-member badge interests.",
  >       "Translate dashboard-relevant Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess projector notifications according to the accepted migration matrix. Scope known club, group, person, membership and conversation identities; use the documented family, club or global conservative fallback when required scope is unavailable instead of silently ignoring a potentially relevant event.",
  >       "For `MessageSent`, emit exact or derived conversation invalidations and a conservative club-conversation invalidation because the event does not contain its audience group. Preserve existing dashboard conversation and reply convergence while removing the current unscoped MemberEmailDelivery refresh, since the dashboard no longer displays delivery data.",
  >       "Replace the dashboard's manual PubSub subscription and hand-written projector predicates with `Binding.bind/4` during mount, `Binding.rebind/3` for route-dependent selected-group changes and explicit command-driven rereads, and `Binding.handle_notification/2` for source messages. Connected bind must subscribe before reading; disconnected mount must read without subscribing.",
  >       "After each successful bind, rebind or notification refresh, synchronize only LiveView-owned shell or route coordination derived from the new dashboard, including `:page_title` and targeted-member resolution where applicable. Keep active section, picker state/query/form, admission and removal operation state, access-request state, targeted success/focus, flash and navigation outside the query result.",
  >       "Map dashboard binding errors back to the LiveView's existing `:forbidden` and `:not_found` owner policy. A failed refresh must not retain private dashboard data or teach the generic binding about redirects, exceptions or Memba authorization.",
  >       "Add focused source/query tests for interest construction, classification, matching, missing-scope fallbacks and unrelated-club isolation. Keep the interest representation app-private and provisional; this task must not claim a frozen package vocabulary.",
  >       "Add focused LiveView proof that club members and selected-group members enter and leave already-open lists, counts and name ordering converge, represented Person invalidation rereads only matching dashboards, represented role assignment/removal and role-definition changes update badges, current-actor role or membership loss rechecks authority, and route patches replace old selected-group interests.",
  >       "Retain and extend proof that relevant dashboard replacement preserves transient picker and command state, that unrelated club/person/group notifications do not expose deliberately changed projection data, and that existing admission, targeted-add, conversation-access and route behavior still works through the binding."
  >     ],
  >     "scope_exclusions": [
  >       "Do not migrate conversation detail, delivery detail, settings, message composition, group creation, invitations or any staff, public or auth surface; tasks 006, 008 and 009 retain those obligations.",
  >       "Do not freeze the provisional API or interest vocabulary. Conversation detail must provide the second materially different vertical proof before task 006 freezes the contract.",
  >       "Do not extract a local Mix package, add a path dependency, or change Docker, release or quality-gate integration; tasks 007 and 010 own those changes.",
  >       "Do not complete projector mappings needed only by non-dashboard consumers or implement delivery-row lookup fallbacks for conversation and delivery detail; task 008 retains the complete adapter obligation.",
  >       "Do not add or change domain events, aggregates, commands, projector writes, projection schemas, migrations, authorization policy or read-model persistence just to drive invalidation.",
  >       "Do not introduce `PersonRenamed`, name editing or profile-photo behavior. Prove the dashboard's exact represented-Person invalidation with existing Person projector envelopes and controlled projection state; iterations 068 and 069 remain out of scope.",
  >       "Do not require exact represented role IDs if the dashboard result does not expose them. Exact membership role-assignment interests plus the accepted conservative club role/permission invalidation are sufficient for this provisional slice.",
  >       "Do not retain the broad MemberEmailDelivery dashboard handler as compatibility behavior; delivery state is not part of the accepted dashboard result.",
  >       "Do not add a GenServer, process per query, global cache, durable notification log, projector replay, event-driven field patching or a claim that PubSub is durable.",
  >       "Do not edit the approved plan, todo line, migration matrix, ADRs, acceptance feature or design sources, and do not mark task 005 complete."
  >     ],
  >     "references": [
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/plan.md",
  >         "facts": "The approved technical model requires one authorized dashboard query under one assign, collection interests for absent-row entry and exit, represented identity interests, fresh authorization on every refresh, subscribe-before-read, bind-window reconciliation and rereading rather than patching fields from events. Dashboard and conversation detail must prove the provisional contract before API freeze."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/todo.md",
  >         "facts": "Task 005 is the first unchecked obligation. It owns dashboard wiring and proof; task 006 retains conversation detail and API freeze, task 007 retains package extraction, task 008 retains complete adapter coverage, and task 011 retains the acceptance feature and final full gate."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
  >         "facts": "The accepted dashboard matrix identifies selected-club members, discoverable and participating groups, selected-group members and conversations, represented Persons and role assignments, current permissions and access as dependencies. Its projector table defines scoped Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess mappings, including conservative fallbacks and the remaining dashboard proof gaps."
  >       },
  >       {
  >         "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
  >         "facts": "The accepted decision requires each view-specific query to return one coherent view model for one assign, with the LiveView owning subscription and relevant committed changes triggering a fresh authorized read. Memba concerns remain outside the generic mechanism, and staff streams are deferred."
  >       },
  >       {
  >         "path": "docs/adr/0021-publish-committed-read-model-changes.md",
  >         "facts": "Committed projector updates are published as `{:read_model_changed, %{projector: ..., source_event: ..., metadata: ..., changes: ...}}` on the shared application PubSub topic after projection transactions commit."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/binding.ex",
  >         "facts": "The accepted provisional binding already supports disconnected reads, connected subscription before the initial read, one shared source, bind-window reconciliation, relevant-only refresh, replacement interests, route rebind and owner-visible access errors while keeping state in the LiveView process. Dashboard integration should consume this behavior rather than create a second lifecycle."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/query.ex",
  >         "facts": "A provisional query has a stable identity, one public assign and a one-argument loader returning either one result plus opaque interests or an access error. Its callback shape remains app-private until both vertical proofs are complete."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/source.ex",
  >         "facts": "The provisional source separates subscription, raw-notification classification and opaque interest matching. It deliberately contains no Memba projector mapping, so dashboard-specific translation belongs in an injected app adapter."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live/member_dashboard_live.ex",
  >         "facts": "The accepted dashboard already stores projection-backed output only in `:dashboard` and derives `:page_title`, but it still manually subscribes, broadly refreshes for every MemberEmailDelivery change and handles only a same-club projector allowlist. `handle_params/3` and command paths call the old direct refresh helper, while picker, targeted-member, operation and access-request assigns remain LiveView-owned."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_query.ex",
  >         "facts": "The accepted query starts from routed club ID, authenticated email and selected group ID; every call normalizes the email, rereads active clubs and delegates to the established presentation boundary, preserving `:forbidden` and `:not_found` distinctions."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_presentation.ex",
  >         "facts": "The coherent dashboard result composes club members, discoverable and participating groups, current authorization, selected-group members, conversations, represented names and role labels. Conversation rows include reply-derived data but deliberately omit delivery glance fields, so MemberEmailDelivery is no longer a dashboard dependency."
  >       },
  >       {
  >         "path": "web/lib/memba/read_model_changes.ex",
  >         "facts": "The existing publisher exposes the single shared topic and ADR-defined post-commit envelope. The dashboard adapter should subscribe through this API; no publisher or projector write change is required."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/person.ex",
  >         "facts": "Current Person projector notifications cover creation and email-address changes and carry Person identity but no club scope. Task 005 must match represented Person identities without inventing a club or introducing the out-of-scope PersonRenamed event."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/role.ex",
  >         "facts": "Role projection handles role definitions, permissions, exact assignments/removals and membership-removal compatibility events. Exact assignment events carry club, membership, person and role IDs, while compatibility removals may require conservative membership, club-permission or global family invalidation."
  >       },
  >       {
  >         "path": "web/lib/memba/messaging/projectors/message.ex",
  >         "facts": "MessageSent projects roots and replies using a derivable conversation ID. The event carries club and conversation/message identity but no audience group, requiring a conservative club-conversation invalidation for dashboard collection entry and reply-derived changes."
  >       },
  >       {
  >         "path": "web/test/memba_web/live/member_dashboard_live_test.exs",
  >         "facts": "Existing tests establish the sole `:dashboard` result assign, group discovery refresh, selected-group access loss, current-actor role loss, conversation-access removal, route rechecks and picker-state preservation. Missing proof includes club-member entry/exit and ordering, represented Person isolation, live represented-member badge changes and old-interest replacement after route patches."
  >       },
  >       {
  >         "path": "web/test/memba_web/live/member_dashboard_admission_live_test.exs",
  >         "facts": "This suite protects the strongest existing real command/projector-to-open-dashboard group-admission behavior and command-owned state. It should remain passing while the manual handler is replaced by the provisional binding."
  >       },
  >       {
  >         "path": "docs/reference/liveview.md",
  >         "facts": "LiveView state changes belong in socket assigns and behavioral tests should use framework APIs. Query refresh must replace the dashboard assign without disturbing transient form, picker or navigation state."
  >       },
  >       {
  >         "path": "docs/reference/elixir-mix-tests.md",
  >         "facts": "Focused tests must avoid `Process.sleep/1`, use deterministic synchronization, and start test processes with `start_supervised!/1` where applicable."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
  >         "facts": "The task-004 worker reported the provisional Query, Source and Binding implementation with seven focused tests passing, including relevant-only refresh, interest replacement, route rebind, access errors, bind-window reconciliation and fresh connected remounts. It explicitly left dashboard wiring and Memba mapping for task 005."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
  >         "facts": "The latest review accepted task 004 and confirmed that dashboard wiring, scoped Memba translation and vertical behavior proof remain later work. There is no rejected task-005 candidate to revise, so this packet is a fresh implementation attempt."
  >       }
  >     ],
  >     "constraints": [
  >       "Keep all dashboard interest and invalidation types app-private and provisional; do not present names or tuple shapes as the frozen package API.",
  >       "Keep the dashboard query result coherent under only `:dashboard`; do not mirror projection fields into separate public socket assigns.",
  >       "Continue to execute reads, subscription handling and refreshes in the owning LiveView process.",
  >       "Use the accepted provisional Binding, Query and Source responsibilities. Change their generic behavior only if dashboard integration reveals a concrete contract defect, and document that defect and its focused regression proof.",
  >       "Subscribe only during connected binding and before the initial connected read. Preserve disconnected initial rendering without a PubSub subscription.",
  >       "On every bind, route rebind and relevant notification, use the authenticated email to reread current active-club and page-specific authority; never authorize from `current_identity_clubs` captured at mount.",
  >       "Replace successful dashboard result and interests together. Do not patch dashboard fields from source events or retain old interests after route rebind.",
  >       "Scope notifications using carried IDs whenever available. Unknown or legacy dashboard-relevant events must use the matrix's conservative family, club or global fallback rather than being silently ignored.",
  >       "Keep represented-member role-label invalidation distinct from current-actor permission invalidation, even when one Role event produces both invalidations.",
  >       "Treat MessageSent roots and replies as dashboard dependencies, but do not restore delivery-status interests or the old all-deliveries refresh.",
  >       "Preserve existing forbidden versus not-found owner behavior and clear private query data on an access error before leaving or raising from the private surface.",
  >       "Preserve route state, targeted-member coordination, picker/form contents, command operation state, flash and navigation across successful query refreshes.",
  >       "Do not use `Process.sleep/1` in tests, do not run an unscoped full-suite command as focused validation, and do not mark the todo line complete."
  >     ],
  >     "focused_validation": [
  >       "bin/dev test test/memba_web/live_query test/memba_web/member_dashboard_query_test.exs",
  >       "bin/dev test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_dashboard_admission_live_test.exs test/memba_web/live/member_dashboard_targeted_add_live_test.exs",
  >       "bin/mix format --check-formatted",
  >       "git diff --check"
  >     ],
  >     "completion_evidence_required": [
  >       "List every changed path and state whether it implements dashboard query interests, Memba source translation, LiveView integration or focused proof.",
  >       "Document the final provisional dashboard query input, success and access-error shapes and show that fresh active-club authority is reread for bind, rebind and notification refresh.",
  >       "Enumerate the dashboard collection, represented identity and authorization interests produced from a successful result, including absent-row entry scopes and replacement after a selected-group route change.",
  >       "Provide a projector/event-to-invalidation summary for Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess, including the conservative behavior used when exact scope is missing.",
  >       "Show that the dashboard no longer manually subscribes or uses its old projector allowlist and broad MemberEmailDelivery handler, and that its notifications flow through the provisional binding.",
  >       "Identify focused tests proving club-member entry/removal, selected-group member entry/removal, member ordering and derived count updates in an already-open dashboard.",
  >       "Identify focused tests proving exact represented-Person matching and isolation without introducing PersonRenamed or another out-of-scope domain event.",
  >       "Identify focused tests proving represented-member role badge assignment/removal or role-definition refresh independently from current-actor permission and access transitions.",
  >       "Show that route patching replaces old selected-group interests, preserves not-found semantics and prevents an old-group-only notification from refreshing the rebound dashboard.",
  >       "Show that selected-club membership, current-actor role or selected-group participation loss performs a fresh authorized read and does not retain private rows.",
  >       "Show unrelated-club and unrelated-Person/group notifications are ignored through the real source matching path rather than merely by a hand-written LiveView clause.",
  >       "Show a relevant dashboard replacement preserves picker/query state and the existing admission, targeted-add, operation, access-request, active-section, flash and navigation behavior.",
  >       "Confirm that no conversation-detail migration, API freeze, package extraction, complete cross-surface adapter, domain event, projector write, acceptance feature or staff-stream change was introduced.",
  >       "Report every focused validation command with exit status and concise pass evidence, plus any unresolved issue; missing entry/exit, role, access, route-isolation or transient-state proof must remain unresolved rather than being treated as complete."
  >     ],
  >     "candidate_origins": []
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
  {"preferred_next_label": "implement"}
  ```

## Stage: revise_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > Packet `task-003-ca07fef-page-title-revision-2` is `ready_for_review`.
  > 
  > Implemented:
  > 
  > - Added a shared `install_dashboard/2` path used by both initial mount and refresh in [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:562).
  > - The helper keeps `:dashboard` as the sole projection-query result and derives only shell metadata `:page_title` from `dashboard.page_title`.
  > - Added the exact regression assertion in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:59):
  >   `assert page_title(view) == "Alpine Club · Memba"`
  > - Preserved all existing authorization, route, transient-state, and provisional notification behavior.
  > - Left the task unchecked as required.
  > - Recorded the result in [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json).
  > 
  > Validation passed:
  > 
  > - `bin/dev test test/memba_web/live/member_dashboard_live_test.exs` — 48 tests, 0 failures
  > - `bin/mix format --check-formatted lib/memba_web/live/member_dashboard_live.ex test/memba_web/live/member_dashboard_live_test.exs` — exit 0
  > - `git diff --check` — exit 0
  > - Worker-result JSON syntax validation — exit 0
  > 
  > The initial TDD run reproduced the defect as `"Memba · Memba"` before the implementation. No unresolved issues remain. Per the packet, the full `dev check` was not run in this worker node; the workflow’s deterministic gate handles it later.

## Stage: route_worker_result
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py route-worker 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  {"preferred_next_label": "review"}
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > {"decision":"revise","task":"- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.","reason":"Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard."}

## Stage: apply_task_verdict
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/apply_task_verdict.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Task revise: - [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.
  Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard.
  {"preferred_next_label": "revise"}
  ```

## Stage: before_delivery_planner
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py before-planner 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Delivery planner baseline captured from 44a595703dd8120dab79bcabaf98e85132fa1bdf in docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json
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
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "accepted_tasks": [
  >       "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
  >       "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
  >       "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >     ],
  >     "pending_obligations": [
  >       {
  >         "task_id": "task-005",
  >         "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >         "status": "prepared",
  >         "origin": "Dashboard vertical proof split from approved plan tasks 2, 4 and 5, using the accepted provisional lifecycle contract before public API freeze.",
  >         "replaces": [
  >           "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "Dashboard registration through the provisional binding",
  >           "Dashboard-specific Memba ReadModelChanges subscription and translation",
  >           "Scoped dashboard collection, identity and authorization interests",
  >           "Club-member and selected-group member entry and exit",
  >           "Member ordering and derived counts",
  >           "Represented Person and role-label refresh",
  >           "Current-actor role, route and access transitions using fresh authority",
  >           "Message and conversation-access invalidation required by the existing dashboard model",
  >           "Unrelated-club and unrelated-notification isolation",
  >           "Transient dashboard state preservation"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-006",
  >         "todo_line": "- [ ] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
  >         "status": "pending",
  >         "origin": "Conversation-detail vertical proof and API-freeze gate split from approved plan tasks 2, 4, 5 and 7. It follows the dashboard proof so the generic contract is justified by two materially different consumers.",
  >         "replaces": [
  >           "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "One coherent conversation-detail result assign",
  >           "Conversation-message collection and represented-author interests",
  >           "Exact follow identity",
  >           "Member delivery status and staff delivery reason contributors",
  >           "Independent projector commit-order convergence",
  >           "Fresh membership, group and conversation authorization",
  >           "Unrelated conversation, message, delivery, club and Person isolation",
  >           "Reply and disclosure state preservation",
  >           "Generic contract freeze only after both vertical proofs"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-007",
  >         "todo_line": "- [ ] 007 Extract, implement and test the frozen generic contract as a local Mix package, replace the two provisional consumers with it, and cover interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, subscriber cleanup and lifecycle without Memba or Commanded imports.",
  >         "status": "pending",
  >         "origin": "Remaining generic-package implementation from approved plan task 3, reordered after the two pre-freeze vertical proofs required by the approved technical model.",
  >         "replaces": [
  >           "- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports."
  >         ],
  >         "coverage": [
  >           "Extractable local Mix application",
  >           "Replacement of app-private binding use in dashboard and conversation detail",
  >           "Generic query registration, interest replacement, matching and refresh",
  >           "Duplicate and out-of-order notification behavior",
  >           "Subscriber cleanup and lifecycle tests",
  >           "No Memba or Commanded imports in package source or tests"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-008",
  >         "todo_line": "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
  >         "status": "pending",
  >         "origin": "Remaining application-adapter and query work from approved plan task 4 after the dashboard and conversation proof mappings are implemented.",
  >         "replaces": [
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
  >         ],
  >         "coverage": [
  >           "Every projector/event mapping recorded in the accepted migration matrix",
  >           "Collection, identity and authorization interests",
  >           "Old and new scopes where available",
  >           "Conservative club, family or global fallbacks when exact scope is unavailable",
  >           "Remaining fresh authorized view-specific queries",
  >           "No app-specific policy in the generic package"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-009",
  >         "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
  >         "status": "pending",
  >         "origin": "Remaining migration work from approved plan task 5 after dashboard and conversation detail serve as the pre-freeze proof consumers.",
  >         "replaces": [
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress."
  >         ],
  >         "coverage": [
  >           "Group creation, settings, message composition, delivery detail and invitation LiveViews",
  >           "One coherent result assign per remaining in-scope page",
  >           "Preserved routes, access transitions, forms, commands, navigation and UI",
  >           "Live delivery status and staff reason convergence",
  >           "Existing conversation and delivery behavior",
  >           "No staff stream migration"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-010",
  >         "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
  >         "status": "pending",
  >         "origin": "Approved plan task 6, retained after minimum development-time package consumption and separated from production release and quality-gate completion.",
  >         "replaces": [
  >           "- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."
  >         ],
  >         "coverage": [
  >           "Supported path dependency in web/mix.exs",
  >           "Docker dependency-copy and compilation ordering",
  >           "Production release inclusion",
  >           "Explicit package test execution in the repository quality gate",
  >           "Supported local and CI environments"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-011",
  >         "todo_line": "- [ ] 011 Add the focused acceptance example, close the focused proof gaps for every migrated member page and a real committed-projector-to-open-LiveView path, complete package lifecycle/race coverage, and run final `dev check`.",
  >         "status": "pending",
  >         "origin": "Approved plan task 7 retained as the final acceptance, proof-gap and exact-state validation obligation after implementation slices complete.",
  >         "replaces": [
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "Stakeholder-readable club-member live-update example",
  >           "Focused regression proof for every migrated member page",
  >           "At least one real committed-projector-to-open-LiveView path",
  >           "Remaining package mount, change, reconnect and race coverage",
  >           "Final full dev check on the exact delivered state"
  >         ],
  >         "candidate_origins": []
  >       }
  >     ],
  >     "candidate_origins": [],
  >     "coverage_map": [
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, focused-proof inventory and explicit exclusions."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted dashboard query/view-model boundary, fresh-authority prerequisite, coherent dashboard result assign, connected subscribe-before-read ordering and provisional predicates."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted provisional generic lifecycle, opaque-interest matching, route rebind, bind-window reconciliation, access-error and reconnect contract."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-005"
  >         ],
  >         "scope": "Dashboard binding, dashboard-scoped Memba invalidation and vertical behavior proof."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-006"
  >         ],
  >         "scope": "Conversation-detail binding, multi-projector/access proof and API freeze."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-007"
  >         ],
  >         "scope": "Frozen generic local package extraction and hardening."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-008"
  >         ],
  >         "scope": "Complete Memba notification adapter and remaining authorized queries."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-009"
  >         ],
  >         "scope": "Migration of the five remaining in-scope member LiveViews."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-010"
  >         ],
  >         "scope": "Production package, Docker release and quality-gate integration."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-011"
  >         ],
  >         "scope": "Acceptance example, remaining focused proof and final exact-state validation."
  >       }
  >     ],
  >     "planner_note": "The accepted review for task 004 is reflected by preserving its exact checked todo line and removing that completed obligation from pending work. Task 005 is now the first unchecked line and is prepared as the dashboard vertical proof without further splitting or reordering. The accepted provisional Binding, Query and Source modules supply the lifecycle prerequisite; this packet adds only dashboard-specific query interests, Memba notification translation and consumer proof. Conversation detail and API freeze remain task 006, package extraction remains task 007, full adapter completion remains task 008, and the acceptance feature plus full dev check remain task 011. No todo line was edited during this planner visit, and there is no unaccepted candidate origin to preserve."
  >   },
  >   "planner_result": {
  >     "schema_version": 1,
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "decision": "ready"
  >   },
  >   "current_worker_packet": {
  >     "schema_version": 1,
  >     "packet_id": "task-005-bcf5640-dashboard-binding-1",
  >     "task_id": "task-005",
  >     "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >     "attempt": "implementation",
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "outcome": "Make the existing member dashboard a real consumer of the provisional LiveView-owned query binding: one fresh-authorized dashboard result and its replacement interests must drive scoped refreshes from committed Memba projection notifications, while unrelated changes are ignored and route, access and transient UI behavior remain intact.",
  >     "scope": [
  >       "Add an app-private, explicitly provisional Memba ReadModelChanges source adapter that subscribes to the shared PubSub topic, classifies dashboard-relevant projector notifications into opaque invalidations, and performs scoped interest matching without moving Memba knowledge into the generic Binding or Source modules.",
  >       "Adapt `MembaWeb.MemberDashboardQuery` to provide a provisional query descriptor or loader returning the existing coherent dashboard view model plus replacement interests. Preserve `load/3` as the fresh-authority boundary, or retain an equivalent directly tested public contract, so every bind, rebind and notification refresh normalizes the authenticated email and rereads active-club authority.",
  >       "Register only one dashboard live query under the existing `:dashboard` assign. Do not recreate separate projection-backed compatibility assigns; internal binding metadata and shell-derived `:page_title` are not additional query results.",
  >       "Register dashboard collection interests for selected-club members, discoverable groups, current-person participating groups, selected-group members, selected-group conversations and represented-membership role assignments so rows absent from the old result can enter and existing rows can leave.",
  >       "Register exact or represented interests for the selected Club and Group, current membership and Person, represented member and conversation participant Persons, represented groups, conversations/messages, selected-group access, current-actor permissions and role data. Keep current-actor authorization interests distinct from represented-member badge interests.",
  >       "Translate dashboard-relevant Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess projector notifications according to the accepted migration matrix. Scope known club, group, person, membership and conversation identities; use the documented family, club or global conservative fallback when required scope is unavailable instead of silently ignoring a potentially relevant event.",
  >       "For `MessageSent`, emit exact or derived conversation invalidations and a conservative club-conversation invalidation because the event does not contain its audience group. Preserve existing dashboard conversation and reply convergence while removing the current unscoped MemberEmailDelivery refresh, since the dashboard no longer displays delivery data.",
  >       "Replace the dashboard's manual PubSub subscription and hand-written projector predicates with `Binding.bind/4` during mount, `Binding.rebind/3` for route-dependent selected-group changes and explicit command-driven rereads, and `Binding.handle_notification/2` for source messages. Connected bind must subscribe before reading; disconnected mount must read without subscribing.",
  >       "After each successful bind, rebind or notification refresh, synchronize only LiveView-owned shell or route coordination derived from the new dashboard, including `:page_title` and targeted-member resolution where applicable. Keep active section, picker state/query/form, admission and removal operation state, access-request state, targeted success/focus, flash and navigation outside the query result.",
  >       "Map dashboard binding errors back to the LiveView's existing `:forbidden` and `:not_found` owner policy. A failed refresh must not retain private dashboard data or teach the generic binding about redirects, exceptions or Memba authorization.",
  >       "Add focused source/query tests for interest construction, classification, matching, missing-scope fallbacks and unrelated-club isolation. Keep the interest representation app-private and provisional; this task must not claim a frozen package vocabulary.",
  >       "Add focused LiveView proof that club members and selected-group members enter and leave already-open lists, counts and name ordering converge, represented Person invalidation rereads only matching dashboards, represented role assignment/removal and role-definition changes update badges, current-actor role or membership loss rechecks authority, and route patches replace old selected-group interests.",
  >       "Retain and extend proof that relevant dashboard replacement preserves transient picker and command state, that unrelated club/person/group notifications do not expose deliberately changed projection data, and that existing admission, targeted-add, conversation-access and route behavior still works through the binding."
  >     ],
  >     "scope_exclusions": [
  >       "Do not migrate conversation detail, delivery detail, settings, message composition, group creation, invitations or any staff, public or auth surface; tasks 006, 008 and 009 retain those obligations.",
  >       "Do not freeze the provisional API or interest vocabulary. Conversation detail must provide the second materially different vertical proof before task 006 freezes the contract.",
  >       "Do not extract a local Mix package, add a path dependency, or change Docker, release or quality-gate integration; tasks 007 and 010 own those changes.",
  >       "Do not complete projector mappings needed only by non-dashboard consumers or implement delivery-row lookup fallbacks for conversation and delivery detail; task 008 retains the complete adapter obligation.",
  >       "Do not add or change domain events, aggregates, commands, projector writes, projection schemas, migrations, authorization policy or read-model persistence just to drive invalidation.",
  >       "Do not introduce `PersonRenamed`, name editing or profile-photo behavior. Prove the dashboard's exact represented-Person invalidation with existing Person projector envelopes and controlled projection state; iterations 068 and 069 remain out of scope.",
  >       "Do not require exact represented role IDs if the dashboard result does not expose them. Exact membership role-assignment interests plus the accepted conservative club role/permission invalidation are sufficient for this provisional slice.",
  >       "Do not retain the broad MemberEmailDelivery dashboard handler as compatibility behavior; delivery state is not part of the accepted dashboard result.",
  >       "Do not add a GenServer, process per query, global cache, durable notification log, projector replay, event-driven field patching or a claim that PubSub is durable.",
  >       "Do not edit the approved plan, todo line, migration matrix, ADRs, acceptance feature or design sources, and do not mark task 005 complete."
  >     ],
  >     "references": [
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/plan.md",
  >         "facts": "The approved technical model requires one authorized dashboard query under one assign, collection interests for absent-row entry and exit, represented identity interests, fresh authorization on every refresh, subscribe-before-read, bind-window reconciliation and rereading rather than patching fields from events. Dashboard and conversation detail must prove the provisional contract before API freeze."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/todo.md",
  >         "facts": "Task 005 is the first unchecked obligation. It owns dashboard wiring and proof; task 006 retains conversation detail and API freeze, task 007 retains package extraction, task 008 retains complete adapter coverage, and task 011 retains the acceptance feature and final full gate."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
  >         "facts": "The accepted dashboard matrix identifies selected-club members, discoverable and participating groups, selected-group members and conversations, represented Persons and role assignments, current permissions and access as dependencies. Its projector table defines scoped Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess mappings, including conservative fallbacks and the remaining dashboard proof gaps."
  >       },
  >       {
  >         "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
  >         "facts": "The accepted decision requires each view-specific query to return one coherent view model for one assign, with the LiveView owning subscription and relevant committed changes triggering a fresh authorized read. Memba concerns remain outside the generic mechanism, and staff streams are deferred."
  >       },
  >       {
  >         "path": "docs/adr/0021-publish-committed-read-model-changes.md",
  >         "facts": "Committed projector updates are published as `{:read_model_changed, %{projector: ..., source_event: ..., metadata: ..., changes: ...}}` on the shared application PubSub topic after projection transactions commit."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/binding.ex",
  >         "facts": "The accepted provisional binding already supports disconnected reads, connected subscription before the initial read, one shared source, bind-window reconciliation, relevant-only refresh, replacement interests, route rebind and owner-visible access errors while keeping state in the LiveView process. Dashboard integration should consume this behavior rather than create a second lifecycle."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/query.ex",
  >         "facts": "A provisional query has a stable identity, one public assign and a one-argument loader returning either one result plus opaque interests or an access error. Its callback shape remains app-private until both vertical proofs are complete."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/source.ex",
  >         "facts": "The provisional source separates subscription, raw-notification classification and opaque interest matching. It deliberately contains no Memba projector mapping, so dashboard-specific translation belongs in an injected app adapter."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live/member_dashboard_live.ex",
  >         "facts": "The accepted dashboard already stores projection-backed output only in `:dashboard` and derives `:page_title`, but it still manually subscribes, broadly refreshes for every MemberEmailDelivery change and handles only a same-club projector allowlist. `handle_params/3` and command paths call the old direct refresh helper, while picker, targeted-member, operation and access-request assigns remain LiveView-owned."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_query.ex",
  >         "facts": "The accepted query starts from routed club ID, authenticated email and selected group ID; every call normalizes the email, rereads active clubs and delegates to the established presentation boundary, preserving `:forbidden` and `:not_found` distinctions."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_presentation.ex",
  >         "facts": "The coherent dashboard result composes club members, discoverable and participating groups, current authorization, selected-group members, conversations, represented names and role labels. Conversation rows include reply-derived data but deliberately omit delivery glance fields, so MemberEmailDelivery is no longer a dashboard dependency."
  >       },
  >       {
  >         "path": "web/lib/memba/read_model_changes.ex",
  >         "facts": "The existing publisher exposes the single shared topic and ADR-defined post-commit envelope. The dashboard adapter should subscribe through this API; no publisher or projector write change is required."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/person.ex",
  >         "facts": "Current Person projector notifications cover creation and email-address changes and carry Person identity but no club scope. Task 005 must match represented Person identities without inventing a club or introducing the out-of-scope PersonRenamed event."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/role.ex",
  >         "facts": "Role projection handles role definitions, permissions, exact assignments/removals and membership-removal compatibility events. Exact assignment events carry club, membership, person and role IDs, while compatibility removals may require conservative membership, club-permission or global family invalidation."
  >       },
  >       {
  >         "path": "web/lib/memba/messaging/projectors/message.ex",
  >         "facts": "MessageSent projects roots and replies using a derivable conversation ID. The event carries club and conversation/message identity but no audience group, requiring a conservative club-conversation invalidation for dashboard collection entry and reply-derived changes."
  >       },
  >       {
  >         "path": "web/test/memba_web/live/member_dashboard_live_test.exs",
  >         "facts": "Existing tests establish the sole `:dashboard` result assign, group discovery refresh, selected-group access loss, current-actor role loss, conversation-access removal, route rechecks and picker-state preservation. Missing proof includes club-member entry/exit and ordering, represented Person isolation, live represented-member badge changes and old-interest replacement after route patches."
  >       },
  >       {
  >         "path": "web/test/memba_web/live/member_dashboard_admission_live_test.exs",
  >         "facts": "This suite protects the strongest existing real command/projector-to-open-dashboard group-admission behavior and command-owned state. It should remain passing while the manual handler is replaced by the provisional binding."
  >       },
  >       {
  >         "path": "docs/reference/liveview.md",
  >         "facts": "LiveView state changes belong in socket assigns and behavioral tests should use framework APIs. Query refresh must replace the dashboard assign without disturbing transient form, picker or navigation state."
  >       },
  >       {
  >         "path": "docs/reference/elixir-mix-tests.md",
  >         "facts": "Focused tests must avoid `Process.sleep/1`, use deterministic synchronization, and start test processes with `start_supervised!/1` where applicable."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
  >         "facts": "The task-004 worker reported the provisional Query, Source and Binding implementation with seven focused tests passing, including relevant-only refresh, interest replacement, route rebind, access errors, bind-window reconciliation and fresh connected remounts. It explicitly left dashboard wiring and Memba mapping for task 005."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
  >         "facts": "The latest review accepted task 004 and confirmed that dashboard wiring, scoped Memba translation and vertical behavior proof remain later work. There is no rejected task-005 candidate to revise, so this packet is a fresh implementation attempt."
  >       }
  >     ],
  >     "constraints": [
  >       "Keep all dashboard interest and invalidation types app-private and provisional; do not present names or tuple shapes as the frozen package API.",
  >       "Keep the dashboard query result coherent under only `:dashboard`; do not mirror projection fields into separate public socket assigns.",
  >       "Continue to execute reads, subscription handling and refreshes in the owning LiveView process.",
  >       "Use the accepted provisional Binding, Query and Source responsibilities. Change their generic behavior only if dashboard integration reveals a concrete contract defect, and document that defect and its focused regression proof.",
  >       "Subscribe only during connected binding and before the initial connected read. Preserve disconnected initial rendering without a PubSub subscription.",
  >       "On every bind, route rebind and relevant notification, use the authenticated email to reread current active-club and page-specific authority; never authorize from `current_identity_clubs` captured at mount.",
  >       "Replace successful dashboard result and interests together. Do not patch dashboard fields from source events or retain old interests after route rebind.",
  >       "Scope notifications using carried IDs whenever available. Unknown or legacy dashboard-relevant events must use the matrix's conservative family, club or global fallback rather than being silently ignored.",
  >       "Keep represented-member role-label invalidation distinct from current-actor permission invalidation, even when one Role event produces both invalidations.",
  >       "Treat MessageSent roots and replies as dashboard dependencies, but do not restore delivery-status interests or the old all-deliveries refresh.",
  >       "Preserve existing forbidden versus not-found owner behavior and clear private query data on an access error before leaving or raising from the private surface.",
  >       "Preserve route state, targeted-member coordination, picker/form contents, command operation state, flash and navigation across successful query refreshes.",
  >       "Do not use `Process.sleep/1` in tests, do not run an unscoped full-suite command as focused validation, and do not mark the todo line complete."
  >     ],
  >     "focused_validation": [
  >       "bin/dev test test/memba_web/live_query test/memba_web/member_dashboard_query_test.exs",
  >       "bin/dev test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_dashboard_admission_live_test.exs test/memba_web/live/member_dashboard_targeted_add_live_test.exs",
  >       "bin/mix format --check-formatted",
  >       "git diff --check"
  >     ],
  >     "completion_evidence_required": [
  >       "List every changed path and state whether it implements dashboard query interests, Memba source translation, LiveView integration or focused proof.",
  >       "Document the final provisional dashboard query input, success and access-error shapes and show that fresh active-club authority is reread for bind, rebind and notification refresh.",
  >       "Enumerate the dashboard collection, represented identity and authorization interests produced from a successful result, including absent-row entry scopes and replacement after a selected-group route change.",
  >       "Provide a projector/event-to-invalidation summary for Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess, including the conservative behavior used when exact scope is missing.",
  >       "Show that the dashboard no longer manually subscribes or uses its old projector allowlist and broad MemberEmailDelivery handler, and that its notifications flow through the provisional binding.",
  >       "Identify focused tests proving club-member entry/removal, selected-group member entry/removal, member ordering and derived count updates in an already-open dashboard.",
  >       "Identify focused tests proving exact represented-Person matching and isolation without introducing PersonRenamed or another out-of-scope domain event.",
  >       "Identify focused tests proving represented-member role badge assignment/removal or role-definition refresh independently from current-actor permission and access transitions.",
  >       "Show that route patching replaces old selected-group interests, preserves not-found semantics and prevents an old-group-only notification from refreshing the rebound dashboard.",
  >       "Show that selected-club membership, current-actor role or selected-group participation loss performs a fresh authorized read and does not retain private rows.",
  >       "Show unrelated-club and unrelated-Person/group notifications are ignored through the real source matching path rather than merely by a hand-written LiveView clause.",
  >       "Show a relevant dashboard replacement preserves picker/query state and the existing admission, targeted-add, operation, access-request, active-section, flash and navigation behavior.",
  >       "Confirm that no conversation-detail migration, API freeze, package extraction, complete cross-surface adapter, domain event, projector write, acceptance feature or staff-stream change was introduced.",
  >       "Report every focused validation command with exit status and concise pass evidence, plus any unresolved issue; missing entry/exit, role, access, route-isolation or transient-state proof must remain unresolved rather than being treated as complete."
  >     ],
  >     "candidate_origins": []
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
  {"preferred_next_label": "implement"}
  ```

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > Implemented packet `task-005-bcf5640-dashboard-binding-1` with result `ready_for_review`.
  > 
  > Key changes:
  > 
  > - Added the provisional scoped Memba notification adapter in [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex), covering Club, Membership, Person, Group, GroupMembership, Role, Message, and ConversationGroupAccess notifications with exact scopes and conservative fallbacks.
  > - Extended [member_dashboard_query.ex](/workspace/memba/web/lib/memba_web/member_dashboard_query.ex) with a single `:dashboard` query descriptor and replacement interests for collections, represented identities, role badges, permissions, participation, conversations, and access.
  > - Migrated [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex) from manual subscription/projector filtering to `Binding.bind/4`, `Binding.rebind/3`, and `Binding.handle_notification/2`. The broad MemberEmailDelivery refresh was removed.
  > - Added focused proof for member entry/removal/order/counts, represented Person and Group isolation, role assignment/definition/removal, route-interest replacement, current membership loss, and transient-state preservation.
  > - Wrote the required artifact at [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json). The task remains unchecked in `todo.md`.
  > 
  > Validation passed:
  > 
  > - Live-query and dashboard-query tests: 18 tests, 0 failures.
  > - Dashboard presentation, LiveView, admission, and targeted-add tests: 89 tests, 0 failures.
  > - `bin/mix format --check-formatted`: passed.
  > - `git diff --check`: passed.
  > - Worker result JSON parsed successfully.
  > 
  > No unresolved issues. The full `dev check` was intentionally not run because this packet delegates that unscoped gate to the workflow’s deterministic `dev_check` node.

## Stage: route_worker_result
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py route-worker 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  {"preferred_next_label": "review"}
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > {"decision":"revise","task":"- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.","reason":"Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard."}

## Stage: apply_task_verdict
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/apply_task_verdict.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Task revise: - [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.
  Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard.
  {"preferred_next_label": "revise"}
  ```

## Stage: before_delivery_planner
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py before-planner 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Delivery planner baseline captured from 44a595703dd8120dab79bcabaf98e85132fa1bdf in docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json
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
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "accepted_tasks": [
  >       "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
  >       "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
  >       "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >     ],
  >     "pending_obligations": [
  >       {
  >         "task_id": "task-005",
  >         "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >         "status": "prepared",
  >         "origin": "Dashboard vertical proof split from approved plan tasks 2, 4 and 5, using the accepted provisional lifecycle contract before public API freeze.",
  >         "replaces": [
  >           "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "Dashboard registration through the provisional binding",
  >           "Dashboard-specific Memba ReadModelChanges subscription and translation",
  >           "Scoped dashboard collection, identity and authorization interests",
  >           "Club-member and selected-group member entry and exit",
  >           "Member ordering and derived counts",
  >           "Represented Person and role-label refresh",
  >           "Current-actor role, route and access transitions using fresh authority",
  >           "Message and conversation-access invalidation required by the existing dashboard model",
  >           "Unrelated-club and unrelated-notification isolation",
  >           "Transient dashboard state preservation"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-006",
  >         "todo_line": "- [ ] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
  >         "status": "pending",
  >         "origin": "Conversation-detail vertical proof and API-freeze gate split from approved plan tasks 2, 4, 5 and 7. It follows the dashboard proof so the generic contract is justified by two materially different consumers.",
  >         "replaces": [
  >           "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "One coherent conversation-detail result assign",
  >           "Conversation-message collection and represented-author interests",
  >           "Exact follow identity",
  >           "Member delivery status and staff delivery reason contributors",
  >           "Independent projector commit-order convergence",
  >           "Fresh membership, group and conversation authorization",
  >           "Unrelated conversation, message, delivery, club and Person isolation",
  >           "Reply and disclosure state preservation",
  >           "Generic contract freeze only after both vertical proofs"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-007",
  >         "todo_line": "- [ ] 007 Extract, implement and test the frozen generic contract as a local Mix package, replace the two provisional consumers with it, and cover interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, subscriber cleanup and lifecycle without Memba or Commanded imports.",
  >         "status": "pending",
  >         "origin": "Remaining generic-package implementation from approved plan task 3, reordered after the two pre-freeze vertical proofs required by the approved technical model.",
  >         "replaces": [
  >           "- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports."
  >         ],
  >         "coverage": [
  >           "Extractable local Mix application",
  >           "Replacement of app-private binding use in dashboard and conversation detail",
  >           "Generic query registration, interest replacement, matching and refresh",
  >           "Duplicate and out-of-order notification behavior",
  >           "Subscriber cleanup and lifecycle tests",
  >           "No Memba or Commanded imports in package source or tests"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-008",
  >         "todo_line": "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
  >         "status": "pending",
  >         "origin": "Remaining application-adapter and query work from approved plan task 4 after the dashboard and conversation proof mappings are implemented.",
  >         "replaces": [
  >           "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
  >         ],
  >         "coverage": [
  >           "Every projector/event mapping recorded in the accepted migration matrix",
  >           "Collection, identity and authorization interests",
  >           "Old and new scopes where available",
  >           "Conservative club, family or global fallbacks when exact scope is unavailable",
  >           "Remaining fresh authorized view-specific queries",
  >           "No app-specific policy in the generic package"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-009",
  >         "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
  >         "status": "pending",
  >         "origin": "Remaining migration work from approved plan task 5 after dashboard and conversation detail serve as the pre-freeze proof consumers.",
  >         "replaces": [
  >           "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress."
  >         ],
  >         "coverage": [
  >           "Group creation, settings, message composition, delivery detail and invitation LiveViews",
  >           "One coherent result assign per remaining in-scope page",
  >           "Preserved routes, access transitions, forms, commands, navigation and UI",
  >           "Live delivery status and staff reason convergence",
  >           "Existing conversation and delivery behavior",
  >           "No staff stream migration"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-010",
  >         "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
  >         "status": "pending",
  >         "origin": "Approved plan task 6, retained after minimum development-time package consumption and separated from production release and quality-gate completion.",
  >         "replaces": [
  >           "- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."
  >         ],
  >         "coverage": [
  >           "Supported path dependency in web/mix.exs",
  >           "Docker dependency-copy and compilation ordering",
  >           "Production release inclusion",
  >           "Explicit package test execution in the repository quality gate",
  >           "Supported local and CI environments"
  >         ],
  >         "candidate_origins": []
  >       },
  >       {
  >         "task_id": "task-011",
  >         "todo_line": "- [ ] 011 Add the focused acceptance example, close the focused proof gaps for every migrated member page and a real committed-projector-to-open-LiveView path, complete package lifecycle/race coverage, and run final `dev check`.",
  >         "status": "pending",
  >         "origin": "Approved plan task 7 retained as the final acceptance, proof-gap and exact-state validation obligation after implementation slices complete.",
  >         "replaces": [
  >           "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
  >         ],
  >         "coverage": [
  >           "Stakeholder-readable club-member live-update example",
  >           "Focused regression proof for every migrated member page",
  >           "At least one real committed-projector-to-open-LiveView path",
  >           "Remaining package mount, change, reconnect and race coverage",
  >           "Final full dev check on the exact delivered state"
  >         ],
  >         "candidate_origins": []
  >       }
  >     ],
  >     "candidate_origins": [],
  >     "coverage_map": [
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, focused-proof inventory and explicit exclusions."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted dashboard query/view-model boundary, fresh-authority prerequisite, coherent dashboard result assign, connected subscribe-before-read ordering and provisional predicates."
  >       },
  >       {
  >         "accepted_task_lines": [
  >           "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
  >         ],
  >         "pending_task_ids": [],
  >         "scope": "Accepted provisional generic lifecycle, opaque-interest matching, route rebind, bind-window reconciliation, access-error and reconnect contract."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-005"
  >         ],
  >         "scope": "Dashboard binding, dashboard-scoped Memba invalidation and vertical behavior proof."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-006"
  >         ],
  >         "scope": "Conversation-detail binding, multi-projector/access proof and API freeze."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-007"
  >         ],
  >         "scope": "Frozen generic local package extraction and hardening."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-008"
  >         ],
  >         "scope": "Complete Memba notification adapter and remaining authorized queries."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-009"
  >         ],
  >         "scope": "Migration of the five remaining in-scope member LiveViews."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-010"
  >         ],
  >         "scope": "Production package, Docker release and quality-gate integration."
  >       },
  >       {
  >         "accepted_task_lines": [],
  >         "pending_task_ids": [
  >           "task-011"
  >         ],
  >         "scope": "Acceptance example, remaining focused proof and final exact-state validation."
  >       }
  >     ],
  >     "planner_note": "The accepted review for task 004 is reflected by preserving its exact checked todo line and removing that completed obligation from pending work. Task 005 is now the first unchecked line and is prepared as the dashboard vertical proof without further splitting or reordering. The accepted provisional Binding, Query and Source modules supply the lifecycle prerequisite; this packet adds only dashboard-specific query interests, Memba notification translation and consumer proof. Conversation detail and API freeze remain task 006, package extraction remains task 007, full adapter completion remains task 008, and the acceptance feature plus full dev check remain task 011. No todo line was edited during this planner visit, and there is no unaccepted candidate origin to preserve."
  >   },
  >   "planner_result": {
  >     "schema_version": 1,
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "decision": "ready"
  >   },
  >   "current_worker_packet": {
  >     "schema_version": 1,
  >     "packet_id": "task-005-bcf5640-dashboard-binding-1",
  >     "task_id": "task-005",
  >     "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
  >     "attempt": "implementation",
  >     "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
  >     "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
  >     "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
  >     "outcome": "Make the existing member dashboard a real consumer of the provisional LiveView-owned query binding: one fresh-authorized dashboard result and its replacement interests must drive scoped refreshes from committed Memba projection notifications, while unrelated changes are ignored and route, access and transient UI behavior remain intact.",
  >     "scope": [
  >       "Add an app-private, explicitly provisional Memba ReadModelChanges source adapter that subscribes to the shared PubSub topic, classifies dashboard-relevant projector notifications into opaque invalidations, and performs scoped interest matching without moving Memba knowledge into the generic Binding or Source modules.",
  >       "Adapt `MembaWeb.MemberDashboardQuery` to provide a provisional query descriptor or loader returning the existing coherent dashboard view model plus replacement interests. Preserve `load/3` as the fresh-authority boundary, or retain an equivalent directly tested public contract, so every bind, rebind and notification refresh normalizes the authenticated email and rereads active-club authority.",
  >       "Register only one dashboard live query under the existing `:dashboard` assign. Do not recreate separate projection-backed compatibility assigns; internal binding metadata and shell-derived `:page_title` are not additional query results.",
  >       "Register dashboard collection interests for selected-club members, discoverable groups, current-person participating groups, selected-group members, selected-group conversations and represented-membership role assignments so rows absent from the old result can enter and existing rows can leave.",
  >       "Register exact or represented interests for the selected Club and Group, current membership and Person, represented member and conversation participant Persons, represented groups, conversations/messages, selected-group access, current-actor permissions and role data. Keep current-actor authorization interests distinct from represented-member badge interests.",
  >       "Translate dashboard-relevant Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess projector notifications according to the accepted migration matrix. Scope known club, group, person, membership and conversation identities; use the documented family, club or global conservative fallback when required scope is unavailable instead of silently ignoring a potentially relevant event.",
  >       "For `MessageSent`, emit exact or derived conversation invalidations and a conservative club-conversation invalidation because the event does not contain its audience group. Preserve existing dashboard conversation and reply convergence while removing the current unscoped MemberEmailDelivery refresh, since the dashboard no longer displays delivery data.",
  >       "Replace the dashboard's manual PubSub subscription and hand-written projector predicates with `Binding.bind/4` during mount, `Binding.rebind/3` for route-dependent selected-group changes and explicit command-driven rereads, and `Binding.handle_notification/2` for source messages. Connected bind must subscribe before reading; disconnected mount must read without subscribing.",
  >       "After each successful bind, rebind or notification refresh, synchronize only LiveView-owned shell or route coordination derived from the new dashboard, including `:page_title` and targeted-member resolution where applicable. Keep active section, picker state/query/form, admission and removal operation state, access-request state, targeted success/focus, flash and navigation outside the query result.",
  >       "Map dashboard binding errors back to the LiveView's existing `:forbidden` and `:not_found` owner policy. A failed refresh must not retain private dashboard data or teach the generic binding about redirects, exceptions or Memba authorization.",
  >       "Add focused source/query tests for interest construction, classification, matching, missing-scope fallbacks and unrelated-club isolation. Keep the interest representation app-private and provisional; this task must not claim a frozen package vocabulary.",
  >       "Add focused LiveView proof that club members and selected-group members enter and leave already-open lists, counts and name ordering converge, represented Person invalidation rereads only matching dashboards, represented role assignment/removal and role-definition changes update badges, current-actor role or membership loss rechecks authority, and route patches replace old selected-group interests.",
  >       "Retain and extend proof that relevant dashboard replacement preserves transient picker and command state, that unrelated club/person/group notifications do not expose deliberately changed projection data, and that existing admission, targeted-add, conversation-access and route behavior still works through the binding."
  >     ],
  >     "scope_exclusions": [
  >       "Do not migrate conversation detail, delivery detail, settings, message composition, group creation, invitations or any staff, public or auth surface; tasks 006, 008 and 009 retain those obligations.",
  >       "Do not freeze the provisional API or interest vocabulary. Conversation detail must provide the second materially different vertical proof before task 006 freezes the contract.",
  >       "Do not extract a local Mix package, add a path dependency, or change Docker, release or quality-gate integration; tasks 007 and 010 own those changes.",
  >       "Do not complete projector mappings needed only by non-dashboard consumers or implement delivery-row lookup fallbacks for conversation and delivery detail; task 008 retains the complete adapter obligation.",
  >       "Do not add or change domain events, aggregates, commands, projector writes, projection schemas, migrations, authorization policy or read-model persistence just to drive invalidation.",
  >       "Do not introduce `PersonRenamed`, name editing or profile-photo behavior. Prove the dashboard's exact represented-Person invalidation with existing Person projector envelopes and controlled projection state; iterations 068 and 069 remain out of scope.",
  >       "Do not require exact represented role IDs if the dashboard result does not expose them. Exact membership role-assignment interests plus the accepted conservative club role/permission invalidation are sufficient for this provisional slice.",
  >       "Do not retain the broad MemberEmailDelivery dashboard handler as compatibility behavior; delivery state is not part of the accepted dashboard result.",
  >       "Do not add a GenServer, process per query, global cache, durable notification log, projector replay, event-driven field patching or a claim that PubSub is durable.",
  >       "Do not edit the approved plan, todo line, migration matrix, ADRs, acceptance feature or design sources, and do not mark task 005 complete."
  >     ],
  >     "references": [
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/plan.md",
  >         "facts": "The approved technical model requires one authorized dashboard query under one assign, collection interests for absent-row entry and exit, represented identity interests, fresh authorization on every refresh, subscribe-before-read, bind-window reconciliation and rereading rather than patching fields from events. Dashboard and conversation detail must prove the provisional contract before API freeze."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/todo.md",
  >         "facts": "Task 005 is the first unchecked obligation. It owns dashboard wiring and proof; task 006 retains conversation detail and API freeze, task 007 retains package extraction, task 008 retains complete adapter coverage, and task 011 retains the acceptance feature and final full gate."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
  >         "facts": "The accepted dashboard matrix identifies selected-club members, discoverable and participating groups, selected-group members and conversations, represented Persons and role assignments, current permissions and access as dependencies. Its projector table defines scoped Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess mappings, including conservative fallbacks and the remaining dashboard proof gaps."
  >       },
  >       {
  >         "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
  >         "facts": "The accepted decision requires each view-specific query to return one coherent view model for one assign, with the LiveView owning subscription and relevant committed changes triggering a fresh authorized read. Memba concerns remain outside the generic mechanism, and staff streams are deferred."
  >       },
  >       {
  >         "path": "docs/adr/0021-publish-committed-read-model-changes.md",
  >         "facts": "Committed projector updates are published as `{:read_model_changed, %{projector: ..., source_event: ..., metadata: ..., changes: ...}}` on the shared application PubSub topic after projection transactions commit."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/binding.ex",
  >         "facts": "The accepted provisional binding already supports disconnected reads, connected subscription before the initial read, one shared source, bind-window reconciliation, relevant-only refresh, replacement interests, route rebind and owner-visible access errors while keeping state in the LiveView process. Dashboard integration should consume this behavior rather than create a second lifecycle."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/query.ex",
  >         "facts": "A provisional query has a stable identity, one public assign and a one-argument loader returning either one result plus opaque interests or an access error. Its callback shape remains app-private until both vertical proofs are complete."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live_query/source.ex",
  >         "facts": "The provisional source separates subscription, raw-notification classification and opaque interest matching. It deliberately contains no Memba projector mapping, so dashboard-specific translation belongs in an injected app adapter."
  >       },
  >       {
  >         "path": "web/lib/memba_web/live/member_dashboard_live.ex",
  >         "facts": "The accepted dashboard already stores projection-backed output only in `:dashboard` and derives `:page_title`, but it still manually subscribes, broadly refreshes for every MemberEmailDelivery change and handles only a same-club projector allowlist. `handle_params/3` and command paths call the old direct refresh helper, while picker, targeted-member, operation and access-request assigns remain LiveView-owned."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_query.ex",
  >         "facts": "The accepted query starts from routed club ID, authenticated email and selected group ID; every call normalizes the email, rereads active clubs and delegates to the established presentation boundary, preserving `:forbidden` and `:not_found` distinctions."
  >       },
  >       {
  >         "path": "web/lib/memba_web/member_dashboard_presentation.ex",
  >         "facts": "The coherent dashboard result composes club members, discoverable and participating groups, current authorization, selected-group members, conversations, represented names and role labels. Conversation rows include reply-derived data but deliberately omit delivery glance fields, so MemberEmailDelivery is no longer a dashboard dependency."
  >       },
  >       {
  >         "path": "web/lib/memba/read_model_changes.ex",
  >         "facts": "The existing publisher exposes the single shared topic and ADR-defined post-commit envelope. The dashboard adapter should subscribe through this API; no publisher or projector write change is required."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/person.ex",
  >         "facts": "Current Person projector notifications cover creation and email-address changes and carry Person identity but no club scope. Task 005 must match represented Person identities without inventing a club or introducing the out-of-scope PersonRenamed event."
  >       },
  >       {
  >         "path": "web/lib/memba/membership/projectors/role.ex",
  >         "facts": "Role projection handles role definitions, permissions, exact assignments/removals and membership-removal compatibility events. Exact assignment events carry club, membership, person and role IDs, while compatibility removals may require conservative membership, club-permission or global family invalidation."
  >       },
  >       {
  >         "path": "web/lib/memba/messaging/projectors/message.ex",
  >         "facts": "MessageSent projects roots and replies using a derivable conversation ID. The event carries club and conversation/message identity but no audience group, requiring a conservative club-conversation invalidation for dashboard collection entry and reply-derived changes."
  >       },
  >       {
  >         "path": "web/test/memba_web/live/member_dashboard_live_test.exs",
  >         "facts": "Existing tests establish the sole `:dashboard` result assign, group discovery refresh, selected-group access loss, current-actor role loss, conversation-access removal, route rechecks and picker-state preservation. Missing proof includes club-member entry/exit and ordering, represented Person isolation, live represented-member badge changes and old-interest replacement after route patches."
  >       },
  >       {
  >         "path": "web/test/memba_web/live/member_dashboard_admission_live_test.exs",
  >         "facts": "This suite protects the strongest existing real command/projector-to-open-dashboard group-admission behavior and command-owned state. It should remain passing while the manual handler is replaced by the provisional binding."
  >       },
  >       {
  >         "path": "docs/reference/liveview.md",
  >         "facts": "LiveView state changes belong in socket assigns and behavioral tests should use framework APIs. Query refresh must replace the dashboard assign without disturbing transient form, picker or navigation state."
  >       },
  >       {
  >         "path": "docs/reference/elixir-mix-tests.md",
  >         "facts": "Focused tests must avoid `Process.sleep/1`, use deterministic synchronization, and start test processes with `start_supervised!/1` where applicable."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
  >         "facts": "The task-004 worker reported the provisional Query, Source and Binding implementation with seven focused tests passing, including relevant-only refresh, interest replacement, route rebind, access errors, bind-window reconciliation and fresh connected remounts. It explicitly left dashboard wiring and Memba mapping for task 005."
  >       },
  >       {
  >         "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
  >         "facts": "The latest review accepted task 004 and confirmed that dashboard wiring, scoped Memba translation and vertical behavior proof remain later work. There is no rejected task-005 candidate to revise, so this packet is a fresh implementation attempt."
  >       }
  >     ],
  >     "constraints": [
  >       "Keep all dashboard interest and invalidation types app-private and provisional; do not present names or tuple shapes as the frozen package API.",
  >       "Keep the dashboard query result coherent under only `:dashboard`; do not mirror projection fields into separate public socket assigns.",
  >       "Continue to execute reads, subscription handling and refreshes in the owning LiveView process.",
  >       "Use the accepted provisional Binding, Query and Source responsibilities. Change their generic behavior only if dashboard integration reveals a concrete contract defect, and document that defect and its focused regression proof.",
  >       "Subscribe only during connected binding and before the initial connected read. Preserve disconnected initial rendering without a PubSub subscription.",
  >       "On every bind, route rebind and relevant notification, use the authenticated email to reread current active-club and page-specific authority; never authorize from `current_identity_clubs` captured at mount.",
  >       "Replace successful dashboard result and interests together. Do not patch dashboard fields from source events or retain old interests after route rebind.",
  >       "Scope notifications using carried IDs whenever available. Unknown or legacy dashboard-relevant events must use the matrix's conservative family, club or global fallback rather than being silently ignored.",
  >       "Keep represented-member role-label invalidation distinct from current-actor permission invalidation, even when one Role event produces both invalidations.",
  >       "Treat MessageSent roots and replies as dashboard dependencies, but do not restore delivery-status interests or the old all-deliveries refresh.",
  >       "Preserve existing forbidden versus not-found owner behavior and clear private query data on an access error before leaving or raising from the private surface.",
  >       "Preserve route state, targeted-member coordination, picker/form contents, command operation state, flash and navigation across successful query refreshes.",
  >       "Do not use `Process.sleep/1` in tests, do not run an unscoped full-suite command as focused validation, and do not mark the todo line complete."
  >     ],
  >     "focused_validation": [
  >       "bin/dev test test/memba_web/live_query test/memba_web/member_dashboard_query_test.exs",
  >       "bin/dev test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_dashboard_admission_live_test.exs test/memba_web/live/member_dashboard_targeted_add_live_test.exs",
  >       "bin/mix format --check-formatted",
  >       "git diff --check"
  >     ],
  >     "completion_evidence_required": [
  >       "List every changed path and state whether it implements dashboard query interests, Memba source translation, LiveView integration or focused proof.",
  >       "Document the final provisional dashboard query input, success and access-error shapes and show that fresh active-club authority is reread for bind, rebind and notification refresh.",
  >       "Enumerate the dashboard collection, represented identity and authorization interests produced from a successful result, including absent-row entry scopes and replacement after a selected-group route change.",
  >       "Provide a projector/event-to-invalidation summary for Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess, including the conservative behavior used when exact scope is missing.",
  >       "Show that the dashboard no longer manually subscribes or uses its old projector allowlist and broad MemberEmailDelivery handler, and that its notifications flow through the provisional binding.",
  >       "Identify focused tests proving club-member entry/removal, selected-group member entry/removal, member ordering and derived count updates in an already-open dashboard.",
  >       "Identify focused tests proving exact represented-Person matching and isolation without introducing PersonRenamed or another out-of-scope domain event.",
  >       "Identify focused tests proving represented-member role badge assignment/removal or role-definition refresh independently from current-actor permission and access transitions.",
  >       "Show that route patching replaces old selected-group interests, preserves not-found semantics and prevents an old-group-only notification from refreshing the rebound dashboard.",
  >       "Show that selected-club membership, current-actor role or selected-group participation loss performs a fresh authorized read and does not retain private rows.",
  >       "Show unrelated-club and unrelated-Person/group notifications are ignored through the real source matching path rather than merely by a hand-written LiveView clause.",
  >       "Show a relevant dashboard replacement preserves picker/query state and the existing admission, targeted-add, operation, access-request, active-section, flash and navigation behavior.",
  >       "Confirm that no conversation-detail migration, API freeze, package extraction, complete cross-surface adapter, domain event, projector write, acceptance feature or staff-stream change was introduced.",
  >       "Report every focused validation command with exit status and concise pass evidence, plus any unresolved issue; missing entry/exit, role, access, route-isolation or transient-state proof must remain unresolved rather than being treated as complete."
  >     ],
  >     "candidate_origins": []
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
  {"preferred_next_label": "implement"}
  ```

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > Implemented packet `task-005-bcf5640-dashboard-binding-1` with result `ready_for_review`.
  > 
  > Key changes:
  > 
  > - Added the provisional scoped Memba notification adapter in [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex), covering Club, Membership, Person, Group, GroupMembership, Role, Message, and ConversationGroupAccess notifications with exact scopes and conservative fallbacks.
  > - Extended [member_dashboard_query.ex](/workspace/memba/web/lib/memba_web/member_dashboard_query.ex) with a single `:dashboard` query descriptor and replacement interests for collections, represented identities, role badges, permissions, participation, conversations, and access.
  > - Migrated [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex) from manual subscription/projector filtering to `Binding.bind/4`, `Binding.rebind/3`, and `Binding.handle_notification/2`. The broad MemberEmailDelivery refresh was removed.
  > - Added focused proof for member entry/removal/order/counts, represented Person and Group isolation, role assignment/definition/removal, route-interest replacement, current membership loss, and transient-state preservation.
  > - Wrote the required artifact at [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json). The task remains unchecked in `todo.md`.
  > 
  > Validation passed:
  > 
  > - Live-query and dashboard-query tests: 18 tests, 0 failures.
  > - Dashboard presentation, LiveView, admission, and targeted-add tests: 89 tests, 0 failures.
  > - `bin/mix format --check-formatted`: passed.
  > - `git diff --check`: passed.
  > - Worker result JSON parsed successfully.
  > 
  > No unresolved issues. The full `dev check` was intentionally not run because this packet delegates that unscoped gate to the workflow’s deterministic `dev_check` node.

## Stage: route_worker_result
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/delivery_planner_state.py route-worker 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  {"preferred_next_label": "review"}
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.6-sol
- Response:
  > {"decision":"revise","task":"- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.","reason":"Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard."}

## Stage: apply_task_verdict
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/apply_task_verdict.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Task revise: - [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.
  Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard.
  {"preferred_next_label": "revise"}
  ```

## Stage: task_escalation
- Status: succeeded
- Handler: command
- Script: `python3 -B .fabro/workflows/iteration-implementation/scripts/escalate_task_review.py 'docs/iterations/067-live-projection-queries/plan.md'`
- Output:
  ```
  Validator's current finding for - [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.: Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard.
  Escalating revise after 3 revision verdict(s) before the iteration-wide worker limit.
  {"preferred_next_label": "discuss"}
  ```

## Stage: task_discussion
- Status: succeeded
- Handler: human

## Current context
| Key | Value |
|-----|-------|
| human.gate.label | *Repair as planned.* An open club Conversations list should show a newly sent conversation without reload or navigation. Please address the reviewer’s refresh and test gaps under the approved 067 plan; I’m not changing the product rule. |
| human.gate.selected | freeform |
| human.gate.task_discussion.answer | *Repair as planned.* An open club Conversations list should show a newly sent conversation without reload or navigation. Please address the reviewer’s refresh and test gaps under the approved 067 plan; I’m not changing the product rule. |
| human.gate.task_discussion.question | <@U0C3C6Y9ZAR> The validator has stopped this task; its finding is in the preceding run evidence. Should we repair the candidate to meet the approved plan, or is there a concrete business example or architectural constraint that changes the approach? Reply in this message's thread with 'repair as planned' or describe that constraint. This cannot approve publication. |
| human.gate.text | *Repair as planned.* An open club Conversations list should show a newly sent conversation without reload or navigation. Please address the reviewer’s refresh and test gaps under the approved 067 plan; I’m not changing the product rule. |
| output.delivery_planner | {"execution_state":{"schema_version":1,"plan_path":"docs/iterations/067-live-projection-queries/plan.md","todo_path":"docs/iterations/067-live-projection-queries/todo.md","source_baseline":"bcf5640aff475789689ea98bf513c4ce5097a274","accepted_tasks":["- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.","- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.","- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."],"pending_obligations":[{"task_id":"task-005","todo_line":"- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.","status":"prepared","origin":"Dashboard vertical proof split from approved plan tasks 2, 4 and 5, using the accepted provisional lifecycle contract before public API freeze.","replaces":["- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.","- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.","- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."],"coverage":["Dashboard registration through the provisional binding","Dashboard-specific Memba ReadModelChanges subscription and translation","Scoped dashboard collection, identity and authorization interests","Club-member and selected-group member entry and exit","Member ordering and derived counts","Represented Person and role-label refresh","Current-actor role, route and access transitions using fresh authority","Message and conversation-access invalidation required by the existing dashboard model","Unrelated-club and unrelated-notification isolation","Transient dashboard state preservation"],"candidate_origins":[]},{"task_id":"task-006","todo_line":"- [ ] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.","status":"pending","origin":"Conversation-detail vertical proof and API-freeze gate split from approved plan tasks 2, 4, 5 and 7. It follows the dashboard proof so the generic contract is justified by two materially different consumers.","replaces":["- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.","- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.","- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.","- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."],"coverage":["One coherent conversation-detail result assign","Conversation-message collection and represented-author interests","Exact follow identity","Member delivery status and staff delivery reason contributors","Independent projector commit-order convergence","Fresh membership, group and conversation authorization","Unrelated conversation, message, delivery, club and Person isolation","Reply and disclosure state preservation","Generic contract freeze only after both vertical proofs"],"candidate_origins":[]},{"task_id":"task-007","todo_line":"- [ ] 007 Extract, implement and test the frozen generic contract as a local Mix package, replace the two provisional consumers with it, and cover interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, subscriber cleanup and lifecycle without Memba or Commanded imports.","status":"pending","origin":"Remaining generic-package implementation from approved plan task 3, reordered after the two pre-freeze vertical proofs required by the approved technical model.","replaces":["- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports."],"coverage":["Extractable local Mix application","Replacement of app-private binding use in dashboard and conversation detail","Generic query registration, interest replacement, matching and refresh","Duplicate and out-of-order notification behavior","Subscriber cleanup and lifecycle tests","No Memba or Commanded imports in package source or tests"],"candidate_origins":[]},{"task_id":"task-008","todo_line":"- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.","status":"pending","origin":"Remaining application-adapter and query work from approved plan task 4 after the dashboard and conversation proof mappings are implemented.","replaces":["- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."],"coverage":["Every projector/event mapping recorded in the accepted migration matrix","Collection, identity and authorization interests","Old and new scopes where available","Conservative club, family or global fallbacks when exact scope is unavailable","Remaining fresh authorized view-specific queries","No app-specific policy in the generic package"],"candidate_origins":[]},{"task_id":"task-009","todo_line":"- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.","status":"pending","origin":"Remaining migration work from approved plan task 5 after dashboard and conversation detail serve as the pre-freeze proof consumers.","replaces":["- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress."],"coverage":["Group creation, settings, message composition, delivery detail and invitation LiveViews","One coherent result assign per remaining in-scope page","Preserved routes, access transitions, forms, commands, navigation and UI","Live delivery status and staff reason convergence","Existing conversation and delivery behavior","No staff stream migration"],"candidate_origins":[]},{"task_id":"task-010","todo_line":"- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.","status":"pending","origin":"Approved plan task 6, retained after minimum development-time package consumption and separated from production release and quality-gate completion.","replaces":["- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."],"coverage":["Supported path dependency in web/mix.exs","Docker dependency-copy and compilation ordering","Production release inclusion","Explicit package test execution in the repository quality gate","Supported local and CI environments"],"candidate_origins":[]},{"task_id":"task-011","todo_line":"- [ ] 011 Add the focused acceptance example, close the focused proof gaps for every migrated member page and a real committed-projector-to-open-LiveView path, complete package lifecycle/race coverage, and run final `dev check`.","status":"pending","origin":"Approved plan task 7 retained as the final acceptance, proof-gap and exact-state validation obligation after implementation slices complete.","replaces":["- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."],"coverage":["Stakeholder-readable club-member live-update example","Focused regression proof for every migrated member page","At least one real committed-projector-to-open-LiveView path","Remaining package mount, change, reconnect and race coverage","Final full dev check on the exact delivered state"],"candidate_origins":[]}],"candidate_origins":[],"coverage_map":[{"accepted_task_lines":["- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."],"pending_task_ids":[],"scope":"Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, focused-proof inventory and explicit exclusions."},{"accepted_task_lines":["- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."],"pending_task_ids":[],"scope":"Accepted dashboard query/view-model boundary, fresh-authority prerequisite, coherent dashboard result assign, connected subscribe-before-read ordering and provisional predicates."},{"accepted_task_lines":["- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."],"pending_task_ids":[],"scope":"Accepted provisional generic lifecycle, opaque-interest matching, route rebind, bind-window reconciliation, access-error and reconnect contract."},{"accepted_task_lines":[],"pending_task_ids":["task-005"],"scope":"Dashboard binding, dashboard-scoped Memba invalidation and vertical behavior proof."},{"accepted_task_lines":[],"pending_task_ids":["task-006"],"scope":"Conversation-detail binding, multi-projector/access proof and API freeze."},{"accepted_task_lines":[],"pending_task_ids":["task-007"],"scope":"Frozen generic local package extraction and hardening."},{"accepted_task_lines":[],"pending_task_ids":["task-008"],"scope":"Complete Memba notification adapter and remaining authorized queries."},{"accepted_task_lines":[],"pending_task_ids":["task-009"],"scope":"Migration of the five remaining in-scope member LiveViews."},{"accepted_task_lines":[],"pending_task_ids":["task-010"],"scope":"Production package, Docker release and quality-gate integration."},{"accepted_task_lines":[],"pending_task_ids":["task-011"],"scope":"Acceptance example, remaining focused proof and final exact-state validation."}],"planner_note":"The accepted review for task 004 is reflected by preserving its exact checked todo line and removing that completed obligation from pending work. Task 005 is now the first unchecked line and is prepared as the dashboard vertical proof without further splitting or reordering. The accepted provisional Binding, Query and Source modules supply the lifecycle prerequisite; this packet adds only dashboard-specific query interests, Memba notification translation and consumer proof. Conversation detail and API freeze remain task 006, package extraction remains task 007, full adapter completion remains task 008, and the acceptance feature plus full dev check remain task 011. No todo line was edited during this planner visit, and there is no unaccepted candidate origin to preserve."},"planner_result":{"schema_version":1,"plan_path":"docs/iterations/067-live-projection-queries/plan.md","todo_path":"docs/iterations/067-live-projection-queries/todo.md","source_baseline":"bcf5640aff475789689ea98bf513c4ce5097a274","decision":"ready"},"current_worker_packet":{"schema_version":1,"packet_id":"task-005-bcf5640-dashboard-binding-1","task_id":"task-005","todo_line":"- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.","attempt":"implementation","plan_path":"docs/iterations/067-live-projection-queries/plan.md","todo_path":"docs/iterations/067-live-projection-queries/todo.md","source_baseline":"bcf5640aff475789689ea98bf513c4ce5097a274","outcome":"Make the existing member dashboard a real consumer of the provisional LiveView-owned query binding: one fresh-authorized dashboard result and its replacement interests must drive scoped refreshes from committed Memba projection notifications, while unrelated changes are ignored and route, access and transient UI behavior remain intact.","scope":["Add an app-private, explicitly provisional Memba ReadModelChanges source adapter that subscribes to the shared PubSub topic, classifies dashboard-relevant projector notifications into opaque invalidations, and performs scoped interest matching without moving Memba knowledge into the generic Binding or Source modules.","Adapt `MembaWeb.MemberDashboardQuery` to provide a provisional query descriptor or loader returning the existing coherent dashboard view model plus replacement interests. Preserve `load/3` as the fresh-authority boundary, or retain an equivalent directly tested public contract, so every bind, rebind and notification refresh normalizes the authenticated email and rereads active-club authority.","Register only one dashboard live query under the existing `:dashboard` assign. Do not recreate separate projection-backed compatibility assigns; internal binding metadata and shell-derived `:page_title` are not additional query results.","Register dashboard collection interests for selected-club members, discoverable groups, current-person participating groups, selected-group members, selected-group conversations and represented-membership role assignments so rows absent from the old result can enter and existing rows can leave.","Register exact or represented interests for the selected Club and Group, current membership and Person, represented member and conversation participant Persons, represented groups, conversations/messages, selected-group access, current-actor permissions and role data. Keep current-actor authorization interests distinct from represented-member badge interests.","Translate dashboard-relevant Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess projector notifications according to the accepted migration matrix. Scope known club, group, person, membership and conversation identities; use the documented family, club or global conservative fallback when required scope is unavailable instead of silently ignoring a potentially relevant event.","For `MessageSent`, emit exact or derived conversation invalidations and a conservative club-conversation invalidation because the event does not contain its audience group. Preserve existing dashboard conversation and reply convergence while removing the current unscoped MemberEmailDelivery refresh, since the dashboard no longer displays delivery data.","Replace the dashboard's manual PubSub subscription and hand-written projector predicates with `Binding.bind/4` during mount, `Binding.rebind/3` for route-dependent selected-group changes and explicit command-driven rereads, and `Binding.handle_notification/2` for source messages. Connected bind must subscribe before reading; disconnected mount must read without subscribing.","After each successful bind, rebind or notification refresh, synchronize only LiveView-owned shell or route coordination derived from the new dashboard, including `:page_title` and targeted-member resolution where applicable. Keep active section, picker state/query/form, admission and removal operation state, access-request state, targeted success/focus, flash and navigation outside the query result.","Map dashboard binding errors back to the LiveView's existing `:forbidden` and `:not_found` owner policy. A failed refresh must not retain private dashboard data or teach the generic binding about redirects, exceptions or Memba authorization.","Add focused source/query tests for interest construction, classification, matching, missing-scope fallbacks and unrelated-club isolation. Keep the interest representation app-private and provisional; this task must not claim a frozen package vocabulary.","Add focused LiveView proof that club members and selected-group members enter and leave already-open lists, counts and name ordering converge, represented Person invalidation rereads only matching dashboards, represented role assignment/removal and role-definition changes update badges, current-actor role or membership loss rechecks authority, and route patches replace old selected-group interests.","Retain and extend proof that relevant dashboard replacement preserves transient picker and command state, that unrelated club/person/group notifications do not expose deliberately changed projection data, and that existing admission, targeted-add, conversation-access and route behavior still works through the binding."],"scope_exclusions":["Do not migrate conversation detail, delivery detail, settings, message composition, group creation, invitations or any staff, public or auth surface; tasks 006, 008 and 009 retain those obligations.","Do not freeze the provisional API or interest vocabulary. Conversation detail must provide the second materially different vertical proof before task 006 freezes the contract.","Do not extract a local Mix package, add a path dependency, or change Docker, release or quality-gate integration; tasks 007 and 010 own those changes.","Do not complete projector mappings needed only by non-dashboard consumers or implement delivery-row lookup fallbacks for conversation and delivery detail; task 008 retains the complete adapter obligation.","Do not add or change domain events, aggregates, commands, projector writes, projection schemas, migrations, authorization policy or read-model persistence just to drive invalidation.","Do not introduce `PersonRenamed`, name editing or profile-photo behavior. Prove the dashboard's exact represented-Person invalidation with existing Person projector envelopes and controlled projection state; iterations 068 and 069 remain out of scope.","Do not require exact represented role IDs if the dashboard result does not expose them. Exact membership role-assignment interests plus the accepted conservative club role/permission invalidation are sufficient for this provisional slice.","Do not retain the broad MemberEmailDelivery dashboard handler as compatibility behavior; delivery state is not part of the accepted dashboard result.","Do not add a GenServer, process per query, global cache, durable notification log, projector replay, event-driven field patching or a claim that PubSub is durable.","Do not edit the approved plan, todo line, migration matrix, ADRs, acceptance feature or design sources, and do not mark task 005 complete."],"references":[{"path":"docs/iterations/067-live-projection-queries/plan.md","facts":"The approved technical model requires one authorized dashboard query under one assign, collection interests for absent-row entry and exit, represented identity interests, fresh authorization on every refresh, subscribe-before-read, bind-window reconciliation and rereading rather than patching fields from events. Dashboard and conversation detail must prove the provisional contract before API freeze."},{"path":"docs/iterations/067-live-projection-queries/todo.md","facts":"Task 005 is the first unchecked obligation. It owns dashboard wiring and proof; task 006 retains conversation detail and API freeze, task 007 retains package extraction, task 008 retains complete adapter coverage, and task 011 retains the acceptance feature and final full gate."},{"path":"docs/iterations/067-live-projection-queries/migration-matrix.md","facts":"The accepted dashboard matrix identifies selected-club members, discoverable and participating groups, selected-group members and conversations, represented Persons and role assignments, current permissions and access as dependencies. Its projector table defines scoped Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess mappings, including conservative fallbacks and the remaining dashboard proof gaps."},{"path":"docs/adr/0027-use-live-projection-queries-for-liveview-reads.md","facts":"The accepted decision requires each view-specific query to return one coherent view model for one assign, with the LiveView owning subscription and relevant committed changes triggering a fresh authorized read. Memba concerns remain outside the generic mechanism, and staff streams are deferred."},{"path":"docs/adr/0021-publish-committed-read-model-changes.md","facts":"Committed projector updates are published as `{:read_model_changed, %{projector: ..., source_event: ..., metadata: ..., changes: ...}}` on the shared application PubSub topic after projection transactions commit."},{"path":"web/lib/memba_web/live_query/binding.ex","facts":"The accepted provisional binding already supports disconnected reads, connected subscription before the initial read, one shared source, bind-window reconciliation, relevant-only refresh, replacement interests, route rebind and owner-visible access errors while keeping state in the LiveView process. Dashboard integration should consume this behavior rather than create a second lifecycle."},{"path":"web/lib/memba_web/live_query/query.ex","facts":"A provisional query has a stable identity, one public assign and a one-argument loader returning either one result plus opaque interests or an access error. Its callback shape remains app-private until both vertical proofs are complete."},{"path":"web/lib/memba_web/live_query/source.ex","facts":"The provisional source separates subscription, raw-notification classification and opaque interest matching. It deliberately contains no Memba projector mapping, so dashboard-specific translation belongs in an injected app adapter."},{"path":"web/lib/memba_web/live/member_dashboard_live.ex","facts":"The accepted dashboard already stores projection-backed output only in `:dashboard` and derives `:page_title`, but it still manually subscribes, broadly refreshes for every MemberEmailDelivery change and handles only a same-club projector allowlist. `handle_params/3` and command paths call the old direct refresh helper, while picker, targeted-member, operation and access-request assigns remain LiveView-owned."},{"path":"web/lib/memba_web/member_dashboard_query.ex","facts":"The accepted query starts from routed club ID, authenticated email and selected group ID; every call normalizes the email, rereads active clubs and delegates to the established presentation boundary, preserving `:forbidden` and `:not_found` distinctions."},{"path":"web/lib/memba_web/member_dashboard_presentation.ex","facts":"The coherent dashboard result composes club members, discoverable and participating groups, current authorization, selected-group members, conversations, represented names and role labels. Conversation rows include reply-derived data but deliberately omit delivery glance fields, so MemberEmailDelivery is no longer a dashboard dependency."},{"path":"web/lib/memba/read_model_changes.ex","facts":"The existing publisher exposes the single shared topic and ADR-defined post-commit envelope. The dashboard adapter should subscribe through this API; no publisher or projector write change is required."},{"path":"web/lib/memba/membership/projectors/person.ex","facts":"Current Person projector notifications cover creation and email-address changes and carry Person identity but no club scope. Task 005 must match represented Person identities without inventing a club or introducing the out-of-scope PersonRenamed event."},{"path":"web/lib/memba/membership/projectors/role.ex","facts":"Role projection handles role definitions, permissions, exact assignments/removals and membership-removal compatibility events. Exact assignment events carry club, membership, person and role IDs, while compatibility removals may require conservative membership, club-permission or global family invalidation."},{"path":"web/lib/memba/messaging/projectors/message.ex","facts":"MessageSent projects roots and replies using a derivable conversation ID. The event carries club and conversation/message identity but no audience group, requiring a conservative club-conversation invalidation for dashboard collection entry and reply-derived changes."},{"path":"web/test/memba_web/live/member_dashboard_live_test.exs","facts":"Existing tests establish the sole `:dashboard` result assign, group discovery refresh, selected-group access loss, current-actor role loss, conversation-access removal, route rechecks and picker-state preservation. Missing proof includes club-member entry/exit and ordering, represented Person isolation, live represented-member badge changes and old-interest replacement after route patches."},{"path":"web/test/memba_web/live/member_dashboard_admission_live_test.exs","facts":"This suite protects the strongest existing real command/projector-to-open-dashboard group-admission behavior and command-owned state. It should remain passing while the manual handler is replaced by the provisional binding."},{"path":"docs/reference/liveview.md","facts":"LiveView state changes belong in socket assigns and behavioral tests should use framework APIs. Query refresh must replace the dashboard assign without disturbing transient form, picker or navigation state."},{"path":"docs/reference/elixir-mix-tests.md","facts":"Focused tests must avoid `Process.sleep/1`, use deterministic synchronization, and start test processes with `start_supervised!/1` where applicable."},{"path":"docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json","facts":"The task-004 worker reported the provisional Query, Source and Binding implementation with seven focused tests passing, including relevant-only refresh, interest replacement, route rebind, access errors, bind-window reconciliation and fresh connected remounts. It explicitly left dashboard wiring and Memba mapping for task 005."},{"path":"docs/iterations/067-live-projection-queries/.delivery/latest-review.json","facts":"The latest review accepted task 004 and confirmed that dashboard wiring, scoped Memba translation and vertical behavior proof remain later work. There is no rejected task-005 candidate to revise, so this packet is a fresh implementation attempt."}],"constraints":["Keep all dashboard interest and invalidation types app-private and provisional; do not present names or tuple shapes as the frozen package API.","Keep the dashboard query result coherent under only `:dashboard`; do not mirror projection fields into separate public socket assigns.","Continue to execute reads, subscription handling and refreshes in the owning LiveView process.","Use the accepted provisional Binding, Query and Source responsibilities. Change their generic behavior only if dashboard integration reveals a concrete contract defect, and document that defect and its focused regression proof.","Subscribe only during connected binding and before the initial connected read. Preserve disconnected initial rendering without a PubSub subscription.","On every bind, route rebind and relevant notification, use the authenticated email to reread current active-club and page-specific authority; never authorize from `current_identity_clubs` captured at mount.","Replace successful dashboard result and interests together. Do not patch dashboard fields from source events or retain old interests after route rebind.","Scope notifications using carried IDs whenever available. Unknown or legacy dashboard-relevant events must use the matrix's conservative family, club or global fallback rather than being silently ignored.","Keep represented-member role-label invalidation distinct from current-actor permission invalidation, even when one Role event produces both invalidations.","Treat MessageSent roots and replies as dashboard dependencies, but do not restore delivery-status interests or the old all-deliveries refresh.","Preserve existing forbidden versus not-found owner behavior and clear private query data on an access error before leaving or raising from the private surface.","Preserve route state, targeted-member coordination, picker/form contents, command operation state, flash and navigation across successful query refreshes.","Do not use `Process.sleep/1` in tests, do not run an unscoped full-suite command as focused validation, and do not mark the todo line complete."],"focused_validation":["bin/dev test test/memba_web/live_query test/memba_web/member_dashboard_query_test.exs","bin/dev test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_dashboard_admission_live_test.exs test/memba_web/live/member_dashboard_targeted_add_live_test.exs","bin/mix format --check-formatted","git diff --check"],"completion_evidence_required":["List every changed path and state whether it implements dashboard query interests, Memba source translation, LiveView integration or focused proof.","Document the final provisional dashboard query input, success and access-error shapes and show that fresh active-club authority is reread for bind, rebind and notification refresh.","Enumerate the dashboard collection, represented identity and authorization interests produced from a successful result, including absent-row entry scopes and replacement after a selected-group route change.","Provide a projector/event-to-invalidation summary for Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess, including the conservative behavior used when exact scope is missing.","Show that the dashboard no longer manually subscribes or uses its old projector allowlist and broad MemberEmailDelivery handler, and that its notifications flow through the provisional binding.","Identify focused tests proving club-member entry/removal, selected-group member entry/removal, member ordering and derived count updates in an already-open dashboard.","Identify focused tests proving exact represented-Person matching and isolation without introducing PersonRenamed or another out-of-scope domain event.","Identify focused tests proving represented-member role badge assignment/removal or role-definition refresh independently from current-actor permission and access transitions.","Show that route patching replaces old selected-group interests, preserves not-found semantics and prevents an old-group-only notification from refreshing the rebound dashboard.","Show that selected-club membership, current-actor role or selected-group participation loss performs a fresh authorized read and does not retain private rows.","Show unrelated-club and unrelated-Person/group notifications are ignored through the real source matching path rather than merely by a hand-written LiveView clause.","Show a relevant dashboard replacement preserves picker/query state and the existing admission, targeted-add, operation, access-request, active-section, flash and navigation behavior.","Confirm that no conversation-detail migration, API freeze, package extraction, complete cross-surface adapter, domain event, projector write, acceptance feature or staff-stream change was introduced.","Report every focused validation command with exit status and concise pass evidence, plus any unresolved issue; missing entry/exit, role, access, route-isolation or transient-state proof must remain unresolved rather than being treated as complete."],"candidate_origins":[]}} |
| output.validate_task | {"decision":"revise","task":"- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.","reason":"Packet task-005-bcf5640-dashboard-binding-1 is current, matches the first unchecked todo and matching ready_for_review result; acceptance features and out-of-scope surfaces are unchanged. Recorded focused validations passed with exit 0 (18 and 89 tests, formatting and diff checks). A supplementary independent rerun of member_dashboard_live_test.exs also passed 54 tests, but does not close these gaps. Revision is required because MemberDashboardQuery derives Person interests only from members/candidates/current member, not conversation-only sender/latest-replier/participant identities, even though latest_replier_name is Person-backed and rendered; add those exact interests and a test where the represented Person is absent from member/candidate collections. MembaReadModelSource also suppresses required conservative fallbacks for partially scoped notifications: role definition/permission with role_id but no club_id emits only an unregistered role key, MessageSent with conversation/message identity but no club_id cannot invalidate an absent root collection entry, and partial GroupMembership mappings can omit both a matching fallback and the matrix-required affected-Person identity. Correct these mappings and add partial-scope tests. Finally, add focused open-dashboard MessageSent proof for root entry and reply-derived convergence; current coverage tests tuple classification but no Message notification refreshing an open dashboard."} |


Facilitate a short, generic clarification with Matt about the independent validator's latest task finding. The issue may need concrete business examples, an architectural decision, or another bounded technical repair. Do not assume it is example mapping. Do not edit files, waive security/plan constraints, check off tasks, or infer approval to resume/publish.

Read Matt's most recent reply from the immediately preceding human-gate stage and the validator evidence in this run's context. If the reply is missing, fail rather than inventing one. Preserve Matt's words and distinguish decisions from hypotheses. If material uncertainty remains, return one JSON routing object with `preferred_next_label` = `ask`, and include ONE focused follow-up question visible in the response for the next Slack message. If Matt explicitly says discussion is complete and guidance is clear, return `preferred_next_label` = `finish` with a concise decision summary. Never treat a single plausible answer as automatic approval. No other label is valid.


Fabro final-output contract

The following contract is trusted workflow configuration. It applies only to your final response, not to intermediate tool calls.
Return a single JSON object with at least one routing field: preferred_next_label, outcome, failure_reason, suggested_next_ids, context_updates.
The contract is complete. Do not ask the user to provide or choose the output shape.