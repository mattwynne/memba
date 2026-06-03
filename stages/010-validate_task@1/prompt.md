Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01KT7BR6YQQSTZVM0G42C138AW
Pipeline progress: 8 of 30 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/020-migrate-production-email-to-postmark/plan.md'
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
  (99 lines omitted)
  6. Reuse iteration 019's provider-neutral command/API for all accepted/rejected behaviour rather than duplicating business rules in Postmark-specific code.
  7. Add Postmark inbound idempotency support using the stable provider message id or equivalent payload field.
  8. Add tests for Postmark inbound payload parsing and controller/dispatcher behaviour, including accepted primary-address sender, alternate-address sender where practical, rejection cases, attachments, HTML-only/missing plain text, and duplicate retry handling.
  9. Verify or add tests proving Postmark outbound member-message payloads still include sender/reply-to, text/HTML bodies, and correlation metadata expected by the Postmark delivery-status webhook handler.
  10. Verify or add tests proving Postmark auth email configuration uses `MEMBA_AUTH_EMAIL_PROVIDER=postmark`, `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`, and fails clearly when incomplete.
  11. Verify rejection-email delivery follows the configured mailer/provider path and works when Postmark is selected.
  12. Update `docs/postmark-email.md` to describe the full Postmark production setup: outbound member-message stream, auth stream, inbound club-message routing for `clubs.memba.io`, delivery-status webhook URL, inbound webhook URL, environment variables, and local smoke-test guidance.
  13. Update `docs/human-todo.md` or add a runbook under this iteration folder with Matt's manual cutover steps, smoke tests, monitoring checks, and rollback steps to Resend.
  14. Update ADR/documentation as needed to reflect that Postmark is the intended primary production provider after approval, while Resend remains a first-class fallback.
  15. Run targeted tests for Postmark inbound, Resend inbound regression, Postmark outbound delivery, auth email configuration, and provider selection.
  16. Run `dev check`.
  
  ## Open Technical Decisions
  
  Implementation should investigate and decide:
  
  - The exact Postmark inbound webhook payload shape and which field is the best stable provider message id for idempotency.
  - Whether Postmark inbound email and delivery-status events should use two separate routes or one dispatching route, based on Postmark configuration capabilities and the existing `/webhooks/postmark` controller.
  - The exact Postmark inbound domain/MX setup needed to preserve `<club-slug>@clubs.memba.io`.
  - Whether Postmark inbound webhooks provide attachment metadata without downloading attachments, and how to detect attachments early enough to preserve the iteration 019 rejection rule.
  - Whether any provider-specific inbound authentication is available and already configured; do not expand into a security iteration unless small and non-disruptive.
  
  ## New Capability
  
  Memba can receive, send, and operationally validate all production email paths through Postmark while preserving Resend as a fallback. Matt has a concrete runbook for a manual production cutover and rollback.
  
  ## Validation Plan
  
  - Run focused tests for Postmark inbound payload parsing/translation.
  - Run focused tests for provider-neutral inbound command/API regressions from iteration 019.
  - Run focused tests for Resend inbound parsing to confirm fallback support still works.
  - Run focused tests for Postmark outbound member-message payload metadata and delivery-status webhook correlation.
  - Run focused tests for Postmark auth email configuration and missing-config errors.
  - Run `dev check`.
  - Manual cutover smoke test from the runbook after Matt changes production configuration:
    1. Confirm Postmark outbound member-message stream, auth stream, inbound routing for `clubs.memba.io`, and webhooks are configured.
    2. Set production secrets to select Postmark for member-message delivery and auth email.
    3. Send a magic link to a controlled inbox, confirm receipt from the Postmark auth sender, and sign in successfully.
    4. Send a member message from the web UI, confirm Postmark accepts and delivers it, and confirm delivery-status webhook updates Memba.
    5. Email `kmc@clubs.memba.io` from an active member address, confirm Memba creates and distributes the club message.
    6. Email `kmc@clubs.memba.io` from an unsupported sender or with an unsupported attachment, confirm no club message is created and the rejection email is delivered through Postmark.
    7. Confirm Resend rollback instructions are complete and the required Resend secrets/webhooks are still available.
  
  ## Risks / Follow-ups
  
  - Postmark inbound payloads may differ enough from Resend that the provider-neutral API needs small adjustments. Keep changes provider-neutral and preserve Resend tests.
  - Inbound domain/MX setup for `clubs.memba.io` may require DNS/provider dashboard work that cannot be completed by code delivery alone; document it clearly for Matt's manual cutover.
  - Production cutover risk includes missed MX propagation, webhook misconfiguration, missing secrets, or sender-domain reputation issues. The runbook and rollback path mitigate this.
  - Webhook authentication remains a known follow-up security concern from ADR 0016 and the provider webhook authentication kaizen note.
  - Keeping both providers increases maintenance cost, but it is valuable while Memba is still proving deliverability and provider fit.
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/020-migrate-production-email-to-postmark/plan.md'
PATH="$PWD/bin:$PATH" dev iteration check-predecessors "$PLAN_PATH"
PATH="$PWD/bin:$PATH" dev iteration check-clear "$PLAN_PATH" --allow-same-iteration`
- Output:
  ```
  (6 lines omitted)
  ✓ Evaluating shell in 3.54s
  ✓ Configuring shell in 3.61s
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 2.22ms
  ✓ Loading tasks in 2.91ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 12.5ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 16.3ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 106µs (no command)
  ✓ Running tasks in 29.7ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:1] [ds:8:1:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  • Validating lock
  ✓ Validating lock in 24.3ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 2.38ms
  • Evaluating shell
  ✓ Evaluating shell in 1.08ms (cached)
  ✓ Configuring shell in 6.64ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 367µs (cached)
  ✓ Loading tasks in 3.23ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.6ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 12.5ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 86.6µs (no command)
  ✓ Running tasks in 23.9ms
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
for tool in python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required bare sandbox tool: $tool" >&2
    echo "The iteration workflow uses $tool in finalization scripts outside bin/dev's devenv shell. Rebuild the Fabro sandbox image with this tool on the default PATH." >&2
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
PLAN_PATH='docs/iterations/020-migrate-production-email-to-postmark/plan.md'
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
  HEAD: 1c26477 fabro(01KT7BR6YQQSTZVM0G42C138AW): preflight_sandbox (succeeded)
  Todo: docs/iterations/020-migrate-production-email-to-postmark/todo.md is absent; sync_task_list will create it from plan.md.
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/020-migrate-production-email-to-postmark/plan.md'
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
  Created docs/iterations/020-migrate-production-email-to-postmark/todo.md from docs/iterations/020-migrate-production-email-to-postmark/plan.md
  PLAN_PATH=docs/iterations/020-migrate-production-email-to-postmark/plan.md
  TODO_PATH=docs/iterations/020-migrate-production-email-to-postmark/todo.md
  # Implementation TODO
  
  - [ ] 001 Start after iteration 019 is delivered. Do not require manual Resend inbound observation before proceeding; Matt approved moving directly to Postmark after production setup showed the current Resend domain/account cannot receive `clubs.memba.io` without further provider changes.
  - [ ] 002 Inspect iteration 019's provider-neutral inbound email API, idempotency model, rejection-email path, Resend inbound parser/controller, provider selection, and tests.
  - [ ] 003 Inspect existing Postmark outbound member-message provider, Postmark delivery-status webhook controller, auth email Postmark configuration, and `docs/postmark-email.md`.
  - [ ] 004 Determine the cleanest Postmark inbound routing shape. Prefer keeping inbound-email handling separate from outbound delivery-status webhooks if Postmark's dashboard supports separate inbound and delivery-status webhook URLs; otherwise make the shared Postmark route dispatch safely by payload shape.
  - [ ] 005 Add a Postmark inbound parser/controller/dispatcher that maps realistic Postmark inbound payload fields to the provider-neutral inbound email structure: provider name, provider message id, sender, recipients, subject, plain text, HTML body if present, attachment metadata, and useful headers.
  - [ ] 006 Reuse iteration 019's provider-neutral command/API for all accepted/rejected behaviour rather than duplicating business rules in Postmark-specific code.
  - [ ] 007 Add Postmark inbound idempotency support using the stable provider message id or equivalent payload field.
  - [ ] 008 Add tests for Postmark inbound payload parsing and controller/dispatcher behaviour, including accepted primary-address sender, alternate-address sender where practical, rejection cases, attachments, HTML-only/missing plain text, and duplicate retry handling.
  - [ ] 009 Verify or add tests proving Postmark outbound member-message payloads still include sender/reply-to, text/HTML bodies, and correlation metadata expected by the Postmark delivery-status webhook handler.
  - [ ] 010 Verify or add tests proving Postmark auth email configuration uses `MEMBA_AUTH_EMAIL_PROVIDER=postmark`, `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`, and fails clearly when incomplete.
  - [ ] 011 Verify rejection-email delivery follows the configured mailer/provider path and works when Postmark is selected.
  - [ ] 012 Update `docs/postmark-email.md` to describe the full Postmark production setup: outbound member-message stream, auth stream, inbound club-message routing for `clubs.memba.io`, delivery-status webhook URL, inbound webhook URL, environment variables, and local smoke-test guidance.
  - [ ] 013 Update `docs/human-todo.md` or add a runbook under this iteration folder with Matt's manual cutover steps, smoke tests, monitoring checks, and rollback steps to Resend.
  - [ ] 014 Update ADR/documentation as needed to reflect that Postmark is the intended primary production provider after approval, while Resend remains a first-class fallback.
  - [ ] 015 Run targeted tests for Postmark inbound, Resend inbound regression, Postmark outbound delivery, auth email configuration, and provider selection.
  - [ ] 016 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 5.0k in / 279 out
- Response:
  > {"cmd": "TODO_PATH='docs/iterations/020-migrate-production-email-to-postmark/todo.md'\nif [ ! -r \"$TODO_PATH\" ] || [ ! -s \"$TODO_PATH\" ]; then\n  echo \"BLOCKING: missing, empty, or unreadable todo: $TODO_PATH\"\nelif grep -nE '^[[:space:]]*- \\[ \\] ' \"$TODO_PATH\"; then\n  echo \"UNCHECKED_TASKS_REMAIN\"\nelse\n  echo \"ALL_TASKS_COMPLETE\"\nfi", "max_output": 12000}{"context_updates":{"task_list_complete":false,"task_list_needs_human":false}}

## Stage: implement_next_task
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 119.8k in / 1.9k out
- Response:
  > 1. **Selected todo line**
  >    - `001 Start after iteration 019 is delivered. Do not require manual Resend inbound observation before proceeding; Matt approved moving directly to Postmark after production setup showed the current Resend domain/account cannot receive clubs.memba.io without further provider changes.`
  > 
  > 2. **Changes made**
  >    - Checked off task 001 in `docs/iterations/020-migrate-production-email-to-postmark/todo.md`.
  >    - No code/config/test/docs content changes beyond the iteration execution-state checkbox.
  > 
  > 3. **Focused validation**
  >    - Ran:
  >      - `git log --oneline --decorate -20`
  >        - Confirmed recent context includes `8e58fa0 iteration 019: mark merged`.
  >      - `git status --short`
  >        - Confirmed clean working tree before editing.
  >      - `PATH="$PWD/bin:$PATH" dev iteration check-predecessors docs/iterations/020-migrate-production-email-to-postmark/plan.md`
  >        - Passed with: `Earlier iterations are merged.`
  >      - Reviewed diff/status after edit.
  >    - Did **not** run `dev check` because this was a todo execution-state-only change, not code/config/app-behaviour.
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
  >    - Read ADR 0016, which keeps Resend as a first-class switchable provider alongside Postmark and explicitly preserves provider switchability.
  >    - Also reviewed nearby relevant ADRs 0014 and 0017 for production hosting/release-state context.
  >    - Task 001 conforms by proceeding only after predecessor delivery was verified, while preserving the plan’s approved decision to move directly toward Postmark without requiring manual Resend inbound observation.

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/020-migrate-production-email-to-postmark/plan.md'
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
  49fa3d2
  49fa3d2 fabro(01KT7BR6YQQSTZVM0G42C138AW): implement_next_task (succeeded)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/020-migrate-production-email-to-postmark/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Current context
| Key | Value |
|-----|-------|
| task_list_complete | false |
| task_list_needs_human | false |


Validate the just-completed iteration task for `docs/iterations/020-migrate-production-email-to-postmark/plan.md`.

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