Implemented task 019.

1. **Selected todo line**
   - `019 Add tests for member-visible inbound address display on dashboard and compose.`

2. **Changes made**
   - Strengthened the existing dashboard LiveView test in:
     - `web/test/memba_web/live/member_dashboard_live_test.exs`
   - Strengthened the existing compose LiveView test in:
     - `web/test/memba_web/live/member_message_live/new_test.exs`
   - Added assertions that the visible inbound-email affordance includes member-facing guidance:
     - `Prefer email?`
     - `Send a club-wide message to`
   - Existing assertions still verify:
     - `data-inbound-address="kmc@clubs.memba.io"`
     - `mailto:kmc@clubs.memba.io`
     - visible address text `kmc@clubs.memba.io`

3. **Validation**
   - `mix format web/test/memba_web/live/member_dashboard_live_test.exs web/test/memba_web/live/member_message_live/new_test.exs`
     - Passed.
   - Attempted focused LiveView test command:
     - `PATH="$PWD/bin:$PATH" bin/mix test web/test/memba_web/live/member_dashboard_live_test.exs web/test/memba_web/live/member_message_live/new_test.exs`
     - Blocked by the sandbox/devenv duplicate Postgres startup lock before tests executed.
   - Broad validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `461 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 019 Add tests for member-visible inbound address display on dashboard and compose.`
   - To:
     - `- [x] 019 Add tests for member-visible inbound address display on dashboard and compose.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Kept this in the Phoenix app test suite.
   - ADR 0013: Used Phoenix/LiveView test helpers for user-visible web behaviour.
   - ADR 0015: Covered member dashboard and compose LiveView/member-app surfaces without changing architecture or domain boundaries.