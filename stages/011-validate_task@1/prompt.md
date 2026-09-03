Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01M1JZX34A6PX42CN82N900CBZ
Pipeline progress: 9 of 33 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/056-group-audience-foundation/plan.md'
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
  (272 lines omitted)
    uses strong consistency, and handles each membership/Admin-role lifecycle event
    independently. The Club aggregate owns group-membership state; idempotent commands
    make at-least-once handler redelivery safe. Because it holds no process state,
    future role/removal events for memberships seeded by backfill work normally.
  - **Membership projection:** `membership_group_memberships` is a current-state
    projection keyed by `(group_id, membership_id)` with `active`; remove/re-add
    toggles that row. The event stream is the membership history. Index current rows
    for group-to-members and person-to-groups access queries.
  - **Backfill:** `Memba.Membership.SystemGroups.Backfill` runs automatically from the
    existing release migration flow, after schema migration and app startup. It is a
    paginated, idempotent command dispatcher that logs counts, aborts safely on
    unrecoverable failure, and resumes on the next release. It never runs at normal
    boot and requires no manual operator command.
  - **Replay proof:** reuse `Memba.EventSourcedCase.rebuild_event_sourced_projections!/0`
    and `Memba.ProjectionBarrier` in an asynchronous-false ExUnit test after adding
    the new projectors/tables to its reset/restart lists. The test compares query
    results before and after rebuild from retained events.
  
  ## New Capability
  
  Memba has explicit, rebuildable Group identities and memberships for its two
  existing conversation cohorts, plus a conversation-to-group write-access model.
  Current club-wide messages are no longer a hidden special case: they are Everyone
  conversations. The next iteration can build a usable Admin-group email route on
  this foundation without introducing a second audience model.
  
  ## Validation Plan
  
  - Run focused Membership and Messaging ExUnit tests while implementing the aggregate,
    policy, projections, and access change.
  - Test a club creation path produces Everyone and Admin facts; member and Admin-role
    lifecycle changes produce the intended group-membership facts once and only once.
  - Test that the existing acceptance examples still have the same recipients,
    authorisation results, reply followers, and email threading after the new policy
    is in place.
  - Exercise the automatic `Memba.Release.migrate/0` backfill path against
    representative existing clubs, memberships, Admin-role assignments, root messages,
    and replies; interrupt/retry it in tests and assert no duplicate facts or current
    rows.
  - Use `Memba.EventSourcedCase.rebuild_event_sourced_projections!/0` and a projection
    barrier to rebuild the relevant Membership and Messaging projections from retained
    events, then compare their group/membership/access query results to the
    post-backfill state.
  - Stop only when those focused tests, existing acceptance regressions, replay parity,
    idempotent automatic-backfill coverage, and `dev check` all pass on the committed
    implementation state.
  
  ## Risks / Follow-ups
  
  - The new system-group event handler is the main operational risk. It crosses
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/056-group-audience-foundation/plan.md'
PATH="$PWD/bin:$PATH" dev iteration check-predecessors "$PLAN_PATH"
PATH="$PWD/bin:$PATH" dev iteration check-clear "$PLAN_PATH" --allow-same-iteration`
- Output:
  ```
  (6 lines omitted)
  ✓ Evaluating shell in 230µs (cached)
  ✓ Configuring shell in 6.30ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 6.08µs (cached)
  ✓ Loading tasks in 1.21ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.5ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.2ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 4.77µs (no command)
  ✓ Running tasks in 22.5ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:2] [ds:8:2:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  • Validating lock
  ✓ Validating lock in 19.9ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 1.87ms
  • Evaluating shell
  ✓ Evaluating shell in 169µs (cached)
  ✓ Configuring shell in 5.90ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 218µs (cached)
  ✓ Loading tasks in 1.59ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 13.9ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 12.2ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 4.68µs (no command)
  ✓ Running tasks in 27.6ms
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
  (379 lines omitted)
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
PLAN_PATH='docs/iterations/056-group-audience-foundation/plan.md'
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
  HEAD: 16c776b fabro(01M1JZX34A6PX42CN82N900CBZ): preflight_sandbox (succeeded)
  Todo: docs/iterations/056-group-audience-foundation/todo.md is absent; sync_task_list will create it from plan.md.
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/056-group-audience-foundation/plan.md'
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
  Created docs/iterations/056-group-audience-foundation/todo.md from docs/iterations/056-group-audience-foundation/plan.md
  PLAN_PATH=docs/iterations/056-group-audience-foundation/plan.md
  TODO_PATH=docs/iterations/056-group-audience-foundation/todo.md
  # Implementation TODO
  
  - [ ] 001 Inspect the existing Membership Club aggregate, membership lifecycle events, Admin-role assignment/removal paths, Commanded router, and projection-barrier setup.
  - [ ] 002 Add the typed Group ID and the Group command/event modules using the project’s existing ID and event conventions.
  - [ ] 003 Extend the Club aggregate state and commands so it owns group definitions and group memberships.
  - [ ] 004 Define deterministic Everyone and Admin group IDs.
  - [ ] 005 Make `CreateClub` emit `GroupCreated` for both system groups while preserving the existing Admin-role creation and permission grant.
  - [ ] 006 Add Group aggregate-state validation and idempotent commands for creating a group and adding/removing a membership: a group belongs to its club; a membership is not added twice; commands carry club, group, membership, and person identities.
  - [ ] 007 Keep custom-group behaviour unavailable through the public UI/API in this slice.
  - [ ] 008 Add `membership_groups` and `membership_group_memberships` migrations, schemas, and strong-consistency projectors.
  - [ ] 009 `membership_group_memberships` has one current-state row keyed by `(group_id, membership_id)`; add/remove toggles its `active` flag, so re-add reactivates the row and the event stream retains history.
  - [ ] 010 Implement and supervise `Memba.Membership.Policies.SystemGroupMembership` as a stateless `Commanded.Event.Handler` with a stable handler name, `consistency: :strong`, and `start_from: :current`.
  - [ ] 011 It handles each `MemberAdded`, `MemberRemoved`, `MemberRoleAssigned`, and `MemberRoleRemoved` independently, dispatching idempotent Club-group membership commands for Everyone and the deterministic Admin role.
  - [ ] 012 It retains no per-membership workflow state: the Club aggregate owns membership state and makes at-least-once handler redelivery safe.
  - [ ] 013 Configure Group projectors as strong and dispatch affected member/role commands with strong consistency, so those commands return only after group membership is queryable.
  - [ ] 014 Add public Membership queries such as active group members and whether a person is an active member of a group. Keep all Membership schema/query details behind these APIs, as required by ADR 0007.
  - [ ] 015 Add `ConversationAccessGrantedToGroup` and make the root-message path in the Message aggregate emit it for the audience group.
  - [ ] 016 Add the `messaging_conversation_group_access` migration, schema, and strong projector; validate access level and make write imply read in the Messaging query API.
  - [ ] 017 Change web compose and accepted inbound Everyone-mail command construction to resolve the deterministic Everyone group and resolve recipients through the Membership group API.
  - [ ] 018 Change reply authorisation to require write access through an active group membership.
  - [ ] 019 Keep reply-recipient/follower delivery unchanged.
  - [ ] 020 Implement `Memba.Membership.SystemGroups.Backfill` as a reusable, paginated, idempotent service, then invoke it from `Memba.Release.migrate/0` after Ecto migrations and application/event-store startup.
  - [ ] 021 It scans authoritative current projections in dependency order (groups, memberships/Admin assignments, root conversations), dispatches only missing commands, logs counts, and aborts the release on an unrecoverable error.
  - [ ] 022 A subsequent release safely resumes; it is not an Ecto migration or an application-boot task.
  - [ ] 023 Do not modify or delete historic events.
  - [ ] 024 Extend `Memba.EventSourcedCase` with the new Group and conversation-access projectors/tables.
  - [ ] 025 Add a replay-parity test that dispatches representative setup and backfill facts, snapshots the group/membership/access queries, calls `rebuild_event_sourced_projections!/0`, awaits the new projectors through `Memba.ProjectionBarrier`, and asserts the same queries return the same state.
  - [ ] 026 Add tests for aggregate decisions; system-group event-handler commands and idempotency; system-group membership after member/role changes—including future role changes and member removal for memberships that were seeded by backfill; sender and reply authorisation; recipient/follower-delivery regression; release-backfill reruns; and replay parity.
  - [ ] 027 Run `dev check`.
  ```

## Stage: todo_readable
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/056-group-audience-foundation/plan.md'
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
  Todo file is present and readable: docs/iterations/056-group-audience-foundation/todo.md
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/056-group-audience-foundation/plan.md'
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
  UNCHECKED tasks remain in docs/iterations/056-group-audience-foundation/todo.md
  3:- [ ] 001 Inspect the existing Membership Club aggregate, membership lifecycle events, Admin-role assignment/removal paths, Commanded router, and projection-barrier setup.
  4:- [ ] 002 Add the typed Group ID and the Group command/event modules using the project’s existing ID and event conventions.
  5:- [ ] 003 Extend the Club aggregate state and commands so it owns group definitions and group memberships.
  6:- [ ] 004 Define deterministic Everyone and Admin group IDs.
  7:- [ ] 005 Make `CreateClub` emit `GroupCreated` for both system groups while preserving the existing Admin-role creation and permission grant.
  8:- [ ] 006 Add Group aggregate-state validation and idempotent commands for creating a group and adding/removing a membership: a group belongs to its club; a membership is not added twice; commands carry club, group, membership, and person identities.
  9:- [ ] 007 Keep custom-group behaviour unavailable through the public UI/API in this slice.
  10:- [ ] 008 Add `membership_groups` and `membership_group_memberships` migrations, schemas, and strong-consistency projectors.
  11:- [ ] 009 `membership_group_memberships` has one current-state row keyed by `(group_id, membership_id)`; add/remove toggles its `active` flag, so re-add reactivates the row and the event stream retains history.
  12:- [ ] 010 Implement and supervise `Memba.Membership.Policies.SystemGroupMembership` as a stateless `Commanded.Event.Handler` with a stable handler name, `consistency: :strong`, and `start_from: :current`.
  13:- [ ] 011 It handles each `MemberAdded`, `MemberRemoved`, `MemberRoleAssigned`, and `MemberRoleRemoved` independently, dispatching idempotent Club-group membership commands for Everyone and the deterministic Admin role.
  14:- [ ] 012 It retains no per-membership workflow state: the Club aggregate owns membership state and makes at-least-once handler redelivery safe.
  15:- [ ] 013 Configure Group projectors as strong and dispatch affected member/role commands with strong consistency, so those commands return only after group membership is queryable.
  16:- [ ] 014 Add public Membership queries such as active group members and whether a person is an active member of a group. Keep all Membership schema/query details behind these APIs, as required by ADR 0007.
  17:- [ ] 015 Add `ConversationAccessGrantedToGroup` and make the root-message path in the Message aggregate emit it for the audience group.
  18:- [ ] 016 Add the `messaging_conversation_group_access` migration, schema, and strong projector; validate access level and make write imply read in the Messaging query API.
  19:- [ ] 017 Change web compose and accepted inbound Everyone-mail command construction to resolve the deterministic Everyone group and resolve recipients through the Membership group API.
  20:- [ ] 018 Change reply authorisation to require write access through an active group membership.
  21:- [ ] 019 Keep reply-recipient/follower delivery unchanged.
  22:- [ ] 020 Implement `Memba.Membership.SystemGroups.Backfill` as a reusable, paginated, idempotent service, then invoke it from `Memba.Release.migrate/0` after Ecto migrations and application/event-store startup.
  ```

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Response:
  > 1. **Selected todo line**
  >    - `- [ ] 001 Inspect the existing Membership Club aggregate, membership lifecycle events, Admin-role assignment/removal paths, Commanded router, and projection-barrier setup.`
  > 
  > 2. **Changes made**
  >    - Added `docs/iterations/056-group-audience-foundation/implementation-notes.md` with durable inspection notes covering:
  >      - Membership and Messaging Commanded app/router split.
  >      - `Memba.Membership.Club` role/state responsibilities.
  >      - Membership lifecycle aggregate/events.
  >      - Admin-role assignment/removal service and aggregate paths.
  >      - ID conventions for future typed Group IDs.
  >      - Existing strong projector conventions.
  >      - `Memba.EventSourcedCase` replay/reset setup.
  >      - `Memba.ProjectionBarrier` checkpoint behavior.
  >    - Updated `docs/iterations/056-group-audience-foundation/todo.md` to check off only task 001.
  > 
  > 3. **Focused validation**
  >    - Inspected recent checkpoint commits:
  >      - `git log --oneline --decorate -20`
  >    - Confirmed clean tree before editing:
  >      - `git status --short` returned no output.
  >    - Final status confirms only intended docs/todo changes:
  >      - `M docs/iterations/056-group-audience-foundation/todo.md`
  >      - `?? docs/iterations/056-group-audience-foundation/implementation-notes.md`
  >    - No `dev check` or ExUnit run: this task was inspection/docs-only, and project guidance says not to run `dev check` for docs-only edits unless requested or executable examples/scripts change.
  > 
  > 4. **Exact todo check-off made**
  >    - Changed:
  >      - `- [ ] 001 Inspect the existing Membership Club aggregate, membership lifecycle events, Admin-role assignment/removal paths, Commanded router, and projection-barrier setup.`
  >    - To:
  >      - `- [x] 001 Inspect the existing Membership Club aggregate, membership lifecycle events, Admin-role assignment/removal paths, Commanded router, and projection-barrier setup.`
  > 
  > 5. **Todo splits/additions/reordering**
  >    - None.
  > 
  > 6. **ADR conformance evidence**
  >    - Read ADR 0007 as explicitly referenced by the plan.
  >    - Also inspected relevant accepted ADRs:
  >      - ADR 0002: Commanded/event sourcing by default.
  >      - ADR 0005: message send commands include resolved recipients.
  >      - ADR 0008: PostgreSQL EventStore schema with Commanded.
  >      - ADR 0009: Commanded Ecto projections.
  >      - ADR 0011: caller-generated UUID aggregate identities.
  >      - ADR 0021: committed read-model changes.
  >      - ADR 0022: projection barriers for read-your-writes.
  >    - The inspection notes preserve the bounded-context/API separation required by ADR 0007 and identify where future group work must fit without crossing Membership/Messaging storage boundaries.

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/056-group-audience-foundation/plan.md'
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
  470149c
  470149c fabro(01M1JZX34A6PX42CN82N900CBZ): implement_next_task (succeeded)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/056-group-audience-foundation/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```


Validate the just-completed iteration task for `docs/iterations/056-group-audience-foundation/plan.md`.

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

Fabro final-output contract

The following contract is trusted workflow configuration. It applies only to your final response, not to intermediate tool calls.
Return a single JSON object with at least one routing field: preferred_next_label, outcome, failure_reason, suggested_next_ids, context_updates.
The contract is complete. Do not ask the user to provide or choose the output shape.