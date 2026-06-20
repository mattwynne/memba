1. **Selected todo line**
   - `- [ ] 005 Make the dispatcher subscribe to Memba.ReadModelChanges.topic() and treat relevant EmailDeliveryCreated/EmailDelivery projection changes as a nudge to dispatch pending email deliveries.`

2. **Changes made**
   - Updated `web/lib/memba/messaging/email_delivery_dispatcher.ex`
     - Subscribes to `Memba.ReadModelChanges.topic()` during `init/1`.
     - Handles committed read-model-change messages for:
       - `projector: Memba.Messaging.Projectors.EmailDelivery`
       - `source_event: %Memba.Messaging.Events.EmailDeliveryCreated{}`
     - Converts those relevant messages into an internal pending-delivery dispatch nudge.
     - Ignores unrelated read-model changes.
     - Does **not** implement claiming, provider delivery, retries, or status transitions; those remain for later todos.
   - Added `web/test/memba/messaging/email_delivery_dispatcher_test.exs`
     - Proves the dispatcher receives relevant committed read-model changes and nudges dispatch.
     - Proves unrelated read-model changes are ignored.
   - Updated `docs/iterations/038-email-delivery-handoff-boundary/todo.md`
     - Checked off only task 005.

3. **Focused validation commands run and results**
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/messaging/email_delivery_dispatcher.ex test/memba/messaging/email_delivery_dispatcher_test.exs`
     - Passed.
   - Focused tests:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/email_delivery_dispatcher_test.exs'`
     - Passed: `2 tests, 0 failures`.
   - Focused messaging app/dispatcher tests:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/app_test.exs test/memba/messaging/email_delivery_dispatcher_test.exs'`
     - Passed: `6 tests, 0 failures`.
   - Broad quick check:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" dev check --quick'`
     - Passed: `804 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.

   Note: I used `devenv shell` for test/check commands because the outer sandbox had stale `PGHOST=/tmp/devenv/postgres`, while `devenv shell` correctly set the active socket path.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 005 Make the dispatcher subscribe to Memba.ReadModelChanges.topic() and treat relevant EmailDeliveryCreated/EmailDelivery projection changes as a nudge to dispatch pending email deliveries.`
   - To:
     - `- [x] 005 Make the dispatcher subscribe to Memba.ReadModelChanges.topic() and treat relevant EmailDeliveryCreated/EmailDelivery projection changes as a nudge to dispatch pending email deliveries.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002 / CQRS: kept provider side effects outside aggregate command handling and only added async dispatch-boundary wiring.
   - ADR 0009: preserved projector responsibilities; the dispatcher reacts after committed projection publication, not during projection/replay.
   - ADR 0021: uses the existing committed read-model-change PubSub topic and filters by projector/source event as intended.
   - ADR 0016: no provider selection or adapter behavior changed.
   - ADR 0022: did not conflate projection barriers with read-model-change notifications; this task only consumes the notification bus.