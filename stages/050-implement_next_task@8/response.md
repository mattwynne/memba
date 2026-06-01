Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 Preserve or deliberately update stable selectors used by browser acceptance:`

2. **Changes made**
   - Added a focused LiveView test in `web/test/memba_web/live/member_dashboard_live_test.exs` that locks down the browser-acceptance selector contract for the member dashboard:
     - `#member-club-home[data-club-id=...]`
     - `#member-send-message-link[href="/messages/new?club_id=..."]`
     - `[data-testid="club-message-row"]`
     - `data-message-id`
     - `data-message-subject`
     - `[data-testid="club-message-link"]`
     - `[data-testid="club-member-row"]`
     - `data-member-id`
     - `data-member-name`
   - No acceptance feature files were changed.

3. **Validation commands run**
   - `cd web && mix format --check-formatted`
     - Passed after formatting indentation fix.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `253 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - `cd acceptance-tests && node --test test/member_message_steps.test.js`
     - Attempted as a focused helper check, but could not run because bare-shell acceptance dependencies are not installed: missing `@playwright/test`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Preserve or deliberately update stable selectors used by browser acceptance:`
   - To:
     - `- [x] 008 Preserve or deliberately update stable selectors used by browser acceptance:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015 remains satisfied: the signed-in selected-club home remains LiveView-backed through `MembaWeb.MemberDashboardLive`.
   - This task only added selector-contract coverage for the existing LiveView dashboard; it did not change routing, public/logged-out behavior, or controller/static page boundaries.