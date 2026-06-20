1. **Selected todo line**
   - `- [ ] 008 On provider success, update the delivery to `sent`; on provider error, update it to `failed`, increment attempt count, and persist the latest error/detail.`

2. **Changes made**
   - Updated `Memba.Messaging.EmailDeliveryDispatcher` to:
     - Claim pending deliveries, hand them to the provider, and persist outcomes.
     - Mark provider-accepted deliveries as `sent`.
     - Mark errored deliveries as `failed`.
     - Increment `attempt_count` on failure.
     - Persist `latest_error`, `latest_detail`, and `failed_at` on failure.
     - Clear stale error/failure fields and set `sent_at` on success.
     - Keep each delivery independent so one failure does not stop later claimed deliveries.
   - Updated dispatcher read-model-change handling so a nudge now dispatches claimed deliveries rather than only claiming them.
   - Added focused tests in `email_delivery_dispatcher_test.exs` for:
     - Nudge-driven dispatch ending in `sent`.
     - Pending delivery dispatch success persistence.
     - Provider error persistence with failed status and diagnostics.

3. **Focused validation commands run**
   - TDD/initial focused run:
     - `PATH="$PWD/bin:$PATH" bin/mix test web/test/memba/messaging/email_delivery_dispatcher_test.exs`
     - Did not reach test execution due the known direct-wrapper `PGHOST` socket mismatch.
   - Formatting:
     - `cd web && PATH="$PWD/../bin:$PATH" ../bin/mix format --check-formatted lib/memba/messaging/email_delivery_dispatcher.ex test/memba/messaging/email_delivery_dispatcher_test.exs`
     - Passed after formatting adjustment.
   - Focused tests:
     - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" ../bin/mix test test/memba/messaging/email_delivery_dispatcher_test.exs'`
     - Passed: `11 tests, 0 failures`.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `813 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 On provider success, update the delivery to `sent`; on provider error, update it to `failed`, increment attempt count, and persist the latest error/detail.`
   - To:
     - `- [x] 008 On provider success, update the delivery to `sent`; on provider error, update it to `failed`, increment attempt count, and persist the latest error/detail.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002 / CQRS: provider side effects remain outside command/aggregate handling; dispatcher owns operational side-effect orchestration.
   - ADR 0009: projector replay remains side-effect-free; outcome persistence is performed by dispatcher code, not by projection replay.
   - ADR 0016: provider calls remain behind the existing `EmailDeliveryProvider` abstraction.
   - ADR 0021: dispatcher continues to react to committed read-model-change nudges and now completes the dispatch lifecycle after claiming.
   - ADR 0022: no projection barriers were added or conflated with read-model notifications.