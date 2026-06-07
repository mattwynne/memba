Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `011 Prevent ordinary members without club.manage_members from granting or revoking Membership Administrator.`

2. **Changes made**
   - Added focused ExUnit coverage in `web/test/memba/membership/member_role_authorization_test.exs` proving:
     - An ordinary active member without `club.manage_members` cannot grant Membership Administrator to another member.
     - An ordinary active member without `club.manage_members` cannot revoke Membership Administrator from another member.
     - The attempted grant/revoke returns `{:error, :unauthorized}`.
     - The target member’s permission state remains unchanged after rejection.
   - No production code changes were needed: the existing Membership Administrator-specific APIs already route through the permission-gated club-member role assignment/removal paths.
   - Checked off task 011 in `docs/iterations/027-membership-administrator-role/todo.md`.

3. **Focused validation**
   - Initial direct focused test:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/member_role_authorization_test.exs`
     - Failed due existing sandbox PGHOST/Postgres readiness mismatch.
   - Focused test via devenv shell:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/member_role_authorization_test.exs'`
     - Passed: `8 tests, 0 failures`.
   - Formatting:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/membership/member_role_authorization_test.exs'`
     - Initially reported formatting changes; after applying equivalent formatting manually, passed.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `656 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 011 Prevent ordinary members without \`club.manage_members\` from granting or revoking Membership Administrator.`
   - To:
     - `- [x] 011 Prevent ordinary members without \`club.manage_members\` from granting or revoking Membership Administrator.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Preserved Commanded/event-sourced workflow; no CRUD/state bypass introduced.
   - ADR 0007: Kept behaviour at the Membership bounded-context API boundary.
   - ADR 0009: Tests exercise projected permission state rather than direct aggregate inspection.
   - ADR 0022: Tests use `consistency: :strong` for read-your-writes behaviour against projections.