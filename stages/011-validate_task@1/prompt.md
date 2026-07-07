Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01KWY3ZH6TQWHAQHX5X0EPH1CK
Pipeline progress: 9 of 33 stages completed

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
  Created docs/iterations/047-conversation-delivery-details/todo.md from docs/iterations/047-conversation-delivery-details/plan.md
  PLAN_PATH=docs/iterations/047-conversation-delivery-details/plan.md
  TODO_PATH=docs/iterations/047-conversation-delivery-details/todo.md
  # Implementation TODO
  
  - [ ] 001 Add a member-scoped route `live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show` in `web/lib/memba_web/router.ex`, in the same authenticated member scope as the message Show route.
  - [ ] 002 Create `MemberMessageDeliveryLive.Show` that loads the target message and its receipt model via `Messaging.list_member_email_deliverys/1 |> MemberEmailDeliveryPresentation.present_receipts/1`, scoped to the member's active clubs (reuse the `member_message_detail` load pattern and authz).
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
  3:- [ ] 001 Add a member-scoped route `live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show` in `web/lib/memba_web/router.ex`, in the same authenticated member scope as the message Show route.
  4:- [ ] 002 Create `MemberMessageDeliveryLive.Show` that loads the target message and its receipt model via `Messaging.list_member_email_deliverys/1 |> MemberEmailDeliveryPresentation.present_receipts/1`, scoped to the member's active clubs (reuse the `member_message_detail` load pattern and authz).
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
- Tokens: 380.9k in / 5.3k out
- Response:
  > 1. **Selected todo line**
  >    - `001 Add a member-scoped route live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show in web/lib/memba_web/router.ex, in the same authenticated member scope as the message Show route.`
  > 
  > 2. **Changes made**
  >    - Added the member delivery LiveView route in `web/lib/memba_web/router.ex` inside the existing authenticated club-member `live_session`, next to the existing message show route:
  >      - `/messages/:message_id/delivery` → `MembaWeb.MemberMessageDeliveryLive.Show`
  >    - Added a router test in `web/test/memba_web/router_test.exs` proving:
  >      - the route exists;
  >      - it is under `[:browser, :club_member_required]`;
  >      - it targets `MembaWeb.MemberMessageDeliveryLive.Show`;
  >      - it captures `message_id`.
  > 
  > 3. **Validation run**
  >    - TDD failing check:
  >      - `PATH="$PWD/bin:$PATH" dev test test/memba_web/router_test.exs`
  >      - Failed as expected before the route existed: route returned `:error`.
  >    - Focused passing check:
  >      - `PATH="$PWD/bin:$PATH" dev test test/memba_web/router_test.exs`
  >      - Passed: `14 tests, 0 failures`.
  >    - Full required route/UI validation:
  >      - `PATH="$PWD/bin:$PATH" dev check`
  >      - Passed, including acceptance run: `85 scenarios (85 passed)`, `523 steps (523 passed)`.
  >    - Final whitespace check:
  >      - `git diff --check`
  >      - Passed.
  > 
  > 4. **Todo check-off made**
  >    - Changed exactly this line:
  >      - `- [ ] 001 Add a member-scoped route ...`
  >    - To:
  >      - `- [x] 001 Add a member-scoped route ...`
  > 
  > 5. **Todo splits/additions/reordering**
  >    - None. I implemented only the first unchecked task and left all later tasks unchecked.
  > 
  > 6. **ADR conformance evidence**
  >    - No ADRs were explicitly referenced by the plan.
  >    - I inspected relevant accepted ADRs:
  >      - ADR 0001: Phoenix is the core application stack.
  >      - ADR 0015: member application pages should use LiveView by default.
  >      - ADR 0023: visible member app state should be URL-addressable where practical.
  >    - The change conforms by adding a Phoenix LiveView route for the member-facing delivery details surface under the existing authenticated member routing/session structure.

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
  3de3041
  3de3041 fabro(01KWY3ZH6TQWHAQHX5X0EPH1CK): implement_next_task (succeeded)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/047-conversation-delivery-details/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```


Validate the just-completed iteration task for `docs/iterations/047-conversation-delivery-details/plan.md`.

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