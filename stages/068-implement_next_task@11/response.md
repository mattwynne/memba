Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `010 Add or update domain/application tests for authorization, duplicate active member rejection, duplicate pending resend, ordinary membership assignment, and Staff-flow preservation.`

2. **Changes made**
   - Updated `web/test/memba/membership/club_member_invitation_lifecycle_test.exs`.
   - Added a focused regression test proving the Staff/system `Membership.invite_club_member/2` flow remains preserved alongside the new member-facing authorization:
     - creates a pending invitation without requiring a club-member actor,
     - resends a duplicate pending invitation using the existing single-invitation rule,
     - preserves a single pending invitation record,
     - accepts for an existing complete person,
     - creates an ordinary active membership,
     - does not grant `club.manage_members`,
     - creates no active role assignments.
   - Checked off task `010` in `docs/iterations/029-membership-admin-invitations/todo.md`.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Failed before tests because the direct wrapper could not start Postgres due an existing `postmaster.pid` / `PGHOST=/tmp/devenv/postgres` readiness issue.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Passed: `14 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `741 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - From:
     - `- [ ] 010 Add or update domain/application tests for authorization, duplicate active member rejection, duplicate pending resend, ordinary membership assignment, and Staff-flow preservation.`
   - To:
     - `- [x] 010 Add or update domain/application tests for authorization, duplicate active member rejection, duplicate pending resend, ordinary membership assignment, and Staff-flow preservation.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Kept coverage in the Commanded/event-sourced Membership workflow.
   - ADR 0007: Stayed within the Membership bounded context; no Messaging coupling or cross-context mutation.
   - ADR 0011: Continued using caller-generated UUID aggregate identities in tests.
   - ADR 0022: Used `consistency: :strong` for read-your-writes projection assertions.