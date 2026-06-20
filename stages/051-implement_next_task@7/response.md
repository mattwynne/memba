1. **Selected todo line**
   - `- [ ] 007 Move request-building/provider-call logic out of Memba.Messaging into the dispatcher or a focused collaborator used by the dispatcher.`

2. **Changes made**
   - Moved provider request-building and provider adapter calls out of `Memba.Messaging`.
   - `Memba.Messaging` now delegates its temporary synchronous handoff to `Memba.Messaging.EmailDeliveryDispatcher.deliver_to_provider/1`.
   - Added dispatcher-owned provider handoff support:
     - Builds `EmailDeliveryRequest` from a projected `EmailDelivery` plus projected `Message` context.
     - Enriches request context through Membership public queries for club/sender information.
     - Calls the configured `EmailDeliveryProvider` from the dispatcher boundary.
     - Keeps a temporary `SendMessage` clause to preserve existing synchronous behavior until task 009 removes it.
   - Added focused tests proving dispatcher-owned handoff:
     - Successful request construction from projections.
     - No provider call when the message projection is missing.

3. **Validation commands run**
   - Initial focused run:
     - `PATH="$PWD/bin:$PATH" bin/mix test web/test/memba/messaging/email_delivery_dispatcher_test.exs`
     - Failed due known sandbox `PGHOST` socket mismatch.
   - Formatting:
     - `cd web && PATH="$PWD/../bin:$PATH" ../bin/mix format --check-formatted lib/memba/messaging.ex lib/memba/messaging/email_delivery_dispatcher.ex test/memba/messaging/email_delivery_dispatcher_test.exs`
     - Passed.
   - Focused tests:
     - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" ../bin/mix test test/memba/messaging/email_delivery_dispatcher_test.exs test/memba/messaging/send_club_message_test.exs'`
     - Passed: `14 tests, 0 failures`.
   - Broad quick check:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" dev check --quick'`
     - Passed: `811 tests, 0 failures`.
   - Full check:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" dev check'`
     - Passed: `811 tests, 0 failures`; acceptance: `82 scenarios, 493 steps passed`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Move request-building/provider-call logic out of Memba.Messaging into the dispatcher or a focused collaborator used by the dispatcher.`
   - To:
     - `- [x] 007 Move request-building/provider-call logic out of Memba.Messaging into the dispatcher or a focused collaborator used by the dispatcher.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002 / CQRS: provider side-effect boundary moved out of the Messaging application service toward the dispatcher; domain command handling remains separate.
   - ADR 0009: projection replay remains provider-side-effect-free; the new handoff function reads projections but is not invoked from projector replay.
   - ADR 0016: provider selection remains behind `EmailDeliveryProvider`; no provider adapter behavior or runtime config semantics changed.
   - ADR 0021: dispatcher remains the subscriber to committed read-model changes; this task only adds the handoff boundary it will use.
   - ADR 0022: no projection barriers were added or conflated with read-model-change notifications.