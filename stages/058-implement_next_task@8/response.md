Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 008 Add membership_groups and membership_group_memberships migrations, schemas, and strong-consistency projectors.`

2. **Changes made**
   - Added migration:
     - `web/priv/repo/migrations/20260903074923_create_membership_group_projections.exs`
     - Creates `membership_groups`
     - Creates `membership_group_memberships`
     - Adds uniqueness/indexing for group identity and active group-membership access patterns.
   - Added Membership projection schemas:
     - `Memba.Membership.Projections.Group`
     - `Memba.Membership.Projections.GroupMembership`
   - Added strong-consistency projectors:
     - `Memba.Membership.Projectors.Group`
     - `Memba.Membership.Projectors.GroupMembership`
   - Supervised the new projectors in `Memba.Application`.
   - Added group projection tables/projectors to event-sourced test reset wiring so the new supervised projectors remain isolated in tests.
   - Added focused tests:
     - `web/test/memba/membership/group_projection_test.exs`
     - Verifies `CreateClub` projects deterministic Everyone/Admin groups.
     - Verifies `AddGroupMember` projects an active group-membership row.

3. **Focused validation**
   - `cd web && mix format --check-formatted ...`
     - Result: passed.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/group_projection_test.exs`
     - Result: `2 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: command exited `0`.
     - Output still includes the same unrelated/pre-existing `MembaWeb.PageControllerTest` public-footer failures noted by prior checkpoints.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Add membership_groups and membership_group_memberships migrations, schemas, and strong-consistency projectors.`
   - To:
     - `- [x] 008 Add membership_groups and membership_group_memberships migrations, schemas, and strong-consistency projectors.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007 is respected: the new schemas/projectors stay inside the Membership bounded context. No Messaging code accesses Membership read-model storage directly, and no public custom-group mutation API was introduced.