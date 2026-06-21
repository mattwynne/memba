# Iteration 038 Review: Email Delivery Handoff Boundary

- **Decision:** ACCEPT
- **Confidence:** High
- **ADR conformance:** PASS

## ADR violations

1. **None found.**

The implementation appears to conform to the binding architectural direction for the asynchronous email delivery handoff boundary:

- `send_club_message/2` is decoupled from provider availability.
- `EmailDelivery` now models the async lifecycle using `pending`, `dispatching`, `sent`, and `failed`, while preserving existing provider/webhook statuses.
- Dispatch is handled by a supervised `EmailDeliveryDispatcher`.
- The dispatcher is nudged by read-model-change PubSub instead of bypassing the event/projection flow.
- Manual/internal retry exists without adding out-of-scope automatic retry, startup sweep, periodic sweep, or staff retry UI.
- CQRS/event-sourcing boundaries remain intact: commands/events establish the domain fact, projections maintain read-model delivery records, and infrastructure dispatch happens asynchronously from the read model.

## Blocking issues

1. **None.**

The implementation passed `dev ci`, the plan-conformance gate had already succeeded, and I do not see an ADR conflict or a missing central acceptance criterion that should block merge.

## Bounded-safe fixes

1. **Clarify `attempt_count` semantics**

   **Files:** `lib/memba/messaging/projections/email_delivery.ex`, related tests/migration docs if present.

   The field appears to increment for more than one lifecycle concern, including failed provider dispatch and manual retry reset. That makes `attempt_count` ambiguous if future maintainers or operator tooling interpret it as “number of provider send attempts.”

   This is not currently blocking, but it is a maintainability risk because delivery diagnostics are now operationally meaningful.

2. **Clarify `dispatched_at` semantics**

   **Files:** `lib/memba/messaging/projections/email_delivery.ex`.

   If `dispatched_at` is set after both successful and failed provider calls, it means “last dispatch attempt time,” not necessarily “successfully dispatched at.” The name is understandable in this iteration, but it could mislead future UI or reporting work.

3. **Add a database-level check constraint for `email_deliveries.status`**

   **Files:** migration touching `email_deliveries`.

   The schema-level enum validation is good, and the plan allowed constraints “where practical.” A database check constraint would make the expanded status vocabulary more durable against future raw SQL, data repair scripts, or migrations.

   The allowed set should include both the new handoff statuses and preserved webhook/provider statuses, for example:

   - `pending`
   - `dispatching`
   - `sent`
   - `failed`
   - `delivered`
   - `bounced`
   - `complained`
   - `opened`

4. **Clean up the `SelectiveFailure` test provider naming seam**

   **File:** `web/test/support/messaging/email_delivery_providers/selective_failure.ex`.

   `start_link/1` accepts a `:name` option, but the helper functions call `Agent` using `__MODULE__` directly. That makes the option misleading.

   Since this is test support only, either remove the `:name` option or consistently pass/use the configured name.

5. **Add one focused inbound async-dispatch regression test if not already present**

   **Files:** messaging/dispatcher integration tests.

   Acceptance coverage is green, and the plan-conformance workflow passed. Still, a narrow test proving that accepted inbound club messages create pending `EmailDelivery` records and dispatch through the same dispatcher path would make this important architectural coupling explicit.

## Judgement-worthy non-blocking code-health findings

1. **Single-threaded dispatcher throughput**

   **Files:** `lib/memba/messaging/email_delivery_dispatcher.ex`.

   **Smell:** The dispatcher appears to claim and deliver records serially from one GenServer.

   **Why it may need human judgement:** This is simple and safe for the first asynchronous handoff iteration. However, provider latency or higher delivery volume could cause dispatch work to accumulate behind the GenServer. A future hardening pass may need bounded concurrency, partitioning, or a durable job system. That is an operational/product trade-off, not a merge blocker.

2. **No startup or periodic sweep**

   **Files:** `lib/memba/messaging/email_delivery_dispatcher.ex`.

   **Smell:** Pending deliveries created while the app is down, missed PubSub nudges, or records stuck in `dispatching` after a crash are not automatically recovered.

   **Why it may need human judgement:** The iteration plan explicitly deferred startup sweeps, periodic sweeps, and automatic retry. This is acceptable for the slice, but it remains an operational gap that should be revisited once real delivery volume and support expectations are clearer.

3. **Crash window after provider acceptance**

   **Files:** `lib/memba/messaging/email_delivery_dispatcher.ex`, `lib/memba/messaging/projections/email_delivery.ex`.

   **Smell:** If the provider accepts the email and the app crashes before the record is marked `sent`, the read model may remain `dispatching`.

   **Why it may need human judgement:** The plan explicitly accepted best-effort duplicate prevention for this iteration. Future work may need provider-level idempotency keys using `delivery_id`, reconciliation tooling, or a more durable outbox/job boundary.

4. **One `status` field now represents both local handoff lifecycle and provider/webhook lifecycle**

   **Files:** `lib/memba/messaging/projections/email_delivery.ex`.

   **Smell:** `pending`/`dispatching`/`failed` are local dispatch states, while statuses such as `delivered`, `bounced`, `complained`, and `opened` are provider/webhook outcomes.

   **Why it may need human judgement:** This is plan-aligned and likely appropriate for now because the existing `EmailDelivery` read model was intentionally reused. If staff/operator views, webhook processing, or retry policy become more sophisticated, separating local dispatch status from provider delivery status may become clearer.

5. **Dispatcher responsibility may grow over time**

   **Files:** `lib/memba/messaging/email_delivery_dispatcher.ex`.

   **Smell:** The dispatcher coordinates PubSub nudges, record claiming, request construction, provider calls, result handling, error normalization, and read-model updates.

   **Why it may need human judgement:** Centralizing this flow keeps the new boundary discoverable. If provider-specific behaviour, retry policy, telemetry, or error classification grows, request-building and result-normalization collaborators may help keep the GenServer orchestration-focused.

6. **Provider error vocabulary is still informal**

   **Files:** `lib/memba/messaging/projections/email_delivery.ex`, provider adapters/test providers.

   **Smell:** Persisted `latest_error` and `latest_error_detail` are useful, but provider errors can have inconsistent shapes.

   **Why it may need human judgement:** The current implementation appears sufficient for fake/local/Postmark/Resend seams. If more provider errors become operator-facing, the project may want a small normalized error struct or vocabulary instead of persisting loosely classified inspected terms.

## Suggested fixes

For a follow-up polish commit or small cleanup iteration:

1. Add comments or schema documentation for:
   - `attempt_count`
   - `dispatched_at`

   Or, if the team wants stronger semantics, rename/split them before staff tooling depends on them.

2. Add a migration with a check constraint for `email_deliveries.status`, preserving both dispatch lifecycle statuses and existing webhook/provider statuses.

3. Simplify `SelectiveFailure` test provider naming:
   - remove the unused `:name` option, or
   - update all helper functions to support named Agent instances consistently.

4. Add a narrow regression test for inbound club-message delivery through the same pending/read-model/dispatcher path.

## Validation notes

- `dev ci` passed before review.
- Full acceptance suite passed:
  - 82 scenarios
  - 493 steps
- Review started from a clean working tree.
- No files were edited during this review.
- Evidence indicates the implementation includes:
  - pending `EmailDelivery` creation,
  - supervised dispatcher wiring,
  - PubSub read-model-change nudges,
  - pending-to-dispatching claim logic,
  - sent/failed status updates,
  - persisted diagnostics on failure,
  - manual retry,
  - async decoupling from `send_club_message/2`,
  - continued browser-composed and inbound club-message delivery paths.