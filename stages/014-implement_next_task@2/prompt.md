Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01KSS97DPE1D5MD7CAZA9M506K
Pipeline progress: 12 of 19 stages completed

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
  ✓ Validating lock in 21.9ms
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
echo 'Working tree clean; safe to resume from durable task commits.'`
- Output:
  ```
  === Iteration resume gate ===
  HEAD: 8e8b99b fabro(01KSS97DPE1D5MD7CAZA9M506K): preflight_sandbox (succeeded)
  Todo: docs/iterations/002-membership-model/todo.md is absent; sync_task_list will create it from plan.md.
  Working tree clean; safe to resume from durable task commits.
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
- Tokens: 6.6k in / 88 out
- Response:
  > {"context_updates":{"task_list_complete":false,"task_list_needs_human":false}}

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 657.4k in / 17.0k out
- Response:
  > Implemented the next unchecked task.
  > 
  > 1. **Selected todo line**
  >    - `- [ ] 001 Add Person aggregate, CreatePerson command, PersonCreated event,`
  > 
  > 2. **Changes made**
  >    - Added Person write model:
  >      - `Memba.Membership.Person`
  >      - `Memba.Membership.Commands.CreatePerson`
  >      - `Memba.Membership.Events.PersonCreated`
  >    - Added Person read side:
  >      - `Memba.Membership.Projections.Person`
  >      - `Memba.Membership.Projectors.Person`
  >      - `Memba.Membership.get_person/1`
  >      - migration for `membership_people`
  >    - Wired Person into:
  >      - `Memba.Membership.Router`
  >      - application supervision
  >      - event-sourced test reset/projector setup
  >      - projection table config
  >    - Added ExUnit coverage for:
  >      - Person aggregate decisions/rules
  >      - CreatePerson dispatch/routing
  >      - Person projector/query behavior
  >      - event-sourced setup handling the new projection table
  >    - Updated existing app test to include the Person command/projector.
  > 
  > 3. **Validation**
  >    - TDD red check:
  >      - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/membership/person_test.exs`
  >      - Failed as expected before implementation because `CreatePerson` was undefined.
  >    - Focused passing checks:
  >      - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/membership/person_test.exs test/memba/membership/create_person_dispatch_test.exs test/memba/membership/person_projection_test.exs test/memba/membership/app_test.exs`
  >      - Result: `13 tests, 0 failures`
  >    - Projection setup check:
  >      - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/event_sourced_setup_test.exs`
  >      - Result: `3 tests, 0 failures`
  >    - Required final gate:
  >      - `PATH="$PWD/bin:$PATH" dev check`
  >      - First run hit a file permission issue from tool-created root-owned files; fixed permissions.
  >      - Rerun result: `40 tests, 0 failures`, exit 0.
  > 
  > 4. **Todo check-off made**
  >    - Changed exactly:
  >      - `- [ ] 001 Add Person aggregate, CreatePerson command, PersonCreated event,`
  >    - To:
  >      - `- [x] 001 Add Person aggregate, CreatePerson command, PersonCreated event,`
  > 
  > 5. **Todo splits/additions/reordering**
  >    - None.
  > 
  > 6. **ADR conformance**
  >    - ADR 0007: Kept Person inside the Membership context (`Memba.Membership.*`) and exposed it through the Membership public query boundary.
  >    - ADR 0011: Person aggregate identity is caller-supplied `person_id`; no natural-key/email identity was introduced.
  >    - ADR 0002/0009: Implemented command/event aggregate behavior with Commanded and Ecto projection read model storage.

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
SNAPSHOT=.fabro/tmp/pre-validate-snapshot.md
mkdir -p .fabro/tmp
{
  echo '# Pre-validation repository snapshot'
  echo
  echo 'Validation-time contract: implement_next_task has not committed. HEAD should normally be the previous successful task commit, while the current task work and todo.md check-off are uncommitted in the working tree.'
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
  Wrote .fabro/tmp/pre-validate-snapshot.md
  # Pre-validation repository snapshot
  
  Validation-time contract: implement_next_task has not committed. HEAD should normally be the previous successful task commit, while the current task work and todo.md check-off are uncommitted in the working tree.
  
  ## HEAD
  4dcdefc
  4dcdefc fabro(01KSS97DPE1D5MD7CAZA9M506K): implement_next_task (succeeded)
  
  ## git status --short
  ?? .fabro/tmp/
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/002-membership-model/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  .fabro/tmp/pre-validate-snapshot.md
  
  ## Combined changed path list from git status --porcelain
  ?? .fabro/tmp/
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 135.4k in / 4.8k out
- Response:
  > ### Decision
  > **VALID**
  > 
  > ### Evidence
  > - Completed todo/check-off evidence found:
  >   - `docs/iterations/002-membership-model/todo.md` has task `001` checked and task `002` remains first unchecked.
  >   - The implementation diff `e2ba61a..4dcdefc` shows exactly one ordinary todo line changed from `- [ ]` to `- [x]` for task `001`.
  >   - Live working tree is clean; snapshot also showed no uncommitted implementation diff, but current repository contents contain the completed task artifacts.
  > - Implementation artifacts found:
  >   - Added Person write model: `Memba.Membership.Person`, `CreatePerson`, `PersonCreated`.
  >   - Added Person read side: `Memba.Membership.Projections.Person`, `Memba.Membership.Projectors.Person`, migration for `membership_people`, and `Memba.Membership.get_person/1`.
  >   - Wired into router, app supervision, config projection table list, and event-sourced test reset support.
  > - Tests run/results found:
  >   - Added/updated ExUnit coverage for Person aggregate behavior, dispatch/routing, projector/query behavior, app wiring, and event-sourced setup.
  >   - Ran live: `PATH="$PWD/bin:$PATH" dev check` → `40 tests, 0 failures`, exit 0.
  > - ADR/plan conformance notes:
  >   - ADR 0007 respected: Person remains inside `Memba.Membership.*`; query exposed through Membership public API.
  >   - ADR 0011 respected: aggregate identity is caller-supplied `person_id`.
  >   - ADR 0002/0009 respected: Commanded command/event aggregate with Ecto projection.
  >   - No `*.feature` files, including under `acceptance-tests/`, were edited.
  >   - Scope is limited to task 001 and is independently committable.
  > 
  > {"context_updates":{"task_valid":true,"task_retry_available":false}}

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: commit_task
- Status: failed
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/002-membership-model/plan.md'
case "$PLAN_PATH" in
  */plan.md) ITERATION_DIR=${PLAN_PATH%/plan.md} ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
TODO_PATH="$ITERATION_DIR/todo.md"
if [ ! -s "$TODO_PATH" ]; then
  echo "Todo file is missing or empty: $TODO_PATH" >&2
  exit 1
fi
status=$(git status --short)
if [ -z "$status" ]; then
  echo 'No changes to commit for completed task.' >&2
  exit 1
fi
if printf '%s
' "$status" | grep -E '\.feature$'; then
  echo 'Refusing to commit locked acceptance feature file changes.' >&2
  exit 1
fi
git add -A
git reset -q -- .fabro/tmp 2>/dev/null || true
files=$(git diff --cached --name-only || true)
if [ -z "$files" ]; then
  echo 'No staged changes remain after excluding Fabro temp files.' >&2
  exit 1
fi
if printf '%s
' "$files" | grep -E '\.feature$'; then
  echo 'Refusing to commit locked acceptance feature file changes.' >&2
  git reset -q
  exit 1
fi
non_todo_files=$(printf '%s
' "$files" | grep -F -x -v "$TODO_PATH" || true)
if [ -z "$non_todo_files" ]; then
  echo 'Refusing to commit only todo.md; completed task has no implementation/test/config/doc artifact staged.' >&2
  git reset -q
  exit 1
fi
checked_count=$(git diff --cached -U0 -- "$TODO_PATH" | grep -E '^\+[[:space:]]*- \[x\] ' | grep -v '^+++' | wc -l | tr -d ' ')
unchecked_removed_count=$(git diff --cached -U0 -- "$TODO_PATH" | grep -E '^-[[:space:]]*- \[ \] ' | grep -v '^---' | wc -l | tr -d ' ')
if [ "${checked_count:-0}" -eq 0 ]; then
  echo 'Refusing to commit without a todo.md check-off for the completed task.' >&2
  git reset -q
  exit 1
fi
if [ "${checked_count:-0}" -gt 1 ] || [ "${unchecked_removed_count:-0}" -gt 1 ]; then
  echo 'Refusing to commit more than one ordinary todo check-off in a single task commit.' >&2
  git reset -q
  exit 1
fi
stat=$(git diff --cached --stat || true)
subject=$(git diff --cached -U0 -- "$TODO_PATH" | grep -E '^\+[[:space:]]*- \[x\] ' | grep -v '^+++' | head -1 | sed -E 's/^\+[[:space:]]*- \[x\] [0-9]*[[:space:]]*//; s/[^A-Za-z0-9._ -]/ /g' | cut -c1-60)
[ -n "$subject" ] || subject='completed task'
msg_file=.fabro/tmp/task-commit-message.txt
mkdir -p .fabro/tmp
{
  printf 'Implement iteration task: %s\n\n' "$subject"
  printf 'Plan: %s\n' "$PLAN_PATH"
  printf 'Todo: %s\n\n' "$TODO_PATH"
  printf 'Evidence files changed:\n%s\n\n' "$files"
  printf 'Diff stat:\n%s\n' "$stat"
} > "$msg_file"
git commit -F "$msg_file"
rm -f .fabro/tmp/task-commit-message.txt
git status --short`
- Output:
  ```
  No changes to commit for completed task.
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
- Tokens: 6.6k in / 88 out
- Response:
  > {"context_updates":{"task_list_complete":false,"task_list_needs_human":false}}

## Current context
| Key | Value |
|-----|-------|
| task_list_complete | false |
| task_list_needs_human | false |
| task_retry_available | false |
| task_valid | true |


Implement the next unchecked iteration task from `todo.md`.

Plan path: `docs/iterations/002-membership-model/plan.md`.
Todo path is derived from the plan path by replacing `/plan.md` with `/todo.md`.

## Ownership rules

- Read the plan and `todo.md` before editing.
- Pick the first unchecked Markdown task line in `todo.md` (`- [ ] ...`). That task is yours from selection through check-off.
- Treat earlier checked todo lines as durable completed work. Do not redo them.
- Inspect recent task commits with `git log --oneline --decorate -20` and use their subjects/bodies as context for what previous runs already completed.
- Inspect `git status --short` before editing. The resume gate should normally guarantee a clean tree; if uncommitted changes are present, stop for human input unless they are clearly the selected task's in-progress work and you can safely continue it to completion without overwriting it.
- Never silently overwrite, discard, or duplicate uncommitted work for an unchecked task.
- Implement exactly the selected task only. Do not opportunistically implement later tasks unless the selected task cannot be completed without splitting/reordering the todo list first.
- When the implementation and focused validation are complete, check off the same task line you implemented by changing that one line from `- [ ]` to `- [x]`.
- Do not check off any other ordinary todo line.
- Do not commit. The deterministic commit node will commit after independent validation.


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
- Never edit acceptance feature files (`*.feature`, including files under `acceptance-tests/`). If a feature file appears wrong, stale, or insufficient, stop and report the issue.
- Add acceptance step definitions only where the plan explicitly requires executable plumbing for locked shared feature files.
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