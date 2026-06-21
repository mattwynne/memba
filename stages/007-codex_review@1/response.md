# Iteration 038 Review: Email Delivery Handoff Boundary

- **Decision:** ACCEPT
- **Confidence:** High
- **ADR conformance:** PASS

## ADR violations

None found.

The implementation appears to conform to the accepted asynchronous email delivery handoff direction, specifically the ADR intent reflected by the plan:

1. `send_club_message/2` is no longer coupled to provider availability.
2. `EmailDelivery` records now model an explicit async lifecycle: `pending`, `dispatching`, `sent`, `failed`, while preserving webhook/provider statuses.
3. Dispatch is handled by a supervised `EmailDeliveryDispatcher` rather than inline application-service code.
4. The dispatcher is nudged through read-model-change PubSub instead of replacing the existing event/projection architecture.
5. Manual retry is available without adding out-of-scope automatic retry, startup sweep, periodic sweep, or staff UI.
6. CQRS/event-sourcing boundaries remain intact: command acceptance records domain facts, projections create/read delivery state, and infrastructure dispatch occurs from the read model.

## Blocking issues

None.

The implementation passed `dev check`, the acceptance suite is green, and there is no evidence of an ADR violation or missed central acceptance criterion requiring a new implementation pass before merge.

## Bounded-safe fixes

1. **Clarify `attempt_count` semantics**

   **Files:** likely `lib/memba/messaging/projections/email_delivery.ex` and related tests/migration.

   The diagnostics field appears to increment on dispatch failure and also during manual retry reset. That makes the name `attempt_count` ambiguous if readers expect it to mean “provider send attempts.”

   Examples of possible ambiguity:

   - First successful provider send may remain `0`.
   - A failed send followed by manual retry may count both the failure and the retry lifecycle transition.
   - A retried failure may count more lifecycle operations than actual provider attempts.

   This is not blocking, but the field should either be documented or renamed/split before operational dashboards or staff tooling start relying on it.

2. **Clarify `dispatched_at` semantics**

   **Files:** likely `lib/memba/messaging/projections/email_delivery.ex`.

   If `dispatched_at` is set on both successful and failed provider calls, it means “last dispatch attempt timestamp,” not necessarily “successfully dispatched at.”

   That is acceptable behaviour, but the current name may mislead future maintainers. A small doc/comment, or a later rename to `last_dispatch_attempt_at`, would improve readability.

3. **Add a database-level status check constraint**

   **Files:** migration touching `email_deliveries`.

   The plan allowed “database constraints or schema validation where practical.” Ecto enum validation is useful, but the database still appears able to store arbitrary status strings if written outside the application.

   A low-risk follow-up migration could add a check constraint allowing the complete current vocabulary:

   - `pending`
   - `dispatching`
   - `sent`
   - `failed`
   - existing webhook statuses such as `delivered`, `bounced`, `complained`, `opened`

   This is especially useful because delivery status is now operationally meaningful.

4. **Clean up the test provider Agent naming seam**

   **File:** `web/test/support/messaging/email_delivery_providers/selective_failure.ex`

   `start_link/1` accepts a `:name` option, but `deliver/1`, `fail_addresses/1`, `deliveries/0`, and `reset/0` all use `__MODULE__` directly. That makes the custom name option misleading.

   Either remove the option or consistently support named instances. Since this is test support only, this is a small safe cleanup.

5. **Add a focused inbound async-dispatch regression test if not already present**

   **Files:** messaging/dispatcher tests.

   The implementation evidence and acceptance suite suggest inbound club messages still work, but a narrow integration test that proves an accepted inbound club message creates a pending `EmailDelivery` and is dispatched by the same dispatcher path would be useful regression coverage.

   This is not a blocker because the acceptance suite is green and the plan-conformance workflow already passed, but it would make the coupling between inbound message acceptance and the new async handoff explicit.

## Judgement-worthy non-blocking code-health findings

1. **Single-threaded dispatcher throughput**

   **Files:** `lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** The dispatcher appears to process claimed deliveries serially in a GenServer.

   **Why it may need human judgement:** This is simple and safe for the current iteration, and it avoids premature concurrency. However, provider latency or higher message volume could cause pending deliveries to accumulate in the dispatcher mailbox. A future hardening iteration may need a bounded task pool, partitioned dispatchers, or Oban-like durable job execution — but that would be a product/ops decision, not a polish fix.

2. **No startup sweep or periodic sweep**

   **Files:** `lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** Deliveries that are `pending` when the app is down, or stuck in `dispatching` after a crash, will not be automatically recovered.

   **Why it may need human judgement:** The plan explicitly deferred automatic retry, startup sweeps, and periodic sweeps. This is acceptable for this slice, but operationally important. A follow-up decision should define whether recovery is manual-only, startup-driven, periodic, or operator-triggered.

3. **Ambiguous crash window after provider acceptance**

   **Files:** `lib/memba/messaging/email_delivery_dispatcher.ex`, `lib/memba/messaging/projections/email_delivery.ex`

   **Smell:** If the provider accepts an email but the app crashes before the read model is marked `sent`, the record may remain `dispatching`.

   **Why it may need human judgement:** The plan explicitly accepted best-effort duplicate prevention and acknowledged this ambiguity. Future work may need provider-level idempotency keys using `delivery_id`, reconciliation, or a more durable outbox/job boundary. That is larger than a bounded-safe refactor.

4. **One status field now combines handoff lifecycle and provider/webhook lifecycle**

   **Files:** `lib/memba/messaging/projections/email_delivery.ex`

   **Smell:** `status` now represents both local dispatch lifecycle states and provider outcome states.

   **Why it may need human judgement:** This is plan-aligned and likely appropriate for the current read model. Over time, however, local handoff state and provider delivery state may diverge conceptually. If operator views or webhook handling become more sophisticated, the project may want separate fields such as `dispatch_status` and `provider_status`.

5. **Dispatcher may accumulate multiple responsibilities**

   **Files:** `lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** The dispatcher likely coordinates PubSub nudges, claims records, builds provider requests, calls providers, normalizes errors, and updates read-model status.

   **Why it may need human judgement:** For this iteration, centralizing the flow is understandable and keeps the new boundary discoverable. If provider-specific behaviour, retry policy, or error classification grows, request construction and result normalization may deserve focused collaborators so the GenServer remains orchestration-only.

6. **Provider error normalization may need a stronger vocabulary**

   **Files:** likely `lib/memba/messaging/projections/email_delivery.ex`, provider adapters.

   **Smell:** Persisted `latest_error` / `latest_error_detail` are useful, but provider errors can have inconsistent shapes.

   **Why it may need human judgement:** Current fake/local/Postmark/Resend seams appear covered. As more providers or webhook statuses are added, the team may want a small normalized error struct or vocabulary to avoid leaking adapter-specific tuples/strings into operator-facing diagnostics.

## Suggested fixes

For a follow-up polish commit or small cleanup iteration:

1. Add documentation or rename diagnostics fields:
   - Document `attempt_count` as lifecycle/dispatch-attempt semantics, or split it into clearer fields.
   - Document `dispatched_at` as “last dispatch attempt timestamp,” or rename it later.

2. Add a database check constraint for `email_deliveries.status`, preserving both new dispatch statuses and existing webhook statuses.

3. Simplify `SelectiveFailure` test provider:
   - Remove the unused `:name` option, or
   - Change all Agent operations to use a consistent configured name.

4. Add one focused test for inbound club-message async dispatch through the same `EmailDeliveryDispatcher` path, if the implementation does not already include one.

## Validation notes

- `dev ci` / `dev check` passed before review.
- Acceptance suite passed:
  - 82 scenarios
  - 493 steps
- The review started from a clean working tree.
- The implementation evidence indicates:
  - `EmailDelivery` records start as `pending`.
  - A supervised dispatcher handles async provider dispatch.
  - Dispatch claiming moves records to `dispatching`.
  - Success marks records `sent`.
  - Provider failure marks records `failed` and persists diagnostics.
  - Manual retry exists.
  - Browser-composed and inbound club-message flows continue through the same projected delivery path.
- No file edits were made during this review.