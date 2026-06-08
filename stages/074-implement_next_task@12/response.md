Implemented the next unchecked task.

1. **Selected todo line**
   - `011 Add or update LiveView/controller tests for Membership Admin visibility, ordinary member non-visibility, and direct URL/action rejection.`

2. **Changes made**
   - Updated `web/test/memba_web/live/member_invitation_live/new_test.exs`
     - Added focused LiveView coverage for a crafted invitation submit after the actor’s `club.manage_members` permission is removed.
     - Asserts the action is rejected, no pending invitation is created, and no email is sent.
   - Updated `web/lib/memba_web/live/member_invitation_live/new.ex`
     - Mapped `:unauthorized` invitation-service failures to the existing clear forbidden message: “You are not allowed to invite members for this club.”
   - Existing web tests already covered:
     - Membership Admin visibility of the invite action.
     - Ordinary member non-visibility.
     - Direct URL rejection for ordinary members / wrong-club permissions.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/member_invitation_live/new.ex test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/member_invitation_live/new_test.exs`
     - Failed before tests due existing Postgres `postmaster.pid` / readiness issue.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed: `9 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/member_dashboard_live_test.exs`
     - Passed: `15 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - From:
     - `- [ ] 011 Add or update LiveView/controller tests for Membership Admin visibility, ordinary member non-visibility, and direct URL/action rejection.`
   - To:
     - `- [x] 011 Add or update LiveView/controller tests for Membership Admin visibility, ordinary member non-visibility, and direct URL/action rejection.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan did not explicitly reference any ADRs, and no `docs/adr/*.md` files were present.
   - The change keeps authorization at the Membership application-service boundary and adds only focused Phoenix LiveView/web coverage for the selected task.