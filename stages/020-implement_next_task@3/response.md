Implemented the next unchecked task.

1. **Selected todo line**
   - `003 Show the derived inbound address on the member dashboard and member compose page for the selected club.`

2. **Changes made**
   - Dashboard:
     - Added an inbound email callout in `web/lib/memba_web/controllers/page_html/club.html.heex`.
     - Displays `kmc@clubs.memba.io` via the existing `Memba.ClubInboundEmailAddress` helper.
     - Includes a `mailto:` link and stable selectors:
       - `#member-dashboard-inbound-email`
       - `#member-dashboard-inbound-email-link`
   - Compose page:
     - Added an inbound email callout in `web/lib/memba_web/live/member_message_live/new.ex`.
     - Displays the selected club’s derived inbound email address with a `mailto:` link.
     - Includes stable selectors:
       - `#member-compose-inbound-email`
       - `#member-compose-inbound-email-link`
   - Tests:
     - Added dashboard coverage in `web/test/memba_web/live/member_dashboard_live_test.exs`.
     - Added compose coverage in `web/test/memba_web/live/member_message_live/new_test.exs`.
     - Extended the dashboard test fixture helper so tests can create a club with an explicit slug.

3. **Validation**
   - `cd web && ../bin/mix format` — passed.
   - `cd web && ../bin/mix compile --warnings-as-errors` — passed.
   - Focused LiveView tests in clean devenv shell:
     - `mix test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_message_live/new_test.exs`
     - Passed: `21 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed: `403 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - ExUnit: `403 tests, 0 failures`
     - Acceptance: `31 scenarios (31 passed), 205 steps (205 passed)`
   - `git diff --check` — passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.`
   - To:
     - `- [x] 003 Show the derived inbound address on the member dashboard and member compose page for the selected club.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Respects ADR 0015 by keeping member app changes in LiveView-backed member surfaces.
   - Respects ADR 0013 by adding user-visible Phoenix/LiveView tests for dashboard and compose behaviour.
   - Respects ADR 0019 by deriving the email address from the club slug while keeping inbound email domain separate from club-site routing/domain config.
   - Respects ADR 0007 by only reading selected club presentation data and not mutating Membership or Messaging state.