1. **Selected todo line**
   - `- [ ] 009 Remove the synchronous provider call from `send_club_message/2`; keep its success contract tied to command acceptance/recording, not provider availability.`

2. **Changes made**
   - Updated `Memba.Messaging.send_club_message/2` so it now:
     - builds the `SendMessage` command,
     - dispatches it to the Messaging Commanded app,
     - returns the dispatch result,
     - **does not call the email provider inline**.
   - Removed the private `Memba.Messaging.deliver_to_provider/1` handoff.
   - Removed the temporary `EmailDeliveryDispatcher.deliver_to_provider/1` clause that accepted a `%SendMessage{}` command and synchronously delivered all recipients.
   - Kept provider delivery available only through dispatcher delivery records, i.e. `%EmailDeliveryProjection{}`.
   - Updated `send_club_message_test.exs` to prove:
     - browser/composed send records `pending` `EmailDelivery` work,
     - provider calls are not made during `send_club_message/2`,
     - configured provider failure no longer makes message acceptance fail.
   - In those focused tests, the supervised dispatcher is stopped/restarted around each test to isolate and prove `send_club_message/2` itself does not perform provider handoff.

3. **Focused validation commands run**
   - Initial direct focused command:
     - `PATH="$PWD/bin:$PATH" bin/mix test web/test/memba/messaging/send_club_message_test.exs`
     - Did not reach test execution due the sandbox `PGHOST` mismatch:
       - `Postgres did not become ready at PGHOST=/tmp/devenv/postgres PGPORT=15432`
   - Formatting:
     - `cd web && PATH="$PWD/../bin:$PATH" ../bin/mix format --check-formatted lib/memba/messaging.ex lib/memba/messaging/email_delivery_dispatcher.ex test/memba/messaging/send_club_message_test.exs`
     - Passed.
   - Focused send tests:
     - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" ../bin/mix test test/memba/messaging/send_club_message_test.exs'`
     - Passed: `5 tests, 0 failures`.
   - Focused send + dispatcher tests:
     - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" ../bin/mix test test/memba/messaging/send_club_message_test.exs test/memba/messaging/email_delivery_dispatcher_test.exs'`
     - Passed: `16 tests, 0 failures`.
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Failed: `813 tests, 17 failures`.
     - The failures are remaining suite/acceptance assumptions that provider deliveries are immediately visible after send, or that provider unavailability makes message submission fail. Those expectations are now intentionally stale after task 009 and align with pending follow-up tasks for inbound flow/test adaptation and broader acceptance-criteria updates.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Remove the synchronous provider call from `send_club_message/2`; keep its success contract tied to command acceptance/recording, not provider availability.`
   - To:
     - `- [x] 009 Remove the synchronous provider call from `send_club_message/2`; keep its success contract tied to command acceptance/recording, not provider availability.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / architecture conformance evidence**
   - Provider side effects are no longer part of `send_club_message/2` command acceptance.
   - Provider calls remain outside aggregate and projector replay paths.
   - Provider dispatch remains behind the existing provider abstraction and now occurs through the dispatcher/projection path only.
   - The command-side success contract is tied to command acceptance/recording, not provider availability.
   - No automatic retries, sweeps, staff UI, or acceptance feature file edits were introduced in this task.