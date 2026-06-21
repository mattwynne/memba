# Iteration 038 Review: Email Delivery Handoff Boundary

- **Decision:** ACCEPT
- **Confidence:** High
- **ADR conformance:** PASS

## ADR violations

None found.

The implementation evidence supports conformance with the binding async email-delivery handoff direction, including ADR 027 / the asynchronous handoff boundary decisions referenced by the plan:

1. `send_club_message/2` is no longer coupled to synchronous provider success.
2. `EmailDelivery` records model the local dispatch lifecycle with `pending`, `dispatching`, `sent`, and `failed`.
3. Existing provider/webhook statuses are preserved.
4. Dispatch is handled by a named supervised OTP process, `Memba.Messaging.EmailDeliveryDispatcher`.
5. The dispatcher is nudged through read-model-change PubSub instead of bypassing the projection/read-model architecture.
6. Pending deliveries are claimed by transitioning to `dispatching` before provider delivery.
7. Provider success/failure updates the read model with observable status and diagnostics.
8. Manual/internal retry exists without introducing automatic retries, startup sweeps, periodic sweeps, or staff retry UI.
9. Browser-composed and inbound club-message paths use the same pending-delivery/dispatcher boundary.

The CQRS/event-sourcing shape is preserved: commands record domain facts, projections create/update read models, and infrastructure delivery happens asynchronously from the projected handoff record.

## Blocking issues

None.

The previously synthesized review “blockers” are not merge blockers based on the available evidence:

1. **`email-delivery-diagnostics-docs`** — maintainability polish at most. The implementation is behaviorally correct, and the repair pass reported that the schema documentation is already present.
2. **`email-delivery-test-provider-cleanup`** — resolved in the final evidence: `SelectiveFailure.start_link/1` is now `def start_link(_opts)`, with no misleading defaulted `start_link/0` seam.
3. **`inbound-email-dispatch-regression-test`** — useful coverage, but not blocking. The repair pass reported a focused inbound regression test already exists, and the full automated suite is green.

## Bounded-safe fixes

None required before merge.

Optional polish if the team wants another cleanup pass later:

1. **Keep `EmailDelivery` diagnostics documentation explicit and close to the schema.**  
   File: `web/lib/memba/messaging/projections/email_delivery.ex`  
   Ensure future maintainers can quickly distinguish:
   - `attempt_count`
   - `last_dispatch_attempted_at`
   - `sent_at`
   - `failed_at`
   - `latest_error`
   - `latest_error_detail`

2. **Keep the focused inbound async-dispatch regression test discoverable.**  
   File: likely `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`  
   If it is already present as reported, no change is needed. If later refactoring moves it, preserve coverage proving accepted inbound email goes through `EmailDelivery` projection + PubSub nudge + dispatcher.

## Judgement-worthy non-blocking code-health findings

1. **Single-threaded dispatcher throughput**

   - **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - **Smell:** Provider dispatch appears to be coordinated serially through one GenServer.
   - **Why it may need human judgement:** This is simple and plan-conforming for the first handoff boundary. If email volume or provider latency grows, the team may need bounded concurrency, partitioned dispatchers, or a durable job system. That is an operational/product trade-off, not a merge blocker.

2. **No startup or periodic sweep**

   - **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - **Smell:** Pending deliveries created while the app is down, missed PubSub nudges, or records left in `dispatching` after a crash are not automatically recovered.
   - **Why it may need human judgement:** The plan explicitly deferred automatic retries, startup sweeps, and periodic sweeps. This is an intentional reliability trade-off to revisit when operational expectations are clearer.

3. **Ambiguous crash window after provider acceptance**

   - **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`, `web/lib/memba/messaging/projections/email_delivery.ex`
   - **Smell:** If a provider accepts an email and the app crashes before the read model is marked `sent`, the delivery can remain `dispatching`.
   - **Why it may need human judgement:** The plan explicitly accepted best-effort duplicate prevention for this slice. Future hardening may require provider idempotency keys, reconciliation tooling, or a more durable outbox/job boundary.

4. **One `status` field combines local handoff lifecycle and provider/webhook outcome**

   - **Files:** `web/lib/memba/messaging/projections/email_delivery.ex`
   - **Smell:** `pending`, `dispatching`, and `failed` are local dispatch lifecycle states, while statuses such as `delivered`, `bounced`, `complained`, and `opened` are provider/webhook outcomes.
   - **Why it may need human judgement:** Reusing `EmailDelivery` was an explicit plan decision. If retry policy, webhook handling, or staff diagnostics become more sophisticated, separate local dispatch and provider outcome fields may become clearer.

5. **Dispatcher responsibility may grow**

   - **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - **Smell:** The dispatcher coordinates PubSub subscription, claiming, request construction, provider invocation, error normalization, and read-model updates.
   - **Why it may need human judgement:** Centralizing this new boundary keeps the slice discoverable. If provider-specific behavior, telemetry, retry policy, or error classification grows, extracting request-building/result-normalization collaborators may keep the GenServer focused on orchestration.

6. **Read model now doubles as an operational handoff table**

   - **Files:** `web/lib/memba/messaging/projections/email_delivery.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - **Smell:** `EmailDelivery` is both a projection/read model and the mutable dispatch coordination record.
   - **Why it may need human judgement:** This is explicitly plan-aligned and keeps the slice small. Future reliability/reporting needs may justify splitting read-model projection data from infrastructure handoff state.

7. **Provider error vocabulary is informal**

   - **Files:** provider adapters/test providers, `web/lib/memba/messaging/projections/email_delivery.ex`
   - **Smell:** `latest_error` and `latest_error_detail` persist loosely normalized provider/test-provider error information.
   - **Why it may need human judgement:** Adequate for current fake/local/Postmark/Resend seams. If operator-facing diagnostics become more important, a small normalized error vocabulary or struct could prevent provider-specific leakage into staff tooling.

## Suggested fixes

No required fixes before merge.

Suggested follow-ups only:

1. Preserve or improve schema-level documentation for email dispatch diagnostics.
2. Preserve focused regression coverage for inbound club-message dispatch through the async handoff path.
3. Consider a future reliability iteration for startup sweep/manual operator tooling, stuck `dispatching` reconciliation, and provider-level idempotency.

## Validation notes

- `dev ci` / `dev check` passed.
- ExUnit suite passed: **822 tests, 0 failures**.
- Acceptance suite passed: **82 scenarios, 493 steps, all passed**.
- Acceptance feature files were not changed.
- Final evidence shows `SelectiveFailure.start_link/1` no longer exposes a misleading defaulted `start_link/0` seam.
- Evidence supports:
  - new deliveries start `pending`;
  - dispatcher is supervised;
  - dispatcher is nudged via read-model-change PubSub;
  - claiming transitions `pending` to `dispatching`;
  - provider success marks delivery `sent`;
  - provider failure marks delivery `failed` and persists diagnostics;
  - manual retry exists;
  - `send_club_message/2` is decoupled from provider availability;
  - inbound and browser-composed club messages use the same async handoff path;
  - existing provider/webhook statuses are preserved;
  - status vocabulary has database-level protection.