Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01KT5M274P6VNG3WJK24N2SZQ9
Pipeline progress: 186 of 30 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  (184 lines omitted)
  22. Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  23. Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  24. Run `dev check`.
  
  ## Open Technical Decisions
  
  None expected to block implementation.
  
  Decisions made during planning:
  
  - Inbound email idempotency is event-sourced, not projection-invented. Use a deterministic inbound aggregate/process identity based on `{provider, provider_message_id}` and emit inbound accepted/rejected events before projecting support/audit state.
  - Add a defensive unique database constraint on `{provider, provider_message_id}` in the inbound source projection/read model, but keep the aggregate/event stream as the command-side source of truth.
  - Resend inbound webhooks use the existing Svix signature verification module, `MembaWeb.ResendWebhookSignature`. Production inbound webhook handling must be signed; development/test can be unsigned only when no signing secret is configured.
  - The Resend inbound parser contract for this iteration is an `email.received`-style payload with message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`.
  - Rejection emails may be sent synchronously during webhook handling for this slice if that is the smallest safe implementation, but duplicate provider message ids must not send duplicate rejections.
  - Quote/signature stripping should be conservative and plain-text only.
  
  ## New Capability
  
  A member can see the club's inbound email address on the member dashboard and compose page, then post to the whole club by email using that address. Memba can receive provider inbound email payloads, route them to clubs, authorize senders, create normal club messages, reject unsupported inbound emails politely, and handle provider retries without duplicate messages.
  
  ## Validation Plan
  
  - Run `dev check`.
  - Run targeted messaging context tests for the provider-neutral inbound email command/API.
  - Run targeted Resend inbound webhook controller/parser tests.
  - Run targeted mailer tests for rejection emails.
  - Run Cucumber configuration tests to confirm `@wip` scenarios are excluded from the default acceptance run until implemented.
  - After implementation removes or narrows `@wip` tags, run the affected Cucumber feature file.
  - Manual demo:
    1. Start the app locally with the local/test mailer.
    2. Ensure Kootenay Mountaineering Club has slug `kmc` and Alice is an active member with primary and alternate email addresses.
    3. Submit a realistic Resend inbound webhook payload representing Alice emailing `kmc@clubs.memba.io` with subject `Trip planning night` and a plain-text body.
    4. Confirm the message appears in KMC member views as a normal club message from Alice.
    5. Confirm KMC active members receive outbound club-message email and Nelson Paddling Club members do not.
    6. Submit the same example from Alice's alternate email address and confirm it is posted as Alice.
    7. Submit examples from an unknown sender and from Pat, who is not a KMC member, and confirm no message appears and each sender receives a rejection email.
    8. Submit an example with an attachment and confirm it is rejected with an attachment-not-supported email.
    9. Submit an HTML-only example and confirm it is rejected with a plain-text-required email.
    10. Submit an example with quoted content/signature and confirm only the new message text appears in the posted club message.
  
  ## Risks / Follow-ups
  
  - Resend inbound webhook support may have payload details that differ from the planned `email.received` parser contract. Keep the Resend-specific parser isolated and covered by realistic payload tests.
  - Inbound webhook idempotency crosses aggregate, projection, database constraint, and outbound side effects. Tests must prove duplicate provider message ids do not create duplicate club messages or duplicate emails.
  - Quote/signature stripping can easily become too aggressive or too weak. Keep this conservative and covered by examples.
  - Rejection emails can create backscatter if sent to spoofed senders. This is acceptable for the first slice only if the implementation uses provider guidance and avoids replying to obviously invalid automated senders where practical.
  - Ignoring HTML is a deliberate short-term simplification. A later rich-content iteration should preserve, sanitise, render, and forward safe HTML rather than adding throwaway HTML-to-text conversion now.
  - Attachments are rejected for now. A later iteration should decide storage, scanning, visibility, and delivery semantics.
  - Future channel/sub-group addressing and custom club-owned inbound domains may change address generation and routing.
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
PATH="$PWD/bin:$PATH" dev iteration check-predecessors "$PLAN_PATH"
PATH="$PWD/bin:$PATH" dev iteration check-clear "$PLAN_PATH" --allow-same-iteration`
- Output:
  ```
  (25 lines omitted)
  ✓ Evaluating shell in 6.61s
  ✓ Configuring shell in 6.68s
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 2.91ms
  ✓ Loading tasks in 3.50ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 28.4ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.5ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 84.9µs (no command)
  ✓ Running tasks in 40.7ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:1] [ds:8:1:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  • Validating lock
  ✓ Validating lock in 23.9ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 2.00ms
  • Evaluating shell
  ✓ Evaluating shell in 1.02ms (cached)
  ✓ Configuring shell in 4.75ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 343µs (cached)
  ✓ Loading tasks in 3.16ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.3ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 15.3ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 76.8µs (no command)
  ✓ Running tasks in 26.6ms
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
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  HEAD: 23bf119 fabro(01KT5M274P6VNG3WJK24N2SZQ9): preflight_sandbox (succeeded)
  Todo: docs/iterations/019-inbound-club-messages-by-email/todo.md is absent; sync_task_list will create it from plan.md.
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Stage: implement_next_task
- Status: failed
- Handler: agent

## Stage: pre_validate_snapshot
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  abe21bf
  abe21bf fabro(01KT5M274P6VNG3WJK24N2SZQ9): implement_next_task (failed)
  
  ## git status --short
  
  ## git diff --stat
  
  ## Working-tree diff for docs/iterations/019-inbound-club-messages-by-email/todo.md
  
  ## git diff --name-only
  
  ## Untracked files
  
  ## Combined changed path list from git status --porcelain
  ```

## Stage: validate_task
- Status: failed
- Handler: agent

## Stage: task_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: task_gate

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/019-inbound-club-messages-by-email/plan.md'
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
  Using existing docs/iterations/019-inbound-club-messages-by-email/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  TODO_PATH=docs/iterations/019-inbound-club-messages-by-email/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller/signature verifier, router webhook scope, current member dashboard/compose surfaces, and current acceptance support.
  - [x] 002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to `clubs.memba.io` for this slice.
  - [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.
  - [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.
  - [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as `inbound-email:<provider>:<provider_message_id>`. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.
  - [x] 006 Add inbound email events such as:
  - [x] 007 Add a projection/read model such as `messaging_inbound_email_sources` driven only by inbound email events. It should expose provider, provider message id, status, message id for accepted emails, rejection reason for rejected emails, and timestamps for audit/support. Add a unique index on `{provider, provider_message_id}` as a defensive database constraint, but do not rely on projection-only state as the source of truth.
  - [x] 008 Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  - [x] 009 Add sender resolution that finds a person by any primary or alternate email address.
  - [ ] 010 Add active-membership authorization for the resolved sender and destination club.
  - [ ] 011 Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  - [ ] 012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another `MessageSent`, create another club message, or send duplicate outbound/rejection emails.
  - [ ] 013 Add plain-text body normalization:
  - [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.
  - [ ] 015 Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  - [ ] 016 Add a Resend inbound webhook route/controller/parser for `email.received`-style inbound payloads. Support message fields under `data`: provider message id (`email_id` or `id`), `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`. Treat missing required fields as malformed/unprocessable and cover this with parser tests.
  - [ ] 017 Require the existing Svix-based `MembaWeb.ResendWebhookSignature` verification when a Resend signing secret is configured. Production must configure the signing secret for inbound webhooks. Development/test may run unsigned only when no signing secret is configured.
  - [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  - [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.
  - [ ] 020 Add tests for provider-neutral inbound behaviour:
  - [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.
  - [ ] 022 Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  - [ ] 023 Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  - [ ] 024 Run `dev check`.
  ```

## Stage: all_tasks_done
- Status: failed
- Handler: prompt

## Current context
| Key | Value |
|-----|-------|
| failure_class | transient_infra |
| failure_signature | all_tasks_done|transient_infra|api_transient|openai|rate_limited |
| task_list_complete | false |
| task_list_needs_human | false |
| task_retry_available | false |
| task_valid | true |


Implement the next unchecked iteration task from `todo.md`.

Plan path: `docs/iterations/019-inbound-club-messages-by-email/plan.md`.
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