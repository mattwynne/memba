Implemented the selected bounded review repairs for iteration 038. No acceptance feature files were edited.

## Issue-to-fix mapping

| Review issue | Resolution | Files/modules/tests |
|---|---|---|
| `email-delivery-status-db-constraint` | No new change needed: the implementation already has a DB check constraint and tests proving allowed/rejected status vocabulary. Verified during `dev check`. | Existing: `web/priv/repo/migrations/20260620071150_add_status_constraints_to_messaging_email_deliveries.exs`, `web/test/memba/messaging/email_delivery_status_constraints_test.exs` |
| `email-delivery-diagnostics-docs` | Added projection moduledoc documentation clarifying operational semantics for `attempt_count`, `last_dispatch_attempted_at`, `sent_at`, and `failed_at`. | `web/lib/memba/messaging/projections/email_delivery.ex` |
| `email-delivery-test-provider-cleanup` | Removed the misleading `:name` option seam from `SelectiveFailure.start_link/1`; it now consistently starts its Agent under the module name used by its helper functions. | `web/test/support/messaging/email_delivery_providers/selective_failure.ex` |
| `inbound-email-dispatch-regression-test` | Added a focused regression test proving accepted inbound club email is dispatched by the read-model-change PubSub nudge through `EmailDeliveryDispatcher`, not just by a manual dispatch call. | `web/test/memba/messaging/inbound_club_message_acceptance_test.exs` |

## Files changed

- `web/lib/memba/messaging/projections/email_delivery.ex`
- `web/test/support/messaging/email_delivery_providers/selective_failure.ex`
- `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`

## Tests / checks run

- `cd web && mix format --check-formatted ...` — passed for changed files.
- Initial direct `mix test ...` attempt failed because Postgres was not running when bypassing the repo `dev` helper.
- `PATH="$PWD/bin:$PATH" dev check --quick` — passed.
  - 822 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev check` — passed.
  - 822 ExUnit tests, 0 failures.
  - 82 acceptance scenarios, 493 steps, all passed.

## Remaining gaps / human questions

None for the selected repair issues.

The existing untracked `.fabro/tmp/` workflow artifacts remain untouched.