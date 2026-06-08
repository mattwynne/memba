Implemented the next unchecked task.

1. **Selected todo line**
   - `004 Authorize the route/action using the club.manage_members permission for the signed-in person in the current club.`

2. **Changes made**
   - Updated `web/lib/memba_web/live/club_member_invitations_live/new.ex`
     - The member invitation LiveView now requires the current active member to have `club.manage_members` for the selected/current club.
     - Uses the Membership public query API: `Membership.person_has_club_permission?/3` with `Permissions.club_manage_members()`.
   - Updated `web/test/memba_web/live/club_member_invitations_live/new_test.exs`
     - Existing successful route tests now grant `club.manage_members`.
     - Added a focused authorization test proving an active member without `club.manage_members` is rejected with `MembaWeb.ForbiddenError` / `plug_status == 403`.
     - Added a helper to insert projected member permissions for the test setup.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format lib/memba_web/live/club_member_invitations_live/new.ex test/memba_web/live/club_member_invitations_live/new_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/club_member_invitations_live/new_test.exs`
     - Hit the sandbox PGHOST/socket readiness mismatch before tests ran.
   - `devenv shell -- bin/mix test test/memba_web/live/club_member_invitations_live/new_test.exs`
     - Passed: `4 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `727 tests, 0 failures`; acceptance `69 scenarios (69 passed)`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Authorize the route/action using the club.manage_members permission for the signed-in person in the current club.`
   - To:
     - `- [x] 004 Authorize the route/action using the club.manage_members permission for the signed-in person in the current club.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: stays within Phoenix/Phoenix LiveView.
   - ADR 0007: uses the Membership public query API for membership authorization state.
   - ADR 0009: authorization reads projected permission state rather than aggregate internals.
   - ADR 0015: keeps the member-facing application page as a LiveView.