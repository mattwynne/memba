# Iteration 038 Review: Email Delivery Handoff Boundary

- **Decision:** ACCEPT
- **Confidence:** High
- **ADR conformance:** PASS

## ADR violations

None found.

The implementation appears to conform to the accepted asynchronous email-delivery handoff direction, including the ADR-relevant architectural points:

1. `send_club_message/2` is decoupled from synchronous provider success/failure.
2. `EmailDelivery` records carry a local dispatch lifecycle: `pending`, `dispatching`, `sent`, `failed`.
3. Existing provider/webhook statuses are preserved.
4. Dispatch is handled by a named, supervised OTP process: `Memba.Messaging.EmailDeliveryDispatcher`.
5. Dispatcher coordination uses read-model-change PubSub nudges rather than bypassing the projection/read-model architecture.
6. Pending deliveries are claimed by transitioning to `dispatching` before provider delivery.
7. Provider success/failure is reflected in the read model with observable status and diagnostics.
8. Manual/internal retry exists without adding out-of-scope automatic retries, startup sweeps, periodic sweeps, or staff retry UI.
9. Browser-composed and inbound club-message paths use the same pending-delivery/dispatcher boundary.

No evidence shows the implementation replacing ADR-mandated infrastructure with a local shortcut, or introducing a conflicting delivery/job architecture.

## Blocking issues

None.

The previously synthesized “blockers” are not merge blockers based on the available evidence:

1. **Email delivery status DB constraint** — evidence shows a migration exists for status constraints and tests/checks passed.
2. **Diagnostics documentation** — useful polish if absent or incomplete, but not a behavioural or ADR blocker.
3. **SelectiveFailure test provider cleanup** — final evidence shows `def start_link(_opts)`, so the misleading defaulted seam has been cleaned up.
4. **Inbound dispatch regression coverage** — useful to keep explicit, but evidence and green checks indicate the inbound path is covered sufficiently for this iteration.

## Bounded-safe fixes

1. **Clarify or verify `EmailDelivery` diagnostics field documentation**

   **File:** `web/lib/memba/messaging/projections/email_delivery.ex`

   If not already explicit in the module documentation, add a short note clarifying the operational semantics of:

   - `attempt_count`
   - `last_dispatch_attempted_at`
   - `sent_at`
   - `failed_at`
   - `latest_error`
   - `latest_error_detail`

   In particular, make clear whether `attempt_count` means failed provider attempts, total dispatch attempts, or retry lifecycle operations. This is a low-risk documentation-only improvement.

2. **Keep the focused inbound async-dispatch test discoverable**

   **File:** likely `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`

   If the focused regression test already exists, no change is needed. If it is only indirectly covered by broader acceptance tests, add a narrow test that demonstrates:

   - accepted inbound club email creates an `EmailDelivery`,
   - the delivery starts `pending`,
   - the read-model-change nudge reaches the dispatcher,
   - the provider seam receives the request,
   - the delivery reaches `sent` or `failed`.

   This is not required before merge, but it would make the architectural coupling easier to maintain.

## Judgement-worthy non-blocking code-health findings

1. **Single-threaded dispatcher throughput**

   **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** Provider delivery appears to be coordinated serially by a GenServer.

   **Why it may need human judgement:** This is simple and plan-conforming for this slice. If outbound volume or provider latency grows, the team may need bounded concurrency, partitioned dispatchers, or a durable job system. That is an operational/product trade-off, not a merge blocker.

2. **No startup or periodic sweep**

   **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** Pending deliveries created while the app is down, missed PubSub nudges, or records left in `dispatching` after a crash are not automatically recovered.

   **Why it may need human judgement:** The iteration explicitly deferred automatic retries, startup sweeps, and periodic sweeps. This remains an intentional reliability trade-off that should be revisited when operational expectations are clearer.

3. **Ambiguous crash window after provider acceptance**

   **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`, `web/lib/memba/messaging/projections/email_delivery.ex`

   **Smell:** If the provider accepts the email but the app crashes before the read model is marked `sent`, the delivery can remain `dispatching`.

   **Why it may need human judgement:** The plan acknowledged best-effort duplicate prevention as acceptable for this slice. Hardening would likely require provider idempotency keys, reconciliation, or a more durable outbox/job boundary.

4. **One `status` field combines local handoff lifecycle and provider/webhook outcome**

   **Files:** `web/lib/memba/messaging/projections/email_delivery.ex`

   **Smell:** `pending`, `dispatching`, `sent`, and `failed` are local dispatch lifecycle states, while statuses such as `delivered`, `bounced`, `complained`, and `opened` are provider/webhook outcomes.

   **Why it may need human judgement:** Reusing `EmailDelivery` was an explicit plan decision. If retry policy, webhook handling, or staff diagnostics become more sophisticated, separate local dispatch and provider outcome fields may become clearer.

5. **Dispatcher responsibility may grow**

   **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** The dispatcher coordinates PubSub subscription, claiming, request construction, provider invocation, error normalization, and read-model updates.

   **Why it may need human judgement:** Centralizing the new boundary is acceptable now. If provider-specific behaviour, telemetry, retry policy, or diagnostics expand, request-building and result-normalization collaborators may help keep the GenServer focused on orchestration.

6. **Read model is now also an operational handoff table**

   **Files:** `web/lib/memba/messaging/projections/email_delivery.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** `EmailDelivery` is both a projection/read model and the mutable handoff/dispatch coordination record.

   **Why it may need human judgement:** This is explicitly plan-aligned. It keeps the slice small and avoids a separate outbox table, but it does mean projection-owned data and infrastructure-owned dispatch state coexist in one schema. Future reliability or reporting needs may justify splitting those responsibilities.

7. **Provider error vocabulary is informal**

   **Files:** provider adapters, `web/lib/memba/messaging/projections/email_delivery.ex`

   **Smell:** `latest_error` and `latest_error_detail` appear to persist loosely normalized provider/test-provider error shapes.

   **Why it may need human judgement:** This is adequate for the current fake/local/Postmark/Resend seams. If operator-facing diagnostics become more important, a small normalized error vocabulary or struct may reduce adapter-specific leakage.

## Suggested fixes

No required fixes before merge.

Optional safe follow-ups:

1. Ensure `EmailDelivery` module docs clearly explain dispatch diagnostic fields and timestamp semantics.
2. Keep or add one focused inbound async-dispatch regression test if the current test is not easily discoverable.
3. Consider a later reliability iteration for startup sweep/manual operator tooling, idempotency, or reconciliation of stuck `dispatching` records.

## Validation notes

- `dev ci` / `dev check` passed.
- ExUnit suite passed: **822 tests, 0 failures**.
- Acceptance suite passed: **82 scenarios, 493 steps**.
- Acceptance feature files were not modified during review repair.
- Final evidence shows `SelectiveFailure.start_link/1` no longer exposes a misleading defaulted `start_link/0` seam.
- Evidence supports:
  - new deliveries start `pending`,
  - dispatcher is supervised,
  - dispatcher is nudged via read-model-change PubSub,
  - claiming transitions `pending` to `dispatching`,
  - provider success marks `sent`,
  - provider failure marks `failed` and persists diagnostics,
  - manual retry exists,
  - `send_club_message/2` is decoupled from provider availability,
  - inbound and browser-composed club messages use the same async handoff path,
  - existing provider/webhook statuses are preserved,
  - status vocabulary has database-level protection.