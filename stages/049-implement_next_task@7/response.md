Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Update member dashboard and member compose copy/mailto links to display the new address.`

2. **Changes made**
   - The dashboard and compose UI already use `Memba.ClubInboundEmailAddress.address/1`, which now renders `everyone@<slug>.clubs.memba.io`.
   - Added focused regression assertions to:
     - `web/test/memba_web/live/member_dashboard_live_test.exs`
     - `web/test/memba_web/live/member_message_live/new_test.exs`
   - These now prove both surfaces:
     - expose `everyone@kmc.clubs.memba.io`;
     - use `mailto:everyone@kmc.clubs.memba.io`;
     - do **not** expose the old `kmc@clubs.memba.io` data attribute or mailto link.

3. **Validation run**
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_message_live/new_test.exs`
     - Result: exit 0.
   - Focused LiveView tests:
     - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 bin/mix test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_message_live/new_test.exs`
     - Result: `27 tests, 0 failures`.
   - Full project check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: command returned exit 0 on the current code/test diff. Afterward I only changed the todo checkbox.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Update member dashboard and member compose copy/mailto links to display the new address.`
   - To:
     - `- [x] 007 Update member dashboard and member compose copy/mailto links to display the new address.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015 preserved: member dashboard and compose remain LiveView/member app surfaces.
   - ADR 0013 preserved: coverage stays in focused web/LiveView tests using stable selectors.
   - ADR 0007 unaffected: no Membership/Messaging boundary changes; the UI continues using the existing selected club data and shared inbound-address helper.