Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Add projection tables/read models for roles, role permissions, role assignments, and/or flattened member permissions. Keep projections queryable by club and person/member.`

2. **Changes made**
   - Added migration:
     - `membership_roles`
     - `membership_role_permissions`
     - `membership_role_assignments`
     - `membership_member_permissions`
   - Added projection schemas:
     - `Memba.Membership.Projections.Role`
     - `RolePermission`
     - `RoleAssignment`
     - `MemberPermission`
   - Added `Memba.Membership.Projectors.Role` to project:
     - `ClubRoleDefined`
     - `ClubRolePermissionGranted`
     - `MemberRoleAssigned`
     - `MemberRoleRemoved`
     - `MemberRemoved`
   - Wired the new projector/table set into:
     - application supervision
     - projection reset config
     - event-sourced test reset support
     - acceptance reset support
     - release schema drift verification
   - Added a `MemberRoleRemoved` no-op to the existing club projector so strong-consistency role removal dispatches can advance it.
   - Added focused ExUnit tests for:
     - default role and permission projection on club creation
     - role assignment projection
     - flattened member permission projection
     - grant-count behavior across multiple roles
     - cleanup/deactivation on role removal and member removal

3. **Focused validation**
   - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/role_projection_test.exs test/memba/membership/app_test.exs'`
     - Passed: `8 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...`
     - Passed
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `646 tests, 0 failures`
   - `git diff --check`
     - Passed

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Add projection tables/read models for roles, role permissions, role assignments, and/or flattened member permissions. Keep projections queryable by club and person/member.`
   - To:
     - `- [x] 006 Add projection tables/read models for roles, role permissions, role assignments, and/or flattened member permissions. Keep projections queryable by club and person/member.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: role/permission state is projected from domain events, not written as CRUD state.
   - ADR 0007: read models remain inside the Membership bounded context.
   - ADR 0008: validation used persistent EventStore-backed tests.
   - ADR 0009: projections use `Commanded.Projections.Ecto`.
   - ADR 0011: role and aggregate IDs remain caller/deterministically supplied.
   - ADR 0022: projector wiring preserves strong-consistency/read-your-writes behavior for role events.