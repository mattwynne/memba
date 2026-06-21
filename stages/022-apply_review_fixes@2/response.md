Implemented the bounded review repair pass for iteration 038.

## Issue-to-fix mapping

| Review issue | Resolution | Files/modules/tests |
|---|---|---|
| `email-delivery-diagnostics-docs` | Already satisfied in the current checkout. `EmailDelivery` has moduledoc documentation clarifying `attempt_count`, `last_dispatch_attempted_at`, `sent_at`, and `failed_at` dispatch-diagnostic semantics. No additional change needed in this pass. | Existing: `web/lib/memba/messaging/projections/email_delivery.ex` |
| `email-delivery-test-provider-cleanup` | Fixed. Removed the misleading defaulted `start_link/0` option seam from the `SelectiveFailure` test provider. It now exposes `start_link/1`, matching how supervisors/start_supervised pass child args while making clear no optional configuration is supported. | Changed: `web/test/support/messaging/email_delivery_providers/selective_failure.ex` |
| `inbound-email-dispatch-regression-test` | Already satisfied in the current checkout. There is a focused regression test proving accepted inbound club email is dispatched through the read-model-change dispatcher nudge. No additional change needed in this pass. | Existing: `web/test/memba/messaging/inbound_club_message_acceptance_test.exs` |

## Concrete change made

Changed:

```elixir
def start_link(_opts \\ []) do
```

to:

```elixir
def start_link(_opts) do
```

in `Memba.Messaging.EmailDeliveryProviders.SelectiveFailure`.

No acceptance feature files were edited.

## Files changed

### `email-delivery-test-provider-cleanup`

- `web/test/support/messaging/email_delivery_providers/selective_failure.ex`

## Tests / checks run

- `cd web && mix format --check-formatted test/support/messaging/email_delivery_providers/selective_failure.ex lib/memba/messaging/projections/email_delivery.ex test/memba/messaging/inbound_club_message_acceptance_test.exs`
  - Passed.

- `cd web && mix test test/memba/messaging/email_delivery_dispatcher_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs`
  - Did not run successfully because direct `mix test` could not connect to unmanaged Postgres at `/tmp/devenv/postgres/.s.PGSQL.15432`.
  - I did not patch app/test code for this sandbox/runtime boundary; validation continued through the repo `dev` helper.

- `PATH="$PWD/bin:$PATH" dev check --quick`
  - Passed.
  - `822 tests, 0 failures`.

- `PATH="$PWD/bin:$PATH" dev check`
  - Passed.
  - ExUnit: `822 tests, 0 failures`.
  - Acceptance: `82 scenarios, 493 steps, all passed`.

## Remaining gaps / human questions

None for the selected review issues. The only remaining untracked path is existing workflow artifact state under `.fabro/tmp/`.