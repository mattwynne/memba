1. **Selected todo line**
   - `014 Add ExUnit tests for events, projections, permission checks, authorization failures, and the last-administrator invariant.`

2. **Changes made**
   - Added projection coverage in `web/test/memba/membership/role_projection_test.exs` proving that granting `club.manage_members` to a role with existing active assignments backfills the flattened `MemberPermission` projection.
   - Added authorization/invariant coverage in `web/test/memba/membership/member_role_authorization_test.exs` proving that the last Membership Administrator cannot be revoked even when the actor has `club.manage_members` through another custom role.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/membership/role_projection_test.exs test/memba/membership/member_role_authorization_test.exs`
     - Passed.
   - `devenv shell -- bash -lc 'cd web && mix test test/memba/membership/role_projection_test.exs test/memba/membership/member_role_authorization_test.exs'`
     - Passed: `15 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `663 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 014 Add ExUnit tests for events, projections, permission checks, authorization failures, and the last-administrator invariant.`
   - To:
     - `- [x] 014 Add ExUnit tests for events, projections, permission checks, authorization failures, and the last-administrator invariant.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / architecture conformance**
   - Kept changes test-only.
   - Tests exercise the event-sourced Membership command/projection path using Commanded dispatch and projected read models.
   - Authorization assertions remain permission-based (`club.manage_members`) rather than hard-coding role-name checks.
   - The last-administrator invariant is verified independently from permission possession, preserving the role/permission separation required by the plan.