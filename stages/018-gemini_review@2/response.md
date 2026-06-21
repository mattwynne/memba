# Iteration 038 Review: Email Delivery Handoff Boundary

- **Decision:** ACCEPT
- **Confidence:** High
- **ADR conformance:** PASS

## ADR violations

1. **None found.**

The implementation conforms to the asynchronous email delivery handoff boundary described by the iteration plan and prior ADR/context evidence:

- `send_club_message/2` is decoupled from synchronous provider availability.
- `EmailDelivery` records model the local handoff lifecycle with `pending`, `dispatching`, `sent`, and `failed`.
- Existing provider/webhook statuses are preserved.
- Dispatch is handled by a named supervised OTP process, `Memba.Messaging.EmailDeliveryDispatcher`.
- The dispatcher is nudged through read-model-change PubSub rather than bypassing the projection/read-model flow.
- Claiming transitions a pending delivery to `dispatching` before provider delivery.
- Provider success/failure updates the read model with observable status and diagnostics.
- Manual/internal retry exists without adding out-of-scope automatic retry, startup sweep, periodic sweep, or staff retry UI.
- Browser-composed and inbound club-message paths use the same pending-delivery/dispatcher boundary.

The implementation preserves the expected CQRS/event-sourcing shape: command acceptance records the domain fact, projections create/update read models, and infrastructure email dispatch occurs asynchronously from the read model.

## Blocking issues

1. **None.**

The synthesized review blockers do not appear to be merge blockers:

- `email-delivery-status-db-constraint`: evidence indicates this already exists in `web/priv/repo/migrations/20260620071150_add_status_constraints_to_messaging_email_deliveries.exs` and is covered by tests.
- `email-delivery-diagnostics-docs`: useful maintainability polish, not a behavioural or ADR blocker.
- `email-delivery-test-provider-cleanup`: test-support hygiene only.
- `inbound-email-dispatch-regression-test`: useful explicit regression coverage, but not required to accept the implementation given the green implementation/acceptance evidence.

## Bounded-safe fixes

1. **Clarify `EmailDelivery` diagnostics field semantics**

   **File:** `web/lib/memba/messaging/projections/email_delivery.ex`

   The new diagnostics fields are operationally meaningful and should be documented in the schema module or nearby comments:

   - `attempt_count`
   - `last_dispatch_attempted_at`
   - `sent_at`
   - `failed_at`

   In particular, future maintainers may assume `attempt_count` means “number of provider send attempts,” while the implementation evidence suggests it is closer to local dispatch/retry lifecycle accounting. `last_dispatch_attempted_at` should also be explicit that it means the latest dispatch attempt, not necessarily a successful send timestamp.

2. **Simplify the `SelectiveFailure` test provider start API**

   **File:** `web/test/support/messaging/email_delivery_providers/selective_failure.ex`

   Current evidence still shows:

   ```elixir
   def start_link(_opts \\ []) do
     Agent.start_link(fn -> %{requests: [], failing_addresses: MapSet.new()} end, name: __MODULE__)
   end
   ```

   The options parameter is ignored, while all helper functions address the Agent by `__MODULE__`. That makes the API look configurable when it is not. A safe cleanup would be either:

   ```elixir
   def start_link(_opts) do
     Agent.start_link(fn -> %{requests: [], failing_addresses: MapSet.new()} end, name: __MODULE__)
   end
   ```

   or `start_link/0` if no supervisor/test setup requires `start_link/1`.

3. **Add focused inbound async-dispatch regression coverage if still absent**

   **File:** `web/test/memba/messaging/inbound_club_message_acceptance_test.exs` or a dispatcher/integration test module

   Acceptance coverage is green, but a narrow test proving the inbound path goes through the new async handoff would make the architectural coupling easier to maintain:

   - accepted inbound club email creates an `EmailDelivery`,
   - the delivery starts as `pending`,
   - read-model-change PubSub nudges `EmailDeliveryDispatcher`,
   - the provider seam receives the request,
   - the delivery transitions to `sent` or `failed`.

   This is not blocking because the broader test suite and implementation evidence already support the required behaviour.

## Judgement-worthy non-blocking code-health findings

1. **Single-threaded dispatcher throughput**

   **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** The dispatcher appears to process claims and provider calls serially from a GenServer.

   **Why it may need human judgement:** This is simple and plan-conforming for the first async handoff slice. If provider latency or outbound volume grows, the team may need bounded concurrency, partitioned dispatchers, or a durable job system. That is an operational/product trade-off, not a merge blocker.

2. **No startup or periodic sweep**

   **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** Deliveries created while the app is down, missed PubSub nudges, or records left in `dispatching` after a crash are not automatically recovered.

   **Why it may need human judgement:** The iteration plan explicitly deferred automatic retries, startup sweeps, and periodic sweeps. This remains an operational follow-up once reliability expectations are clearer.

3. **Ambiguous crash window after provider acceptance**

   **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`, `web/lib/memba/messaging/projections/email_delivery.ex`

   **Smell:** If a provider accepts the email and the app crashes before the read model is marked `sent`, the delivery can remain `dispatching`.

   **Why it may need human judgement:** The plan explicitly accepted best-effort duplicate prevention for this slice. Hardening would likely require provider idempotency keys, reconciliation tooling, or a more durable job/outbox boundary.

4. **One `status` field combines local handoff lifecycle and provider/webhook outcomes**

   **Files:** `web/lib/memba/messaging/projections/email_delivery.ex`

   **Smell:** `pending`, `dispatching`, and `failed` are local dispatch states, while `delivered`, `bounced`, `complained`, and `opened` are provider/webhook outcomes.

   **Why it may need human judgement:** This is plan-aligned because the iteration intentionally reused the existing `EmailDelivery` read model. If staff diagnostics, retry policy, or webhook processing becomes more sophisticated, separate local dispatch and provider outcome fields may become clearer.

5. **Dispatcher responsibility may grow**

   **Files:** `web/lib/memba/messaging/email_delivery_dispatcher.ex`

   **Smell:** The dispatcher coordinates PubSub subscription, record claiming, request construction, provider invocation, result normalization, and read-model updates.

   **Why it may need human judgement:** Centralizing this logic keeps the new boundary discoverable. If provider-specific behaviour, telemetry, retry policy, or error classification grows, focused collaborators for request building/result normalization may keep the GenServer orchestration-focused.

6. **Provider error vocabulary is informal**

   **Files:** `web/lib/memba/messaging/projections/email_delivery.ex`, provider adapters/test providers

   **Smell:** `latest_error` and `latest_error_detail` appear to persist loosely normalized provider error information.

   **Why it may need human judgement:** This is sufficient for the current fake/local/Postmark/Resend seams. If operator-facing diagnostics become more important, a small normalized error vocabulary or struct could prevent adapter-specific tuples/strings leaking into staff tooling.

## Suggested fixes

For a follow-up polish commit or small cleanup pass:

1. Add schema/module documentation for `EmailDelivery` diagnostics fields:
   - `attempt_count`
   - `last_dispatch_attempted_at`
   - `sent_at`
   - `failed_at`

2. Simplify `SelectiveFailure.start_link/1` so it does not suggest unsupported configuration.

3. Add one focused regression test for inbound club-message dispatch through the read-model-change PubSub and `EmailDeliveryDispatcher` path.

No product behaviour changes or acceptance feature-file edits are required for these fixes.

## Validation notes

- `dev ci` / `dev check` passed.
- ExUnit suite passed: 822 tests, 0 failures.
- Acceptance suite passed: 82 scenarios, 493 steps.
- Review started from a clean working tree.
- Acceptance feature files were not changed.
- Evidence shows:
  - `EmailDelivery` records start as `pending`.
  - Dispatcher is supervised.
  - Dispatcher is nudged via read-model-change PubSub.
  - Claiming transitions `pending` to `dispatching`.
  - Provider success marks delivery `sent`.
  - Provider failure marks delivery `failed` and persists diagnostics.
  - Manual retry exists.
  - `send_club_message/2` is decoupled from provider availability.
  - Existing provider/webhook statuses are preserved.
  - Status vocabulary has database-level protection in the migration evidence.

One process note: the attempted review-repair stage reported fixes, but `verify_review_repair` found no working-tree diff, and later evidence still showed at least the `SelectiveFailure.start_link(_opts \\ [])` shape. That does not affect merge readiness, but it means the bounded-safe polish items should be treated as still available unless separately confirmed in the committed diff.