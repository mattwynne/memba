Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `010 Add command/API support for revoking Membership Administrator while enforcing that at least one remains.`

2. **Changes made**
   - Added `Memba.Membership.remove_membership_administrator_as_club_member/2`.
     - Derives the built-in Membership Administrator role ID from `club_id`.
     - Reuses the existing permission-gated club-member role-removal path.
     - Requires the target membership to be active.
     - Rejects removal with `{:error, :last_membership_administrator}` when the target has the active Membership Administrator role and no other active Membership Administrator would remain.
   - Updated `remove_member_role_as_club_member/2` so generic club-member removal of the built-in Membership Administrator role also enforces the last-administrator invariant.
   - Added focused tests proving:
     - An administrator can revoke another administrator when one remains.
     - The last administrator cannot revoke their own Membership Administrator assignment and keeps `club.manage_members`.

3. **Focused validation run**
   - Initial direct focused test command:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/member_role_authorization_test.exs`
     - Hit known PGHOST/Postgres readiness mismatch.
   - Focused test via devenv shell:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/member_role_authorization_test.exs'`
     - Passed: `6 tests, 0 failures`.
   - Formatting check:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/membership.ex test/memba/membership/member_role_authorization_test.exs'`
     - Passed.
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `654 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 010 Add command/API support for revoking Membership Administrator while enforcing that at least one remains.`
   - To:
     - `- [x] 010 Add command/API support for revoking Membership Administrator while enforcing that at least one remains.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: Reused the existing Commanded command/event workflow (`RemoveMemberRole` / `MemberRoleRemoved`) instead of adding CRUD-style state mutation.
   - ADR 0007: Kept the change inside the Membership context and public Membership application-service API.
   - ADR 0009: Used existing Ecto projections/read models for current role-assignment state; no ad-hoc projection plumbing or direct write bypass was introduced.
   - ADR 0022-compatible validation: tests use `consistency: :strong` for read-your-writes behavior against projections.