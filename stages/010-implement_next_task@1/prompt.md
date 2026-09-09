Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01M23P8GASTPS25GCXAZ8TF95X
Pipeline progress: 8 of 36 stages completed

## Stage: verify_source_head
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-implementation/scripts/verify_source_head.sh '723a2f9671d874c65b32ef95e5d3e509a545c4f7'`
- Output:
  ```
  Expected source HEAD: 723a2f9671d874c65b32ef95e5d3e509a545c4f7
  Actual source HEAD:   723a2f9671d874c65b32ef95e5d3e509a545c4f7
  Source directory:     /repos/mattwynne/memba
  Source checkout matches the expected implementation commit.
  ```

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/059-populated-clubs-always-have-an-admin/plan.md'
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
  (173 lines omitted)
  18. Retain existing member/role events, projectors, and `SystemGroupMembership`; prove one activation yields queryable membership, permission, Everyone, and Admin-group state.
  19. Present the two confirmed removal errors on the existing Staff club page. Test blocked members remain visible and permitted removal retains its success path.
  20. Repair affected tests, development seeds, and smoke fixtures to use event-sourced clubs and deterministic first-member ordering, without projection-only write fixtures.
  21. Add pure Club tests for first/later activation, idempotency, duplicate and Club-known removed IDs, inactive-member role assignment, both removal floors, and replacement Admin removal.
  22. Add one same-stream append contract test and one concurrent two-invitation test proving both memberships succeed with exactly one automatic Admin.
  23. Run replay, projection, system-group, onboarding, invitation, Staff UI, member-list, messaging, seed, smoke, and Cucumber regressions. Remove runner-debt tags and run `dev check`.
  
  ## Technical Decisions
  
  - **Consistency boundary:** the existing Club aggregate owns active roster decisions because it already owns Admin roles and assignments. Aggregate boundaries follow the immediate invariant, not the old membership-ID stream partition.
  - **Atomicity:** one Club-routed activation command may return both `MemberAdded` and `MemberRoleAssigned`; Commanded appends that event list atomically to one club stream. The claim deliberately excludes person creation, onboarding-request state, invitation state, email, and projections.
  - **Concurrency:** all membership additions for one club use the same aggregate identity. Commanded aggregate serialization and optimistic concurrency order competing decisions; after the first append, the second decision rehydrates/sees a populated club and emits no automatic Admin assignment. No custom lock or retry coordinator is introduced.
  - **Historical compatibility and precedence:** iteration 056 appended deterministic Everyone group-membership facts to Club streams for existing data. Those facts drive roster state only for membership IDs with no native Club membership lifecycle. The first native `MemberAdded` or `MemberRemoved` permanently marks that membership ID native; every later Everyone compatibility event still updates group state but cannot change roster state. Active Admins are active roster IDs intersected with active deterministic-Admin role assignments from Club role events.
  - **Invitation retry identity:** invitation IDs are the stable recovery key. Namespaced deterministic person/membership IDs are used when records do not yet exist; matching person-by-invited-email and active-membership-by-club/person queries recover committed partial progress. Exact matching command no-ops are success, while mismatched or ambiguous identities fail closed. This is idempotent application-service continuation, not a transaction coordinator.
  - **Proportionate cutover check:** this iteration adds no permanent release gate. A documented one-time read-only check runs immediately before the first iteration-059 production deployment and again afterward. It verifies both current zero-Admin state and compatibility facts; any violation pauses that cutover for human-approved repair.
  - **Membership identity scope:** Club rejects IDs present in its rehydrated lifecycle and production paths generate deterministic or fresh opaque IDs. Pre-cutover inactive IDs absent from Club streams are not imported solely to defend against a speculative opaque-ID collision.
  - **Inactive role assignments:** Club rejects assigning any role to an inactive membership. This existing application rule belongs beside the Admin-floor decision in the aggregate.
  - **Events and projections:** retain existing membership and role event types so current projectors and policies continue to build read models regardless of the stream that owns new events. Historic membership streams remain immutable.
  - **Error precedence:** reject final-member removal before sole-Admin removal. This keeps the two agreed rules visible and gives Staff the most specific recovery guidance.
  - **Infrastructure coverage:** aggregate tests carry the business proof. Add at most one thin EventStore contract test for same-stream append and one concurrency integration example; do not repeat transactional failure cases in stakeholder Gherkin.
  
  ## New Capability
  
  Every ordinary path into or out of a club preserves a viable membership administration structure. The first active person can administer the club immediately, concurrent first joins cannot create zero or two automatic Admins, and Staff cannot remove the authority or final member needed to keep an established club alive.
  
  ## Validation Plan
  
  - Validate the new Gherkin with the repository’s feature parser and tag-configuration checks before implementing step support.
  - Run pure aggregate tests without a database to prove the event lists and rejection decisions for all first/later/add/remove examples.
  - Replay representative historical and mixed Club streams and compare aggregate decision state with current active membership and Admin projections. Include `MemberAdded(A)`, `MemberAdded(B)`, `MemberRemoved(A)`, then delayed Everyone `GroupMemberAdded(A)` and prove A remains inactive and cannot count as an Admin.
  - Review `cutover-check.md` against complete and deliberately incomplete examples. Immediately before the first production deployment, run its read-only current-invariant and compatibility checks; pause for human judgement on any violation, then repeat the checks after deployment.
  - Inspect the persisted Club stream in one focused integration test to confirm first membership and Admin assignment came from one dispatch and share one aggregate stream.
  - Exercise two distinct invitation acceptances concurrently through the application boundary and await strong projections before asserting both memberships and exactly one Admin.
  - Inject failures after person creation and after membership activation but before invitation acceptance; retry both invitation paths and prove stable identities, one person, one active membership, one accepted invitation, and no duplicate Admin.
  - Run focused tests for Membership public APIs, Club aggregate dispatch, membership and role projections, system groups, onboarding conversion, existing/new-person invitation acceptance, accepted-link retry, Staff removal LiveView, member presentation, messaging recipients, seeds, and production smoke fixtures.
  - Exercise the accepted non-concurrent examples through both domain and browser Cucumber runners; run the concurrency example through the domain runner only.
  - Manually demo an empty Staff-created club: accept the first invitation, confirm Admin/member badge and invitation authority, add a later ordinary member, observe blocked sole-Admin removal, grant a replacement Admin, remove the original Admin, and observe blocked final-member removal on a one-member fixture.
  - Run `dev check` on the committed delivery candidate.
  
  ## Risks / Follow-ups
  
  - Moving add/remove commands to the Club stream will invalidate projection-only tests and fixtures that never created an event-sourced club. Fix the fixtures rather than adding a fallback write path.
  - Existing tests and seeds may assume the first generic `add_member` call creates an ordinary member. Their setup order must make intended authority explicit.
  - Historical roster hydration depends on iteration-056 Everyone facts being complete wherever no native Club membership lifecycle exists. The one-time cutover check must fail visibly and must not trigger an automatic production mutation; a permanent deployment gate would add disproportionate release coupling after the aggregate owns the invariant.
  - Leaving onboarding’s explicit role assignment in place would turn a successful atomic activation into a misleading duplicate-assignment failure. Remove that follow-up and protect its retry paths.
  - Club streams will receive more membership lifecycle events and become a stronger serialization point. That contention is intentional for this immediate invariant and appropriate for current club sizes; monitor before optimizing.
  - The system-group handler remains downstream of the atomic domain decision. Admin authority comes from the role event in the append, not from eventual Admin-group projection timing.
  - Invitation/person bookkeeping can still fail before or after the Club append. This iteration preserves and tests idempotent recovery but does not claim cross-aggregate transactionality.
  - Follow-up: design the explicit archive/close behaviour that may end an established club and define what happens to its remaining member, roles, groups, conversations, and email routes.
  - Follow-up: define first-Admin behaviour if a future bulk-import capability can create several memberships as one operation.
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/059-populated-clubs-always-have-an-admin/plan.md'
PATH="$PWD/bin:$PATH" dev iteration check-predecessors "$PLAN_PATH"
PATH="$PWD/bin:$PATH" dev iteration check-clear "$PLAN_PATH" --allow-same-iteration`
- Output:
  ```
  (6 lines omitted)
  ✓ Evaluating shell in 1.06ms (cached)
  ✓ Configuring shell in 9.00ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 302µs (cached)
  ✓ Loading tasks in 1.24ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 9.61ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.3ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 4.11µs (no command)
  ✓ Running tasks in 21.5ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:2] [ds:8:2:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  • Validating lock
  ✓ Validating lock in 18.2ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 1.80ms
  • Evaluating shell
  ✓ Evaluating shell in 684µs (cached)
  ✓ Configuring shell in 5.12ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 183µs (cached)
  ✓ Loading tasks in 1.75ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 9.80ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 10.8ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 72.0µs (no command)
  ✓ Running tasks in 21.6ms
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
PLAN_PATH='docs/iterations/059-populated-clubs-always-have-an-admin/plan.md'
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
  HEAD: d5ac07a fabro(01M23P8GASTPS25GCXAZ8TF95X): preflight_sandbox (succeeded)
  Todo: docs/iterations/059-populated-clubs-always-have-an-admin/todo.md is absent; sync_task_list will create it from plan.md.
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/059-populated-clubs-always-have-an-admin/plan.md'
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
  Created docs/iterations/059-populated-clubs-always-have-an-admin/todo.md from docs/iterations/059-populated-clubs-always-have-an-admin/plan.md
  PLAN_PATH=docs/iterations/059-populated-clubs-always-have-an-admin/plan.md
  TODO_PATH=docs/iterations/059-populated-clubs-always-have-an-admin/todo.md
  # Implementation TODO
  
  - [ ] 001 Implement the existing iteration-059 Gherkin steps and confirm unfinished steps remain excluded until executable. Keep the later-invitee ordinary example as regression coverage.
  - [ ] 002 Add Club replay tests for historic Everyone membership and role facts, active-Admin reconstruction, and delayed compatibility events after native membership events.
  - [ ] 003 Write `cutover-check.md` with exact one-time read-only production checks for source-fact compatibility and populated clubs without an active Admin, including pre/post-deploy expectations and stop instructions.
  - [ ] 004 Extend Club aggregate state with active roster entries, permanent native-lifecycle markers, and active Admins derived by intersecting active roster IDs with active Admin-role assignments.
  - [ ] 005 Apply historic Everyone events only where no native marker exists. Make native `MemberAdded` or `MemberRemoved` permanently authoritative for that membership while preserving ordinary group state.
  - [ ] 006 Add club/person identity to member commands, validate it against Club state, route add/remove by `club_id`, and de-register the membership-ID write route.
  - [ ] 007 Remove the legacy Membership aggregate if unused; otherwise mark it unregistered legacy replay code and create a named deletion follow-up. Never expose a second write path.
  - [ ] 008 Make activation idempotent for an exact active identity and reject another active membership for the same person. Reject removed IDs known to Club without importing absent pre-cutover tombstones.
  - [ ] 009 Emit `MemberAdded` plus the Admin `MemberRoleAssigned` event for the first activation in one decision. Emit only `MemberAdded` for later members.
  - [ ] 010 Reject role assignment to an inactive membership inside Club and enforce the active-Admin floor when handling direct `RemoveMemberRole`.
  - [ ] 011 Enforce final-member precedence and sole-Admin protection in Club’s `RemoveMember`; apply success to both roster and active-Admin decision state.
  - [ ] 012 Thin `Memba.Membership` write APIs around Club decisions. Projection lookups may enrich routing identity but must not decide duplicate, first-member, Admin-floor, or member-floor rules.
  - [ ] 013 Route onboarding conversion through Club activation and remove its separate Admin assignment. Route both invitation-acceptance paths through the same activation command.
  - [ ] 014 Derive new invitation person/membership candidates from the invitation ID with namespaced `Memba.ID.deterministic/2`; require explicit caller IDs to be reused.
  - [ ] 015 Recover zero-or-one person by invited email and zero-or-one active membership by club/person. Reuse matches and fail closed on ambiguous or mismatched identities.
  - [ ] 016 Treat exact same-ID person/member creation as successful retry continuation and use strong projections or a barrier before recovery queries after uncertain dispatch results.
  - [ ] 017 Accept the invitation with recovered identities and preserve its result contract. Add failure-injection retry tests after person creation and membership activation for both paths.
  - [ ] 018 Retain existing member/role events, projectors, and `SystemGroupMembership`; prove one activation yields queryable membership, permission, Everyone, and Admin-group state.
  - [ ] 019 Present the two confirmed removal errors on the existing Staff club page. Test blocked members remain visible and permitted removal retains its success path.
  - [ ] 020 Repair affected tests, development seeds, and smoke fixtures to use event-sourced clubs and deterministic first-member ordering, without projection-only write fixtures.
  - [ ] 021 Add pure Club tests for first/later activation, idempotency, duplicate and Club-known removed IDs, inactive-member role assignment, both removal floors, and replacement Admin removal.
  - [ ] 022 Add one same-stream append contract test and one concurrent two-invitation test proving both memberships succeed with exactly one automatic Admin.
  - [ ] 023 Run replay, projection, system-group, onboarding, invitation, Staff UI, member-list, messaging, seed, smoke, and Cucumber regressions. Remove runner-debt tags and run `dev check`.
  ```

## Stage: todo_readable
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/059-populated-clubs-always-have-an-admin/plan.md'
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
  Todo file is present and readable: docs/iterations/059-populated-clubs-always-have-an-admin/todo.md
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/059-populated-clubs-always-have-an-admin/plan.md'
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
  UNCHECKED tasks remain in docs/iterations/059-populated-clubs-always-have-an-admin/todo.md
  3:- [ ] 001 Implement the existing iteration-059 Gherkin steps and confirm unfinished steps remain excluded until executable. Keep the later-invitee ordinary example as regression coverage.
  4:- [ ] 002 Add Club replay tests for historic Everyone membership and role facts, active-Admin reconstruction, and delayed compatibility events after native membership events.
  5:- [ ] 003 Write `cutover-check.md` with exact one-time read-only production checks for source-fact compatibility and populated clubs without an active Admin, including pre/post-deploy expectations and stop instructions.
  6:- [ ] 004 Extend Club aggregate state with active roster entries, permanent native-lifecycle markers, and active Admins derived by intersecting active roster IDs with active Admin-role assignments.
  7:- [ ] 005 Apply historic Everyone events only where no native marker exists. Make native `MemberAdded` or `MemberRemoved` permanently authoritative for that membership while preserving ordinary group state.
  8:- [ ] 006 Add club/person identity to member commands, validate it against Club state, route add/remove by `club_id`, and de-register the membership-ID write route.
  9:- [ ] 007 Remove the legacy Membership aggregate if unused; otherwise mark it unregistered legacy replay code and create a named deletion follow-up. Never expose a second write path.
  10:- [ ] 008 Make activation idempotent for an exact active identity and reject another active membership for the same person. Reject removed IDs known to Club without importing absent pre-cutover tombstones.
  11:- [ ] 009 Emit `MemberAdded` plus the Admin `MemberRoleAssigned` event for the first activation in one decision. Emit only `MemberAdded` for later members.
  12:- [ ] 010 Reject role assignment to an inactive membership inside Club and enforce the active-Admin floor when handling direct `RemoveMemberRole`.
  13:- [ ] 011 Enforce final-member precedence and sole-Admin protection in Club’s `RemoveMember`; apply success to both roster and active-Admin decision state.
  14:- [ ] 012 Thin `Memba.Membership` write APIs around Club decisions. Projection lookups may enrich routing identity but must not decide duplicate, first-member, Admin-floor, or member-floor rules.
  15:- [ ] 013 Route onboarding conversion through Club activation and remove its separate Admin assignment. Route both invitation-acceptance paths through the same activation command.
  16:- [ ] 014 Derive new invitation person/membership candidates from the invitation ID with namespaced `Memba.ID.deterministic/2`; require explicit caller IDs to be reused.
  17:- [ ] 015 Recover zero-or-one person by invited email and zero-or-one active membership by club/person. Reuse matches and fail closed on ambiguous or mismatched identities.
  18:- [ ] 016 Treat exact same-ID person/member creation as successful retry continuation and use strong projections or a barrier before recovery queries after uncertain dispatch results.
  19:- [ ] 017 Accept the invitation with recovered identities and preserve its result contract. Add failure-injection retry tests after person creation and membership activation for both paths.
  20:- [ ] 018 Retain existing member/role events, projectors, and `SystemGroupMembership`; prove one activation yields queryable membership, permission, Everyone, and Admin-group state.
  21:- [ ] 019 Present the two confirmed removal errors on the existing Staff club page. Test blocked members remain visible and permitted removal retains its success path.
  22:- [ ] 020 Repair affected tests, development seeds, and smoke fixtures to use event-sourced clubs and deterministic first-member ordering, without projection-only write fixtures.
  ```


Implement the next unchecked iteration task from `todo.md`.

Plan path: `docs/iterations/059-populated-clubs-always-have-an-admin/plan.md`.
Todo path is derived from the plan path by replacing `/plan.md` with `/todo.md`.

## Ownership rules

- Read the plan and `todo.md` before editing.
- Pick the first unchecked Markdown task line in `todo.md` (`- [ ] ...`). That task is yours from selection through check-off.
- Treat earlier checked todo lines as durable completed work. Do not redo them.
- Inspect recent Fabro checkpoint commits with `git log --oneline --decorate -20` and use their subjects/bodies/diffs as context for what previous runs already completed.
- Read existing implementation notes, reviews, and recovery handoffs for the selected task before repeating repository-wide research. A committed failed checkpoint is candidate work, not a completed task: inspect and continue or correct it without treating its unchecked todo as untouched work.
- Inspect `git status --short` before editing. The resume gate should normally guarantee a clean tree; if uncommitted changes are present, stop for human input unless they are clearly the selected task's in-progress work and you can safely continue it to completion without overwriting it.
- Never silently overwrite, discard, or duplicate uncommitted work for an unchecked task.
- Implement exactly the selected task only. Do not opportunistically implement later tasks unless the selected task cannot be completed without splitting/reordering the todo list first.
- When the implementation and focused validation are complete, check off the same task line you implemented by changing that one line from `- [ ]` to `- [x]`.
- Immediately before editing `todo.md` for that check-off, read the exact active todo path with the agent read tool, then patch only the selected line. Shell `cat`, earlier workflow/script output, and prior reads of other paths do not satisfy Fabro's active-agent read guard.
- Do not check off any other ordinary todo line.
- Do not spawn subagents in this per-task node. Keep task research, implementation, and focused validation under one bounded owner so child-agent waits cannot consume the node's fixed deadline.
- Do not commission an extra independent review. The workflow's next `validate_task` node already provides independent review after Fabro checkpoints your completed task.
- Do not commit manually. Fabro will checkpoint your changes automatically after this node; independent validation will inspect that checkpoint evidence.


## Local reference docs

- Prefer local project documentation over network lookups. Do not `curl` upstream docs unless the local docs are missing or clearly insufficient.
- Start with `docs/tools/README.md` for library documentation signposts. Relevant local docs include:
  - `docs/tools/commanded/README.md` for Commanded.
  - `docs/tools/commanded-eventstore-adapter/README.md` for the EventStore adapter.
  - `docs/tools/eventstore/README.md` for EventStore.
  - `docs/tools/commanded-ecto-projections/README.md` for projections.
  - `docs/tools/cucumber/README.md` for Elixir Cucumber.
  - `docs/tools/ecto/README.md` and `docs/tools/ecto-sql/README.md` for Ecto.
  - `docs/tools/phoenix/README.md` and related Phoenix docs for web framework work.
- If you need examples, search the local `web/deps/` source tree and `docs/tools/` before using the network.

## Binding rules

- `plan.md` remains the source of truth. `todo.md` is derived execution state.
- You may split the selected task into smaller unchecked tasks, add required technical subtasks, or reorder pending tasks only to satisfy the approved plan.
- If the selected task is too large, split it in `todo.md`, leave the parent/current task unchecked or replace it with smaller unchecked tasks, then implement and check off only the first newly available slice.
- You may not delete, weaken, or silently defer plan-required work.
- Before editing, read every ADR explicitly referenced by the plan and inspect nearby/current ADRs under `docs/adr/` when relevant.
- Treat accepted ADRs as binding architecture constraints.
- Use test-driven development for behaviour changes.
- Add or update automated tests proving the selected task's behaviour/configuration.
- Run focused validation appropriate to the selected task and capture the commands/results in your response.
- For per-task validation, prefer the smallest checks that prove the selected task: relevant focused tests plus formatting for touched files when practical.
- Use `PATH="$PWD/bin:$PATH" dev check --quick` for broad per-task validation when the selected task does not change browser-facing behaviour, acceptance tests, routing, LiveView/UI, or feature/step files.
- Run full `PATH="$PWD/bin:$PATH" dev check` during a task only when that task changes browser-facing behaviour, acceptance tests, routing, LiveView/UI, feature/step files, or when the selected task is the final validation task. The workflow's final quality gate will still run the full check before publication.
- In the Fabro sandbox, avoid wrapping focused commands in `devenv shell -- ...` unless there is a specific reason. The sandbox image and project wrappers are already prepared for the project; prefer `PATH="$PWD/bin:$PATH" dev test ...` for focused Elixir tests and `PATH="$PWD/bin:$PATH" dev ...` for broader project checks so command execution stays consistent with the workflow environment. Do not use direct `bin/mix test ...` for focused tests in a Fabro sandbox because stale baked `PGHOST`/`PGPORT` values can point it at the wrong Postgres socket.
- Acceptance feature files (`*.feature`, including files under `acceptance-tests/`) are locked unless the plan has a `## Allowed acceptance feature changes` section naming the exact file and allowed kind of change. If the plan permits a feature edit, make only that explicit edit and preserve/validate the coverage promised by the plan. If a feature file appears wrong, stale, or insufficient without explicit permission, stop and report the issue.
- Add acceptance step definitions only where the plan explicitly requires executable plumbing for shared feature files.
- Use Req for HTTP requests; do not introduce HTTPoison, Tesla, or `:httpc`.
- Follow relevant project guidance for Phoenix, LiveView, HEEx, Tailwind, Ecto, Elixir, Mix, and tests.
- If you hit a real blocker, stop and report it clearly without checking off the task.

When finished, summarize:

1. Selected todo line and task text.
2. Code/config/test/doc changes made for this task only.
3. Focused validation commands run and results.
4. The exact todo check-off you made.
5. Any todo splits/additions/reordering and why they still satisfy the plan.
6. ADR conformance evidence for this task.