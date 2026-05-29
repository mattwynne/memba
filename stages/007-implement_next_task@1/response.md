Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 001 Extend the Message aggregate with commands and events for delivered,`

2. **Changes made**
   - Added Messaging command modules for:
     - delivered
     - delayed
     - bounced
     - spam complaint
     - opened
   - Added corresponding domain event modules, preserving `reason` on delayed/bounced/spam complaint events.
   - Extended `Memba.Messaging.Message` aggregate with:
     - per-delivery status state
     - valid transition rules
     - invalid transition rejection
     - idempotency for repeated equivalent reports, including repeated opens
     - reason conflict rejection for same-status reports with different reason text
   - Registered the new commands in `Memba.Messaging.Router`.
   - Updated app/router tests to include the new commands.
   - Added aggregate tests for:
     - emitted delivery status events
     - malformed command rejection
     - unknown delivery/message mismatch rejection
     - valid delayed recovery/problem transitions
     - invalid status transitions
     - idempotent repeated reports
     - aggregate `apply/2` status state updates
   - Added dispatch coverage proving delivery status commands route through Commanded and repeated opened reports produce no new events.
   - `mix format` also reformatted two pre-existing long lines touched by the required `dev check` formatting gate:
     - `web/lib/memba/messaging/delivery_provider.ex`
     - `web/test/features/cucumber_configuration_test.exs`

3. **Validation**
   - Ran:
     - `cd web && mix format --check-formatted` — passed
     - `PATH="$PWD/bin:$PATH" dev check` — passed
   - Final `dev check` result:
     - `80 tests, 0 failures`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 Extend the Message aggregate with commands and events for delivered,`
   - To:
     - `- [x] 001 Extend the Message aggregate with commands and events for delivered,`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0004: delivery status state and transition rules are owned by the single Message aggregate.
   - ADR 0012: `opened` is modeled as a boolean-like terminal status; repeated opens are idempotent and no open count/timestamp/device data was added.
   - ADR 0006: detailed statuses now exist in the domain so later member/operator projections can map or preserve them appropriately.
   - ADR 0011: commands route by caller-supplied `message_id`; no aggregate-generated identity was introduced.