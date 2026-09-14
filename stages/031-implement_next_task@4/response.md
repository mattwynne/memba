Task 004 is implemented and ready for independent review.

1. Selected task

`- [ ] 004 Reuse GroupMemberAdded and the existing projection.`

2. Changes made

- Consolidated trusted and authenticated group additions onto the same `group_member_added_event/1` builder in [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:1060).
- Both `AddGroupMember` and `AddCustomGroupMember` continue emitting the established `GroupMemberAdded` event.
- Added an integration assertion in [add_custom_group_member_dispatch_test.exs](/workspace/memba/web/test/memba/membership/add_custom_group_member_dispatch_test.exs:14) proving that authenticated admission updates the existing `GroupMembership` projection with the exact club, group, membership, and person identities.
- No new event, projector, projection schema, or projection-only mutation was introduced.

3. Focused validation

- `PATH="/workspace/memba/bin:$PATH" dev test test/memba/membership/add_custom_group_member_dispatch_test.exs test/memba/membership/group_projection_test.exs test/memba/membership/club_test.exs`
  - 66 tests, 0 failures.
- `mix format --check-formatted lib/memba/membership/club.ex test/memba/membership/add_custom_group_member_dispatch_test.exs`
  - Passed.
- `git diff --check`
  - Passed.

Full `dev check` remains explicit task 016 and was not run here.

4. Todo state

Still exactly unchecked and ready for independent review:

`- [ ] 004 Reuse GroupMemberAdded and the existing projection.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0002: the authenticated admission remains an event-sourced aggregate decision projected into the existing Ecto read model.
- ADR 0007: the event and projection remain owned by the Membership bounded context.
- ADR 0011: existing caller-generated typed club, group, membership, and person identities are retained.
- ADR 0024: the Club aggregate emits the membership transition; authorization and mutation are not inferred from or performed directly against the projection.