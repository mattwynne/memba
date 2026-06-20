1. **Selected todo line**
   - `- [ ] 011 Adapt accepted inbound club-message flow so it relies on the same pending-delivery projection and dispatcher path.`

2. **Changes made**
   - Clarified `Memba.Messaging.receive_inbound_club_email/2` docs to say accepted inbound email creates pending delivery projections for dispatcher handoff.
   - Updated inbound club-message acceptance tests to assert:
     - accepted inbound email creates `pending` delivery records,
     - no provider calls happen inline,
     - `EmailDeliveryDispatcher.dispatch_pending_email_deliveries/0` performs provider handoff and marks deliveries `sent`,
     - duplicate inbound provider retries do not create new messages or dispatch duplicate deliveries.
   - Updated Postmark and Resend inbound webhook controller tests with the same pending-then-dispatch expectation.
   - No acceptance feature files were edited.

3. **Validation run**
   - Formatting check:
     - `cd web && PATH="$PWD/../bin:$PATH" ../bin/mix format --check-formatted lib/memba/messaging.ex test/memba/messaging/inbound_club_message_acceptance_test.exs test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
     - Passed.
   - Focused tests:
     - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" ../bin/mix test test/memba/messaging/inbound_club_message_acceptance_test.exs test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs test/memba_web/controllers/resend_inbound_webhook_controller_test.exs'`
     - Passed: `33 tests, 0 failures`.
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Completed but still reported `816 tests, 8 failures`, all around remaining immediate-provider-delivery/failure expectations in broader acceptance/LiveView coverage that align with later unchecked tasks.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 011 Adapt accepted inbound club-message flow so it relies on the same pending-delivery projection and dispatcher path.`
   - To:
     - `- [x] 011 Adapt accepted inbound club-message flow so it relies on the same pending-delivery projection and dispatcher path.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / architecture conformance**
   - No ADR was explicitly referenced by the plan.
   - Changes preserve the CQRS/event-sourcing boundary: inbound acceptance records domain events and read models; provider side effects are asserted to happen only through the dispatcher path.
   - Duplicate inbound provider retries do not create duplicate messages or duplicate provider dispatches.
   - Provider handoff remains outside aggregate/projector replay and outside `receive_inbound_club_email/2` inline execution.