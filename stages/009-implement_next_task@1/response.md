1. **Selected todo line**
   - `001 Inspect the existing role projection schemas and queries (`Membership.Projections.RoleAssignment`, role projections, and role-assignment projector) to confirm field names and active flags.`

2. **Changes made**
   - Inspected relevant Membership role projection/query code only.
   - Confirmed:
     - `Memba.Membership.Projections.RoleAssignment`
       - table: `membership_role_assignments`
       - fields: `club_id`, `membership_id`, `person_id`, `role_id`, `active`
       - migration has `active` boolean default `true`, unique index on `[:membership_id, :role_id]`
     - `Memba.Membership.Projections.Role`
       - table: `membership_roles`
       - primary key: `role_id`
       - fields: `club_id`, `role_key`, `name`
     - `Memba.Membership.Projectors.Role`
       - `MemberRoleAssigned` inserts/upserts assignment with `active: true`
       - `MemberRoleRemoved` sets matching assignment `active: false`
       - `MemberRemoved` sets all assignments for the membership `active: false`
     - `Membership.list_active_members_of_club/1` currently returns active members only, joined to person + primary email, and does **not yet** include role names.
   - No application code/config/test files were changed for this inspection task.
   - Updated only `docs/iterations/049-member-role-badges/todo.md` to check off task 001.

3. **Focused validation**
   - First attempted:
     - `PATH="$PWD/bin:$PATH" dev test web/test/memba/membership/role_projection_test.exs web/test/memba/membership/query_test.exs`
     - Result: failed because `dev test` runs from `web/`, so repo-root paths did not match.
   - Reran with correct paths:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/role_projection_test.exs test/memba/membership/query_test.exs`
     - Result: passed — `22 tests, 0 failures`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect the existing role projection schemas and queries (...)`
   - To:
     - `- [x] 001 Inspect the existing role projection schemas and queries (...)`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed relevant accepted ADRs:
     - ADR 0002: Commanded/CQRS/event sourcing by default.
     - ADR 0007: Membership owns its Commanded context and read models.
     - ADR 0009: Use Commanded Ecto projections.
     - ADR 0021: Publish committed read-model changes from projectors.
     - ADR 0022: Projection barriers for read-your-writes synchronization.
   - The inspection confirms the current role state is modeled through Membership Commanded events and Ecto projections, consistent with those ADRs.