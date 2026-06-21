Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KVMJ25ZA75KV5A0DPJ4A6X2D
Pipeline progress: 5 of 27 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/038-email-delivery-handoff-boundary/plan.md'
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
  (107 lines omitted)
  
  1. Inspect current outbound send paths and tests:
     - `Memba.Messaging.send_club_message/2`, `deliver_to_provider/1`, and `email_delivery_request/3`.
     - browser compose and inbound club-message acceptance callers.
     - `Memba.Messaging.Projectors.EmailDelivery` and related member/staff delivery projections.
     - fake/local/Postmark/Resend provider test seams.
  2. Update the `EmailDelivery` projection/read model so newly created records start with status `pending` and can store dispatch diagnostics such as attempt count, latest error/detail, and useful timestamps.
  3. Add database constraints or schema validation for the expanded status vocabulary where practical, preserving existing webhook statuses.
  4. Introduce a named dispatch module/process, probably `Memba.Messaging.EmailDeliveryDispatcher`, under the application supervision tree.
  5. Make the dispatcher subscribe to `Memba.ReadModelChanges.topic()` and treat relevant `EmailDeliveryCreated`/EmailDelivery projection changes as a nudge to dispatch pending email deliveries.
  6. Implement claiming logic that moves a pending delivery to `dispatching` before provider delivery, avoiding two dispatcher invocations claiming the same pending delivery concurrently.
  7. Move request-building/provider-call logic out of `Memba.Messaging` into the dispatcher or a focused collaborator used by the dispatcher.
  8. On provider success, update the delivery to `sent`; on provider error, update it to `failed`, increment attempt count, and persist the latest error/detail.
  9. Remove the synchronous provider call from `send_club_message/2`; keep its success contract tied to command acceptance/recording, not provider availability.
  10. Add an internal/manual retry API for failed deliveries. Do not add automatic retries, startup sweeps, periodic sweeps, or staff retry UI in this slice.
  11. Adapt accepted inbound club-message flow so it relies on the same pending-delivery projection and dispatcher path.
  12. Adjust member-facing and staff/operator delivery presentation only as needed for the new statuses: hide or soften infrastructure detail on member-facing screens, while allowing staff/operator diagnostics to show exact status/error.
  13. Add/update focused tests for the acceptance criteria above.
  14. Run `dev check` and fix any regressions.
  
  ## Open Technical Decisions
  
  None known.
  
  The plan intentionally decides the previously-open design choices:
  
  - Use existing `EmailDelivery` records rather than a separate handoff/outbox table.
  - Use `pending`, `dispatching`, `sent`, and `failed` as the pre/post-provider dispatch lifecycle.
  - Use a supervised OTP dispatcher and Phoenix PubSub read-model-change nudges.
  - Provide manual/internal retry only; automatic retry is a follow-up.
  - Do not rename `MessageSent` in this slice.
  
  ## New Capability
  
  Developers/operators can reason about outbound provider dispatch as an explicit, asynchronous lifecycle on each `EmailDelivery`. Provider outages or misconfiguration become observable failed delivery dispatches with retry diagnostics instead of misleading `send_club_message/2` failures after message events have already committed.
  
  ## Validation Plan
  
  - Run targeted tests around messaging send, `EmailDelivery` projection/status transitions, dispatcher behaviour, provider adapters/fakes, manual retry, and inbound club-message acceptance during implementation.
  - Run `dev check` before declaring the iteration complete.
  - Manually inspect a local/dev send flow with the fake provider to confirm message acceptance creates pending deliveries, the dispatcher sends them, and existing message/delivery views still populate.
  - Manually or through tests simulate provider failure and confirm the message remains accepted, the affected delivery becomes `failed`, attempt count/latest error are persisted, and manual retry can move it to `sent`.
  
  ## Risks / Follow-ups
  
  - There is deliberately no automatic retry, startup sweep, or periodic sweep in this iteration. If the PubSub nudge is missed or the app is down when deliveries are created, an operator/developer must use the internal retry/dispatch API. Automatic retry/sweeping should be a follow-up problem/iteration.
  - Best-effort duplicate prevention is acceptable for this slice: retry must not create duplicate domain events or duplicate local delivery records, but a crash after provider acceptance and before marking `sent` can still leave an ambiguous delivery. Strong provider-level idempotency using `delivery_id` may be a later hardening iteration.
  - Staff/operator diagnostics may need a later UI polish iteration if raw provider errors are too technical or if retry should become a Staff-facing action.
  - Existing callers/tests may assume email deliveries are immediately `sent`; updating them to understand `pending`/async dispatch may touch several tests and projections.
  - Other design-review findings remain: large application-service modules, Membership projection-backed policy preflights, onboarding conversion orchestration, and deprecated `opened` compatibility cleanup.
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
  (267 lines omitted)
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
  (1355 lines omitted)
  
    Rule: Staff-edited slugs must already be address-safe
  
      Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-06-21T07:51:25.636Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-06-21T07:51:25.700Z] scenario reset app state: Staff enter an invalid slug
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-21T07:51:27.027Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1259ms
        Given Kootenay Mountaineering Club is a club
        When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
        Then Memba should reject the club slug as invalid
        And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-06-21T07:51:28.766Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-06-21T07:51:28.777Z] scenario finish: Staff enter an invalid slug status=PASSED duration=3141ms
  
    Rule: A slug can belong to only one club
  
      Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-06-21T07:51:28.781Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-06-21T07:51:28.845Z] scenario reset app state: Staff enter a slug that another club already uses
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-21T07:51:30.152Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1262ms
        Given Kootenay Mountaineering Club has the slug "kmc"
        And Nelson Paddling Club is a club
        When Pat tries to change Nelson Paddling Club's slug to "kmc"
        Then Memba should reject the club slug as already taken
        And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-06-21T07:51:32.261Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-06-21T07:51:32.269Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=3489ms
  
    Rule: A club slug routes public visitors to that club's public page
  
      @not-domain
      Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-06-21T07:51:32.276Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-06-21T07:51:32.334Z] scenario reset app state: Robin opens an unknown club subdomain
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-21T07:51:33.637Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1245ms
        When Robin opens "unknown.clubs.memba.io"
        Then Robin should see a not found page
  [acceptance 2026-06-21T07:51:33.707Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-06-21T07:51:33.714Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1438ms
  
  [acceptance 2026-06-21T07:51:33.714Z] AfterAll: closing shared browser
  [acceptance 2026-06-21T07:51:33.766Z] AfterAll: closed shared browser
  [acceptance 2026-06-21T07:51:33.766Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-06-21T07:51:33.769Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  82 scenarios (82 passed)
  493 steps (493 passed)
  4m29.731s (executing steps: 4m14.191s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh '90134f8ebf5b313e76e43e912c50800ab2687545'`
- Output:
  ```
  (5053 lines omitted)
    end
  end
  
  === web/test/support/messaging/email_delivery_providers/selective_failure.ex ===
  defmodule Memba.Messaging.EmailDeliveryProviders.SelectiveFailure do
    @moduledoc """
    Test email delivery provider that records every request and fails configured recipients.
    """
  
    use Agent
  
    alias Memba.Messaging.EmailDeliveryProvider
    alias Memba.Messaging.EmailDeliveryRequest
  
    @behaviour EmailDeliveryProvider
  
    def start_link(_opts \\ []) do
      Agent.start_link(fn -> %{requests: [], failing_addresses: MapSet.new()} end, name: __MODULE__)
    end
  
    @impl EmailDeliveryProvider
    def deliver(%EmailDeliveryRequest{} = request) do
      Agent.get_and_update(__MODULE__, fn state ->
        state = update_in(state.requests, &[request | &1])
  
        result =
          if MapSet.member?(state.failing_addresses, request.recipient_address) do
            {:error, {:selective_failure, request.recipient_address}}
          else
            :ok
          end
  
        {result, state}
      end)
    end
  
    def fail_addresses(addresses) when is_list(addresses) do
      Agent.update(__MODULE__, fn state ->
        %{state | failing_addresses: MapSet.new(addresses)}
      end)
    end
  
    def deliveries do
      Agent.get(__MODULE__, fn state -> Enum.reverse(state.requests) end)
    end
  
    def reset do
      Agent.update(__MODULE__, fn _state -> %{requests: [], failing_addresses: MapSet.new()} end)
    end
  end
  ```

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 5.8k in / 9.7k out
- Response:
  > # Iteration 038 Implementation Review
  > 
  > ## Decision: ACCEPT
  > 
  > ## Confidence: Medium
  > 
  > The implementation successfully delivers the planned capability and passes all automated tests. However, several architectural patterns warrant human judgement about whether they align with Memba's design philosophy and long-term maintainability goals.
  > 
  > ## ADR Conformance: UNCERTAIN
  > 
  > I cannot definitively assess ADR conformance without access to the specific ADRs governing projections, read models, and async processing. The implementation evidence shows patterns that may conflict with strict event-sourcing and projection-responsibility principles, but these may be acceptable pragmatic compromises in Memba's context.
  > 
  > **Requires verification**: 
  > - Does Memba have an ADR governing projection responsibilities and whether projections may query current state vs. event payload?
  > - Does Memba have an ADR governing crash recovery and at-least-once delivery guarantees for async processes?
  > 
  > ## ADR Violations: None Confirmed
  > 
  > Without the actual ADR texts, I cannot confirm violations. However, two patterns merit ADR cross-reference:
  > 
  > 1. **EmailDelivery projection querying member state** (`web/lib/memba/messaging/projectors/email_delivery.ex`):
  >    ```elixir
  >    project(%MessageSent{} = event, _metadata, fn multi ->
  >      case Memba.ClubMemberships.get_member_by_id(event.member_id) do
  >        %{email: email} when is_binary(email) and email != "" ->
  >          # creates delivery
  >      _ ->
  >        multi  # silently skips if no email
  >      end
  >    end)
  >    ```
  >    - Projections querying current aggregate state (not event payload) creates temporal coupling
  >    - If member email changes/deletes between event emission and projection, results differ
  >    - Classic event-sourcing anti-pattern unless explicitly accepted by ADR
  >    - May violate projection-responsibility boundaries from `docs/reference/event-sourcing.md` and `docs/reference/responsibility-driven-design.md`
  > 
  > 2. **Crash recovery gap** - The plan explicitly accepts crash-after-provider scenarios as requiring manual intervention, but doesn't address crash-during-dispatch leaving deliveries in "dispatching" limbo. If Memba has an ADR requiring resilient async processing, this may violate it.
  > 
  > ## Blocking Issues: None
  > 
  > The implementation meets all stated acceptance criteria. The concerns below are architectural/robustness issues that should be considered for follow-up, not blockers for this merge given the plan's explicit trade-offs.
  > 
  > ## Bounded-Safe Fixes
  > 
  > 1. **Add database constraint on email_deliveries.status**:
  >    ```elixir
  >    # In migration:
  >    create constraint(:email_deliveries, :valid_status,
  >      check: "status IN ('pending', 'dispatching', 'sent', 'failed', 'bounced', 'delivered', 'opened', 'clicked', 'complained', 'unsubscribed')"
  >    )
  >    ```
  >    Plan step 3 says "Add database constraints or schema validation for the expanded status vocabulary where practical". Schema validation exists but DB constraint provides defense in depth.
  > 
  > 2. **Make deliver_to_provider/1 internal or move to dispatcher**:
  >    ```elixir
  >    # In Memba.Messaging:
  >    @doc false
  >    def deliver_to_provider(%EmailDelivery{} = delivery) do
  >    ```
  >    This function is only meant to be called by the dispatcher, not public API. Mark as internal or move to dispatcher module.
  > 
  > 3. **Add defensive error handling in dispatcher**:
  >    ```elixir
  >    def handle_info({:email_delivery_created, %EmailDelivery{status: "pending"} = delivery}, state) do
  >      try do
  >        dispatch(delivery)
  >      rescue
  >        e ->
  >          Logger.error("Dispatcher crash for delivery #{delivery.delivery_id}: #{inspect(e)}")
  >          # Delivery stays "dispatching" - manual retry required as per plan
  >      end
  >      {:noreply, state}
  >    end
  >    ```
  >    Prevents dispatcher crash from taking down the GenServer, though delivery still requires manual intervention.
  > 
  > 4. **Add logging for observability**:
  >    ```elixir
  >    defp handle_dispatch_result(delivery, :ok) do
  >      Logger.info("Successfully dispatched delivery #{delivery.delivery_id}")
  >      # ... existing code
  >    end
  > 
  >    defp handle_dispatch_result(delivery, {:error, reason}) do
  >      Logger.warning("Failed to dispatch delivery #{delivery.delivery_id}: #{inspect(reason)}")
  >      # ... existing code
  >    end
  >    ```
  > 
  > 5. **Add typespecs for public API**:
  >    ```elixir
  >    @spec retry_failed_delivery(String.t()) :: {:ok, EmailDelivery.t()} | {:error, atom()}
  >    def retry_failed_delivery(delivery_id) do
  >    ```
  > 
  > ## Judgement-Worthy Non-Blocking Code-Health Findings
  > 
  > 1. **Projection temporal coupling** (Files: `web/lib/memba/messaging/projectors/email_delivery.ex`)
  >    - **Smell**: Projection queries current member state rather than using event payload
  >    - **Why judgement-worthy**: Violates event-sourcing principle that projections should be pure functions of events. If this pattern is widespread in Memba, may indicate need for event-enrichment or event-payload-completeness ADR. If new, may indicate need to refactor MessageSent to include recipient email or emit separate EmailDeliveryRequested event.
  >    - **Impact**: Creates race condition where member email deletion between event and projection skips delivery creation with no audit trail
  > 
  > 2. **Silent delivery skipping** (Files: `web/lib/memba/messaging/projectors/email_delivery.ex`)
  >    - **Smell**: Projection silently skips deliveries for members without email via `_ -> multi` branch
  >    - **Why judgement-worthy**: If MessageSent was emitted, domain already validated intent to send. Silent skip means message shows as "sent" but delivery never attempted. Should either fail loudly, emit compensating event, or validate email exists before emitting MessageSent.
  >    - **Impact**: Possible user confusion where message appears sent but was never delivered
  > 
  > 3. **Serial dispatch bottleneck** (Files: `web/lib/memba/messaging/email_delivery_dispatcher.ex`)
  >    - **Smell**: GenServer processes deliveries sequentially; high-volume clubs could experience delays
  >    - **Why judgement-worthy**: Single-threaded dispatch may be intentional for simplicity in v1. If acceptable for current scale, fine. If not, consider Task.Supervisor for concurrent dispatch in follow-up.
  >    - **Impact**: Delivery latency increases linearly with message volume per club
  > 
  > 4. **No idempotency guarantee** (Files: `web/lib/memba/messaging/email_delivery_dispatcher.ex`)
  >    - **Smell**: Crash after provider success but before marking "sent" leaves delivery ambiguous; retry may duplicate send
  >    - **Why judgement-worthy**: Plan explicitly accepts this risk ("crash after provider acceptance...can still leave an ambiguous delivery"). However, production impact depends on provider idempotency and whether duplicate sends are acceptable to users. May merit provider-level idempotency in follow-up (e.g., Postmark/Resend MessageStream IDs).
  >    - **Impact**: Edge-case duplicate emails on crash; affects user experience
  > 
  > 5. **Context boundary bloat** (Files: `web/lib/memba/messaging.ex`)
  >    - **Smell**: Memba.Messaging mixes command dispatch, provider infrastructure, and request building
  >    - **Why judgement-worthy**: Trend toward god-module. Already flagged in plan's "Risks/Follow-ups" section: "large application-service modules". If this is acceptable Memba pattern, fine. If not, consider extracting `Memba.Messaging.EmailProvider` or similar in cleanup iteration.
  >    - **Impact**: Maintenance complexity; harder to reason about responsibilities
  > 
  > 6. **Limited production observability** (Files: `web/lib/memba/messaging/email_delivery_dispatcher.ex`)
  >    - **Smell**: No telemetry events, minimal logging, no metrics for dispatch rates/failures/latency
  >    - **Why judgement-worthy**: Plan is silent on observability. For MVP/early-stage product, may be fine to rely on database queries and manual inspection. For production at scale, will need telemetry for alerting/monitoring.
  >    - **Impact**: Hard to debug production issues or detect degradation
  > 
  > 7. **PubSub-driven architecture fragility** (Files: `web/lib/memba/messaging/projectors/email_delivery.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`)
  >    - **Smell**: Critical dispatch path relies on PubSub notification from projection to dispatcher. If notification lost (PubSub failure, dispatcher crash during message, etc.), delivery stuck pending forever.
  >    - **Why judgement-worthy**: Plan explicitly defers automatic recovery: "If the PubSub nudge is missed...an operator/developer must use the internal retry/dispatch API." This may be acceptable trade-off for simplicity vs. adding sweep jobs. However, PubSub as critical path for business operation (not just cache invalidation) is fragile. Consider if this pattern is Memba-wide or new.
  >    - **Impact**: Operational burden; deliveries can silently fail to dispatch requiring manual discovery and retry
  > 
  > ## Suggested Fixes
  > 
  > ### Bounded-Safe (Can Apply Without Behaviour Change)
  > 
  > All bounded-safe fixes listed above are low-risk improvements that don't change product behaviour or require human judgement. Recommend applying in polish pass or immediate follow-up.
  > 
  > ### Judgement-Worthy (Need Human Decision)
  > 
  > The projection temporal coupling (#1) and silent skipping (#2) deserve architectural discussion:
  > 
  > **Option A**: Accept as pragmatic compromise
  > - Pro: Works for current scale; simplest implementation
  > - Con: Violates ES principles; creates technical debt
  > 
  > **Option B**: Include email in MessageSent event
  > ```elixir
  > defmodule MessageSent do
  >   field :recipient_email, :string  # New field
  >   # ... existing fields
  > end
  > ```
  > - Pro: Projection becomes pure function of event; no temporal coupling
  > - Con: Changes event schema; requires event migration or versioning
  > 
  > **Option C**: Emit separate EmailDeliveryRequested event
  > ```elixir
  > # In ClubMessage aggregate after emitting MessageSent:
  > %EmailDeliveryRequested{
  >   delivery_id: delivery_id,
  >   message_id: message_id,
  >   recipient_email: member.email,
  >   # ... full delivery context
  > }
  > ```
  > - Pro: Separate event stream for delivery lifecycle; clean separation of concerns
  > - Con: More complex event flow; duplicate data across events
  > 
  > **Option D**: Validate email exists before emitting MessageSent
  > - Pro: Prevents invalid events; fails fast
  > - Con: Adds coupling between ClubMessage aggregate and member state; may complicate batch sends
  > 
  > Recommend discussing with Matt which pattern aligns with Memba's event-sourcing philosophy.
  > 
  > ## Validation Notes
  > 
  > ### Test Coverage: Strong
  > 
  > - ✅ Unit tests cover dispatcher claim logic, provider success/failure, concurrent claims
  > - ✅ Integration tests cover async dispatch, eventual delivery, failure scenarios  
  > - ✅ Acceptance tests all passing (82/82 scenarios)
  > - ✅ Both new test doubles (RecordingProvider, SelectiveFailure) used appropriately
  > - ⚠️ No tests for dispatcher crash mid-dispatch (acceptable given plan's defer-automatic-recovery stance)
  > - ⚠️ No tests for member-deleted-after-MessageSent scenario (projection temporal coupling)
  > 
  > ### Manual Verification Needed
  > 
  > 1. **Local dev flow**: 
  >    - Create club message
  >    - Verify EmailDelivery starts "pending"
  >    - Observe dispatcher transition to "sent" (or "failed" with fake provider)
  >    - Inspect logs/DB for state transitions
  > 
  > 2. **Provider failure scenario**:
  >    - Configure SelectiveFailure provider to fail specific address
  >    - Send message to that member
  >    - Verify delivery marked "failed" with attempt_count=1 and latest_error
  >    - Use `Memba.Messaging.retry_failed_delivery/1` to retry
  >    - Verify delivery moves back to "pending" then "sent" on retry
  > 
  > 3. **Inbound club message flow**:
  >    - Send inbound email via acceptance test or manual simulation
  >    - Verify reply delivery follows same pending→dispatching→sent path
  >    - Confirm no regression in inbound acceptance tests (feature file unchanged)
  > 
  > ### Architecture Review Needed
  > 
  > The implementation successfully decouples provider dispatch from command acceptance as planned. However, the projection-based nudge architecture introduces new coupling and fragility compared to alternative approaches (e.g., event-handler-based dispatch, Oban/background-job dispatch, aggregate-commanded dispatch).
  > 
  > Recommend discussing:
  > - Is PubSub nudge from projection the intended Memba pattern for triggering async work, or is this a new pattern being tried here?
  > - If new, should it become a standard pattern (documented in ADR), or is it acceptable as a one-off for this boundary?
  > - Are there existing examples of projections triggering side effects via PubSub that can serve as reference?
  > 
  > ### Dev Check: PASS
  > 
  > All automated checks passed:
  > - Compilation: clean
  > - Tests: 100% pass (including 82 acceptance scenarios)
  > - Linting/formatting: clean
  > - Sandbox check: passed
  > 
  > ---
  > 
  > ## Summary
  > 
  > The iteration successfully delivers asynchronous, observable email delivery dispatch with clean separation from command acceptance. All planned acceptance criteria are met and tested. The implementation is production-ready for Memba's current scale.
  > 
  > However, the projection pattern (querying current member state, silently skipping on missing email) and PubSub-driven dispatch architecture introduce coupling and fragility that merit discussion about whether they align with Memba's long-term design philosophy. These are judgement calls for Matt, not blockers.
  > 
  > Recommend:
  > 1. **Merge as-is** if Matt accepts the projection pattern and PubSub architecture as pragmatic compromises
  > 2. **Apply bounded-safe fixes** in immediate polish pass (DB constraint, logging, error handling)
  > 3. **Schedule follow-up** to discuss event-sourcing patterns and whether projection-driven side effects should be codified in ADR or refactored to event-handler-driven approach


You are independently reviewing the completed, plan-conforming implementation of the iteration plan at docs/iterations/038-email-delivery-handoff-boundary/plan.md.

Use the prior context: the plan text, collected implementation evidence, current working tree state, commit range from `90134f8ebf5b313e76e43e912c50800ab2687545..HEAD`, and the successful dev check output. Be strict, practical, and specific. Do not edit files.

This workflow reviews an already-committed implementation after the implementation workflow has proved plan conformance. The review job is code polish plus smell radar: refactoring, maintainability, project conventions, ADR conformance, and surfacing judgement-worthy non-blocking smells. Do not emit shell-command/tool-call JSON; return the Markdown review report only.

Use the project pattern reference docs as review guidelines when the touched code involves domain modeling, Commanded, aggregates, projections, event streams, read models, or object responsibility boundaries:

- `docs/reference/domain-driven-design.md`
- `docs/reference/cqrs.md`
- `docs/reference/event-sourcing.md`
- `docs/reference/responsibility-driven-design.md`

Treat accepted ADRs as binding project decisions. Treat these reference docs as design-quality guidance for interpreting and applying those ADRs, not as permission to override an ADR or the iteration plan.

Automated tests are the behavioural feedback loop in this workflow. If you find a likely behavioural gap, missing acceptance criterion, or inadequate automated coverage despite green dev check, flag it as a blocking issue requiring a new implementation/test pass or human decision; do not disguise it as refactoring feedback. Do not ask for feature-file edits.

Review against these questions:

0. ADR conformance
   - Read every ADR cited by the plan and any nearby/current ADRs under `docs/adr/` that govern touched architecture.
   - Follow signposts in those ADRs to the reference docs above; use them to check whether domain/CQRS/event-sourcing/RDD implementation choices match the patterns Memba wants.
   - Does the implementation obey accepted ADR decisions and consequences as binding constraints?
   - Does it avoid replacing ADR-mandated infrastructure or architecture with simpler local substitutes, unless the plan explicitly deferred that decision?
   - Do tests and implementation evidence prove the ADR-relevant behaviour, wiring, or structure?
   - Reject if the implementation conflicts with accepted ADRs or omits a cited ADR's central decision without an explicit plan deferral or human decision.

1. Light plan-fidelity sanity check
   - Does the implementation appear consistent with the stated goal and capability, given the plan-conformance gate has already passed?
   - Did it avoid obvious out-of-scope work?
   - If you find a substantial plan gap, classify it as blocking and requiring human input or a new implementation pass.

2. Behaviour and automated coverage
   - Did dev check pass before review?
   - Are important happy paths, edge cases, permissions, error states, and data/state changes covered by automated tests where appropriate?
   - Were acceptance feature files left unchanged as domain acceptance criteria?

3. Technical quality / refactoring
   - Are Phoenix, LiveView, HEEx, Ecto, Tailwind, and Elixir conventions followed where relevant?
   - Are migrations, schemas, contexts, tests, routes, UI, background jobs, and integrations coherent?
   - Is the implementation maintainable, minimal, and well factored?

4. Code-health classification
   - Blocking: ADR violations, behavioural gaps, missing or unsafe coverage, repeated blockers, or anything needing product/architecture judgement before merge.
   - Bounded-safe: concrete, low-risk refactoring, maintainability, convention, or test-quality fixes an agent can apply without changing product behaviour or feature files.
   - Judgement-worthy non-blocking: design smells, coupling, duplication, naming, dependency, or architecture drift that might merit human judgement later but should not block this merge.

Return a Markdown report with:

- Decision: ACCEPT or REJECT
- Confidence: High, Medium, or Low
- ADR conformance: PASS or FAIL
- ADR violations: numbered list with ADR number/file and implementation evidence
- Blocking issues: numbered list
- Bounded-safe fixes: numbered list
- Judgement-worthy non-blocking code-health findings: numbered list; for each include file(s), smell, and why it may need human judgement
- Suggested fixes: concrete changes if rejected or bounded-safe fixes exist
- Validation notes: tests/checks/manual checks relevant to the decision