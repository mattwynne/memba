Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01KWY3ZH6TQWHAQHX5X0EPH1CK
Pipeline progress: 21 of 33 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  (95 lines omitted)
  1. Add a member-scoped route `live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show`
     in `web/lib/memba_web/router.ex`, in the same authenticated member scope as the message Show route.
  2. Create `MemberMessageDeliveryLive.Show` that loads the target message and its receipt model via
     `Messaging.list_member_email_deliverys/1 |> MemberEmailDeliveryPresentation.present_receipts/1`,
     scoped to the member's active clubs (reuse the `member_message_detail` load pattern and authz).
  3. Build the delivery page template per `delivery-details.html`: header (subject / sender /
     `inserted_at`), summary bar + legend, grouped recipients (problems expanded, delivered collapsed).
  4. Show each recipient's bounce reason for the "didn't go through" group, from the existing receipt
     presentation fields; keep the delivered group collapsed with a count.
  5. Port the delivery-details CSS (`delivery-summary`, `delivery-bar`, `delivery-legend`,
     `delivery-group`, `recipient`, `deliv-*` tints) from `design-system/` into
     `web/assets/css/app.css`, names 1:1 with the mirror.
  6. Add a **Back to conversation** link on the delivery page returning to the message's conversation.
  7. Add a per-message **⋮ menu** to `conversation_entry_card` (`page_html.ex`) with a Delivery details
     item linking to `/messages/#{message_id}/delivery`.
  8. Remove the inline `#member-receipt-summary` section and the "Members by delivery status" grouped
     section from `message.html.heex`.
  9. Remove the "sent to N members" delivery meta line from the conversation subject header.
  10. Add tests: the delivery route renders the per-recipient breakdown for a message; it enforces the
      same authz as the conversation; the conversation kebab links to it; the conversation no longer
      renders the inline delivery sections.
  11. Run `./bin/dev gallery-walk` and compare the delivery page to `delivery-details.html` and the
      conversation to `member-conversation.html`.
  12. Run `dev check` and confirm it is green (no feature-file changes).
  
  ## Open Technical Decisions
  
  None open. **Route/module: decided —** `MemberMessageDeliveryLive.Show` at
  `/messages/:message_id/delivery`, in the member scope, reusing the conversation loader's receipt
  model and authorization. Replies are messages too, so each reply's ⋮ links to its own delivery page.
  
  ## New Capability
  
  Members reach a focused **Delivery details** page per message, and the conversation page is
  decluttered of inline delivery — matching the refreshed design.
  
  ## Validation Plan
  
  - **Automated:** LiveView/route tests (delivery page renders the breakdown; authz parity; kebab
    link; inline sections removed); `dev check` green.
  - **Visual:** `./bin/dev gallery-walk`; compare to `delivery-details.html` and `member-conversation.html`.
  - **Manual:** open a conversation, use a message's ⋮ → Delivery details, see the breakdown, and
    return via Back to conversation.
  
  ## Risks / Follow-ups
  
  - **Reply receipts:** replies are emailed to followers, so a reply's delivery page shows its own
    (smaller) recipient set; if a message has no receipts yet, the page shows an empty/none state.
  - Depends on 044 (shell); follows 045/046 in the delivery order. Builds directly on the 046 kebab-less
    conversation (046 leaves inline delivery; 047 removes it).
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
PATH="$PWD/bin:$PATH" dev iteration check-predecessors "$PLAN_PATH"
PATH="$PWD/bin:$PATH" dev iteration check-clear "$PLAN_PATH" --allow-same-iteration`
- Output:
  ```
  (6 lines omitted)
  ✓ Evaluating shell in 2.19ms (cached)
  ✓ Configuring shell in 8.79ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 236µs (cached)
  ✓ Loading tasks in 1.46ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.6ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 10.9ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 4.80µs (no command)
  ✓ Running tasks in 22.2ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:2] [ds:8:2:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  • Validating lock
  ✓ Validating lock in 20.7ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 2.07ms
  • Evaluating shell
  ✓ Evaluating shell in 146µs (cached)
  ✓ Configuring shell in 5.59ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 226µs (cached)
  ✓ Loading tasks in 1.74ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.2ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.2ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 3.37µs (no command)
  ✓ Running tasks in 22.5ms
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
  (313 lines omitted)
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
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  HEAD: 463048d fabro(01KWY3ZH6TQWHAQHX5X0EPH1CK): preflight_sandbox (succeeded)
  Todo: docs/iterations/047-conversation-delivery-details/todo.md is absent; sync_task_list will create it from plan.md.
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  Using existing docs/iterations/047-conversation-delivery-details/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/047-conversation-delivery-details/plan.md
  TODO_PATH=docs/iterations/047-conversation-delivery-details/todo.md
  # Implementation TODO
  
  - [x] 001 Add a member-scoped route `live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show` in `web/lib/memba_web/router.ex`, in the same authenticated member scope as the message Show route.
  - [x] 002 Create `MemberMessageDeliveryLive.Show` that loads the target message and its receipt model via `Messaging.list_member_email_deliverys/1 |> MemberEmailDeliveryPresentation.present_receipts/1`, scoped to the member's active clubs (reuse the `member_message_detail` load pattern and authz).
  - [ ] 003 Build the delivery page template per `delivery-details.html`: header (subject / sender / `inserted_at`), summary bar + legend, grouped recipients (problems expanded, delivered collapsed).
  - [ ] 004 Show each recipient's bounce reason for the "didn't go through" group, from the existing receipt presentation fields; keep the delivered group collapsed with a count.
  - [ ] 005 Port the delivery-details CSS (`delivery-summary`, `delivery-bar`, `delivery-legend`, `delivery-group`, `recipient`, `deliv-*` tints) from `design-system/` into `web/assets/css/app.css`, names 1:1 with the mirror.
  - [ ] 006 Add a **Back to conversation** link on the delivery page returning to the message's conversation.
  - [ ] 007 Add a per-message **⋮ menu** to `conversation_entry_card` (`page_html.ex`) with a Delivery details item linking to `/messages/#{message_id}/delivery`.
  - [ ] 008 Remove the inline `#member-receipt-summary` section and the "Members by delivery status" grouped section from `message.html.heex`.
  - [ ] 009 Remove the "sent to N members" delivery meta line from the conversation subject header.
  - [ ] 010 Add tests: the delivery route renders the per-recipient breakdown for a message; it enforces the same authz as the conversation; the conversation kebab links to it; the conversation no longer renders the inline delivery sections.
  - [ ] 011 Run `./bin/dev gallery-walk` and compare the delivery page to `delivery-details.html` and the conversation to `member-conversation.html`.
  - [ ] 012 Run `dev check` and confirm it is green (no feature-file changes).
  ```

## Stage: todo_readable
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  Todo file is present and readable: docs/iterations/047-conversation-delivery-details/todo.md
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  UNCHECKED tasks remain in docs/iterations/047-conversation-delivery-details/todo.md
  5:- [ ] 003 Build the delivery page template per `delivery-details.html`: header (subject / sender / `inserted_at`), summary bar + legend, grouped recipients (problems expanded, delivered collapsed).
  6:- [ ] 004 Show each recipient's bounce reason for the "didn't go through" group, from the existing receipt presentation fields; keep the delivered group collapsed with a count.
  7:- [ ] 005 Port the delivery-details CSS (`delivery-summary`, `delivery-bar`, `delivery-legend`, `delivery-group`, `recipient`, `deliv-*` tints) from `design-system/` into `web/assets/css/app.css`, names 1:1 with the mirror.
  8:- [ ] 006 Add a **Back to conversation** link on the delivery page returning to the message's conversation.
  9:- [ ] 007 Add a per-message **⋮ menu** to `conversation_entry_card` (`page_html.ex`) with a Delivery details item linking to `/messages/#{message_id}/delivery`.
  10:- [ ] 008 Remove the inline `#member-receipt-summary` section and the "Members by delivery status" grouped section from `message.html.heex`.
  11:- [ ] 009 Remove the "sent to N members" delivery meta line from the conversation subject header.
  12:- [ ] 010 Add tests: the delivery route renders the per-recipient breakdown for a message; it enforces the same authz as the conversation; the conversation kebab links to it; the conversation no longer renders the inline delivery sections.
  13:- [ ] 011 Run `./bin/dev gallery-walk` and compare the delivery page to `delivery-details.html` and the conversation to `member-conversation.html`.
  14:- [ ] 012 Run `dev check` and confirm it is green (no feature-file changes).
  ```

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 846.5k in / 11.6k out
- Response:
  > 1. **Selected todo line**
  >    - `002 Create MemberMessageDeliveryLive.Show that loads the target message and its receipt model via Messaging.list_member_email_deliverys/1 |> MemberEmailDeliveryPresentation.present_receipts/1, scoped to the member's active clubs (reuse the member_message_detail load pattern and authz).`
  > 
  > 2. **Changes made for this task only**
  >    - Added `web/lib/memba_web/live/member_message_delivery_live/show.ex`
  >      - Defines `MembaWeb.MemberMessageDeliveryLive.Show`.
  >      - Reuses `MembaWeb.MemberMessageDetail.load/3`, preserving the selected active-club authorization and existing receipt loading/presentation path.
  >      - Handles host-selected `club_id` session params the same way as the conversation LiveView.
  >      - Provides a minimal render scaffold exposing the loaded message and receipt presentation model via stable IDs/data attributes. Full design/template work remains for later todos.
  >    - Added `web/test/memba_web/live/member_message_delivery_live/show_test.exs`
  >      - Proves the route loads the selected club message and presented receipt model.
  >      - Proves messages outside the selected active club are rejected with the same not-found behavior as the conversation authz pattern.
  > 
  > 3. **Validation commands run and results**
  >    - TDD failing check before implementation:
  >      - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
  >      - Failed as expected because `MembaWeb.MemberMessageDeliveryLive.Show` was undefined.
  >    - Focused passing check:
  >      - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
  >      - Passed: `2 tests, 0 failures`.
  >    - Required broad UI/LiveView validation:
  >      - `PATH="$PWD/bin:$PATH" dev check`
  >      - Passed, including acceptance suite: `85 scenarios (85 passed)`, `523 steps (523 passed)`.
  > 
  > 4. **Todo check-off made**
  >    - Changed exactly task `002` from:
  >      - `- [ ] 002 Create MemberMessageDeliveryLive.Show ...`
  >    - To:
  >      - `- [x] 002 Create MemberMessageDeliveryLive.Show ...`
  >    - No other ordinary todo lines were checked off.
  > 
  > 5. **Todo splits/additions/reordering**
  >    - None.
  > 
  > 6. **ADR conformance evidence**
  >    - ADR 0001: Uses the Phoenix/Phoenix LiveView stack for the core app surface.
  >    - ADR 0006: Reuses the existing member-facing delivery presentation model instead of introducing new delivery status vocabulary.
  >    - ADR 0015: Implements the member-facing page as a LiveView.
  >    - ADR 0023: Keeps the delivery detail state URL-addressable at `/messages/:message_id/delivery`.

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  27fe6a0
  27fe6a0 fabro(01KWY3ZH6TQWHAQHX5X0EPH1CK): implement_next_task (succeeded)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/047-conversation-delivery-details/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 174.6k in / 3.2k out
- Response:
  > ### Decision
  > **VALID**
  > 
  > ### Evidence
  > - Completed todo/check-off evidence found:
  >   - Live `todo.md` now has `001` and `002` checked; `003` remains first unchecked.
  >   - `git show 27fe6a0` shows exactly one ordinary todo change: task `002` from `- [ ]` to `- [x]`.
  >   - The parent todo state had `001` checked and `002` unchecked, so `002` was the first unchecked task when implementation began.
  > 
  > - Implementation artifacts found:
  >   - Added `web/lib/memba_web/live/member_message_delivery_live/show.ex`.
  >   - `MemberMessageDeliveryLive.Show` reuses `MembaWeb.MemberMessageDetail.load/3`, which loads the message, enforces selected active-club scoping, and builds the receipt model via:
  >     - `Messaging.list_member_email_deliverys/1`
  >     - `MemberEmailDeliveryPresentation.present_receipts/1`
  >   - The route from prior task is present in the authenticated member LiveView session:
  >     - `live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show`
  > 
  > - Tests run/results found:
  >   - Added `web/test/memba_web/live/member_message_delivery_live/show_test.exs`.
  >   - Tests cover successful loading of the selected club message and receipt presentation model, plus rejection of a message outside the selected active club.
  >   - Validator reran focused test:
  >     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
  >     - Result: `2 tests, 0 failures`.
  >   - Implementation summary also reports `dev check` passed.
  >   - No acceptance `.feature` files were edited.
  > 
  > - ADR/plan conformance notes:
  >   - Conforms to ADR 0001 by using the Phoenix app stack.
  >   - Conforms to ADR 0015 by implementing the member-facing surface as a LiveView.
  >   - Conforms to ADR 0023 by keeping the delivery detail page URL-addressable.
  >   - Conforms to ADR 0006 by reusing the existing member-facing delivery presentation model/status vocabulary.
  >   - Work is within task `002` scope and leaves later visual/template/menu/removal work unchecked for future tasks.
  >   - Working tree is clean; evidence is in recent Fabro checkpoint commit `27fe6a0`.
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
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  Using existing docs/iterations/047-conversation-delivery-details/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/047-conversation-delivery-details/plan.md
  TODO_PATH=docs/iterations/047-conversation-delivery-details/todo.md
  # Implementation TODO
  
  - [x] 001 Add a member-scoped route `live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show` in `web/lib/memba_web/router.ex`, in the same authenticated member scope as the message Show route.
  - [x] 002 Create `MemberMessageDeliveryLive.Show` that loads the target message and its receipt model via `Messaging.list_member_email_deliverys/1 |> MemberEmailDeliveryPresentation.present_receipts/1`, scoped to the member's active clubs (reuse the `member_message_detail` load pattern and authz).
  - [ ] 003 Build the delivery page template per `delivery-details.html`: header (subject / sender / `inserted_at`), summary bar + legend, grouped recipients (problems expanded, delivered collapsed).
  - [ ] 004 Show each recipient's bounce reason for the "didn't go through" group, from the existing receipt presentation fields; keep the delivered group collapsed with a count.
  - [ ] 005 Port the delivery-details CSS (`delivery-summary`, `delivery-bar`, `delivery-legend`, `delivery-group`, `recipient`, `deliv-*` tints) from `design-system/` into `web/assets/css/app.css`, names 1:1 with the mirror.
  - [ ] 006 Add a **Back to conversation** link on the delivery page returning to the message's conversation.
  - [ ] 007 Add a per-message **⋮ menu** to `conversation_entry_card` (`page_html.ex`) with a Delivery details item linking to `/messages/#{message_id}/delivery`.
  - [ ] 008 Remove the inline `#member-receipt-summary` section and the "Members by delivery status" grouped section from `message.html.heex`.
  - [ ] 009 Remove the "sent to N members" delivery meta line from the conversation subject header.
  - [ ] 010 Add tests: the delivery route renders the per-recipient breakdown for a message; it enforces the same authz as the conversation; the conversation kebab links to it; the conversation no longer renders the inline delivery sections.
  - [ ] 011 Run `./bin/dev gallery-walk` and compare the delivery page to `delivery-details.html` and the conversation to `member-conversation.html`.
  - [ ] 012 Run `dev check` and confirm it is green (no feature-file changes).
  ```

## Stage: todo_readable
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  Todo file is present and readable: docs/iterations/047-conversation-delivery-details/todo.md
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  UNCHECKED tasks remain in docs/iterations/047-conversation-delivery-details/todo.md
  5:- [ ] 003 Build the delivery page template per `delivery-details.html`: header (subject / sender / `inserted_at`), summary bar + legend, grouped recipients (problems expanded, delivered collapsed).
  6:- [ ] 004 Show each recipient's bounce reason for the "didn't go through" group, from the existing receipt presentation fields; keep the delivered group collapsed with a count.
  7:- [ ] 005 Port the delivery-details CSS (`delivery-summary`, `delivery-bar`, `delivery-legend`, `delivery-group`, `recipient`, `deliv-*` tints) from `design-system/` into `web/assets/css/app.css`, names 1:1 with the mirror.
  8:- [ ] 006 Add a **Back to conversation** link on the delivery page returning to the message's conversation.
  9:- [ ] 007 Add a per-message **⋮ menu** to `conversation_entry_card` (`page_html.ex`) with a Delivery details item linking to `/messages/#{message_id}/delivery`.
  10:- [ ] 008 Remove the inline `#member-receipt-summary` section and the "Members by delivery status" grouped section from `message.html.heex`.
  11:- [ ] 009 Remove the "sent to N members" delivery meta line from the conversation subject header.
  12:- [ ] 010 Add tests: the delivery route renders the per-recipient breakdown for a message; it enforces the same authz as the conversation; the conversation kebab links to it; the conversation no longer renders the inline delivery sections.
  13:- [ ] 011 Run `./bin/dev gallery-walk` and compare the delivery page to `delivery-details.html` and the conversation to `member-conversation.html`.
  14:- [ ] 012 Run `dev check` and confirm it is green (no feature-file changes).
  ```

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 846.5k in / 11.6k out
- Response:
  > 1. **Selected todo line**
  >    - `002 Create MemberMessageDeliveryLive.Show that loads the target message and its receipt model via Messaging.list_member_email_deliverys/1 |> MemberEmailDeliveryPresentation.present_receipts/1, scoped to the member's active clubs (reuse the member_message_detail load pattern and authz).`
  > 
  > 2. **Changes made for this task only**
  >    - Added `web/lib/memba_web/live/member_message_delivery_live/show.ex`
  >      - Defines `MembaWeb.MemberMessageDeliveryLive.Show`.
  >      - Reuses `MembaWeb.MemberMessageDetail.load/3`, preserving the selected active-club authorization and existing receipt loading/presentation path.
  >      - Handles host-selected `club_id` session params the same way as the conversation LiveView.
  >      - Provides a minimal render scaffold exposing the loaded message and receipt presentation model via stable IDs/data attributes. Full design/template work remains for later todos.
  >    - Added `web/test/memba_web/live/member_message_delivery_live/show_test.exs`
  >      - Proves the route loads the selected club message and presented receipt model.
  >      - Proves messages outside the selected active club are rejected with the same not-found behavior as the conversation authz pattern.
  > 
  > 3. **Validation commands run and results**
  >    - TDD failing check before implementation:
  >      - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
  >      - Failed as expected because `MembaWeb.MemberMessageDeliveryLive.Show` was undefined.
  >    - Focused passing check:
  >      - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
  >      - Passed: `2 tests, 0 failures`.
  >    - Required broad UI/LiveView validation:
  >      - `PATH="$PWD/bin:$PATH" dev check`
  >      - Passed, including acceptance suite: `85 scenarios (85 passed)`, `523 steps (523 passed)`.
  > 
  > 4. **Todo check-off made**
  >    - Changed exactly task `002` from:
  >      - `- [ ] 002 Create MemberMessageDeliveryLive.Show ...`
  >    - To:
  >      - `- [x] 002 Create MemberMessageDeliveryLive.Show ...`
  >    - No other ordinary todo lines were checked off.
  > 
  > 5. **Todo splits/additions/reordering**
  >    - None.
  > 
  > 6. **ADR conformance evidence**
  >    - ADR 0001: Uses the Phoenix/Phoenix LiveView stack for the core app surface.
  >    - ADR 0006: Reuses the existing member-facing delivery presentation model instead of introducing new delivery status vocabulary.
  >    - ADR 0015: Implements the member-facing page as a LiveView.
  >    - ADR 0023: Keeps the delivery detail state URL-addressable at `/messages/:message_id/delivery`.

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  27fe6a0
  27fe6a0 fabro(01KWY3ZH6TQWHAQHX5X0EPH1CK): implement_next_task (succeeded)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/047-conversation-delivery-details/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 174.6k in / 3.2k out
- Response:
  > ### Decision
  > **VALID**
  > 
  > ### Evidence
  > - Completed todo/check-off evidence found:
  >   - Live `todo.md` now has `001` and `002` checked; `003` remains first unchecked.
  >   - `git show 27fe6a0` shows exactly one ordinary todo change: task `002` from `- [ ]` to `- [x]`.
  >   - The parent todo state had `001` checked and `002` unchecked, so `002` was the first unchecked task when implementation began.
  > 
  > - Implementation artifacts found:
  >   - Added `web/lib/memba_web/live/member_message_delivery_live/show.ex`.
  >   - `MemberMessageDeliveryLive.Show` reuses `MembaWeb.MemberMessageDetail.load/3`, which loads the message, enforces selected active-club scoping, and builds the receipt model via:
  >     - `Messaging.list_member_email_deliverys/1`
  >     - `MemberEmailDeliveryPresentation.present_receipts/1`
  >   - The route from prior task is present in the authenticated member LiveView session:
  >     - `live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show`
  > 
  > - Tests run/results found:
  >   - Added `web/test/memba_web/live/member_message_delivery_live/show_test.exs`.
  >   - Tests cover successful loading of the selected club message and receipt presentation model, plus rejection of a message outside the selected active club.
  >   - Validator reran focused test:
  >     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
  >     - Result: `2 tests, 0 failures`.
  >   - Implementation summary also reports `dev check` passed.
  >   - No acceptance `.feature` files were edited.
  > 
  > - ADR/plan conformance notes:
  >   - Conforms to ADR 0001 by using the Phoenix app stack.
  >   - Conforms to ADR 0015 by implementing the member-facing surface as a LiveView.
  >   - Conforms to ADR 0023 by keeping the delivery detail page URL-addressable.
  >   - Conforms to ADR 0006 by reusing the existing member-facing delivery presentation model/status vocabulary.
  >   - Work is within task `002` scope and leaves later visual/template/menu/removal work unchecked for future tasks.
  >   - Working tree is clean; evidence is in recent Fabro checkpoint commit `27fe6a0`.
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
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  Using existing docs/iterations/047-conversation-delivery-details/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/047-conversation-delivery-details/plan.md
  TODO_PATH=docs/iterations/047-conversation-delivery-details/todo.md
  # Implementation TODO
  
  - [x] 001 Add a member-scoped route `live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show` in `web/lib/memba_web/router.ex`, in the same authenticated member scope as the message Show route.
  - [x] 002 Create `MemberMessageDeliveryLive.Show` that loads the target message and its receipt model via `Messaging.list_member_email_deliverys/1 |> MemberEmailDeliveryPresentation.present_receipts/1`, scoped to the member's active clubs (reuse the `member_message_detail` load pattern and authz).
  - [ ] 003 Build the delivery page template per `delivery-details.html`: header (subject / sender / `inserted_at`), summary bar + legend, grouped recipients (problems expanded, delivered collapsed).
  - [ ] 004 Show each recipient's bounce reason for the "didn't go through" group, from the existing receipt presentation fields; keep the delivered group collapsed with a count.
  - [ ] 005 Port the delivery-details CSS (`delivery-summary`, `delivery-bar`, `delivery-legend`, `delivery-group`, `recipient`, `deliv-*` tints) from `design-system/` into `web/assets/css/app.css`, names 1:1 with the mirror.
  - [ ] 006 Add a **Back to conversation** link on the delivery page returning to the message's conversation.
  - [ ] 007 Add a per-message **⋮ menu** to `conversation_entry_card` (`page_html.ex`) with a Delivery details item linking to `/messages/#{message_id}/delivery`.
  - [ ] 008 Remove the inline `#member-receipt-summary` section and the "Members by delivery status" grouped section from `message.html.heex`.
  - [ ] 009 Remove the "sent to N members" delivery meta line from the conversation subject header.
  - [ ] 010 Add tests: the delivery route renders the per-recipient breakdown for a message; it enforces the same authz as the conversation; the conversation kebab links to it; the conversation no longer renders the inline delivery sections.
  - [ ] 011 Run `./bin/dev gallery-walk` and compare the delivery page to `delivery-details.html` and the conversation to `member-conversation.html`.
  - [ ] 012 Run `dev check` and confirm it is green (no feature-file changes).
  ```

## Stage: todo_readable
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  Todo file is present and readable: docs/iterations/047-conversation-delivery-details/todo.md
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/047-conversation-delivery-details/plan.md'
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
  UNCHECKED tasks remain in docs/iterations/047-conversation-delivery-details/todo.md
  5:- [ ] 003 Build the delivery page template per `delivery-details.html`: header (subject / sender / `inserted_at`), summary bar + legend, grouped recipients (problems expanded, delivered collapsed).
  6:- [ ] 004 Show each recipient's bounce reason for the "didn't go through" group, from the existing receipt presentation fields; keep the delivered group collapsed with a count.
  7:- [ ] 005 Port the delivery-details CSS (`delivery-summary`, `delivery-bar`, `delivery-legend`, `delivery-group`, `recipient`, `deliv-*` tints) from `design-system/` into `web/assets/css/app.css`, names 1:1 with the mirror.
  8:- [ ] 006 Add a **Back to conversation** link on the delivery page returning to the message's conversation.
  9:- [ ] 007 Add a per-message **⋮ menu** to `conversation_entry_card` (`page_html.ex`) with a Delivery details item linking to `/messages/#{message_id}/delivery`.
  10:- [ ] 008 Remove the inline `#member-receipt-summary` section and the "Members by delivery status" grouped section from `message.html.heex`.
  11:- [ ] 009 Remove the "sent to N members" delivery meta line from the conversation subject header.
  12:- [ ] 010 Add tests: the delivery route renders the per-recipient breakdown for a message; it enforces the same authz as the conversation; the conversation kebab links to it; the conversation no longer renders the inline delivery sections.
  13:- [ ] 011 Run `./bin/dev gallery-walk` and compare the delivery page to `delivery-details.html` and the conversation to `member-conversation.html`.
  14:- [ ] 012 Run `dev check` and confirm it is green (no feature-file changes).
  ```

## Current context
| Key | Value |
|-----|-------|
| task_retry_available | false |
| task_valid | true |


Implement the next unchecked iteration task from `todo.md`.

Plan path: `docs/iterations/047-conversation-delivery-details/plan.md`.
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
- Immediately before editing `todo.md` for that check-off, read the exact active todo path with the agent read tool, then patch only the selected line. Shell `cat`, earlier workflow/script output, and prior reads of other paths do not satisfy Fabro's active-agent read guard.
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