# Iteration 038 Implementation Review

## Decision: ACCEPT

## Confidence: Medium

The implementation successfully delivers the planned capability and passes all automated tests. However, several architectural patterns warrant human judgement about whether they align with Memba's design philosophy and long-term maintainability goals.

## ADR Conformance: UNCERTAIN

I cannot definitively assess ADR conformance without access to the specific ADRs governing projections, read models, and async processing. The implementation evidence shows patterns that may conflict with strict event-sourcing and projection-responsibility principles, but these may be acceptable pragmatic compromises in Memba's context.

**Requires verification**: 
- Does Memba have an ADR governing projection responsibilities and whether projections may query current state vs. event payload?
- Does Memba have an ADR governing crash recovery and at-least-once delivery guarantees for async processes?

## ADR Violations: None Confirmed

Without the actual ADR texts, I cannot confirm violations. However, two patterns merit ADR cross-reference:

1. **EmailDelivery projection querying member state** (`web/lib/memba/messaging/projectors/email_delivery.ex`):
   ```elixir
   project(%MessageSent{} = event, _metadata, fn multi ->
     case Memba.ClubMemberships.get_member_by_id(event.member_id) do
       %{email: email} when is_binary(email) and email != "" ->
         # creates delivery
     _ ->
       multi  # silently skips if no email
     end
   end)
   ```
   - Projections querying current aggregate state (not event payload) creates temporal coupling
   - If member email changes/deletes between event emission and projection, results differ
   - Classic event-sourcing anti-pattern unless explicitly accepted by ADR
   - May violate projection-responsibility boundaries from `docs/reference/event-sourcing.md` and `docs/reference/responsibility-driven-design.md`

2. **Crash recovery gap** - The plan explicitly accepts crash-after-provider scenarios as requiring manual intervention, but doesn't address crash-during-dispatch leaving deliveries in "dispatching" limbo. If Memba has an ADR requiring resilient async processing, this may violate it.

## Blocking Issues: None

The implementation meets all stated acceptance criteria. The concerns below are architectural/robustness issues that should be considered for follow-up, not blockers for this merge given the plan's explicit trade-offs.

## Bounded-Safe Fixes

1. **Add database constraint on email_deliveries.status**:
   ```elixir
   # In migration:
   create constraint(:email_deliveries, :valid_status,
     check: "status IN ('pending', 'dispatching', 'sent', 'failed', 'bounced', 'delivered', 'opened', 'clicked', 'complained', 'unsubscribed')"
   )
   ```
   Plan step 3 says "Add database constraints or schema validation for the expanded status vocabulary where practical". Schema validation exists but DB constraint provides defense in depth.

2. **Make deliver_to_provider/1 internal or move to dispatcher**:
   ```elixir
   # In Memba.Messaging:
   @doc false
   def deliver_to_provider(%EmailDelivery{} = delivery) do
   ```
   This function is only meant to be called by the dispatcher, not public API. Mark as internal or move to dispatcher module.

3. **Add defensive error handling in dispatcher**:
   ```elixir
   def handle_info({:email_delivery_created, %EmailDelivery{status: "pending"} = delivery}, state) do
     try do
       dispatch(delivery)
     rescue
       e ->
         Logger.error("Dispatcher crash for delivery #{delivery.delivery_id}: #{inspect(e)}")
         # Delivery stays "dispatching" - manual retry required as per plan
     end
     {:noreply, state}
   end
   ```
   Prevents dispatcher crash from taking down the GenServer, though delivery still requires manual intervention.

4. **Add logging for observability**:
   ```elixir
   defp handle_dispatch_result(delivery, :ok) do
     Logger.info("Successfully dispatched delivery #{delivery.delivery_id}")
     # ... existing code
   end

   defp handle_dispatch_result(delivery, {:error, reason}) do
     Logger.warning("Failed to dispatch delivery #{delivery.delivery_id}: #{inspect(reason)}")
     # ... existing code
   end
   ```

5. **Add typespecs for public API**:
   ```elixir
   @spec retry_failed_delivery(String.t()) :: {:ok, EmailDelivery.t()} | {:error, atom()}
   def retry_failed_delivery(delivery_id) do
   ```

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Projection temporal coupling** (Files: `web/lib/memba/messaging/projectors/email_delivery.ex`)
   - **Smell**: Projection queries current member state rather than using event payload
   - **Why judgement-worthy**: Violates event-sourcing principle that projections should be pure functions of events. If this pattern is widespread in Memba, may indicate need for event-enrichment or event-payload-completeness ADR. If new, may indicate need to refactor MessageSent to include recipient email or emit separate EmailDeliveryRequested event.
   - **Impact**: Creates race condition where member email deletion between event and projection skips delivery creation with no audit trail

2. **Silent delivery skipping** (Files: `web/lib/memba/messaging/projectors/email_delivery.ex`)
   - **Smell**: Projection silently skips deliveries for members without email via `_ -> multi` branch
   - **Why judgement-worthy**: If MessageSent was emitted, domain already validated intent to send. Silent skip means message shows as "sent" but delivery never attempted. Should either fail loudly, emit compensating event, or validate email exists before emitting MessageSent.
   - **Impact**: Possible user confusion where message appears sent but was never delivered

3. **Serial dispatch bottleneck** (Files: `web/lib/memba/messaging/email_delivery_dispatcher.ex`)
   - **Smell**: GenServer processes deliveries sequentially; high-volume clubs could experience delays
   - **Why judgement-worthy**: Single-threaded dispatch may be intentional for simplicity in v1. If acceptable for current scale, fine. If not, consider Task.Supervisor for concurrent dispatch in follow-up.
   - **Impact**: Delivery latency increases linearly with message volume per club

4. **No idempotency guarantee** (Files: `web/lib/memba/messaging/email_delivery_dispatcher.ex`)
   - **Smell**: Crash after provider success but before marking "sent" leaves delivery ambiguous; retry may duplicate send
   - **Why judgement-worthy**: Plan explicitly accepts this risk ("crash after provider acceptance...can still leave an ambiguous delivery"). However, production impact depends on provider idempotency and whether duplicate sends are acceptable to users. May merit provider-level idempotency in follow-up (e.g., Postmark/Resend MessageStream IDs).
   - **Impact**: Edge-case duplicate emails on crash; affects user experience

5. **Context boundary bloat** (Files: `web/lib/memba/messaging.ex`)
   - **Smell**: Memba.Messaging mixes command dispatch, provider infrastructure, and request building
   - **Why judgement-worthy**: Trend toward god-module. Already flagged in plan's "Risks/Follow-ups" section: "large application-service modules". If this is acceptable Memba pattern, fine. If not, consider extracting `Memba.Messaging.EmailProvider` or similar in cleanup iteration.
   - **Impact**: Maintenance complexity; harder to reason about responsibilities

6. **Limited production observability** (Files: `web/lib/memba/messaging/email_delivery_dispatcher.ex`)
   - **Smell**: No telemetry events, minimal logging, no metrics for dispatch rates/failures/latency
   - **Why judgement-worthy**: Plan is silent on observability. For MVP/early-stage product, may be fine to rely on database queries and manual inspection. For production at scale, will need telemetry for alerting/monitoring.
   - **Impact**: Hard to debug production issues or detect degradation

7. **PubSub-driven architecture fragility** (Files: `web/lib/memba/messaging/projectors/email_delivery.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`)
   - **Smell**: Critical dispatch path relies on PubSub notification from projection to dispatcher. If notification lost (PubSub failure, dispatcher crash during message, etc.), delivery stuck pending forever.
   - **Why judgement-worthy**: Plan explicitly defers automatic recovery: "If the PubSub nudge is missed...an operator/developer must use the internal retry/dispatch API." This may be acceptable trade-off for simplicity vs. adding sweep jobs. However, PubSub as critical path for business operation (not just cache invalidation) is fragile. Consider if this pattern is Memba-wide or new.
   - **Impact**: Operational burden; deliveries can silently fail to dispatch requiring manual discovery and retry

## Suggested Fixes

### Bounded-Safe (Can Apply Without Behaviour Change)

All bounded-safe fixes listed above are low-risk improvements that don't change product behaviour or require human judgement. Recommend applying in polish pass or immediate follow-up.

### Judgement-Worthy (Need Human Decision)

The projection temporal coupling (#1) and silent skipping (#2) deserve architectural discussion:

**Option A**: Accept as pragmatic compromise
- Pro: Works for current scale; simplest implementation
- Con: Violates ES principles; creates technical debt

**Option B**: Include email in MessageSent event
```elixir
defmodule MessageSent do
  field :recipient_email, :string  # New field
  # ... existing fields
end
```
- Pro: Projection becomes pure function of event; no temporal coupling
- Con: Changes event schema; requires event migration or versioning

**Option C**: Emit separate EmailDeliveryRequested event
```elixir
# In ClubMessage aggregate after emitting MessageSent:
%EmailDeliveryRequested{
  delivery_id: delivery_id,
  message_id: message_id,
  recipient_email: member.email,
  # ... full delivery context
}
```
- Pro: Separate event stream for delivery lifecycle; clean separation of concerns
- Con: More complex event flow; duplicate data across events

**Option D**: Validate email exists before emitting MessageSent
- Pro: Prevents invalid events; fails fast
- Con: Adds coupling between ClubMessage aggregate and member state; may complicate batch sends

Recommend discussing with Matt which pattern aligns with Memba's event-sourcing philosophy.

## Validation Notes

### Test Coverage: Strong

- ✅ Unit tests cover dispatcher claim logic, provider success/failure, concurrent claims
- ✅ Integration tests cover async dispatch, eventual delivery, failure scenarios  
- ✅ Acceptance tests all passing (82/82 scenarios)
- ✅ Both new test doubles (RecordingProvider, SelectiveFailure) used appropriately
- ⚠️ No tests for dispatcher crash mid-dispatch (acceptable given plan's defer-automatic-recovery stance)
- ⚠️ No tests for member-deleted-after-MessageSent scenario (projection temporal coupling)

### Manual Verification Needed

1. **Local dev flow**: 
   - Create club message
   - Verify EmailDelivery starts "pending"
   - Observe dispatcher transition to "sent" (or "failed" with fake provider)
   - Inspect logs/DB for state transitions

2. **Provider failure scenario**:
   - Configure SelectiveFailure provider to fail specific address
   - Send message to that member
   - Verify delivery marked "failed" with attempt_count=1 and latest_error
   - Use `Memba.Messaging.retry_failed_delivery/1` to retry
   - Verify delivery moves back to "pending" then "sent" on retry

3. **Inbound club message flow**:
   - Send inbound email via acceptance test or manual simulation
   - Verify reply delivery follows same pending→dispatching→sent path
   - Confirm no regression in inbound acceptance tests (feature file unchanged)

### Architecture Review Needed

The implementation successfully decouples provider dispatch from command acceptance as planned. However, the projection-based nudge architecture introduces new coupling and fragility compared to alternative approaches (e.g., event-handler-based dispatch, Oban/background-job dispatch, aggregate-commanded dispatch).

Recommend discussing:
- Is PubSub nudge from projection the intended Memba pattern for triggering async work, or is this a new pattern being tried here?
- If new, should it become a standard pattern (documented in ADR), or is it acceptable as a one-off for this boundary?
- Are there existing examples of projections triggering side effects via PubSub that can serve as reference?

### Dev Check: PASS

All automated checks passed:
- Compilation: clean
- Tests: 100% pass (including 82 acceptance scenarios)
- Linting/formatting: clean
- Sandbox check: passed

---

## Summary

The iteration successfully delivers asynchronous, observable email delivery dispatch with clean separation from command acceptance. All planned acceptance criteria are met and tested. The implementation is production-ready for Memba's current scale.

However, the projection pattern (querying current member state, silently skipping on missing email) and PubSub-driven dispatch architecture introduce coupling and fragility that merit discussion about whether they align with Memba's long-term design philosophy. These are judgement calls for Matt, not blockers.

Recommend:
1. **Merge as-is** if Matt accepts the projection pattern and PubSub architecture as pragmatic compromises
2. **Apply bounded-safe fixes** in immediate polish pass (DB constraint, logging, error handling)
3. **Schedule follow-up** to discuss event-sourcing patterns and whether projection-driven side effects should be codified in ADR or refactored to event-handler-driven approach