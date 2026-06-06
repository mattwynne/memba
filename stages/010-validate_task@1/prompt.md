Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01KTD3TRN7HAXJPZM7STW1E393
Pipeline progress: 8 of 30 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/022-request-to-club-onboarding/plan.md'
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
  (190 lines omitted)
  13. Implement conversion transactionally where practical: create club, create/reuse person, create active membership, mark request converted, and send/wrap welcome email behaviour consistently.
  14. Implement welcome email generation with a magic sign-in token and post-auth destination for the new club member home.
  15. Add or update tests for public form validation/submission, signed-in prepopulation, notification email, staff authorization, active inbox, rejection, conversion, existing-person reuse, slug validation, welcome email, and preservation of existing club creation/slug behaviour.
  16. Add acceptance step support for `request_account.feature` and remove `@wip` once the scenarios pass.
  17. Run targeted tests while developing, then run `dev check`.
  
  ## Open Technical Decisions
  
  Implementation should investigate and decide:
  
  - Whether request persistence belongs in an existing context or a new onboarding/requests context.
  - The cleanest way to reuse staff club creation slug behaviour: extracted helper functions, shared form component, or routing conversion through an existing create-club flow with request context.
  - The exact post-auth return URL mechanism for welcome magic links to land on the club member home, especially for club subdomains.
  - Whether new-request notification and welcome emails should reuse existing auth email configuration or introduce a small onboarding email module/config.
  - How to keep conversion transactional around database changes while email delivery remains an external side effect.
  - How to derive the signed-in person’s display name efficiently and reliably from the current identity email.
  
  ## New Capability
  
  Memba has a staff-approved onboarding path: people can ask to try Memba, staff can reject unsuitable requests, and staff can convert genuine requests into clubs with active first members and direct sign-in links, without exposing public self-serve email-sending access.
  
  ## Validation Plan
  
  - Review `acceptance-tests/features/request_account.feature` with Matt for domain language and examples before removing `@wip`.
  - Run browser Cucumber configuration checks to ensure the new feature is excluded while `@wip`.
  - During implementation, add LiveView/controller/context tests for request creation, validation, staff inbox, rejection, conversion, slug reuse, welcome email, and authorization.
  - Run existing staff club slug tests to prove the shared slug behaviour still works.
  - Run existing authentication tests to prove magic-link sign-in behaviour still works.
  - Run the new acceptance scenarios after removing `@wip`.
  - Run `dev check` before delivery is complete.
  
  Manual demo after implementation:
  
  1. Visit `/get-started` signed out.
  2. Submit a request for West Coast Paddlers and see the acknowledgement.
  3. Confirm no club/member access exists yet.
  4. Sign in as Memba staff.
  5. Open `/admin/requests` and see the active request.
  6. Reject a second request with an internal note and confirm no requester email is sent.
  7. Convert the West Coast Paddlers request, edit the generated slug, and confirm.
  8. Confirm the club exists, the requester is an active member, and the request leaves the active inbox.
  9. Open the welcome email and follow the magic link to the new club member home.
  
  ## Risks / Follow-ups
  
  - This iteration reduces abuse from public self-serve signup but does not add automated spam controls; CAPTCHA/rate limits/spam scoring may still be useful later.
  - Converted/rejected request history will probably become useful once there is real traffic.
  - Staff may later need request search, filters, duplicate detection, and richer qualification fields.
  - Staff may later need to invite additional club organisers during conversion.
  - Club branding, billing/trials, and plan setup remain separate onboarding follow-ups.
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/022-request-to-club-onboarding/plan.md'
PATH="$PWD/bin:$PATH" dev iteration check-predecessors "$PLAN_PATH"
PATH="$PWD/bin:$PATH" dev iteration check-clear "$PLAN_PATH" --allow-same-iteration`
- Output:
  ```
  (6 lines omitted)
  ✓ Evaluating shell in 1.27ms (cached)
  ✓ Configuring shell in 8.19ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 357µs (cached)
  ✓ Loading tasks in 2.22ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.8ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.6ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 93.3µs (no command)
  ✓ Running tasks in 24.7ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:1] [ds:8:1:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  • Validating lock
  ✓ Validating lock in 21.3ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 2.35ms
  • Evaluating shell
  ✓ Evaluating shell in 1.15ms (cached)
  ✓ Configuring shell in 6.19ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 384µs (cached)
  ✓ Loading tasks in 2.18ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.5ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 12.2ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 108µs (no command)
  ✓ Running tasks in 23.6ms
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
  (192 lines omitted)
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
PLAN_PATH='docs/iterations/022-request-to-club-onboarding/plan.md'
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
  HEAD: 49a1b0c fabro(01KTD3TRN7HAXJPZM7STW1E393): preflight_sandbox (succeeded)
  Todo: docs/iterations/022-request-to-club-onboarding/todo.md is absent; sync_task_list will create it from plan.md.
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/022-request-to-club-onboarding/plan.md'
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
  Created docs/iterations/022-request-to-club-onboarding/todo.md from docs/iterations/022-request-to-club-onboarding/plan.md
  PLAN_PATH=docs/iterations/022-request-to-club-onboarding/plan.md
  TODO_PATH=docs/iterations/022-request-to-club-onboarding/todo.md
  # Implementation TODO
  
  - [ ] 001 Inspect current public `/get-started`, homepage links, layouts, auth/current identity assigns, staff navigation, staff club creation LiveView, slug helper modules, membership/person creation APIs, and auth email/token APIs.
  - [ ] 002 Extract reusable club creation/slug form logic if needed so request conversion and `/admin/clubs` share the same slug generation, validation, and availability behaviour. Prefer reuse over duplication.
  - [ ] 003 Design the request persistence model:
  - [ ] 004 Add migration/schema/context functions for creating, listing active, rejecting, and converting requests.
  - [ ] 005 Implement signed-out `/get-started` form with required-field and email validation.
  - [ ] 006 Implement signed-in `/get-started` behaviour using the current person’s known name/email as read-only request details.
  - [ ] 007 Send a new-request notification email to `hello@memba.io` after successful request creation.
  - [ ] 008 Add staff `/admin/requests` route and LiveView under existing staff authentication.
  - [ ] 009 Add Requests to the staff navigation without regressing existing Clubs, People, Messages, and Deliveries navigation.
  - [ ] 010 Build the active requests inbox with clear request details and actions for reject/convert.
  - [ ] 011 Implement rejection with required internal notes and no requester email.
  - [ ] 012 Implement conversion preparation with generated/editable slug using the same rules as staff club creation.
  - [ ] 013 Implement conversion transactionally where practical: create club, create/reuse person, create active membership, mark request converted, and send/wrap welcome email behaviour consistently.
  - [ ] 014 Implement welcome email generation with a magic sign-in token and post-auth destination for the new club member home.
  - [ ] 015 Add or update tests for public form validation/submission, signed-in prepopulation, notification email, staff authorization, active inbox, rejection, conversion, existing-person reuse, slug validation, welcome email, and preservation of existing club creation/slug behaviour.
  - [ ] 016 Add acceptance step support for `request_account.feature` and remove `@wip` once the scenarios pass.
  - [ ] 017 Run targeted tests while developing, then run `dev check`.
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 4.6k in / 354 out
- Response:
  > {"cmd": "TODO_PATH='docs/iterations/022-request-to-club-onboarding/todo.md'\nif [ ! -r \"$TODO_PATH\" ]; then\n  echo \"MISSING_OR_UNREADABLE $TODO_PATH\"\nelif [ ! -s \"$TODO_PATH\" ]; then\n  echo \"EMPTY $TODO_PATH\"\nelse\n  unchecked=$(grep -nE '^[[:space:]]*- \\[ \\] ' \"$TODO_PATH\" || true)\n  if [ -n \"$unchecked\" ]; then\n    echo \"UNCHECKED\"\n    printf '%s\\n' \"$unchecked\"\n  else\n    echo \"COMPLETE\"\n  fi\nfi"}{"context_updates":{"task_list_complete":false,"task_list_needs_human":false}}

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 1.3m in / 6.5k out
- Response:
  > 1. **Selected todo line**
  >    - `001 Inspect current public /get-started, homepage links, layouts, auth/current identity assigns, staff navigation, staff club creation LiveView, slug helper modules, membership/person creation APIs, and auth email/token APIs.`
  > 
  > 2. **Changes made**
  >    - Inspection-only task; no app code/config/test changes.
  >    - Checked off the completed task in `docs/iterations/022-request-to-club-onboarding/todo.md`.
  > 
  >    Key inspection findings:
  >    - `/get-started` is currently a static `PageController.get_started/2` page with a mailto link in `page_html/get_started.html.heex`.
  >    - Public homepage and `Layouts.app` already link to `/get-started`.
  >    - Current identity assigns include email, staff flag, and active clubs, but not person name; signed-in requester name should be derived via `Membership.get_person_by_email/1`.
  >    - Staff routes use `:staff_browser` and `live_session :memba_staff` with existing staff auth/onboarding gates.
  >    - Staff nav is centralized in `Layouts.admin/1`; active values and nav tests currently cover Clubs, People, Messages, Deliveries.
  >    - Club creation slug behavior is split between `Admin.ClubsLive.Index`, `Admin.ClubsLive.Show`, `Memba.Membership.Slug`, and `Membership.create_club/update_club`; task 002 should extract/reuse this to avoid divergence.
  >    - Membership APIs already support `create_club`, `create_person`, `get_person_by_email`, and `add_member`, all with caller-generated IDs and optional `consistency: :strong`.
  >    - Auth token APIs distinguish `request_sign_in_link/2` eligibility from unrestricted `create_sign_in_token/2`; welcome email likely needs `create_sign_in_token/2`.
  >    - Auth callback currently uses session `return_to`; welcome-link destination to club home will need a deliberate mechanism.
  >    - `acceptance-tests/features/request_account.feature` already exists and remains `@wip`.
  > 
  > 3. **Focused validation**
  >    - Ran/inspected:
  >      - `git log --oneline --decorate -20`
  >      - `git status --short`
  >      - Read the iteration plan and todo.
  >      - Inspected relevant Phoenix/controller/LiveView/context/auth/test files.
  >      - Confirmed final status only shows the todo check-off.
  >    - Did **not** run `dev check` because this was a docs/todo-only inspection task with no code/config/app-behaviour changes, matching project workflow guidance.
  > 
  > 4. **Exact todo check-off made**
  >    - Changed:
  >      - `- [ ] 001 Inspect current public ...`
  >    - To:
  >      - `- [x] 001 Inspect current public ...`
  > 
  > 5. **Todo splits/additions/reordering**
  >    - None.
  > 
  > 6. **ADR conformance evidence**
  >    - No ADR was explicitly referenced by the plan.
  >    - Inspected relevant accepted ADRs for this task:
  >      - ADR 0001 Phoenix core app.
  >      - ADR 0002 Commanded/event sourcing default.
  >      - ADR 0007 separate Membership/Messaging contexts.
  >      - ADR 0011 caller-generated UUID aggregate IDs.
  >      - ADR 0013 PhoenixTest for feature-style web tests.
  >      - ADR 0015 LiveView default for member app pages.
  >      - ADR 0019 club subdomain URLs via `lvh.me`.
  >      - ADR 0021/0022 read-model change/projection barrier constraints.
  >    - Inspection findings align with these constraints; no implementation changes were made.

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/022-request-to-club-onboarding/plan.md'
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
  e9346ba
  e9346ba fabro(01KTD3TRN7HAXJPZM7STW1E393): implement_next_task (succeeded)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/022-request-to-club-onboarding/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Current context
| Key | Value |
|-----|-------|
| task_list_complete | false |
| task_list_needs_human | false |


Validate the just-completed iteration task for `docs/iterations/022-request-to-club-onboarding/plan.md`.

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