Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01KVN2FJS9ZMT166JRRS6TKCT2
Pipeline progress: 14 of 33 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md'
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
  (87 lines omitted)
  ## Implementation Plan
  
  1. Add follow/unfollow command(s)/event(s) and a per-(member, conversation) follow read model; auto-follow the sender on conversation creation and a replier on reply (from the 039 events).
  2. Rewire the reply delivery introduced in 039 from "all current members" to "current club-member followers of the conversation," excluding the author and excluding former/non-current members even when a historical follow record exists.
  3. Add the in-app follow/unfollow control + copy on the message-detail surface, reflecting the viewer's state and preventing non-current members from newly following.
  4. Add a one-click signed stop-following (unsubscribe) link to the reply email, consistent with in-app unfollow; ensure unfollow halts future reply emails.
  5. Revise `club_message_replies.feature` per Allowed acceptance feature changes; make the `@iteration-040` scenarios executable (domain then browser/email), removing/narrowing `@todo-*`.
  6. Run `dev check`.
  
  ## Email Stop-Follow Behaviour
  
  The reply-email footer contains a one-click signed stop-following link. This is an unsubscribe-style action and does **not** require sign-in.
  
  Required behaviour:
  
  - The token is opaque/signed and scoped to the club, conversation, and intended recipient/member-person; it must not be usable to change any other person's or conversation's follow state.
  - The product behaviour is long-lived/non-expiring so old reply emails remain useful; if the chosen implementation helper forces an expiry, use the longest practical expiry and treat expired tokens like invalid tokens.
  - A valid link unfollows only that recipient from that conversation and then shows a simple success page/state that offers a path back to the conversation if the viewer can sign in.
  - Reusing a valid link after the recipient is already unfollowed is idempotent and shows the same safe success.
  - Invalid, tampered, expired, or wrong-scope tokens change nothing and show a generic failure that does not reveal whether the club, conversation, or member exists.
  - A valid email stop-follow link may clear a historical follow state for a former/non-current member, because it only reduces notifications. Former/non-current members still cannot newly follow and are never eligible reply-email recipients.
  
  ## Open Technical Decisions
  
  None that require product decisions before implementation.
  
  Implementation choices left to the implementer, with constraints:
  
  - Follow storage may be a dedicated follow projection or a conversation-membership read-model field, provided "is viewer following?" and "who are the current club-member followers?" are cheap and deterministic.
  - The signed stop-follow token may reuse existing token helpers or use a dedicated token module, provided it satisfies the behaviour above.
  - Reply delivery may keep reusing 039's delivery path (now filtered to current club-member followers) or factor a shared "deliver to recipients" helper; note any interaction with iteration 038's email-handoff boundary if landed.
  
  ## New Capability
  
  Replies reach exactly the people who want them: the sender and repliers automatically, plus anyone who chooses to follow — and no one else — removing the interim reply-all and realising Model C, with unfollow always available.
  
  ## Validation Plan
  
  - Domain/integration tests: auto-follow (sender + replier), opt-in default, follow/unfollow, idempotent repeated follow/unfollow, current-member-only in-app permissions, reply fan-out to current club-member followers only, former/non-current followers excluded, replier excluded, unfollow stops delivery.
  - Email tests: only current club-member followers emailed; stop-following link works for the intended recipient/conversation; reused already-unfollowed links are safe; invalid/tampered/expired/wrong-scope links change nothing; footer, `<club> via Memba`, conversation context preserved.
  - Acceptance: the `@iteration-040` scenarios green; 039 conversation/reply/membership scenarios green.
  - Full `dev check`.
  
  ## Risks / Follow-ups
  
  - **This slice is what removes the 039 reply-all noise** — sequence it close behind 039 so production does not sit long on reply-all.
  - Per-reply emails could be noisy on busy conversations; digest/batching is a follow-up, not this slice.
  - Depends on 039's conversation model exposing participants and supporting a cheap follower set.
  - If iteration 038 (email-handoff boundary) has landed, route reply emails through that boundary.
  - Sits behind 039 in the queue; planning ahead.
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md'
PATH="$PWD/bin:$PATH" dev iteration check-predecessors "$PLAN_PATH"
PATH="$PWD/bin:$PATH" dev iteration check-clear "$PLAN_PATH" --allow-same-iteration`
- Output:
  ```
  (6 lines omitted)
  ✓ Evaluating shell in 1.01ms (cached)
  ✓ Configuring shell in 6.73ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 179µs (cached)
  ✓ Loading tasks in 1.11ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.3ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.2ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 43.3µs (no command)
  ✓ Running tasks in 22.0ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:2] [ds:8:2:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  • Validating lock
  ✓ Validating lock in 20.0ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 2.18ms
  • Evaluating shell
  ✓ Evaluating shell in 202µs (cached)
  ✓ Configuring shell in 5.58ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 177µs (cached)
  ✓ Loading tasks in 1.54ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.1ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.2ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 4.08µs (no command)
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
  (266 lines omitted)
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
PLAN_PATH='docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md'
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
  HEAD: 94ff280 fabro(01KVN2FJS9ZMT166JRRS6TKCT2): preflight_sandbox (succeeded)
  Todo: docs/iterations/040-thread-follow-and-reply-notification-emails/todo.md is absent; sync_task_list will create it from plan.md.
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md'
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
  Using existing docs/iterations/040-thread-follow-and-reply-notification-emails/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md
  TODO_PATH=docs/iterations/040-thread-follow-and-reply-notification-emails/todo.md
  # Implementation TODO
  
  - [x] 001 Add follow/unfollow command(s)/event(s) and a per-(member, conversation) follow read model; auto-follow the sender on conversation creation and a replier on reply (from the 039 events).
  - [ ] 002 Rewire the reply delivery introduced in 039 from "all current members" to "current club-member followers of the conversation," excluding the author and excluding former/non-current members even when a historical follow record exists.
  - [ ] 003 Add the in-app follow/unfollow control + copy on the message-detail surface, reflecting the viewer's state and preventing non-current members from newly following.
  - [ ] 004 Add a one-click signed stop-following (unsubscribe) link to the reply email, consistent with in-app unfollow; ensure unfollow halts future reply emails.
  - [ ] 005 Revise `club_message_replies.feature` per Allowed acceptance feature changes; make the `@iteration-040` scenarios executable (domain then browser/email), removing/narrowing `@todo-*`.
  - [ ] 006 Run `dev check`.
  ```

## Stage: todo_readable
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md'
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
  Todo file is present and readable: docs/iterations/040-thread-follow-and-reply-notification-emails/todo.md
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md'
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
  UNCHECKED tasks remain in docs/iterations/040-thread-follow-and-reply-notification-emails/todo.md
  4:- [ ] 002 Rewire the reply delivery introduced in 039 from "all current members" to "current club-member followers of the conversation," excluding the author and excluding former/non-current members even when a historical follow record exists.
  5:- [ ] 003 Add the in-app follow/unfollow control + copy on the message-detail surface, reflecting the viewer's state and preventing non-current members from newly following.
  6:- [ ] 004 Add a one-click signed stop-following (unsubscribe) link to the reply email, consistent with in-app unfollow; ensure unfollow halts future reply emails.
  7:- [ ] 005 Revise `club_message_replies.feature` per Allowed acceptance feature changes; make the `@iteration-040` scenarios executable (domain then browser/email), removing/narrowing `@todo-*`.
  8:- [ ] 006 Run `dev check`.
  ```

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 657.8k in / 21.3k out
- Response:
  > Implemented the first unchecked iteration task.
  > 
  > 1. **Selected todo line**
  >    - `001 Add follow/unfollow command(s)/event(s) and a per-(member, conversation) follow read model; auto-follow the sender on conversation creation and a replier on reply (from the 039 events).`
  > 
  > 2. **Changes made**
  >    - Added `FollowConversation` / `UnfollowConversation` commands.
  >    - Added `ConversationFollowed` / `ConversationUnfollowed` events.
  >    - Added `Memba.Messaging.ConversationFollowers` aggregate with idempotent follow/unfollow behavior.
  >    - Added `messaging_conversation_follows` projection schema, migration, and strong projector.
  >    - Projector auto-follows `MessageSent.sender_id` for both root messages and replies.
  >    - Added public Messaging APIs:
  >      - `follow_conversation/2`
  >      - `unfollow_conversation/2`
  >      - `get_conversation_follow/2`
  >      - `following_conversation?/2`
  >      - `list_conversation_followers/1`
  >    - Registered new commands in the Messaging router.
  >    - Supervised the new projector and included it in event-sourced test/reset support.
  >    - Added `:conversation_follow` typed ID prefix.
  >    - Added/updated tests for aggregate behavior, projection behavior, auto-follow, public API contract, migration contract, and app wiring.
  > 
  > 3. **Validation run**
  >    - `devenv shell -- bin/mix format --check-formatted ...` — passed.
  >    - `devenv shell -- bin/mix test test/memba/messaging/no_crud_spike_test.exs test/memba/messaging/conversation_followers_test.exs test/memba/messaging/conversation_follow_projection_test.exs test/memba/messaging/app_test.exs` — passed, 17 tests.
  >    - `PATH="$PWD/bin:$PATH" dev check --quick` — passed on the final worktree state, 859 tests, 0 failures.
  > 
  > 4. **Todo check-off made**
  >    - Changed exactly:
  >      - `- [ ] 001 ...`
  >    - To:
  >      - `- [x] 001 ...`
  > 
  > 5. **Todo splits/additions/reordering**
  >    - None.
  > 
  > 6. **ADR conformance evidence**
  >    - The plan did not explicitly reference any ADRs, and no `docs/adr/*.md` files were present to inspect.
  >    - Implementation follows the existing Commanded/CQRS style in the Messaging bounded context: commands routed through `Memba.Messaging.Router`, domain events with `Jason.Encoder`, an aggregate for write behavior, and a Commanded Ecto projection for read state.

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md'
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
  714b444
  714b444 fabro(01KVN2FJS9ZMT166JRRS6TKCT2): implement_next_task (succeeded)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/040-thread-follow-and-reply-notification-emails/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 209.9k in / 3.8k out
- Response:
  > ### Decision
  > **VALID**
  > 
  > ### Evidence
  > - Completed todo/check-off evidence found:
  >   - Live worktree is clean.
  >   - Recent checkpoint `714b444 fabro(...): implement_next_task (succeeded)` changed exactly one ordinary todo line:
  >     - `001 Add follow/unfollow command(s)/event(s)...` from `- [ ]` to `- [x]`.
  >   - Current `todo.md` has task 001 checked and tasks 002–006 still unchecked, so the first unchecked task was selected and no plan-required work was removed.
  > - Implementation artifacts found:
  >   - Added follow/unfollow commands, events, aggregate, projection schema/projector, migration, typed ID prefix, router wiring, app supervision, public Messaging APIs, and reset/support wiring.
  >   - Auto-follow is projected from `MessageSent` for root messages and replies.
  >   - No acceptance feature files were edited in this task.
  > - Tests run/results found:
  >   - Focused validation run passed:
  >     - `devenv shell -- bin/mix test test/memba/messaging/no_crud_spike_test.exs test/memba/messaging/conversation_followers_test.exs test/memba/messaging/conversation_follow_projection_test.exs test/memba/messaging/app_test.exs`
  >     - Result: `17 tests, 0 failures`.
  >   - Implementation summary also reports formatting and `dev check --quick` passed.
  > - ADR/plan conformance notes:
  >   - No `docs/adr/*.md` files found.
  >   - Work stays within task 001 scope and preserves later plan scope for reply-delivery rewiring, UI controls, email stop-follow link, acceptance feature changes, and final `dev check`.
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
PLAN_PATH='docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md'
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
  Using existing docs/iterations/040-thread-follow-and-reply-notification-emails/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md
  TODO_PATH=docs/iterations/040-thread-follow-and-reply-notification-emails/todo.md
  # Implementation TODO
  
  - [x] 001 Add follow/unfollow command(s)/event(s) and a per-(member, conversation) follow read model; auto-follow the sender on conversation creation and a replier on reply (from the 039 events).
  - [ ] 002 Rewire the reply delivery introduced in 039 from "all current members" to "current club-member followers of the conversation," excluding the author and excluding former/non-current members even when a historical follow record exists.
  - [ ] 003 Add the in-app follow/unfollow control + copy on the message-detail surface, reflecting the viewer's state and preventing non-current members from newly following.
  - [ ] 004 Add a one-click signed stop-following (unsubscribe) link to the reply email, consistent with in-app unfollow; ensure unfollow halts future reply emails.
  - [ ] 005 Revise `club_message_replies.feature` per Allowed acceptance feature changes; make the `@iteration-040` scenarios executable (domain then browser/email), removing/narrowing `@todo-*`.
  - [ ] 006 Run `dev check`.
  ```

## Stage: todo_readable
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md'
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
  Todo file is present and readable: docs/iterations/040-thread-follow-and-reply-notification-emails/todo.md
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md'
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
  UNCHECKED tasks remain in docs/iterations/040-thread-follow-and-reply-notification-emails/todo.md
  4:- [ ] 002 Rewire the reply delivery introduced in 039 from "all current members" to "current club-member followers of the conversation," excluding the author and excluding former/non-current members even when a historical follow record exists.
  5:- [ ] 003 Add the in-app follow/unfollow control + copy on the message-detail surface, reflecting the viewer's state and preventing non-current members from newly following.
  6:- [ ] 004 Add a one-click signed stop-following (unsubscribe) link to the reply email, consistent with in-app unfollow; ensure unfollow halts future reply emails.
  7:- [ ] 005 Revise `club_message_replies.feature` per Allowed acceptance feature changes; make the `@iteration-040` scenarios executable (domain then browser/email), removing/narrowing `@todo-*`.
  8:- [ ] 006 Run `dev check`.
  ```

## Current context
| Key | Value |
|-----|-------|
| task_retry_available | false |
| task_valid | true |


Implement the next unchecked iteration task from `todo.md`.

Plan path: `docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md`.
Todo path is derived from the plan path by replacing `/plan.md` with `/todo.md`.

## Ownership rules

- Read the plan and `todo.md` before editing.
- Pick the first unchecked Markdown task line in `todo.md` (`- [ ] ...`). That task is yours from selection through check-off.
- Treat earlier checked todo lines as durable completed work. Do not redo them.
- Inspect recent Fabro checkpoint commits with `git log --oneline --decorate -20` and use their subjects/bodies/diffs as context for what previous runs already completed.
- Inspect `git status --short` before editing. The resume gate should normally guarantee a clean tree; if uncommitted changes are present, stop for human input unless they are clearly the selected task's in-progress work and you can safely continue it to completion without overwriting it.
- Never silently overwrite, discard, or duplicate uncommitted work for an unchecked task.
- Implement exactly the selected task only. Do not opportunistically implement later tasks unless the selected task cannot be completed without splitting/reordering the todo list first.
- When the implementation and focused validation are complete, check off the same task line you implemented by changing that one line from `- [ ]` to `- [x]`.
- Do not check off any other ordinary todo line.
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
- In the Fabro sandbox, avoid wrapping focused commands in `devenv shell -- ...` unless there is a specific reason. The sandbox image and project wrappers are already prepared for the project; prefer `PATH="$PWD/bin:$PATH" bin/mix ...` or `PATH="$PWD/bin:$PATH" dev ...` so command execution stays consistent with the workflow environment.
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