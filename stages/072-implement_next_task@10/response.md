1. **Selected todo line**
   - `- [ ] 010 Add an internal/manual retry API for failed deliveries. Do not add automatic retries, startup sweeps, periodic sweeps, or staff retry UI in this slice.`

2. **Changes made**
   - Added `Memba.Messaging.retry_failed_email_delivery/1` as the internal/operator-facing API.
   - Added `Memba.Messaging.EmailDeliveryDispatcher.retry_failed_delivery/1`.
   - Retry behavior:
     - validates/casts delivery IDs through the context API,
     - retries only deliveries currently in `failed`,
     - atomically claims a failed delivery by moving it to `dispatching`,
     - calls the provider through the dispatcher boundary,
     - marks retry success as `sent`, clears diagnostics, clears `failed_at`, sets `sent_at`, and increments `attempt_count`,
     - marks retry failure as `failed`, increments `attempt_count`, and persists fresh diagnostics,
     - rejects invalid/missing/non-failed deliveries without provider handoff.
   - Updated dispatcher docs to remove the stale “later retry” note and clarify no automatic retry sweeps.
   - Added focused manual retry tests in `email_delivery_dispatcher_test.exs`.

3. **Focused validation commands run**
   - Initial preferred direct command:
     - `PATH="$PWD/bin:$PATH" bin/mix test web/test/memba/messaging/email_delivery_dispatcher_test.exs`
     - Did not reach test execution due sandbox `PGHOST` mismatch / Postgres readiness issue.
   - Focused test command via `devenv shell` because of that PGHOST issue:
     - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" ../bin/mix test test/memba/messaging/email_delivery_dispatcher_test.exs'`
     - Passed: `14 tests, 0 failures`.
   - Formatting:
     - `cd web && PATH="$PWD/../bin:$PATH" ../bin/mix format --check-formatted lib/memba/messaging.ex lib/memba/messaging/email_delivery_dispatcher.ex test/memba/messaging/email_delivery_dispatcher_test.exs`
     - Passed.
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Output still reports `816 tests, 17 failures`, matching remaining suite assumptions around immediate provider delivery / provider-unavailability behavior that belong to later unchecked tasks.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 010 Add an internal/manual retry API for failed deliveries. Do not add automatic retries, startup sweeps, periodic sweeps, or staff retry UI in this slice.`
   - To:
     - `- [x] 010 Add an internal/manual retry API for failed deliveries. Do not add automatic retries, startup sweeps, periodic sweeps, or staff retry UI in this slice.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / architecture conformance evidence**
   - No ADR was explicitly referenced by the plan.
   - Retry does not dispatch commands or create new message/delivery events.
   - Provider side effects remain outside aggregate replay and projector replay.
   - Manual retry is explicit and internal; no automatic retry, startup sweep, periodic sweep, or staff UI was added.
   - Retry uses the existing dispatcher/provider boundary and updates the existing `EmailDelivery` read model lifecycle.