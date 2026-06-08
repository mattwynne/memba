1. **Selected todo line**
   - `004 Authorize the route/action using the club.manage_members permission for the signed-in person in the current club.`

2. **Changes made**
   - Updated `web/lib/memba_web/live/member_invitation_live/new.ex`
     - The invitation LiveView now authorizes the selected club context by:
       - resolving the signed-in person from the current identity email;
       - checking `Memba.Membership.person_has_club_permission?/3`;
       - requiring `Memba.Membership.Permissions.club_manage_members()`;
       - rejecting unauthorized access with `MembaWeb.ForbiddenError`.
   - Updated `web/test/memba_web/live/member_invitation_live/new_test.exs`
     - Existing successful route/host tests now create a Membership Admin fixture.
     - Added coverage that:
       - an active ordinary member without `club.manage_members` is forbidden;
       - a member with `club.manage_members` in a different club is still forbidden for the selected club.
     - Added test helpers for projecting `membership_member_permissions`.

3. **Focused validation commands run**
   - Formatting check:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/member_invitation_live/new.ex test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/member_invitation_live/new_test.exs test/memba_web/router_test.exs`
     - Passed: `18 tests, 0 failures`.
   - Whitespace check:
     - `git diff --check`
     - Passed.
   - Full required validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `69 scenarios (69 passed), 466 steps (466 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Authorize the route/action using the club.manage_members permission for the signed-in person in the current club.`
   - To:
     - `- [x] 004 Authorize the route/action using the club.manage_members permission for the signed-in person in the current club.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0015: kept the member-facing invitation surface as a LiveView.
   - ADR 0007: the LiveView uses the Membership public API for permission checks rather than querying projection tables directly.
   - ADR 0013: added focused web/LiveView tests around authorization behaviour and route access.