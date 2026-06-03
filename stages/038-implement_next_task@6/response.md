1. **Selected todo line**
   - `006 Add inbound email events such as:`

2. **Changes made**
   - Added provider-neutral inbound outcome event modules:
     - `Memba.Messaging.Events.InboundClubEmailAccepted`
       - Includes inbound aggregate id, provider/message ids, optional provider event id, from/to addresses, resolved club id, resolved sender id, and created message id.
     - `Memba.Messaging.Events.InboundClubEmailRejected`
       - Includes inbound aggregate id, provider/message ids, optional provider event id, from address, optional to address, rejection reason, and optional rejection email delivery reference.
   - Both events derive `Jason.Encoder` for Commanded/EventStore serialization.
   - Added tests in `web/test/memba/messaging/inbound_email_events_test.exs` proving event field shape and JSON serialization, including optional rejected-email fields.

3. **Validation**
   - `cd web && ../bin/mix format` — passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed:
     - `415 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - ExUnit: `415 tests, 0 failures`
     - Acceptance: `31 scenarios (31 passed), 205 steps (205 passed)`
   - `git diff --check` — passed.
   - Note: direct focused `mix test test/memba/messaging/inbound_email_events_test.exs` attempts were blocked by the local bare Mix/Postgres socket mismatch before test execution; the same test file was included successfully in `dev check --quick` and full `dev check`.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 006 Add inbound email events such as:`
   - To:
     - `- [x] 006 Add inbound email events such as:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Adds explicit domain events for Commanded/event-sourced workflow history.
   - ADR 0007: Keeps the work inside the Messaging bounded context and does not query or mutate Membership.
   - ADR 0008/0009: Events are serializable and ready to drive later EventStore-backed projections; no projection state was invented in this task.
   - ADR 0016: Events remain provider-neutral and do not introduce Resend-specific parsing or webhook coupling.