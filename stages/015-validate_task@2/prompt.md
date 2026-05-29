Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01KST2YJGFYEGE4CAR6JK5JF8H
Pipeline progress: 13 of 18 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/002-membership-model/plan.md'
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
  (40 lines omitted)
    `list_active_members_of_club/1` returning enough identity to drive recipient
    resolution (id, name, email).
  - Cucumber step definitions for all Background lines in
    `member_message_deliverability.feature` and
    `operator_email_deliverability.feature`:
    - "<Club> is a club"
    - "<People> are people" / "<Person> is a person"
    - "<People> are members of <Club>" / "<Person> is a member of <Club>"
  - ExUnit coverage for Person and Membership aggregate rules and projector
    behaviour.
  
  ### Out of scope
  
  - Anything Messaging.
  - Lapsed/revoked membership.
  - Household or family modelling.
  
  ## Acceptance Criteria
  
  - `Memba.Membership.list_active_members_of_club/1` returns the active
    members of the given club and excludes members of other clubs.
  - A person created independently can be added as a member of a club via
    domain commands.
  - Background steps for both shared feature files pass under Elixir Cucumber.
  - ExUnit covers aggregate decisions and projector behaviour.
  - `devenv shell mix precommit` passes.
  
  ## Implementation Plan
  
  1. Add `Person` aggregate, `CreatePerson` command, `PersonCreated` event,
     and Person projector + query.
  2. Add `Membership` aggregate, `AddMember` command, `MemberAdded` event,
     and Membership projector.
  3. Implement `list_active_members_of_club/1` and supporting queries on the
     Membership context boundary.
  4. Add Cucumber step definitions for all Background lines in both feature
     files, using the public Membership API.
  5. Run `devenv shell mix precommit` and fix any issues.
  
  ## Validation Plan
  
  - Cucumber Background of both feature files passes.
  - ExUnit covers aggregate rules, projector behaviour, and the query API.
  - `devenv shell mix precommit` passes.
  
  ## Risks / Follow-ups
  
  - The minimal membership model will need to evolve soon (lapsed/active,
    households, renewals, privacy). That work belongs to a later iteration.
  - Iteration 003 implements Messaging on top of this API.
  ```

## Stage: preflight_sandbox
- Status: succeeded
- Handler: command
- Script: `set -eu
if [ ! -x bin/dev ]; then
  echo "Missing or non-executable bin/dev" >&2
  exit 1
fi
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
  ✓ Validating lock in 21.2ms
  Manager did not shut down within 30 seconds, sending SIGKILL
  ```

## Stage: resume_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/002-membership-model/plan.md'
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
  HEAD: 4490f32 fabro(01KST2YJGFYEGE4CAR6JK5JF8H): preflight_sandbox (succeeded)
  Todo: docs/iterations/002-membership-model/todo.md is absent; sync_task_list will create it from plan.md.
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/002-membership-model/plan.md'
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
  Using existing docs/iterations/002-membership-model/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/002-membership-model/plan.md
  TODO_PATH=docs/iterations/002-membership-model/todo.md
  # Implementation TODO
  
  - [x] 001 Add `Person` aggregate, `CreatePerson` command, `PersonCreated` event,
  - [ ] 002 Add `Membership` aggregate, `AddMember` command, `MemberAdded` event,
  - [ ] 003 Implement `list_active_members_of_club/1` and supporting queries on the
  - [ ] 004 Add Cucumber step definitions for all Background lines in both feature
  - [ ] 005 Run `devenv shell mix precommit` and fix any issues.
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 5.6k in / 109 out
- Response:
  > {"context_updates":{"task_list_complete":false,"task_list_needs_human":false}}

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 757.0k in / 14.5k out
- Response:
  > Implemented the next unchecked iteration task.
  > 
  > 1. **Selected todo line**
  >    - `- [ ] 002 Add Membership aggregate, AddMember command, MemberAdded event,`
  > 
  > 2. **Changes made for this task**
  >    - Added Membership write model:
  >      - `Memba.Membership.Membership`
  >      - `Memba.Membership.Commands.AddMember`
  >      - `Memba.Membership.Events.MemberAdded`
  >    - Added Membership projection:
  >      - `Memba.Membership.Projections.Membership`
  >      - `Memba.Membership.Projectors.Membership`
  >      - Migration: `create_membership_memberships_projection`
  >    - Wired Membership into:
  >      - `Memba.Membership.Router` with `identify(Membership, by: :membership_id)`
  >      - `Memba.Application` supervision tree
  >      - event-sourced projection reset config/test helpers
  >    - Added/updated tests for:
  >      - aggregate decision and apply rules
  >      - Commanded dispatch/routing
  >      - projector persistence
  >      - supervised projector/registered command coverage
  >      - projection migration/reset support
  >    - Did not edit acceptance feature files.
  > 
  > 3. **Validation commands/results**
  >    - `cd web && mix compile --warnings-as-errors`
  >      - Passed.
  >    - `cd web && mix format --check-formatted`
  >      - Passed after manual format fix.
  >    - `PATH="$PWD/bin:$PATH" dev check`
  >      - Passed: `49 tests, 0 failures`.
  >    - Note: an initial direct `mix test ...` attempt outside `dev` failed because Postgres was not running in that shell; final validation used `dev check`, which starts required services.
  > 
  > 4. **Todo check-off made**
  >    - Changed exactly:
  >      - `- [ ] 002 Add Membership aggregate, AddMember command, MemberAdded event,`
  >    - To:
  >      - `- [x] 002 Add Membership aggregate, AddMember command, MemberAdded event,`
  > 
  > 5. **Todo splits/additions/reordering**
  >    - None.
  > 
  > 6. **ADR conformance**
  >    - ADR 0007: all changes stay inside the Membership bounded context; no Messaging coupling or Messaging code changes.
  >    - ADR 0011: Membership uses caller-supplied `membership_id` as aggregate identity, routed via Commanded conventions; `club_id` and `person_id` are event/projection fields rather than natural aggregate identity.

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/002-membership-model/plan.md'
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
  250bb79
  250bb79 fabro(01KST2YJGFYEGE4CAR6JK5JF8H): implement_next_task (succeeded)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/002-membership-model/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 179.0k in / 3.4k out
- Response:
  > ### Decision
  > **VALID**
  > 
  > ### Evidence
  > - Completed todo/check-off evidence found:
  >   - Working tree is clean.
  >   - Recent checkpoint `7e7a370 fabro(...): implement_next_task (succeeded)` changed exactly one ordinary todo line:
  >     - `- [ ] 001 Add Person aggregate, CreatePerson command, PersonCreated event,`
  >     - to `- [x] 001 ...`
  >   - Current `docs/iterations/002-membership-model/todo.md` shows task 001 checked and tasks 002–005 still unchecked. No split/reorder/deletion was found.
  > - Implementation artifacts found:
  >   - Added Person aggregate/command/event:
  >     - `web/lib/memba/membership/person.ex`
  >     - `web/lib/memba/membership/commands/create_person.ex`
  >     - `web/lib/memba/membership/events/person_created.ex`
  >   - Added Person projection/projector/migration:
  >     - `web/lib/memba/membership/projections/person.ex`
  >     - `web/lib/memba/membership/projectors/person.ex`
  >     - `web/priv/repo/migrations/20260529145014_create_membership_people_projection.exs`
  >   - Wired into router, supervision, config, and public query API:
  >     - `Memba.Membership.Router` dispatches `CreatePerson` to `Person`.
  >     - `Memba.Application` supervises `Memba.Membership.Projectors.Person`.
  >     - `Memba.Membership.get_person/1` added.
  > - Tests run/results found:
  >   - Added/updated ExUnit coverage for aggregate rules, dispatch/routing, projection/query behaviour, supervision, and reset support.
  >   - Live validation run: `PATH="$PWD/bin:$PATH" dev check` passed with `40 tests, 0 failures`.
  >   - Working tree remained clean after validation.
  > - ADR/plan conformance notes:
  >   - Matches the first implementation-plan slice: Person aggregate, command, event, projector, and query.
  >   - ADR 0007 respected: work remains inside Membership bounded context; no Messaging coupling found.
  >   - ADR 0011 respected: caller-supplied `person_id` UUID with Commanded `identify(Person, by: :person_id)`.
  >   - No `.feature` or `acceptance-tests/` files were edited in the implementation checkpoint.
  >   - Scope is small and independently useful as a checkpoint.
  > 
  > {"context_updates":{"task_valid":true,"task_retry_available":false}}

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/002-membership-model/plan.md'
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
  Using existing docs/iterations/002-membership-model/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/002-membership-model/plan.md
  TODO_PATH=docs/iterations/002-membership-model/todo.md
  # Implementation TODO
  
  - [x] 001 Add `Person` aggregate, `CreatePerson` command, `PersonCreated` event,
  - [ ] 002 Add `Membership` aggregate, `AddMember` command, `MemberAdded` event,
  - [ ] 003 Implement `list_active_members_of_club/1` and supporting queries on the
  - [ ] 004 Add Cucumber step definitions for all Background lines in both feature
  - [ ] 005 Run `devenv shell mix precommit` and fix any issues.
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 5.6k in / 109 out
- Response:
  > {"context_updates":{"task_list_complete":false,"task_list_needs_human":false}}

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 757.0k in / 14.5k out
- Response:
  > Implemented the next unchecked iteration task.
  > 
  > 1. **Selected todo line**
  >    - `- [ ] 002 Add Membership aggregate, AddMember command, MemberAdded event,`
  > 
  > 2. **Changes made for this task**
  >    - Added Membership write model:
  >      - `Memba.Membership.Membership`
  >      - `Memba.Membership.Commands.AddMember`
  >      - `Memba.Membership.Events.MemberAdded`
  >    - Added Membership projection:
  >      - `Memba.Membership.Projections.Membership`
  >      - `Memba.Membership.Projectors.Membership`
  >      - Migration: `create_membership_memberships_projection`
  >    - Wired Membership into:
  >      - `Memba.Membership.Router` with `identify(Membership, by: :membership_id)`
  >      - `Memba.Application` supervision tree
  >      - event-sourced projection reset config/test helpers
  >    - Added/updated tests for:
  >      - aggregate decision and apply rules
  >      - Commanded dispatch/routing
  >      - projector persistence
  >      - supervised projector/registered command coverage
  >      - projection migration/reset support
  >    - Did not edit acceptance feature files.
  > 
  > 3. **Validation commands/results**
  >    - `cd web && mix compile --warnings-as-errors`
  >      - Passed.
  >    - `cd web && mix format --check-formatted`
  >      - Passed after manual format fix.
  >    - `PATH="$PWD/bin:$PATH" dev check`
  >      - Passed: `49 tests, 0 failures`.
  >    - Note: an initial direct `mix test ...` attempt outside `dev` failed because Postgres was not running in that shell; final validation used `dev check`, which starts required services.
  > 
  > 4. **Todo check-off made**
  >    - Changed exactly:
  >      - `- [ ] 002 Add Membership aggregate, AddMember command, MemberAdded event,`
  >    - To:
  >      - `- [x] 002 Add Membership aggregate, AddMember command, MemberAdded event,`
  > 
  > 5. **Todo splits/additions/reordering**
  >    - None.
  > 
  > 6. **ADR conformance**
  >    - ADR 0007: all changes stay inside the Membership bounded context; no Messaging coupling or Messaging code changes.
  >    - ADR 0011: Membership uses caller-supplied `membership_id` as aggregate identity, routed via Commanded conventions; `club_id` and `person_id` are event/projection fields rather than natural aggregate identity.

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/002-membership-model/plan.md'
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
  250bb79
  250bb79 fabro(01KST2YJGFYEGE4CAR6JK5JF8H): implement_next_task (succeeded)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/002-membership-model/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Current context
| Key | Value |
|-----|-------|
| task_list_complete | false |
| task_list_needs_human | false |
| task_retry_available | false |
| task_valid | true |


Validate the just-completed iteration task for `docs/iterations/002-membership-model/plan.md`.

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