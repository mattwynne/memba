Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 010 Add or update domain/application tests for authorization, duplicate active member rejection, duplicate pending resend, ordinary membership assignment, and Staff-flow preservation.`

2. **Changes made**
   - Updated `web/test/memba/membership/authorization_test.exs`
     - Added domain authorization coverage proving `authorize_manage_members/2`:
       - rejects a member before they have `club.manage_members`
       - allows a Membership Admin
       - rejects an ordinary member
       - rejects a Membership Admin for another club
   - Updated `web/test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Strengthened application lifecycle tests to prove accepted invitees become ordinary active members only:
       - no `club.manage_members` permission via public permission check
       - no `MemberPermission` projection grant
   - Updated `web/test/memba/membership/public_api_test.exs`
     - Renamed/strengthened the actor-neutral invitation test to explicitly preserve Staff/system invitation flow without requiring a club-member actor.
     - Added assertion that pending invitation creation does not create active memberships.
   - Updated `docs/iterations/029-membership-admin-invitations/todo.md`
     - Checked off only task 010.

3. **Validation commands/results**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/membership/authorization_test.exs test/memba/membership/club_member_invitation_lifecycle_test.exs test/memba/membership/public_api_test.exs`
     - Passed after applying formatter-equivalent whitespace fix.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/authorization_test.exs test/memba/membership/club_member_invitation_lifecycle_test.exs test/memba/membership/public_api_test.exs`
     - Blocked by sandbox Postgres lock/readiness issue.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `735 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 010 Add or update domain/application tests for authorization, duplicate active member rejection, duplicate pending resend, ordinary membership assignment, and Staff-flow preservation.`
   - To:
     - `- [x] 010 Add or update domain/application tests for authorization, duplicate active member rejection, duplicate pending resend, ordinary membership assignment, and Staff-flow preservation.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs.
   - No `docs/adr/*.md` files are present.
   - Changes are limited to domain/application tests and the selected todo check-off.