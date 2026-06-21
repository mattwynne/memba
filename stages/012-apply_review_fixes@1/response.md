Implemented the bounded review-repair pass for iteration 038. No acceptance feature files were changed.

## Issue-to-fix mapping

| Review issue | Fixes made | Files/modules/tests |
|---|---|---|
| `dispatcher-boundary-observability` | Added structured dispatcher logging for claims, skipped claims, retry claims/skips, provider success/failure, disabled dispatch, and PubSub nudges. Exposed configured provider name through the provider boundary for log metadata. | `web/lib/memba/messaging/email_delivery_dispatcher.ex`, `web/lib/memba/messaging/email_delivery_provider.ex` |
| `provider-exception-to-failed-delivery` | Wrapped provider handoff in exception normalization. Unexpected provider exceptions are now logged and returned as `{:error, {:provider_exception, ExceptionModule, message}}`, so existing failed-delivery persistence records `status: "failed"`, increments `attempt_count`, and stores diagnostics. Added a raising test provider and regression test. | `web/lib/memba/messaging/email_delivery_dispatcher.ex`, `web/test/support/messaging/email_delivery_providers/raising.ex`, `web/test/memba/messaging/email_delivery_dispatcher_test.exs` |
| `email-delivery-status-vocabulary-integrity` | Added centralized `Memba.Messaging.EmailDeliveryStatus` vocabulary for dispatch lifecycle and provider webhook statuses. Reused it in dispatcher/projector code and strengthened status constraint tests to prove the shared vocabulary matches intended allowed statuses. Added projection docs pointing to the shared vocabulary and DB constraint. | `web/lib/memba/messaging/email_delivery_status.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`, `web/lib/memba/messaging/projectors/email_delivery.ex`, `web/lib/memba/messaging/projections/email_delivery.ex`, `web/test/memba/messaging/email_delivery_status_constraints_test.exs` |

## Files changed

### Dispatcher boundary / observability
- `web/lib/memba/messaging/email_delivery_dispatcher.ex`
- `web/lib/memba/messaging/email_delivery_provider.ex`

### Provider exception hardening
- `web/lib/memba/messaging/email_delivery_dispatcher.ex`
- `web/test/memba/messaging/email_delivery_dispatcher_test.exs`
- `web/test/support/messaging/email_delivery_providers/raising.ex`

### Status vocabulary integrity
- `web/lib/memba/messaging/email_delivery_status.ex`
- `web/lib/memba/messaging/email_delivery_dispatcher.ex`
- `web/lib/memba/messaging/projectors/email_delivery.ex`
- `web/lib/memba/messaging/projections/email_delivery.ex`
- `web/test/memba/messaging/email_delivery_status_constraints_test.exs`

## Tests / validation

- `cd web && mix format --check-formatted ...` — passed for changed Elixir files.
- `git diff --check` — passed.
- `PATH="$PWD/bin:$PATH" dev check` — exited successfully.
  - ExUnit: `824 tests, 0 failures`
  - Acceptance: `82 scenarios passed`, `493 steps passed`

Note: a direct `cd web && mix test ...` attempt failed outside the dev wrapper because Postgres was not available at `/tmp/devenv/postgres/.s.PGSQL.15432`. Running through the project dev wrapper succeeded.

## Remaining gaps / human questions

Out-of-scope judgement-heavy items remain unchanged:
- durable recovery/sweep for missed PubSub nudges,
- stale `dispatching` recovery,
- projection determinism/event enrichment,
- provider-level idempotency.

Those were not part of the synthesized bounded repair set.