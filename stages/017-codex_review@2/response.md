# Iteration 038 Review: Email Delivery Handoff Boundary

- **Decision:** ACCEPT
- **Confidence:** High
- **ADR conformance:** PASS

## ADR violations

None.

The implementation conforms to the asynchronous email delivery handoff boundary described by the iteration plan and the cited/nearby ADR direction:

1. `send_club_message/2` is no longer coupled to synchronous provider success.
2. `EmailDelivery` now carries an explicit local dispatch lifecycle: `pending`, `dispatching`, `sent`, `failed`.
3. Existing provider/webhook statuses are preserved rather than replaced.
4. Dispatch is handled by a named supervised OTP process, `Memba.Messaging.EmailDeliveryDispatcher`.
5. The dispatcher is nudged through read-model-change PubSub rather than bypassing the projection/read-model architecture.
6. Claiming moves records from `pending` to `dispatching` before provider delivery.
7. Provider success/failure updates the read model with observable status and diagnostics.
8. Manual/internal retry exists without introducing out-of-scope automatic retries, startup sweeps, periodic sweeps, or staff UI.
9. Browser-composed and inbound club-message flows use the same pending-delivery/dispatcher path.

The implementation preserves the intended CQRS/event-sourcing boundary: command acceptance records domain facts, projections create/update read models, and infrastructure email dispatch occurs asynchronously from the read model.

## Blocking issues

None.

The synthesized review blockers do not appear to be merge blockers:

1. **`email-delivery-status-db-constraint`** — Evidence indicates this is already implemented in `web/priv/repo/migrations/20260620071150_add_status_constraints_to_messaging_email_deliveries.exs` and covered by status-constraint tests.
2. **`email-delivery-diagnostics-docs`** — Useful maintainability polish, but not a behavioural or ADR blocker.
3. **`email-delivery-test-provider-cleanup`** — Test-support hygiene only.
4. **`inbound-email-dispatch-regression-test`** — Useful explicit regression coverage, but the implementation evidence and green acceptance/unit checks support the required behaviour.

## Bounded-safe fixes

1. **Clarify `EmailDelivery` diagnostic field semantics**

   **File:** `web/lib/memba/messaging/projections/email_delivery.ex`

   The diagnostics fields are operationally important now and should be documented in the schema module.

   In particular:

   - `attempt_count` may be interpreted as “number of provider attempts,” but the observed semantics appear closer to dispatch/retry lifecycle accounting.
   - `last_dispatch_attempted_at` means “last attempt timestamp,” not necessarily successful send time.
   - `sent_at` and `failed_at` should be documented as lifecycle timestamps, especially because webhook/provider statuses can later supersede the local `sent` state.

   This is safe to address with module documentation or comments; no behaviour change is needed.

2. **Clean up `SelectiveFailure` test provider start API**

   **File:** `web/test/support/messaging/email_delivery_providers/selective_failure.ex`

   Current evidence shows:

   ```elixir
   def start_link(_opts \\ []) do
     Agent.start_link(fn -> %{requests: [], failing_addresses: MapSet.new()} end, name: __MODULE__)
   end
   ```

   The parameter is ignored, and all helper functions use `__MODULE__` directly. Either remove the defaulted option seam or make the name configurable consistently. Since this is test support, the simplest safe cleanup is:

   ```elixir
   def start_link(_opts) do
     Agent.start_link(fn -> %{requests: [], failing_addresses: MapSet.new()} end, name: __MODULE__)
   end
   ```

   or, if no supervisor expects `start_link/1`, `start_link/0`.

3. **Add focused inbound async-dispatch regression coverage if absent**

   **File:** `web/test/memba/messaging/inbound_club_message_acceptance_test.exs` or dispatcher/integration test module

   Acceptance coverage is green, but a narrow test proving:

   - accepted inbound club email creates an `EmailDelivery` in `pending`,
   - read-model-change PubSub nudges the dispatcher,
   - dispatcher delivers via the provider seam,
   - delivery transitions to `sent` or `failed`,

   would make the inbound coupling to the new async boundary easier to maintain.

   This is not blocking because the plan-conformance gate and acceptance suite already passed.

## Judgement-worthy non-blocking code-health findings

1. **Single-threaded dispatcher throughput**

   **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** The dispatcher appears to claim and deliver records serially from a GenServer.

   **Why it may need human judgement:** This is acceptable for the current iteration and keeps the boundary simple. If provider latency or outbound volume grows, dispatch may need bounded concurrency, partitioning, or a durable job system. That is an operational/product decision rather than a polish fix.

2. **No startup sweep or periodic sweep**

   **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** Pending deliveries created while the app is down, missed PubSub nudges, or records left `dispatching` after a crash will not be automatically recovered.

   **Why it may need human judgement:** The plan explicitly deferred automatic retry, startup sweep, and periodic sweep. This is plan-conforming, but it remains an operational follow-up for production reliability.

3. **Ambiguous crash window after provider acceptance**

   **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`, `web/lib/memba/messaging/projections/email_delivery.ex`

   **Smell:** If the provider accepts the email but the app crashes before the read model is marked `sent`, the record can remain `dispatching`.

   **Why it may need human judgement:** The plan explicitly accepted best-effort duplicate prevention for this slice. Hardening would likely require provider idempotency keys, reconciliation, or a more durable job/outbox boundary.

4. **Single status field combines local handoff lifecycle and provider/webhook outcomes**

   **Files:** `web/lib/memba/messaging/projections/email_delivery.ex`

   **Smell:** `status` now represents both local dispatch states such as `pending`, `dispatching`, `failed`, and provider/webhook outcomes such as `delivered`, `bounced`, `complained`, and `opened`.

   **Why it may need human judgement:** This is plan-aligned because the iteration intentionally reused existing `EmailDelivery` records. If staff diagnostics, retry policy, or webhook semantics become more complex, separate `dispatch_status` and `provider_status` fields may become clearer.

5. **Dispatcher responsibility may grow**

   **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** The dispatcher coordinates PubSub subscription, claiming, request construction, provider invocation, result normalization, and read-model updates.

   **Why it may need human judgement:** Centralizing the initial boundary is reasonable. If provider-specific logic, telemetry, retry policy, or error classification expands, request-building and result-normalization collaborators could keep the GenServer focused on orchestration.

6. **Provider error vocabulary is informal**

   **Files:** `web/lib/memba/messaging/projections/email_delivery.ex`, provider adapters/test providers

   **Smell:** `latest_error` and `latest_error_detail` appear to persist loosely normalized provider error shapes.

   **Why it may need human judgement:** This is sufficient for current fake/local/Postmark/Resend provider seams. If operator-facing diagnostics become more important, a small normalized error vocabulary or struct may prevent adapter-specific tuples/strings leaking into staff tooling.

## Suggested fixes

For a follow-up polish commit or small cleanup iteration:

1. Add schema/module documentation for `EmailDelivery` diagnostic fields:
   - `attempt_count`
   - `last_dispatch_attempted_at`
   - `sent_at`
   - `failed_at`

2. Simplify `SelectiveFailure.start_link/1` so it does not suggest unsupported named Agent instances.

3. Add one focused integration/regression test for inbound club-message dispatch through the read-model-change PubSub and `EmailDeliveryDispatcher` path.

No product behaviour changes or acceptance feature-file edits are required for these fixes.

## Validation notes

- `dev ci` / `dev check` passed.
- Full acceptance suite passed:
  - 82 scenarios
  - 493 steps
- ExUnit suite passed:
  - 822 tests
  - 0 failures
- Review started from a clean working tree.
- Acceptance feature files were not changed during review.
- Evidence shows:
  - `EmailDelivery` records start as `pending`.
  - Dispatcher is supervised.
  - PubSub read-model-change nudges dispatch.
  - Claiming transitions `pending` to `dispatching`.
  - Provider success marks delivery `sent`.
  - Provider failure marks delivery `failed` and persists diagnostics.
  - Manual retry exists.
  - `send_club_message/2` acceptance is decoupled from provider availability.
  - Existing provider/webhook statuses are preserved.
  - Status vocabulary has database-level protection in the migration evidence.