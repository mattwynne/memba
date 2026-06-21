Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KVMJ25ZA75KV5A0DPJ4A6X2D
Pipeline progress: 10 of 27 stages completed

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

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 8.1k in / 4.3k out
- Response:
  > # Iteration 038 Review: Email Delivery Handoff Boundary
  > 
  > ## Decision: ACCEPT
  > 
  > ## Confidence: Medium
  > 
  > The implementation appears to satisfy the iteration goal: outbound email provider dispatch has been moved behind an asynchronous `EmailDelivery` lifecycle, `send_club_message/2` is no longer coupled to provider availability, failed dispatches are observable, and manual/internal retry exists. `dev ci` passed, including the full acceptance suite.
  > 
  > Confidence is medium rather than high because the main remaining concerns are architectural/code-health judgement calls around projection purity, PubSub-driven dispatch, and failure recovery semantics rather than obvious behavioural failures.
  > 
  > ## ADR conformance: PASS
  > 
  > No ADR violation is evident from the supplied implementation evidence.
  > 
  > The plan itself did not cite a specific ADR. The implementation appears consistent with the intended Commanded/CQRS/event-sourced architecture in the broad sense: domain command acceptance remains separate from read-model/projection state, and provider delivery is represented as read-model dispatch lifecycle rather than as synchronous command handling.
  > 
  > The reference-doc-level concerns below — especially projection temporal coupling and PubSub as a business-process nudge — are worth human judgement, but I do not see enough evidence to classify them as binding ADR failures.
  > 
  > ## ADR violations
  > 
  > 1. None identified.
  > 
  > ## Blocking issues
  > 
  > 1. None.
  > 
  > The implementation is plan-conforming enough to merge from this review perspective. I did not find a behavioural gap that requires a new implementation pass before merge.
  > 
  > ## Bounded-safe fixes
  > 
  > 1. **Mark or move provider-dispatch helpers that remain on `Memba.Messaging`**
  >    - File: `web/lib/memba/messaging.ex`
  >    - If `deliver_to_provider/1` or request-building helpers remain public on the context but are now dispatcher-only implementation details, mark them `@doc false`, make them private where possible, or move them behind `Memba.Messaging.EmailDeliveryDispatcher` / a focused collaborator.
  >    - This reduces accidental external coupling to what should now be infrastructure internals.
  > 
  > 2. **Add structured logging around dispatch success/failure/retry**
  >    - File: `web/lib/memba/messaging/email_delivery_dispatcher.ex`
  >    - Low-risk observability improvement:
  >      - delivery claimed
  >      - provider success
  >      - provider error
  >      - retry requested
  >      - claim skipped because status changed
  >    - Include `delivery_id`, `message_id`, provider module, status, and sanitized error/detail where appropriate.
  > 
  > 3. **Defensively normalize provider exceptions into failed dispatches**
  >    - File: `web/lib/memba/messaging/email_delivery_dispatcher.ex`
  >    - The plan covers provider errors, and provider adapters likely return `{:error, reason}`. Still, provider boundaries are a reasonable place to rescue/log unexpected exceptions and mark the delivery `failed` with diagnostics rather than crashing the dispatcher and leaving a record indefinitely in `dispatching`.
  >    - This should be done carefully so programming errors remain visible in logs.
  > 
  > 4. **Centralize valid email delivery statuses**
  >    - Files likely involved:
  >      - `web/lib/memba/messaging/email_delivery.ex`
  >      - `web/lib/memba/messaging/projectors/email_delivery.ex`
  >      - migrations / tests / views that reference statuses
  >    - If statuses are currently repeated across schema validation, dispatcher clauses, UI/status labels, tests, and migrations, extract a single status vocabulary module or schema constant.
  >    - This helps avoid drift between lifecycle statuses: `pending`, `dispatching`, `sent`, `failed`, and preserved webhook/provider statuses.
  > 
  > 5. **Consider a DB-level check constraint if the status vocabulary is already stable**
  >    - File: relevant migration for `email_deliveries`
  >    - The plan allowed “database constraints or schema validation.” Schema validation is acceptable, but a check constraint would provide better protection for operational/manual updates.
  >    - This is bounded-safe only if the full existing status vocabulary is known and centralized; avoid hand-copying a partial list that could reject historical/provider webhook statuses.
  > 
  > ## Judgement-worthy non-blocking code-health findings
  > 
  > 1. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`**
  >    - **Smell:** Projection appears to query current member state to obtain email data when handling `MessageSent`.
  >    - **Why it may need judgement:** In event-sourced systems, projections are usually most reliable when they are deterministic functions of event data. Querying current membership state introduces temporal coupling: the projected delivery can differ depending on when the projector runs relative to member email changes/deletions.
  >    - **Why not blocking:** This may already be an accepted Memba trade-off, and the iteration plan explicitly chose to use existing `EmailDelivery` records rather than introduce a new delivery-request event/table.
  > 
  > 2. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`**
  >    - **Smell:** Missing/blank member email may silently skip creating an `EmailDelivery`.
  >    - **Why it may need judgement:** If the domain has accepted/recorded `MessageSent`, silently skipping the delivery read model can make the system appear to have sent a message with no attempted delivery or diagnostic record.
  >    - **Potential follow-up:** Consider whether “no deliverable email address” should become an explicit failed/undeliverable delivery record, a command preflight failure, or enriched event data.
  > 
  > 3. **File(s): `web/lib/memba/messaging/email_delivery_dispatcher.ex`, `web/lib/memba/messaging/projectors/email_delivery.ex`**
  >    - **Smell:** Business dispatch depends on a PubSub/read-model-change nudge.
  >    - **Why it may need judgement:** The plan explicitly accepts no startup sweep, no periodic sweep, and manual intervention if nudges are missed. That is acceptable for this slice, but PubSub is a fragile trigger for durable business work unless paired with recovery/sweeping.
  >    - **Potential follow-up:** Decide whether this should remain a one-off pragmatic pattern or be formalized/hardened with a durable dispatcher sweep/job in a later iteration.
  > 
  > 4. **File(s): `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
  >    - **Smell:** Deliveries can likely remain indefinitely in `dispatching` if the process crashes after claim but before marking `sent`/`failed`.
  >    - **Why it may need judgement:** The plan explicitly accepts ambiguity after provider acceptance, but stale `dispatching` before or during provider dispatch is a separate operational state operators will need to understand.
  >    - **Potential follow-up:** Add an internal “requeue stale dispatching delivery” API, or include `dispatching_started_at`/timeout handling in a future retry/sweep iteration.
  > 
  > 5. **File(s): `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
  >    - **Smell:** Single GenServer dispatch path serializes provider calls.
  >    - **Why it may need judgement:** This is simple and appropriate for a first handoff boundary, but it can become a throughput bottleneck for large clubs or bulk sends.
  >    - **Potential follow-up:** If volume grows, use supervised tasks or a job system while preserving the same claim/update lifecycle.
  > 
  > 6. **File(s): `web/lib/memba/messaging.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
  >    - **Smell:** Messaging context may still mix command orchestration, read-model queries, delivery provider infrastructure, and retry/dispatch APIs.
  >    - **Why it may need judgement:** The plan already lists large application-service modules as a follow-up concern. This iteration improves the boundary but may not fully isolate provider infrastructure from the context API.
  >    - **Potential follow-up:** Extract a focused delivery dispatch/service module and keep `Memba.Messaging` as a thinner facade.
  > 
  > 7. **File(s): provider adapters / dispatcher request-building code**
  >    - **Smell:** Provider-level idempotency does not appear to be enforced.
  >    - **Why it may need judgement:** The plan explicitly accepts possible duplicate sends after provider acceptance and before marking `sent`. That is fine for this slice, but it is user-visible if it happens in production.
  >    - **Potential follow-up:** Use `delivery_id` as a provider idempotency/custom metadata key where Postmark/Resend support it.
  > 
  > 8. **File(s): staff/member delivery presentation files**
  >    - **Smell:** New infrastructure statuses may leak into user-facing presentation if labels are shared too broadly.
  >    - **Why it may need judgement:** The plan wanted member-facing screens to hide/soften infrastructure detail while staff/operator views may show exact diagnostics.
  >    - **Potential follow-up:** Keep separate member-facing and staff-facing status-label helpers if they are not already separate.
  > 
  > ## Suggested fixes
  > 
  > Recommended non-blocking polish before or soon after merge:
  > 
  > 1. Add `Logger` instrumentation to dispatcher claim/success/failure/retry paths.
  > 2. Mark dispatcher-only context functions as `@doc false` or move them into the dispatcher/collaborator module.
  > 3. Add exception-to-failed-delivery handling around provider calls, with clear error logging.
  > 4. Centralize status vocabulary and, if safe, back it with a DB check constraint.
  > 5. Create a follow-up ticket for stale `dispatching` recovery and/or durable sweep semantics.
  > 
  > No feature-file changes are recommended.
  > 
  > ## Validation notes
  > 
  > - `dev ci` passed successfully.
  > - Full browser acceptance suite passed:
  >   - 82 scenarios
  >   - 493 steps
  > - The implementation evidence indicates coverage around:
  >   - pending email delivery creation
  >   - dispatcher claiming
  >   - provider success path
  >   - provider failure path
  >   - failed-delivery diagnostics
  >   - manual retry
  >   - fake/selective-failure provider seams
  >   - inbound club-message flow using the same delivery path
  > - No blocking acceptance-criteria gap was identified.
  > - Manual checks still worth doing operationally:
  >   1. Send a local/dev club message with the fake provider and observe `pending → dispatching → sent`.
  >   2. Force provider failure and confirm `failed`, `attempt_count`, and latest error/detail are persisted.
  >   3. Retry a failed delivery and confirm it returns to the dispatch path without creating duplicate local delivery records.
  >   4. Inspect member-facing and staff-facing delivery views for appropriate status wording.

## Stage: gemini_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 10.6k in / 2.7k out
- Response:
  > # Iteration 038 Review: Email Delivery Handoff Boundary
  > 
  > ## Decision: ACCEPT
  > 
  > ## Confidence: Medium
  > 
  > The implementation appears to deliver the intended handoff boundary: message acceptance is no longer synchronously coupled to provider availability, `EmailDelivery` records now model an explicit dispatch lifecycle, provider failures are persisted as delivery diagnostics, and a manual/internal retry path exists. The completed `dev ci`/dev check passed, including the browser acceptance suite.
  > 
  > Confidence is medium because the remaining concerns are mostly architectural/code-health judgement calls around projection determinism, PubSub-triggered durable work, and operational recovery semantics rather than clear behavioural defects.
  > 
  > ## ADR conformance: PASS
  > 
  > The iteration plan does not cite a specific ADR. Based on the supplied implementation evidence and the plan’s explicit design decisions, I did not identify a binding ADR conflict.
  > 
  > The implementation is broadly consistent with the CQRS/event-sourced direction: command acceptance remains distinct from read-model/provider dispatch, and provider interaction has been moved behind an explicit async lifecycle. Some choices are event-sourcing/code-health smells — especially projection-time member lookups and PubSub as the dispatch trigger — but the plan intentionally selected existing `EmailDelivery` records and a supervised PubSub-nudged dispatcher for this slice. I would not reject on those grounds without a specific accepted ADR forbidding the pattern.
  > 
  > ## ADR violations
  > 
  > 1. None identified from the available plan and implementation evidence.
  > 
  > ## Blocking issues
  > 
  > 1. None.
  > 
  > The implementation appears plan-conforming enough to merge. I did not find a substantial missing acceptance criterion, behavioural gap, or unsafe test omission that should require a new implementation pass before merge.
  > 
  > ## Bounded-safe fixes
  > 
  > 1. **Mark dispatcher-only context helpers as internal or move them behind the dispatcher boundary**
  >    - File: `web/lib/memba/messaging.ex`
  >    - If `deliver_to_provider/1` and request-building helpers remain public on `Memba.Messaging` only for dispatcher use, mark them `@doc false`, add typespecs, or move them into `Memba.Messaging.EmailDeliveryDispatcher` / a focused collaborator.
  >    - This is a low-risk boundary polish that reduces accidental coupling to provider infrastructure.
  > 
  > 2. **Add structured dispatcher logging**
  >    - File: `web/lib/memba/messaging/email_delivery_dispatcher.ex`
  >    - Add `Logger` entries for:
  >      - delivery claimed
  >      - claim skipped because status changed
  >      - provider success
  >      - provider error
  >      - failed delivery retried/requeued
  >    - Include useful fields such as `delivery_id`, `message_id`, provider module, prior/new status, and sanitized error detail.
  >    - This does not change product behaviour and will help operators understand the new async lifecycle.
  > 
  > 3. **Centralize email delivery status vocabulary**
  >    - Files likely involved:
  >      - `web/lib/memba/messaging/email_delivery.ex`
  >      - `web/lib/memba/messaging/email_delivery_dispatcher.ex`
  >      - `web/lib/memba/messaging/projectors/email_delivery.ex`
  >      - delivery presentation helpers/tests
  >    - If statuses are currently repeated as string literals, extract schema-level constants or a small vocabulary helper for lifecycle/provider statuses.
  >    - This reduces drift between validation, UI labels, dispatcher clauses, tests, and any future DB constraints.
  > 
  > 4. **Add a DB check constraint only if the full status vocabulary is already known**
  >    - File: relevant `email_deliveries` migration.
  >    - The plan allowed “database constraints or schema validation.” If schema validation already exists, this is not required for merge.
  >    - A DB constraint would be safe only if it includes all existing and preserved webhook/provider statuses. Avoid hand-copying a partial list that could reject historical or provider-originated states.
  > 
  > 5. **Add typespecs for new public/internal retry and dispatch APIs**
  >    - Files:
  >      - `web/lib/memba/messaging.ex`
  >      - `web/lib/memba/messaging/email_delivery_dispatcher.ex`
  >    - Useful candidates include retry APIs, claim/dispatch entry points, and provider request builders.
  >    - This is small maintainability polish for the new boundary.
  > 
  > ## Judgement-worthy non-blocking code-health findings
  > 
  > 1. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`**
  >    - **Smell:** The `EmailDelivery` projector appears to query current member state to derive recipient email/address data while handling `MessageSent`.
  >    - **Why it may need human judgement:** In an event-sourced system, projections are usually healthiest when they are deterministic functions of the event stream. Querying current read-model/domain state introduces temporal coupling: replay or delayed projection can produce different delivery records depending on member email changes, deletion, or projection timing.
  >    - **Why not blocking:** The iteration plan explicitly chose to use existing `EmailDelivery` records and did not require event enrichment or a new delivery-request event. This may be an accepted pragmatic trade-off for this slice.
  > 
  > 2. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`**
  >    - **Smell:** Missing or blank member email can apparently cause the projector to skip creating an `EmailDelivery`.
  >    - **Why it may need human judgement:** If the domain has recorded `MessageSent`, silently having no local delivery/diagnostic record may make operator reasoning harder: a message appears accepted/sent, but no dispatch attempt or failure record exists.
  >    - **Potential follow-up:** Decide whether “no deliverable recipient address” should be represented as an explicit failed/undeliverable delivery record, prevented before `MessageSent`, or solved by including recipient delivery data in the event.
  > 
  > 3. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
  >    - **Smell:** Provider dispatch depends on a PubSub/read-model-change nudge.
  >    - **Why it may need human judgement:** The plan explicitly deferred automatic retry, startup sweeps, and periodic sweeps. That makes PubSub acceptable for this slice, but it is still a fragile trigger for durable business work: if a nudge is missed while a delivery is `pending`, dispatch can stall until manual intervention.
  >    - **Potential follow-up:** Decide whether this pattern should be codified as a Memba convention, replaced by a durable job/sweep mechanism, or hardened in a later iteration.
  > 
  > 4. **File(s): `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
  >    - **Smell:** Deliveries can remain indefinitely in `dispatching` if the process crashes after claim but before marking `sent` or `failed`.
  >    - **Why it may need human judgement:** The plan explicitly accepts ambiguity after provider acceptance, but stale `dispatching` before/during provider dispatch is a distinct operational state. Operators need a way to recognize and safely recover it.
  >    - **Potential follow-up:** Add a manual “requeue stale dispatching delivery” API or a later sweep/timeout process.
  > 
  > 5. **File(s): `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
  >    - **Smell:** Dispatch appears serialized through a single GenServer/process.
  >    - **Why it may need human judgement:** This is simple and likely appropriate for an initial boundary, but bulk sends or large clubs could experience provider-call latency accumulating linearly.
  >    - **Potential follow-up:** If volume requires it, preserve the claim/update lifecycle while moving provider calls to supervised tasks or a durable job system.
  > 
  > 6. **File(s): `web/lib/memba/messaging.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
  >    - **Smell:** The `Memba.Messaging` context may still carry mixed responsibilities: command orchestration, read-model access, provider request building, dispatch support, and retry APIs.
  >    - **Why it may need human judgement:** The iteration improves the most important coupling by removing synchronous provider delivery from `send_club_message/2`, but the context can still drift toward an application-service god module.
  >    - **Potential follow-up:** Extract a focused delivery handoff/request-building module and keep `Memba.Messaging` as a thin facade.
  > 
  > 7. **File(s): provider adapters and dispatcher request-building code**
  >    - **Smell:** Provider-level idempotency does not appear to be enforced.
  >    - **Why it may need human judgement:** The plan explicitly accepts possible duplicate sends after provider acceptance and before marking `sent`. That is fine for this slice but remains user-visible if it happens in production.
  >    - **Potential follow-up:** Use `delivery_id` as provider metadata/idempotency where Postmark/Resend support it.
  > 
  > 8. **File(s): member/staff delivery presentation helpers or templates**
  >    - **Smell:** New infrastructure statuses such as `pending`, `dispatching`, and `failed` can leak into user-facing language if staff/member labels share helpers too broadly.
  >    - **Why it may need human judgement:** The plan wanted member-facing screens to hide or soften infrastructure detail while staff/operator views may show exact diagnostics.
  >    - **Potential follow-up:** Keep separate presentation helpers for member-facing status labels versus operator diagnostics.
  > 
  > ## Suggested fixes
  > 
  > Recommended polish before or shortly after merge:
  > 
  > 1. Add structured logging to dispatcher claim/success/failure/retry paths.
  > 2. Mark dispatcher-only context functions as `@doc false` or move them to a focused dispatch/request-building module.
  > 3. Centralize the status vocabulary to avoid string-literal drift.
  > 4. Add typespecs for the new retry/dispatch/public boundary functions.
  > 5. Create follow-up work for:
  >    - stale `dispatching` recovery,
  >    - durable pending-delivery sweep/retry semantics,
  >    - projection determinism / event enrichment for delivery recipient data,
  >    - provider-level idempotency using `delivery_id`.
  > 
  > ## Validation notes
  > 
  > - `dev ci` / dev check passed before review.
  > - Full browser acceptance suite passed:
  >   - 82 scenarios
  >   - 493 steps
  > - The supplied evidence indicates automated coverage around:
  >   - pending delivery creation,
  >   - dispatcher claim logic,
  >   - provider success path,
  >   - provider failure path,
  >   - attempt count and latest error/detail persistence,
  >   - manual failed-delivery retry,
  >   - fake/selective-failure provider seams,
  >   - inbound club-message flow using the same delivery path.
  > - No feature-file changes are recommended.
  > - Useful manual/operator checks after merge:
  >   1. Send a local/dev club message with the fake provider and observe `pending → dispatching → sent`.
  >   2. Force provider failure and confirm `failed`, incremented attempt count, and persisted latest error/detail.
  >   3. Retry a failed delivery and confirm it re-enters dispatch without duplicate local delivery records.
  >   4. Inspect member-facing and staff/operator delivery views for appropriate status wording and diagnostics.

## Stage: synthesize_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 13.4k in / 1.8k out
- Response:
  > {
  >   "context_updates": {
  >     "implementation_accepted": false,
  >     "review_fixes_available": true,
  >     "review_blockers": [
  >       {
  >         "id": "dispatcher-boundary-observability",
  >         "title": "Polish email delivery dispatcher boundary and observability",
  >         "source": "review_synthesis",
  >         "first_seen_stage": "synthesize_review",
  >         "status": "open"
  >       },
  >       {
  >         "id": "provider-exception-to-failed-delivery",
  >         "title": "Normalize unexpected provider exceptions into failed delivery diagnostics",
  >         "source": "review_synthesis",
  >         "first_seen_stage": "synthesize_review",
  >         "status": "open"
  >       },
  >       {
  >         "id": "email-delivery-status-vocabulary-integrity",
  >         "title": "Centralize and harden email delivery status vocabulary",
  >         "source": "review_synthesis",
  >         "first_seen_stage": "synthesize_review",
  >         "status": "open"
  >       }
  >     ]
  >   }
  > }

## Stage: review_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: review_gate

## Stage: snapshot_before_review_repair
- Status: succeeded
- Handler: command
- Script: `set -eu
mkdir -p .fabro/tmp
kind='review'
git diff --binary > ".fabro/tmp/${kind}-repair-before.patch"
git diff --name-only > ".fabro/tmp/${kind}-repair-before-files.txt"
git diff --stat > ".fabro/tmp/${kind}-repair-before-stat.txt" || true
printf 'Repair baseline (%s) captured.\n' "$kind"`
- Output:
  ```
  Repair baseline (review) captured.
  ```

## Current context
| Key | Value |
|-----|-------|
| implementation_accepted | false |
| review_blockers | [{"id":"dispatcher-boundary-observability","title":"Polish email delivery dispatcher boundary and observability","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"},{"id":"provider-exception-to-failed-delivery","title":"Normalize unexpected provider exceptions into failed delivery diagnostics","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"},{"id":"email-delivery-status-vocabulary-integrity","title":"Centralize and harden email delivery status vocabulary","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"}] |
| review_fixes_available | true |


Apply the automatic repair brief from the preceding Synthesize Review stage for docs/iterations/038-email-delivery-handoff-boundary/plan.md.

Rules:

- Fix only the concrete bounded issues selected by the review synthesis.
- Treat this as a post-green refactoring, maintainability, verification, and hardening pass. Do not add new product behaviour here.
- Stay within the iteration plan and do not introduce new product decisions.
- Enforce or prove existing intended behaviour when safe: add/strengthen automated tests, validation attributes, input normalization, constraints, comments, or small shared-service refactors when the synthesis selected them.
- Never edit acceptance feature files (`*.feature`, including files under `acceptance-tests/`). If a requested fix requires changing one, leave it unchanged and report it as a code-health/manual follow-up.
- Add or update automated tests whenever they are the safest bounded way to prove a reviewer concern about lifecycle reuse, authorization, duplicate handling, state transitions, or other already-planned behaviour.
- Do not skip or weaken existing validation.
- Do not commit changes.
- Review must never push red. If a fix proves unsafe, too large, judgement-heavy, or likely to regress behaviour, discard that fix, leave the code unchanged for that issue, and report it as a code-health/manual follow-up instead of forcing a change.
- Do not abandon a selected fix merely because it is a hardening or verification change. First try the smallest safe test/config/code change that addresses the concern within the existing design.
- **Sandbox/runtime boundary**: If the requested fix or failure appears caused by sandbox/toolchain/runtime incoherence (stale `/env` paths, unwritable caches, missing tools, broken services, stale process-compose state), stop and report a sandbox blocker. Do not patch `bin/dev`, application scripts, product code, dependencies, or tests merely to compensate for sandbox runtime defects.
- **If no changes were needed**: If after reviewing the issues you determine that no code/config/test changes are required, state that explicitly and provide clear justification for why the review issues do not require changes.

When finished, summarize:

1. Each review issue from the gate.
2. The concrete code/config/test changes made for each issue (or an explicit statement that no changes were needed with justification).
3. Files changed (grouped by issue addressed).
4. Tests run and their results.
5. Any remaining gaps or human questions.

Include an issue-to-fix mapping showing which files/modules/tests address each review issue.