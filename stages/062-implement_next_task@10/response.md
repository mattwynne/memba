1. **Selected todo line**
   - `009 Ensure accepted Membership Admin invitations create ordinary active memberships only.`

2. **Changes made**
   - Updated `web/test/memba/membership/club_member_invitation_lifecycle_test.exs`.
   - Added assertions to the existing Membership Admin unknown-invitee lifecycle test proving the accepted invitee:
     - becomes an active club member,
     - does **not** receive `club.manage_members`,
     - has no active role assignments.
   - Added a focused lifecycle test for an existing complete person invited by a Membership Admin, proving acceptance creates an ordinary active membership only.
   - Added a small `active_role_assignments/1` test helper.
   - Updated `docs/iterations/029-membership-admin-invitations/todo.md` to check off only task `009`.

3. **Focused validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Initially failed on one indentation issue; fixed.
     - Re-run passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Failed before tests due the known sandbox `PGHOST` mismatch.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Passed: `13 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `740 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   - From:
     - `- [ ] 009 Ensure accepted Membership Admin invitations create ordinary active memberships only.`
   - To:
     - `- [x] 009 Ensure accepted Membership Admin invitations create ordinary active memberships only.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: Kept invitation/membership lifecycle in the existing Commanded/event-sourced Membership flow.
   - ADR 0007: Stayed within the Membership bounded context; no Messaging or cross-context mutation was introduced.
   - ADR 0011: Tests continue to use caller-generated UUIDs for aggregate identities.
   - ADR 0022: Used strong consistency in lifecycle tests for read-your-writes projection checks.