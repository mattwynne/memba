Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KT3RSHJ7DQJYFQHXAMQ3Q8MY
Pipeline progress: 7 of 28 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/017-remove-open-tracking/plan.md'
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
  - Provider open webhook events should be rejected as unsupported, not silently accepted.
  
  ## Implementation Plan
  
  1. Inspect current opened references in `web/lib`, `web/test`, `acceptance-tests/features`, active docs, and Postmark delivery code. Exclude old `docs/iterations/**` design/prototype artifacts from cleanup unless they are active validation inputs.
  2. Update shared acceptance feature expectations to remove opened receipts.
  3. Remove or deprecate the Messaging opened-report command/API/event path from current behaviour:
     - delete or stop routing `ReportEmailDeliveryOpened` command handling;
     - delete or stop emitting `EmailDeliveryOpened` for current command execution;
     - remove the delivered-to-opened transition from the aggregate;
     - ensure current public APIs and tests use delivered/problem statuses only.
  4. Update projections/read models and loaders so current status lists, summaries, and grouping functions do not include opened.
  5. Update Postmark outbound delivery so it does not set `track_opens: true` or any equivalent open-tracking option.
  6. Update Postmark webhook handling so open events are treated as unsupported and do not mutate delivery status.
  7. Update member LiveViews/presentation modules/tests to remove opened receipt segments, groups, toggles, counts, data attributes, and copy.
  8. Update Memba staff delivery views/tests to remove opened status expectations while preserving delivered/problem visibility.
  9. Update active operational/current-app documentation, especially Postmark email docs, to remove open-tracking instructions or claims.
  10. Run targeted tests while changing each layer, then run `dev check` and fix regressions.
  
  ## Open Technical Decisions
  
  None known.
  
  Implementation notes:
  
  - If deleting old opened event modules would break event deserialization for local historic data, prefer keeping a compatibility shim that is not emitted by current code and is not exposed as current model behaviour. Do not add a data migration/backfill unless implementation discovers the app cannot boot or replay without one.
  - Keep webhook rejection consistent with the existing unsupported-event response style.
  
  ## New Capability
  
  Memba can send and monitor member email delivery without pixel-based open tracking. The product vocabulary is simpler and avoids implying that Memba observes whether a recipient read a message.
  
  ## Validation Plan
  
  - Run or update the shared acceptance harness so:
    - member deliverability scenarios pass with Sending, Delivered, and Delivery problem only;
    - staff deliverability scenarios pass without any opened scenario.
  - Run Messaging domain tests covering delivered, delayed, bounced, and spam complaint reports.
  - Run Postmark provider tests proving open tracking is not enabled.
  - Run Postmark webhook/controller tests proving open events are unsupported and do not alter delivery status.
  - Run member dashboard and member message LiveView tests proving opened groups/counts/copy are absent.
  - Run Memba staff delivery LiveView/tests proving opened status is absent while other statuses remain visible.
  - Run documentation/search checks such as `rg "opened|track_opens|open tracking" web/lib web/test acceptance-tests/features docs/email-delivery.md` and confirm remaining matches are either removed or explicitly historical/irrelevant.
  - Run `dev check`.
  
  ## Risks / Follow-ups
  
  - Removing old event modules entirely may be awkward if local event stores contain historic opened events. Keep compatibility internal if needed, but do not expose opened as current behaviour.
  - Third-party provider dashboards may still report opens independently if a stream was configured outside Memba. Document that Memba does not request or consume those signals.
  - Future engagement metrics, if ever wanted, should be planned as a separate product/privacy decision rather than reusing tracking pixels by accident.
  ```

## Stage: preflight_sandbox
- Status: succeeded
- Handler: command
- Script: `set -eu
if [ ! -x bin/dev ]; then
  echo "Missing or non-executable bin/dev" >&2
  exit 1
fi
status=$(git status --short)
if [ -n "$status" ]; then
  echo 'Iteration review requires a clean working tree before review starts.' >&2
  printf '%s\n' "$status" >&2
  exit 1
fi
rm -rf .fabro/tmp
mkdir -p .fabro/tmp
git rev-parse HEAD > .fabro/tmp/review-start-sha.txt
echo "Review start SHA: $(cat .fabro/tmp/review-start-sha.txt)"
PATH="$PWD/bin:$PATH" dev sandbox-check`
- Output:
  ```
  (212 lines omitted)
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

## Stage: dev_check
- Status: succeeded
- Handler: command
- Script: `PATH="$PWD/bin:$PATH" dev ci`
- Output:
  ```
  • Validating lock
  ✓ Validating lock in 22.8ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 2.77ms
  • Evaluating shell
  ✓ Evaluating shell in 1.12ms (cached)
  ✓ Configuring shell in 8.15ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 369µs (cached)
  ✓ Loading tasks in 2.35ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 11.7ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 12.0ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 93.2µs (no command)
  ✓ Running tasks in 24.6ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:1] [ds:8:1:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  • Validating lock
  ✓ Validating lock in 20.0ms
  Compiling 115 files (.ex)
  Generated memba app
  Running ExUnit with seed: 830830, max_cases: 2
  
  ............................................................................................................................................................................................................09:00:49.858 request_id=GLU4C4cgmJ6hSasAAU6h [warning] Rejected auth sign-in link callback: :consumed
  .09:00:49.860 request_id=GLU4C4c6mvS-chIAAU7B [warning] Rejected auth sign-in link callback: :not_found
  ......09:00:49.904 request_id=GLU4C4nYO3TEt60AAVCB [warning] Rejected auth sign-in link callback: :expired
  .........................................................................................................................................................................
  Finished in 19.2 seconds (8.3s async, 10.8s sync)
  380 tests, 0 failures
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `set -eu
base_sha='9bf6d3c8c1134c4cda5bc94c2d9d4f4033b7948e'
echo '=== Implementation Evidence Debug ==='
echo "PWD: $PWD"
echo "Branch: $(git branch --show-current || true)"
echo "HEAD: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
echo "Base sha input: ${base_sha:-<empty>}"
echo ''
if [ -z "$base_sha" ]; then
  echo 'Missing required input: base_sha' >&2
  echo 'Run via: bin/dev fabro review <branch> <plan_path> [base_ref_or_base_sha]' >&2
  exit 1
fi
if ! git cat-file -e "$base_sha^{commit}" 2>/dev/null; then
  shallow=$(git rev-parse --is-shallow-repository 2>/dev/null || echo unknown)
  echo "Base sha is not present locally: $base_sha" >&2
  echo "Repository shallow: $shallow" >&2
  if [ "$shallow" = true ]; then
    echo 'Trying to unshallow repository before failing...' >&2
    git fetch --quiet --unshallow origin || true
  fi
fi
if ! git cat-file -e "$base_sha^{commit}" 2>/dev/null; then
  echo "Base sha still does not resolve after fallback: $base_sha" >&2
  echo '--- available refs ---' >&2
  git show-ref >&2 || true
  echo '--- recent commits ---' >&2
  git log --oneline --decorate --max-count=40 --all >&2 || true
  exit 1
fi
echo '=== Implementation Evidence ==='
echo "Branch: $(git branch --show-current || true)"
echo "HEAD: $(git rev-parse HEAD)"
echo "Base sha: $base_sha"
echo ''
echo '--- git status --short ---'
git status --short
echo ''
echo '--- git diff --stat ---'
if ! git diff --stat "$base_sha"..HEAD; then
  echo "Could not compute diff stat from $base_sha to HEAD." >&2
  exit 1
fi
echo ''
echo '--- git diff --name-status ---'
if ! git diff --name-status "$base_sha"..HEAD; then
  echo "Could not compute diff name-status from $base_sha to HEAD." >&2
  exit 1
fi
echo ''
echo '--- changed source/config/test file excerpts ---'
if ! changed_files=$(git diff --name-only "$base_sha"..HEAD); then
  echo "Could not compute changed files from $base_sha to HEAD." >&2
  exit 1
fi
if [ -z "$changed_files" ]; then
  echo 'No files differ between base sha and HEAD.'
else
  excerpt_files=$(printf '%s
' "$changed_files" | grep -E '^(web/(lib|config|test|priv/repo/migrations|mix\.exs|mix\.lock)|bin/|docs/iterations/|docs/adr/)' || true)
  if [ -z "$excerpt_files" ]; then
    echo 'No changed files matched the excerpt filter.'
  else
    printf '%s
' "$excerpt_files" | while IFS= read -r file; do
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
  (6101 lines omitted)
      club_id = Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0)
      person_id = Ecto.UUID.generate()
      club_name = Keyword.fetch!(attrs, :club_name)
  
      club =
        Repo.get(Club, club_id) ||
          insert_membership_club!(
            club_id: club_id,
            name: club_name
          )
  
      person =
        insert_membership_person!(
          person_id: person_id,
          name: Keyword.get(attrs, :name, "Test Member"),
          email: Keyword.fetch!(attrs, :email)
        )
  
      Repo.insert!(%Membership{
        membership_id: Ecto.UUID.generate(),
        club_id: club_id,
        person_id: person.person_id,
        active: true
      })
  
      club
      |> Map.from_struct()
      |> Map.put(:person_id, person.person_id)
    end
  
    defp create_message(attrs) do
      Repo.insert!(%Message{
        message_id: Ecto.UUID.generate(),
        club_id: Keyword.fetch!(attrs, :club_id),
        sender_id: Keyword.fetch!(attrs, :sender_id),
        subject: Keyword.fetch!(attrs, :subject),
        body: Keyword.get(attrs, :body, "Message body")
      })
    end
  
    defp create_member_email_delivery(attrs) do
      Repo.insert!(%MemberEmailDelivery{
        delivery_id: Ecto.UUID.generate(),
        message_id: Keyword.fetch!(attrs, :message_id),
        recipient_id: Keyword.fetch!(attrs, :recipient_id),
        recipient_name: Keyword.fetch!(attrs, :recipient_name),
        status: Keyword.fetch!(attrs, :status)
      })
    end
  end
  ```

## Stage: review_fork
- Status: partially_succeeded
- Handler: parallel
- Notes: Parallel node dispatched 3 branches (2 succeeded, 1 failed)

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 5.6k in / 11.9k out
- Response:
  > # Implementation Review Report
  > 
  > ## Decision: ACCEPT
  > 
  > ## Confidence: High
  > 
  > ## ADR Conformance: PASS
  > 
  > ### ADR Violations
  > None.
  > 
  > The implementation correctly adheres to all relevant ADRs:
  > 
  > - **ADR-001 (Use Commanded for CQRS/ES)**: Command/event modules follow Commanded patterns. Router properly excludes deprecated command dispatch. Event deserialization warning is appropriate.
  > - **ADR-003 (Projection Schema Design)**: `MemberEmailDelivery` projection updated to three-status enum with schema validation enforcing constraint.
  > - **ADR-004 (Email Delivery via Postmark)**: Still uses Postmark. Explicitly sets `track_opens: false` in `OutboundEmail.new/1`. Webhook controller rejects open events with 400 "unsupported event type".
  > - **ADR-007 (Acceptance Testing Strategy)**: Acceptance feature files updated to remove opened scenarios while maintaining domain acceptance criteria for delivered/problem statuses.
  > - **ADR-009 (Remove Email Open Tracking)**: Newly created and correctly implemented throughout the codebase.
  > 
  > ### Evidence
  > - `web/lib/memba/postmark/outbound_email.ex:17`: `track_opens: false` hardcoded
  > - `web/lib/memba/postmark/webhook_controller.ex`: Open events return `400` with `"unsupported event type"`
  > - `web/lib/memba/messaging/router.ex`: `ReportEmailDeliveryOpened` dispatch removed
  > - `web/lib/memba/messaging/projections/member_email_delivery.ex:12-13`: Status enum limited to `[:sending, :delivered, :delivery_problem]`
  > - `web/test/memba/postmark/outbound_email_test.exs:18`: Explicit test `assert email.track_opens == false`
  > 
  > ## Blocking Issues
  > None.
  > 
  > ## Bounded-Safe Fixes
  > 
  > 1. **LiveView status helper duplication**: Both `MemberDeliveriesLive` and `Staff.ClubDeliveriesLive` duplicate `status_badge_class/1` and `format_status/1`. Extract to shared module:
  >    - Create `web/lib/memba_web/components/delivery_status.ex` or similar
  >    - Move both helpers to shared module
  >    - Import in both LiveViews
  >    - Update tests if needed
  > 
  > 2. **Deprecated command moduledoc inaccuracy**: `ReportEmailDeliveryOpened` moduledoc claims "will return an error if used" but there's no handler—dispatch would raise `Commanded.Router.UnregisteredCommandError`. Fix moduledoc:
  >    ```elixir
  >    @moduledoc """
  >    DEPRECATED: Open tracking has been removed from Memba.
  >    This command is retained for backwards compatibility with historic event data
  >    but is no longer routed. Attempting to dispatch this command will raise an error.
  >    See ADR 009: Remove Email Open Tracking.
  >    """
  >    ```
  > 
  > ## Judgement-Worthy Non-Blocking Code-Health Findings
  > 
  > 1. **Deprecated module lifecycle policy**
  >    - **Files**: `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`, `web/lib/memba/messaging/events/email_delivery_opened.ex`
  >    - **Smell**: No documented timeline or policy for eventual removal of deprecated event/command modules
  >    - **Why judgement-worthy**: If deprecated modules accumulate without a removal strategy, technical debt grows. May warrant a project-wide policy: e.g., "deprecated event modules retained indefinitely for replay compatibility; deprecated command modules removed after N months if never dispatched." Not urgent since this is the first deprecated command, but worth establishing precedent.
  > 
  > 2. **File rename without migration guide**
  >    - **Files**: `web/lib/memba/postmark/email.ex` (deleted) → `web/lib/memba/postmark/outbound_email.ex` (created); same for test files
  >    - **Smell**: Simple rename but no inline comment explaining relationship to old module name
  >    - **Why judgement-worthy**: Future developers searching for `Postmark.Email` references won't find breadcrumbs. Consider adding brief comment in `OutboundEmail` moduledoc: "Replaces deprecated `Postmark.Email` module." Low risk since git history is clear.
  > 
  > 3. **Status formatting repetition across member/staff contexts**
  >    - **Files**: `web/lib/memba_web/live/member_deliveries_live.ex`, `web/lib/memba_web/live/staff/club_deliveries_live.ex`
  >    - **Smell**: Beyond the DRY issue flagged above, the status display logic is duplicated across member and staff contexts with identical semantics
  >    - **Why judgement-worthy**: If status formatting rules diverge in future (e.g., staff sees different labels or colors), current duplication makes that harder. Shared component would make divergence explicit. However, premature abstraction may be worse if contexts truly are independent. Judgement call on component extraction strategy.
  > 
  > ## Suggested Fixes
  > 
  > ### If Bounded-Safe Fixes Applied
  > 
  > **Fix 1: Extract status helpers to shared module**
  > 
  > Create `web/lib/memba_web/components/delivery_status_helpers.ex`:
  > ```elixir
  > defmodule MembaWeb.Components.DeliveryStatusHelpers do
  >   @moduledoc """
  >   Shared helper functions for formatting email delivery statuses.
  >   """
  > 
  >   @doc """
  >   Returns Tailwind classes for status badge based on delivery status.
  >   """
  >   def status_badge_class(:sending), do: "px-3 py-1 rounded-full text-sm bg-blue-100 text-blue-800"
  >   def status_badge_class(:delivered), do: "px-3 py-1 rounded-full text-sm bg-green-100 text-green-800"
  >   def status_badge_class(:delivery_problem), do: "px-3 py-1 rounded-full text-sm bg-red-100 text-red-800"
  > 
  >   @doc """
  >   Formats delivery status atom as human-readable string.
  >   """
  >   def format_status(:sending), do: "Sending"
  >   def format_status(:delivered), do: "Delivered"
  >   def format_status(:delivery_problem), do: "Delivery problem"
  > end
  > ```
  > 
  > Update `web/lib/memba_web/live/member_deliveries_live.ex`:
  > ```elixir
  > defmodule MembaWeb.MemberDeliveriesLive do
  >   use MembaWeb, :live_view
  > 
  >   alias Memba.Messaging
  >   import MembaWeb.Components.DeliveryStatusHelpers
  > 
  >   # ... rest unchanged, remove duplicated helper functions
  > end
  > ```
  > 
  > Update `web/lib/memba_web/live/staff/club_deliveries_live.ex` similarly.
  > 
  > Add test in `web/test/memba_web/components/delivery_status_helpers_test.exs`:
  > ```elixir
  > defmodule MembaWeb.Components.DeliveryStatusHelpersTest do
  >   use ExUnit.Case, async: true
  >   import MembaWeb.Components.DeliveryStatusHelpers
  > 
  >   describe "status_badge_class/1" do
  >     test "returns correct classes for each status" do
  >       assert status_badge_class(:sending) =~ "bg-blue-100"
  >       assert status_badge_class(:delivered) =~ "bg-green-100"
  >       assert status_badge_class(:delivery_problem) =~ "bg-red-100"
  >     end
  >   end
  > 
  >   describe "format_status/1" do
  >     test "formats status atoms as strings" do
  >       assert format_status(:sending) == "Sending"
  >       assert format_status(:delivered) == "Delivered"
  >       assert format_status(:delivery_problem) == "Delivery problem"
  >     end
  >   end
  > end
  > ```
  > 
  > **Fix 2: Correct deprecated command moduledoc**
  > 
  > In `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`, replace moduledoc:
  > ```elixir
  > @moduledoc """
  > DEPRECATED: Open tracking has been removed from Memba.
  > This command struct is retained for backwards compatibility with historic event data
  > but is no longer routed by the Messaging.Router. Attempting to dispatch this command
  > will raise Commanded.Router.UnregisteredCommandError.
  > See ADR 009: Remove Email Open Tracking.
  > """
  > ```
  > 
  > ## Validation Notes
  > 
  > ### Tests/Checks Confirming Correctness
  > 
  > 1. **Dev check passed**: 380 tests, 0 failures, including:
  >    - Postmark provider tests verify `track_opens: false` explicitly
  >    - Webhook controller tests verify open events rejected with 400
  >    - LiveView tests verify "Opened" status absent from UI
  >    - Projection tests validate three-status-only schema
  > 
  > 2. **Acceptance test updates**: Both `member-deliverability.feature` and `staff-deliverability.feature` removed opened scenarios; remaining scenarios cover delivered and delivery_problem paths.
  > 
  > 3. **Domain behaviour**: 
  >    - `MessageOutbox` aggregate no longer transitions to opened state
  >    - Projection schema `validate_inclusion` rejects `:opened`
  >    - Messaging context functions work with three statuses only
  > 
  > 4. **Integration coverage**:
  >    - `web/test/memba/postmark/outbound_email_test.exs` explicitly asserts `email.track_opens == false`
  >    - `web/test/memba/postmark/webhook_controller_test.exs` verifies open webhook returns 400
  >    - `web/test/memba_web/live/member_deliveries_live_test.exs:36` uses `refute has_element?(view, "span", "Opened")`
  >    - `web/test/memba_web/live/staff/club_deliveries_live_test.exs:57` similarly refutes opened display
  > 
  > 5. **Documentation updated**: `docs/email-delivery.md` explicitly states open tracking disabled and references ADR-009.
  > 
  > ### Manual Checks Performed
  > 
  > - Verified ADR-009 created with correct status, context, decision, and consequences
  > - Confirmed deprecated event has `__after_deserialize__/1` callback with warning
  > - Confirmed router excludes `ReportEmailDeliveryOpened` from dispatch list
  > - Verified `OutboundEmail` typespec hardcodes `track_opens: false`
  > 
  > ### Remaining Risks
  > 
  > - **Historic event compatibility**: Deprecated modules retained for event store replay. No migration added. Per plan: "Do not add a data migration/backfill unless implementation discovers the app cannot boot or replay without one." Since dev check passed and app boots, this appears safe.
  > - **Third-party tracking**: Plan notes "Third-party provider dashboards may still report opens independently if a stream was configured outside Memba." Documentation correctly states Memba does not request or consume open signals, mitigating this risk.
  > 
  > ---
  > 
  > **Conclusion**: Clean, thorough implementation. Bounded-safe fixes are optional polish. Judgement-worthy findings are low-priority observations for future policy decisions. Ready to merge.

## Stage: review_merge
- Status: succeeded
- Handler: parallel.fan_in
- Notes: Selected best candidate: claude_review

## Current context
| Key | Value |
|-----|-------|
| parallel.branch_count | 3 |
| parallel.fan_in.best_head_sha | 2ad36e36fb7262fa0908500f265f482d4cdab747 |
| parallel.fan_in.best_id | claude_review |
| parallel.fan_in.best_outcome | succeeded |
| parallel.results | [{"id":"claude_review","status":"succeeded","head_sha":"2ad36e36fb7262fa0908500f265f482d4cdab747"},{"id":"codex_review","status":"succeeded","head_sha":"3f1af06e44775b18526ad3630520b6f7c31a88a9"},{"id":"","status":"failed"}] |


Synthesize the independent implementation reviews for docs/iterations/017-remove-open-tracking/plan.md.

This review runs after implementation has already merged to `main`. It is a smell radar and bounded polish loop, not a delivery gate. Decide whether there are bounded fixes the workflow should attempt now, or whether remaining findings should be logged for human judgement in `docs/code-health.md` while the run continues.

## Context

Use the prior context from this workflow run:

- The iteration plan text and its explicit requirements.
- Implementation evidence collected from `9bf6d3c8c1134c4cda5bc94c2d9d4f4033b7948e` to `HEAD`.
- Successful `dev check` output.
- Independent review reports (Claude, Codex, Gemini).
- Previous synthesis decisions and repair summaries, if this is a repeated synthesis after repair.

## Standards

- Treat automated tests and implementation plan-conformance as already-owned by the implementation workflow.
- Request automatic fixes only for concrete, bounded refactoring, maintainability, project-convention, documentation, or low-risk test-quality issues that can be resolved without changing product behaviour or feature files.
- Do not request edits to acceptance feature files (`*.feature`).
- Do not introduce new product behaviour in review.
- If a finding requires product, architecture, scope, or acceptance-criteria judgement, do not block. Mark it as a code-health/manual follow-up.
- If a prior automatic repair attempted the same issue and it still remains, do not request another repair. Mark it as a code-health/manual follow-up.
- If no bounded automatic fixes are worth attempting, accept the review and let the next step record any judgement-worthy findings in `docs/code-health.md`.

## Output format

Return a concise Markdown synthesis with these sections:

### Decision

One of: **ACCEPTED** or **FIX**.

### Review synthesis

Summarize the important findings across reviewers.

### Bounded automatic fixes

If **FIX**, list exact bounded changes to make, with constraints and validation.

### Code-health findings for human judgement

List findings that should be logged to `docs/code-health.md` because they are not safe bounded review fixes. If none, state "None."

### Fixed or dismissed findings

Note findings that were already fixed during this review run, duplicates, or findings you are dismissing as not supported by evidence.

## Routing JSON

End your response with exactly one JSON object that Fabro can use for routing. The JSON object must be the final text in the response and must not be wrapped in a Markdown code fence.

Use one of these shapes:

- Accepted / log-only findings:
  `{"context_updates":{"implementation_accepted":true,"review_fixes_available":false}}`
- Automatic fixes appropriate:
  `{"context_updates":{"implementation_accepted":false,"review_fixes_available":true,"review_blockers":[{"id":"fix-id-1","title":"Short fix title","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"}]}}`

Do not route to human input from this post-merge review. Human-judgement findings belong in the Markdown section above so the next step can record them in `docs/code-health.md`.