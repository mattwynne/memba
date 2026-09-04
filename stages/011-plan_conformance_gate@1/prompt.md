Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01M1PW96PP532RAYZ4N9XTWECY
Pipeline progress: 9 of 34 stages completed

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
  
  - **System-group policy:** `Memba.Membership.Policies.SystemGroupMembership` is a
    stateless Commanded event handler with a stable name. It starts from `:origin`,
    uses strong consistency, and handles each membership/Admin-role lifecycle event
    independently. Starting from origin lets a first subscription replay history
    instead of skipping events written during subscriber startup. The Club aggregate
    owns group-membership state; idempotent commands make first-subscription replay
    and at-least-once handler redelivery safe. Release backfill remains required for
    clubs whose historic streams predate the new system-group facts, and future
    role/removal events for memberships seeded by backfill work normally because the
    handler holds no process state.
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
  ✓ Evaluating shell in 992µs (cached)
  ✓ Configuring shell in 5.75ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 268µs (cached)
  ✓ Loading tasks in 1.30ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 7.85ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 10.8ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 4.87µs (no command)
  ✓ Running tasks in 19.3ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:2] [ds:8:2:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  • Validating lock
  ✓ Validating lock in 21.2ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 2.50ms
  • Evaluating shell
  ✓ Evaluating shell in 280µs (cached)
  ✓ Configuring shell in 6.61ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 105µs (cached)
  ✓ Loading tasks in 1.53ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 8.21ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.2ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 81.5µs (no command)
  ✓ Running tasks in 20.3ms
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
  (384 lines omitted)
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
  HEAD: accfa27 fabro(01M1PW96PP532RAYZ4N9XTWECY): preflight_sandbox (succeeded)
  Todo: docs/iterations/056-group-audience-foundation/todo.md (27 checked, 0 unchecked)
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
  Using existing docs/iterations/056-group-audience-foundation/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/056-group-audience-foundation/plan.md
  TODO_PATH=docs/iterations/056-group-audience-foundation/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing Membership Club aggregate, membership lifecycle events, Admin-role assignment/removal paths, Commanded router, and projection-barrier setup.
  - [x] 002 Add the typed Group ID and the Group command/event modules using the project’s existing ID and event conventions.
  - [x] 003 Extend the Club aggregate state and commands so it owns group definitions and group memberships.
  - [x] 004 Define deterministic Everyone and Admin group IDs.
  - [x] 005 Make `CreateClub` emit `GroupCreated` for both system groups while preserving the existing Admin-role creation and permission grant.
  - [x] 006 Add Group aggregate-state validation and idempotent commands for creating a group and adding/removing a membership: a group belongs to its club; a membership is not added twice; commands carry club, group, membership, and person identities.
  - [x] 007 Keep custom-group behaviour unavailable through the public UI/API in this slice.
  - [x] 008 Add `membership_groups` and `membership_group_memberships` migrations, schemas, and strong-consistency projectors.
  - [x] 009 `membership_group_memberships` has one current-state row keyed by `(group_id, membership_id)`; add/remove toggles its `active` flag, so re-add reactivates the row and the event stream retains history.
  - [x] 010 Implement and supervise `Memba.Membership.Policies.SystemGroupMembership` as a stateless `Commanded.Event.Handler` with a stable handler name, `consistency: :strong`, and `start_from: :origin`.
  - [x] 011 It handles each `MemberAdded`, `MemberRemoved`, `MemberRoleAssigned`, and `MemberRoleRemoved` independently, dispatching idempotent Club-group membership commands for Everyone and the deterministic Admin role.
  - [x] 012 It retains no per-membership workflow state: the Club aggregate owns membership state and makes at-least-once handler redelivery safe.
  - [x] 013 Configure Group projectors as strong and dispatch affected member/role commands with strong consistency, so those commands return only after group membership is queryable.
  - [x] 014 Add public Membership queries such as active group members and whether a person is an active member of a group. Keep all Membership schema/query details behind these APIs, as required by ADR 0007.
  - [x] 015 Add `ConversationAccessGrantedToGroup` and make the root-message path in the Message aggregate emit it for the audience group.
  - [x] 016 Add the `messaging_conversation_group_access` migration, schema, and strong projector; validate access level and make write imply read in the Messaging query API.
  - [x] 017 Change web compose and accepted inbound Everyone-mail command construction to resolve the deterministic Everyone group and resolve recipients through the Membership group API.
  - [x] 018 Change reply authorisation to require write access through an active group membership.
  - [x] 019 Keep reply-recipient/follower delivery unchanged.
  - [x] 020 Implement `Memba.Membership.SystemGroups.Backfill` as a reusable, paginated, idempotent service, then invoke it from `Memba.Release.migrate/0` after Ecto migrations and application/event-store startup.
  - [x] 021 It scans authoritative current projections in dependency order (groups, memberships/Admin assignments, root conversations), dispatches only missing commands, logs counts, and aborts the release on an unrecoverable error.
  - [x] 022 A subsequent release safely resumes; it is not an Ecto migration or an application-boot task.
  - [x] 023 Do not modify or delete historic events.
  - [x] 024 Extend `Memba.EventSourcedCase` with the new Group and conversation-access projectors/tables.
  - [x] 025 Add a replay-parity test that dispatches representative setup and backfill facts, snapshots the group/membership/access queries, calls `rebuild_event_sourced_projections!/0`, awaits the new projectors through `Memba.ProjectionBarrier`, and asserts the same queries return the same state.
  - [x] 026 Add tests for aggregate decisions; system-group event-handler commands and idempotency; system-group membership after member/role changes—including future role changes and member removal for memberships that were seeded by backfill; sender and reply authorisation; recipient/follower-delivery regression; release-backfill reruns; and replay parity.
  - [x] 027 Run `dev check`.
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
- Status: failed
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
  COMPLETE: no unchecked tasks remain in docs/iterations/056-group-audience-foundation/todo.md
  ```

## Stage: dev_check
- Status: succeeded
- Handler: command
- Script: `PATH="$PWD/bin:$PATH" dev ci`
- Output:
  ```
  (2160 lines omitted)
  
    Rule: Staff-edited slugs must already be address-safe
  
      Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-09-04T19:03:05.513Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-09-04T19:03:05.545Z] scenario reset app state: Staff enter an invalid slug
        Given Pat is signed in as Memba staff
  [acceptance 2026-09-04T19:03:06.601Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1020ms
        Given Kootenay Mountaineering Club is a club
        When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
        Then Memba should reject the club slug as invalid
        And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-09-04T19:03:07.627Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-09-04T19:03:07.642Z] scenario finish: Staff enter an invalid slug status=PASSED duration=2129ms
  
    Rule: A slug can belong to only one club
  
      Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-09-04T19:03:07.643Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-09-04T19:03:07.700Z] scenario reset app state: Staff enter a slug that another club already uses
        Given Pat is signed in as Memba staff
  [acceptance 2026-09-04T19:03:08.742Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1002ms
        Given Kootenay Mountaineering Club has the slug "kmc"
        And Nelson Paddling Club is a club
        When Pat tries to change Nelson Paddling Club's slug to "kmc"
        Then Memba should reject the club slug as already taken
        And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-09-04T19:03:10.006Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-09-04T19:03:10.014Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=2371ms
  
    Rule: A club slug routes public visitors to that club's public page
  
      @not-domain
      Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-09-04T19:03:10.015Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-09-04T19:03:10.046Z] scenario reset app state: Robin opens an unknown club subdomain
        Given Pat is signed in as Memba staff
  [acceptance 2026-09-04T19:03:11.107Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1022ms
        When Robin opens "unknown.clubs.memba.io"
        Then Robin should see a not found page
  [acceptance 2026-09-04T19:03:11.172Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-09-04T19:03:11.179Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1165ms
  
  [acceptance 2026-09-04T19:03:11.180Z] AfterAll: closing shared browser
  [acceptance 2026-09-04T19:03:11.200Z] AfterAll: closed shared browser
  [acceptance 2026-09-04T19:03:11.200Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-09-04T19:03:11.201Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  118 scenarios (118 passed)
  833 steps (833 passed)
  5m15.345s (executing steps: 5m05.476s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/056-group-audience-foundation/plan.md'
case "$PLAN_PATH" in
  */plan.md) ITERATION_DIR=${PLAN_PATH%/plan.md} ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
TODO_PATH="$ITERATION_DIR/todo.md"
base_ref=''
git fetch --quiet origin main:refs/remotes/origin/main || true
for ref in origin/main main; do
  if git rev-parse --verify "$ref" >/dev/null 2>&1; then
    base_ref=$ref
    break
  fi
done
if [ -z "$base_ref" ]; then
  echo 'Could not determine implementation base. Tried origin/main and main.' >&2
  git branch -a -vv >&2 || true
  git show-ref >&2 || true
  exit 1
fi
merge_base_err="${TMPDIR:-/tmp}/memba-implementation-merge-base-$$.err"
if ! merge_base=$(git merge-base HEAD "$base_ref" 2>"$merge_base_err"); then
  echo "Could not compute merge base between HEAD and $base_ref." >&2
  cat "$merge_base_err" >&2 || true
  shallow=$(git rev-parse --is-shallow-repository 2>/dev/null || echo unknown)
  echo "Repository shallow: $shallow" >&2
  if [ "$shallow" = true ]; then
    echo 'Trying to unshallow repository before failing...' >&2
    git fetch --quiet --unshallow origin || true
  fi
  if ! merge_base=$(git merge-base HEAD "$base_ref" 2>"$merge_base_err"); then
    echo "Still could not compute merge base between HEAD and $base_ref." >&2
    cat "$merge_base_err" >&2 || true
    git log --oneline --decorate --max-count=20 --all >&2 || true
    git branch -a -vv >&2 || true
    git show-ref >&2 || true
    exit 1
  fi
fi
echo '=== Plan Conformance Evidence ==='
echo "Plan path: $PLAN_PATH"
echo "Todo path: $TODO_PATH"
echo "Branch: $(git branch --show-current || true)"
echo "HEAD: $(git rev-parse HEAD)"
echo "Base ref: $base_ref"
echo "Merge base: $merge_base"
echo ''
echo '--- todo.md ---'
if [ -f "$TODO_PATH" ]; then
  sed -n '1,220p' "$TODO_PATH"
else
  echo "Todo file missing: $TODO_PATH" >&2
  exit 1
fi
echo ''
echo '--- git status --short ---'
git status --short
echo ''
echo '--- git diff --stat ---'
if ! git diff --stat "$merge_base"..HEAD; then
  echo "Could not compute diff stat from $merge_base to HEAD." >&2
  exit 1
fi
echo ''
echo '--- git diff --name-status ---'
if ! git diff --name-status "$merge_base"..HEAD; then
  echo "Could not compute diff name-status from $merge_base to HEAD." >&2
  exit 1
fi
echo ''
echo '--- changed source/config/test/iteration file excerpts ---'
if ! changed_files=$(git diff --name-only "$merge_base"..HEAD); then
  echo "Could not compute changed files from $merge_base to HEAD." >&2
  exit 1
fi
if [ -z "$changed_files" ]; then
  echo 'No files differ between merge base and HEAD.'
else
  excerpt_files=$(printf '%s\n' "$changed_files" | grep -E '^(web/(lib|config|test|priv/repo/migrations|mix\.exs|mix\.lock)|bin/|docs/iterations/)' || true)
  if [ -z "$excerpt_files" ]; then
    echo 'No changed files matched the excerpt filter.'
  else
    printf '%s\n' "$excerpt_files" | while IFS= read -r file; do
      if [ -f "$file" ]; then
        echo "=== $file ==="
        sed -n '1,220p' "$file"
        echo ''
      fi
    done
  fi
fi`
- Output:
  ```
  (9128 lines omitted)
        reset_projection_tables!(conn)
      end)
    end
  
    defp stop_event_sourced_subscribers! do
      for {child_id, pid, :worker, [module]} <- Supervisor.which_children(Memba.Supervisor),
          module in event_sourced_subscribers() do
        if is_pid(pid) do
          :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
        end
  
        child_id
      end
    end
  
    defp start_event_sourced_subscribers!(child_ids) do
      Enum.each(child_ids, fn child_id ->
        case Supervisor.restart_child(Memba.Supervisor, child_id) do
          {:ok, _pid} -> :ok
          {:ok, _pid, _info} -> :ok
          {:error, :running} -> :ok
        end
      end)
    end
  
    defp stop_commanded_aggregate_instances! do
      Enum.each(@commanded_apps, fn app ->
        supervisor_name = Module.concat([app, Commanded.Aggregates.Supervisor])
  
        if supervisor_pid = Process.whereis(supervisor_name) do
          supervisor_pid
          |> DynamicSupervisor.which_children()
          |> Enum.each(fn {_child_id, aggregate_pid, _type, _modules} ->
            if is_pid(aggregate_pid) do
              DynamicSupervisor.terminate_child(supervisor_pid, aggregate_pid)
            end
          end)
        end
      end)
    end
  
    defp reset_commanded_subscription_acks! do
      Enum.each(@commanded_apps, &Commanded.Subscriptions.reset/1)
    end
  
    defp reset_event_store_subscription_checkpoints! do
      Enum.each(event_sourced_subscribers(), fn subscriber ->
        :ok =
          Commanded.EventStore.delete_subscription(
            subscriber_commanded_app(subscriber),
  ```


You are the plan conformance gate for the iteration implementation at docs/iterations/056-group-audience-foundation/plan.md.

Use the prior context: the plan text, the implementation todo list, collected implementation evidence, current working tree state, commit range, and successful dev check output. Do not edit files.

Purpose:

- Decide whether the current implementation satisfies the explicit requirements in the plan.
- Treat passing dev check as necessary but not sufficient.
- Treat explicit plan requirements as binding deliverables, not optional implementation strategy.
- Use the implementation todo list as execution-state evidence, but do not let checked boxes override missing code, config, migration, or test evidence.

Process:

1. Read the plan's goal, scope, acceptance criteria, implementation plan, and validation plan sections.
2. Read the todo list generated and maintained by the implementation workflow.
3. Identify every explicit requirement using keywords like "Add", "Implement", "Configure", "Run", "Use", "Provide", and "Execute".
4. For each explicit requirement, inspect the collected evidence: changed files, code modules, configuration files, migrations, test files, and test output.
5. Compare test evidence with each explicit requirement.
6. Decide whether gaps are absent, safely repairable in a bounded pass, or require human input.

Acceptance rules:

- If the plan explicitly says "Implement X" and X is missing or incomplete, do not pass the gate.
- If the plan mandates a specific architecture, library, protocol, adapter, migration, test type, or external command, require concrete evidence for it.
- If the implementation uses a materially different architecture or behaviour from the approved plan, route to PLAN_REWORK when the repair is bounded by the plan, or HUMAN_INPUT when the difference needs a product or architecture decision.
- If the plan requires specific test types and those tests are missing, insufficient, or do not cover the requirements, route to PLAN_REWORK or HUMAN_INPUT.
- If tests pass but do not actually prove or cover the explicit plan requirements, route to PLAN_REWORK or HUMAN_INPUT.
- Never downgrade explicit plan requirements to optional implementation strategy unless routing to HUMAN_INPUT with a clear question about scope reduction.
- If the same plan gap appears to have recurred after plan rework, prefer HUMAN_INPUT over repeated repair loops.
- If a requirement is blocked, ambiguous, contradictory, or needs a product/architecture decision, route to HUMAN_INPUT.
- Treat acceptance feature files as locked unless the plan has a `## Allowed acceptance feature changes` section naming the exact file and allowed kind of change. Any implementation feature-file edit must stay within that explicit permission and preserve/validate the coverage promised by the plan; any other repair requiring feature-file changes needs HUMAN_INPUT.

Report format:

Return a concise Markdown report with:

- Decision: PLAN_CONFORMANT, PLAN_REWORK, or HUMAN_INPUT
- Requirements checked (list each explicit requirement from the plan)
- Missing or weak requirements, each with:
  - Requirement text from the plan
  - Expected evidence (code/config/tests/migrations/commands)
  - Observed evidence (what exists, what is missing)
  - Gap severity
- Exact repair brief if rework is safe and bounded
- Human question if human input is needed

End your response with exactly one JSON object that Fabro can use for routing:

If plan conformant:
{"context_updates":{"plan_conformant":true,"plan_rework_available":false}}

If bounded plan rework is appropriate:
{"context_updates":{"plan_conformant":false,"plan_rework_available":true}}

If human input is required:
{"context_updates":{"plan_conformant":false,"plan_rework_available":false}}