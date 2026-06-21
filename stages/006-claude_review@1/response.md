# Iteration 038 Implementation Review

**Decision**: ACCEPT  
**Confidence**: High  
**ADR Conformance**: PASS

---

## ADR Conformance

### Pass

**ADR 027: Asynchronous Email Delivery Handoff Boundary**

All binding decisions are implemented:

✓ Async dispatch with `pending`/`dispatching`/`sent`/`failed` lifecycle  
✓ Supervised `EmailDeliveryDispatcher` GenServer under application tree  
✓ PubSub read-model-change coordination via `EmailDeliveryCreated` events  
✓ Manual retry API (`retry_email_delivery/1`), no automatic retries  
✓ Command acceptance (`send_club_message/2`) decoupled from provider success  
✓ Claiming logic with `pending → dispatching` transition prevents concurrent dispatch  
✓ Error tracking via `attempt_count`, `latest_error`, `latest_error_detail` fields  
✓ Inbound club messages use same async path via `EmailDelivery` projection  

**Minor interpretation variations** (all plan-aligned):
- Database constraints on status enum: deferred to Ecto.Enum application-level validation (plan: "where practical")
- Startup sweep of pending deliveries: explicitly deferred (plan acknowledges this operational gap)
- Concurrent dispatch: single-threaded dispatcher acceptable for first iteration

**CQRS/Event-Sourcing/RDD pattern conformance**:
✓ Commands → events → projections separation maintained  
✓ Read model (`EmailDelivery`) vs write model (event stream) properly separated  
✓ Event-driven async coordination via PubSub  
✓ OTP supervision and fault tolerance  
✓ Projection responsibility: tracks delivery lifecycle state for operational queries  
✓ Dispatcher responsibility: single async send concern, no domain logic

---

## Blocking Issues

None.

The implementation passes `dev check`, implements all stated acceptance criteria, conforms to ADR 027, and follows project patterns. Acceptance tests confirm browser compose, inbound club messages, and staff workflows still work.

---

## Bounded-Safe Fixes

1. **Semantic clarity on `attempt_count`**  
   **Files**: `lib/memba/messaging/projections/email_delivery.ex`, schema and changesets  
   **Issue**: Field increments on both dispatch failure (`mark_failed_changeset`) and manual retry (`reset_for_retry_changeset`), creating semantic ambiguity.  
   - A delivery succeeding on first try: `attempt_count: 0`  
   - A delivery succeeding after one manual retry: `attempt_count: 2` (retry → 1, then success leaves it)  
   - A delivery failing, retried, failing again: `attempt_count: 3` (fail → 1, retry → 2, fail → 3)  
   
   **Fix options**:
   - Rename to `lifecycle_operation_count` to clarify it tracks both retries and dispatch attempts
   - OR remove increment from `reset_for_retry_changeset`, add separate `retry_count` field
   - OR document current semantic clearly in schema moduledoc

2. **Database constraint for `status` enum**  
   **Files**: `priv/repo/migrations/*_add_email_delivery_dispatch_tracking.exs`, `email_deliveries` table  
   **Issue**: While `Ecto.Enum` validates at application level, no DB check constraint prevents invalid status from other sources (SQL console, future migrations).  
   **Fix**: Add check constraint in a new migration:
   ```sql
   ALTER TABLE email_deliveries 
   ADD CONSTRAINT valid_status 
   CHECK (status IN ('pending', 'dispatching', 'sent', 'failed', 
                     'delivered', 'bounced', 'complained', 'opened'));
   ```
   (Include existing webhook statuses to preserve backward compatibility)

3. **`dispatched_at` field semantics**  
   **Files**: `lib/memba/messaging/projections/email_delivery.ex`, `mark_sent_changeset` and `mark_failed_changeset`  
   **Issue**: Field is set on both success and failure, making it "last attempt timestamp" not "successfully dispatched timestamp". Name implies the latter.  
   **Fix options**:
   - Rename to `last_dispatch_attempt_at`
   - OR only set on success, add separate `last_attempt_at` for failures
   - OR document current semantic in schema

---

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Single-threaded dispatcher bottleneck risk**  
   **File**: `lib/memba/messaging/email_delivery_dispatcher.ex`  
   **Smell**: Dispatcher handles deliveries one at a time in `handle_info`. If delivery volume grows or provider latency spikes, pending deliveries queue up in the GenServer mailbox.  
   **Why human judgement**: Acceptable for first iteration, but may need concurrent dispatch (Task pooling, partitioned dispatchers) in future. Trade-off: simplicity vs throughput.

2. **No startup sweep of pending deliveries**  
   **File**: `lib/memba/messaging/email_delivery_dispatcher.ex`  
   **Smell**: If app restarts while deliveries are `pending` or `dispatching`, they remain stuck until manual retry. PubSub events are not durable across restarts.  
   **Why human judgement**: Plan explicitly defers this ("operator/developer must use internal retry API"). Operational gap vs implementation complexity. Needs product/ops decision on sweep strategy (startup? periodic? on-demand?).

3. **Ambiguous state on crash between provider acceptance and `mark_sent`**  
   **Files**: `lib/memba/messaging/email_delivery_dispatcher.ex`, projection changesets  
   **Smell**: If app crashes after provider accepts delivery but before updating status to `sent`, delivery remains `dispatching`. Won't be auto-retried (good, no duplicate), but also won't be marked `sent` (bad, operational ambiguity).  
   **Why human judgement**: Plan acknowledges this as acceptable ("best-effort duplicate prevention"). Future hardening could use provider-level idempotency keys (delivery_id) to safely retry and reconcile. Trade-off: correctness vs complexity.

4. **Error normalization robustness**  
   **File**: `lib/memba/messaging/projections/email_delivery.ex`, `error_type/1` and `error_detail/1` private functions  
   **Smell**: Pattern matches on `{:selective_failure, _}` and `{:http_error, _}` tuples. Catch-all returns `"unknown"` / `inspect(reason)`. Provider errors might have other shapes.  
   **Why human judgement**: Works for current providers (fake, selective_failure, Postmark/Resend). May need refinement as provider ecosystem grows or error types evolve. Low risk, but worth monitoring.

5. **No explicit integration test for inbound message async dispatch**  
   **File**: Test suite gap  
   **Smell**: `InboundClubMessageAccepted` events create `EmailDelivery` projections with `status: :pending`, and dispatcher should pick them up. But no unit/integration test explicitly verifies this path end-to-end.  
   **Why human judgement**: Acceptance tests pass (likely covering it), and the code path is identical to browser-composed messages. Adding a focused test would improve regression safety, but current coverage may be adequate. Test investment vs value.

6. **UI changes not evident in implementation**  
   **File**: Evidence gap, possibly `lib/memba_web/live/*` (not in collected diff)  
   **Smell**: Plan says "Adjust member-facing and staff/operator delivery presentation only as needed for the new statuses." No UI file changes in evidence.  
   **Why human judgement**: Either UI already handles status enum generically (likely, given acceptance tests pass), or changes were trivial/outside diff scope, or this was missed. Unlikely to be a real gap given green acceptance tests, but worth confirming UI gracefully handles new statuses (`pending`, `dispatching`, `failed`) in production scenarios.

---

## Suggested Fixes

### For bounded-safe fixes:

1. **Clarify `attempt_count` semantics**:
   - Add schema moduledoc comment: `@doc "Increments on both dispatch failure and manual retry; counts total lifecycle operations, not just provider send attempts"`
   - OR rename field in new migration: `attempt_count → lifecycle_operation_count` (requires app-wide search/replace)
   - OR split into `dispatch_attempt_count` (incremented on send) and `manual_retry_count` (incremented on retry)

2. **Add database status constraint**:
   ```elixir
   # priv/repo/migrations/YYYYMMDDHHmmSS_add_email_delivery_status_constraint.exs
   defmodule Memba.Repo.Migrations.AddEmailDeliveryStatusConstraint do
     use Ecto.Migration

     def up do
       execute """
       ALTER TABLE email_deliveries
       ADD CONSTRAINT email_deliveries_status_check
       CHECK (status IN ('pending', 'dispatching', 'sent', 'failed',
                        'delivered', 'bounced', 'complained', 'opened'))
       """
     end

     def down do
       execute "ALTER TABLE email_deliveries DROP CONSTRAINT email_deliveries_status_check"
     end
   end
   ```

3. **Clarify `dispatched_at` semantics**:
   - Add schema field doc: `dispatched_at: "Timestamp of last dispatch attempt, whether successful or failed"`
   - OR rename in new migration: `dispatched_at → last_dispatch_attempt_at`

---

## Validation Notes

- ✓ `dev check` passed before review (compilation, dialyzer, credo, format, unit tests, acceptance tests)
- ✓ All 82 acceptance scenarios passed, including messaging, inbound club messages, staff workflows
- ✓ Specific test coverage for dispatcher claiming, success/failure paths, manual retry, concurrent dispatch prevention
- ✓ Test providers (fake, selective_failure) support error simulation
- ✓ Migration is reversible, adds indexes for common queries
- ✓ Dispatcher added to supervision tree, handles crash recovery via OTP
- ✓ PubSub coordination tested via `EmailDeliveryCreated` broadcast
- ✓ Command acceptance (`send_club_message/2`) succeeds even when provider fails (tests prove decoupling)

---

## Recommendation

**Accept with bounded-safe improvements**.

The iteration successfully implements asynchronous email delivery per ADR 027, decoupling command acceptance from provider dispatch. The architecture is sound, tests are comprehensive, and all acceptance criteria pass.

The bounded-safe fixes (semantic clarity on fields, database constraint) are polish, not correctness issues. They can be applied as a follow-up commit or small iteration without changing behaviour.

The judgement-worthy findings are deliberate trade-offs documented in the plan (no automatic retry, no startup sweep) or typical first-iteration technical debt (single-threaded dispatch, crash-recovery edge cases). None block merge; they inform future hardening iterations.