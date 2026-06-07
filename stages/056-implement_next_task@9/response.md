Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `009 Add command/API support for a member with club.manage_members to make another active member a Membership Administrator.`

2. **Changes made**
   - Added `Memba.Membership.assign_membership_administrator_as_club_member/2`.
     - Derives the built-in Membership Administrator role ID from `club_id`.
     - Reuses the existing permission-gated role assignment path.
     - Requires `actor_person_id`.
     - Requires the actor to have projected `club.manage_members`.
     - Requires the target membership to be active.
   - Added a focused ExUnit test proving Robin can make Alice a Membership Administrator and Alice receives `club.manage_members`.

3. **Focused validation**
   - Initial focused test before implementation:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/member_role_authorization_test.exs`
     - Hit the known PGHOST readiness mismatch.
   - Focused test after implementation:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/member_role_authorization_test.exs'`
     - Passed: `4 tests, 0 failures`.
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/membership.ex test/memba/membership/member_role_authorization_test.exs`
     - Passed.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `652 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Add command/API support for a member with club.manage_members to make another active member a Membership Administrator.`
   - To:
     - `- [x] 009 Add command/API support for a member with club.manage_members to make another active member a Membership Administrator.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No explicit ADR files were present under `docs/adr/`.
   - The change stays within the Membership application-service boundary.
   - It reuses the existing Commanded command/event path (`AssignMemberRole` / `MemberRoleAssigned`) rather than adding a parallel flag or direct projection write.
   - Authorization continues to use projected permission state (`club.manage_members`) rather than checking the actor’s role name.