1. **Selected todo line**
   - `011 Add or update LiveView/controller tests for Membership Admin visibility, ordinary member non-visibility, and direct URL/action rejection.`

2. **Changes made**
   - Updated `web/test/memba_web/live/club_member_invitations_live/send_test.exs`.
   - Added a focused web test proving an ordinary club member cannot use a direct/crafted invitation request:
     - raises `MembaWeb.ForbiddenError` with `plug_status == 403`
     - does not create a pending club member invitation
     - does not send an invitation email
   - Existing web tests already cover:
     - Membership Admin invite-link visibility in `member_dashboard_live_test.exs`
     - ordinary-member invite-link non-visibility
     - direct routed GET rejection in `club_member_invitations_live/new_test.exs`

3. **Focused validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/live/club_member_invitations_live/send_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/club_member_invitations_live/send_test.exs`
     - Failed due sandbox PostgreSQL readiness/lock mismatch.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/club_member_invitations_live/send_test.exs`
     - Passed: `3 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/club_member_invitations_live/new_test.exs test/memba_web/live/club_member_invitations_live/send_test.exs`
     - Passed: `23 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `740 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 011 Add or update LiveView/controller tests for Membership Admin visibility, ordinary member non-visibility, and direct URL/action rejection.`
   - To:
     - `- [x] 011 Add or update LiveView/controller tests for Membership Admin visibility, ordinary member non-visibility, and direct URL/action rejection.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADRs were explicitly referenced by the plan.
   - The test follows local Phoenix/LiveView testing guidance by asserting through routed web behavior and stable DOM/route outcomes.
   - No acceptance feature files, routes, UI behavior, dependencies, or unrelated functionality were changed.