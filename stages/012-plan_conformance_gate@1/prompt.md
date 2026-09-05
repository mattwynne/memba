Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01M1RA4HRSTJZNXNDGSGVY4XY8
Pipeline progress: 10 of 36 stages completed

## Stage: verify_source_head
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-implementation/scripts/verify_source_head.sh 'a01d2be3fff783e24521f8435bc95053d2217da3'`
- Output:
  ```
  Expected source HEAD: a01d2be3fff783e24521f8435bc95053d2217da3
  Actual source HEAD:   a01d2be3fff783e24521f8435bc95053d2217da3
  Source directory:     /repos/mattwynne/memba
  Source checkout matches the expected implementation commit.
  ```

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/057-admin-group-email-conversations/plan.md'
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
  (195 lines omitted)
     Everyone acceptance regressions passing.
  10. Implement the accepted scenarios' domain and browser support, removing or narrowing
      `@todo-domain` / `@todo-ui` only when each runner can execute the relevant scenario.
      Run `dev check`.
  
  ## Open Technical Decisions
  
  None expected to block implementation.
  
  - The email slug is an immutable routing key, distinct from a group display name and
    from the deterministic internal system-group identity.
  - The initial policy is a fixed named policy boundary, not a persisted group setting.
  - Existing email idempotency remains keyed by provider/message identity; the new group
    lookup must not turn provider retries into duplicate conversations or deliveries.
  
  ## New Capability
  
  Clubs can use an Admin email address for private Admin conversations. Any active member
  can contact the Admin group by email, while only its active members receive and reply to
  the conversation. The domain and read APIs are ready for a later UI to list a selected
  group's conversations without changing the underlying access model.
  
  ## Validation Plan
  
  - Before implementation, run the acceptance configuration tests to confirm the new
    `@todo-domain` / `@todo-ui` scenarios are excluded from their respective default
    runners.
  - During implementation, run focused Membership tests for slug persistence, uniqueness,
    backfill, and replay; focused Messaging tests for group destination resolution,
    recipient delivery, sender policy, access grants, and reply authorisation; and the
    existing inbound-email/reply regressions.
  - Exercise realistic inbound payloads for Admin messages from an active non-Admin,
    active Admin, inactive sender, other-club sender, and duplicate provider message.
  - Confirm group-ID-based Messaging queries return only the requested group's accessible
    conversations and that existing web surfaces request Everyone.
  - After step support is complete, remove/narrow runner-debt tags and run the affected
    Cucumber features.
  - Run `dev check` on the committed implementation state.
  
  ## Risks / Follow-ups
  
  - Iteration 056 is a hard dependency and must be merged before this plan can start.
  - The current Groups vision says non-members cannot post to group addresses. Update it
    before delivery to reflect the confirmed `club_members_only` new-conversation rule.
  - An email slug becomes externally visible and should be treated as stable once used;
    group rename/slug-change policy is deferred.
  - The email sender who is also an Admin receives a redundant root-message copy. This is
    deliberately deferred in the related problem note.
  - The current app must not accidentally expose Admin conversations while its views stay
    Everyone-only; the generic group-ID query is preparation, not UI exposure.
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/057-admin-group-email-conversations/plan.md'
PATH="$PWD/bin:$PATH" dev iteration check-predecessors "$PLAN_PATH"
PATH="$PWD/bin:$PATH" dev iteration check-clear "$PLAN_PATH" --allow-same-iteration`
- Output:
  ```
  (6 lines omitted)
  ✓ Evaluating shell in 1.16ms (cached)
  ✓ Configuring shell in 6.07ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 242µs (cached)
  ✓ Loading tasks in 1.35ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 9.69ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.1ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 78.1µs (no command)
  ✓ Running tasks in 21.8ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:2] [ds:8:2:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  • Validating lock
  ✓ Validating lock in 22.5ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 1.86ms
  • Evaluating shell
  ✓ Evaluating shell in 945µs (cached)
  ✓ Configuring shell in 5.21ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 192µs (cached)
  ✓ Loading tasks in 1.62ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.0ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 10.8ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 19.6µs (no command)
  ✓ Running tasks in 21.4ms
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
PLAN_PATH='docs/iterations/057-admin-group-email-conversations/plan.md'
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
  HEAD: ee45740 fabro(01M1RA4HRSTJZNXNDGSGVY4XY8): preflight_sandbox (succeeded)
  Todo: docs/iterations/057-admin-group-email-conversations/todo.md (18 checked, 0 unchecked)
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/057-admin-group-email-conversations/plan.md'
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
  Using existing docs/iterations/057-admin-group-email-conversations/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/057-admin-group-email-conversations/plan.md
  TODO_PATH=docs/iterations/057-admin-group-email-conversations/todo.md
  # Implementation TODO
  
  - [x] 001 Extend the Membership group write model, events, state, and projections with an immutable normalised email slug, unique per club.
  - [x] 002 Evolve new-group creation to carry it, and append idempotent email-slug facts for existing Everyone and Admin groups without rewriting historic group events.
  - [x] 003 Make new-club system-group creation and the release backfill assign `everyone` and `admin` consistently. Expose a public Membership lookup by club and group email slug; Messaging must not query Membership schemas directly.
  - [x] 004 Generalise inbound destination resolution from the hard-coded `everyone` local part to a group-slug lookup on the existing `<club-slug>.clubs.memba.io` host.
  - [x] 005 Keep unsupported routes and unknown club/group slugs on the existing rejection path.
  - [x] 006 Introduce a named fixed group-email posting policy in Messaging.
  - [x] 007 For a new inbound conversation it authorises the resolved sender by active membership of the destination club, not membership of the addressed group.
  - [x] 008 Carry the resolved audience group through the existing inbound root-message command.
  - [x] 009 Resolve deliveries through active group members and emit the group write-access grant.
  - [x] 010 If the sender is not a recipient, do not create a delivery, acknowledgement, access, or follower relationship for them.
  - [x] 011 Reuse the group-write reply authorisation delivered by 056 for Admin conversations.
  - [x] 012 Keep header routing and follower-only reply delivery unchanged; cover direct/forged non-member reply attempts with focused domain tests rather than a new stakeholder scenario.
  - [x] 013 Add public Messaging queries that list conversations and read a conversation through a supplied group ID and its access grant.
  - [x] 014 Refactor current web query callers to pass the Everyone group, preserving the existing visual UI and ensuring Admin conversations remain absent until the later group display iteration.
  - [x] 015 Add aggregate, policy, projection/replay, release-backfill, inbound-route, authorisation, recipient-delivery, sender-non-following, and reply-authorisation tests.
  - [x] 016 Cover slug uniqueness and safe re-runs of the slug backfill.
  - [x] 017 Keep existing Everyone acceptance regressions passing.
  - [x] 018 Implement the accepted scenarios' domain and browser support, removing or narrowing `@todo-domain` / `@todo-ui` only when each runner can execute the relevant scenario. Run `dev check`.
  ```

## Stage: todo_readable
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/057-admin-group-email-conversations/plan.md'
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
  Todo file is present and readable: docs/iterations/057-admin-group-email-conversations/todo.md
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/057-admin-group-email-conversations/plan.md'
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
  COMPLETE: no unchecked tasks remain in docs/iterations/057-admin-group-email-conversations/todo.md
  ```

## Stage: dev_check
- Status: succeeded
- Handler: command
- Script: `PATH="$PWD/bin:$PATH" dev ci`
- Output:
  ```
  (2248 lines omitted)
  [acceptance 2026-09-05T08:25:09.003Z] scenario finish: Staff create a club with the suggested slug status=PASSED duration=1960ms
  
    Rule: Staff-edited slugs must already be address-safe
  
      Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-09-05T08:25:09.004Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-09-05T08:25:09.036Z] scenario reset app state: Staff enter an invalid slug
        Given Pat is signed in as Memba staff
  [acceptance 2026-09-05T08:25:10.087Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1009ms
        Given Kootenay Mountaineering Club is a club
        When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
        Then Memba should reject the club slug as invalid
        And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-09-05T08:25:11.065Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-09-05T08:25:11.071Z] scenario finish: Staff enter an invalid slug status=PASSED duration=2067ms
  
    Rule: A slug can belong to only one club
  
      Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-09-05T08:25:11.071Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-09-05T08:25:11.105Z] scenario reset app state: Staff enter a slug that another club already uses
        Given Pat is signed in as Memba staff
        Given Kootenay Mountaineering Club has the slug "kmc"
        And Nelson Paddling Club is a club
        When Pat tries to change Nelson Paddling Club's slug to "kmc"
        Then Memba should reject the club slug as already taken
        And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-09-05T08:25:13.446Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-09-05T08:25:13.450Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=2379ms
  
    Rule: A club slug routes public visitors to that club's public page
  
      @not-domain
      Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-09-05T08:25:13.451Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-09-05T08:25:13.494Z] scenario reset app state: Robin opens an unknown club subdomain
        Given Pat is signed in as Memba staff
  [acceptance 2026-09-05T08:25:14.540Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1004ms
        When Robin opens "unknown.clubs.memba.io"
        Then Robin should see a not found page
  [acceptance 2026-09-05T08:25:14.605Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-09-05T08:25:14.611Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1160ms
  
  [acceptance 2026-09-05T08:25:14.611Z] AfterAll: closing shared browser
  [acceptance 2026-09-05T08:25:14.643Z] AfterAll: closed shared browser
  [acceptance 2026-09-05T08:25:14.643Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-09-05T08:25:14.644Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  122 scenarios (122 passed)
  877 steps (877 passed)
  5m43.053s (executing steps: 5m32.984s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/057-admin-group-email-conversations/plan.md'
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
  (9528 lines omitted)
    end
  end
  
  === web/test/support/messaging_fixtures.ex ===
  defmodule Memba.MessagingFixtures do
    @moduledoc """
    Shared fixtures for member-facing Messaging projection tests.
  
    Member web surfaces read conversations through group access grants, so these
    fixtures create the message projection and its root-conversation grant
    together.
    """
  
    alias Memba.Membership.SystemGroups
    alias Memba.Messaging.Projections.ConversationGroupAccess
    alias Memba.Messaging.Projections.Message
    alias Memba.Repo
  
    def insert_group_accessible_message!(attrs) when is_list(attrs) do
      message_id = Keyword.get_lazy(attrs, :message_id, fn -> Memba.ID.generate(:message) end)
      club_id = Keyword.fetch!(attrs, :club_id)
  
      message =
        Repo.insert!(%Message{
          message_id: message_id,
          club_id: club_id,
          sender_id: Keyword.fetch!(attrs, :sender_id),
          conversation_id: Keyword.get(attrs, :conversation_id, message_id),
          reply_to_message_id: Keyword.get(attrs, :reply_to_message_id),
          subject: Keyword.fetch!(attrs, :subject),
          body: Keyword.get(attrs, :body, "Message body"),
          inserted_at: Keyword.get(attrs, :inserted_at),
          updated_at: Keyword.get(attrs, :updated_at, Keyword.get(attrs, :inserted_at))
        })
  
      if message.message_id == message.conversation_id do
        Repo.insert!(%ConversationGroupAccess{
          conversation_id: message.message_id,
          club_id: club_id,
          group_id:
            Keyword.get_lazy(attrs, :audience_group_id, fn ->
              SystemGroups.everyone_group_id(club_id)
            end),
          access_level: Keyword.get(attrs, :access_level, "write")
        })
      end
  
      message
    end
  end
  ```


You are the plan conformance gate for the iteration implementation at docs/iterations/057-admin-group-email-conversations/plan.md.

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