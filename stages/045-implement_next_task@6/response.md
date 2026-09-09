Implemented and checked off task 006. Membership activation and removal now share the Club aggregate’s `club_id` consistency boundary.

1. Selected todo line

   `006 Add club/person identity to member commands, validate it against Club state, route add/remove by club_id, and de-register the membership-ID write route.`

2. Changes made

   - [remove_member.ex](/workspace/memba/web/lib/memba/membership/commands/remove_member.ex:1) now requires `club_id`, `membership_id`, and `person_id`. `AddMember` documentation also reflects Club routing.
   - [router.ex](/workspace/memba/web/lib/memba/membership/router.ex:33) routes both lifecycle commands to `Club` and removes the Membership aggregate identity registration.
   - [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:104) now handles activation/removal, validates typed IDs, requires an existing matching club, and confirms removal’s membership/person identity against the rehydrated active roster.
   - [membership.ex](/workspace/memba/web/lib/memba/membership.ex:399) preserves the existing public removal API by enriching omitted club/person routing fields from the membership projection. The Club aggregate remains responsible for validating the decision.
   - [add_member_dispatch_test.exs](/workspace/memba/web/test/memba/membership/add_member_dispatch_test.exs:13) proves both commands return the club ID as their aggregate UUID and update Club state.
   - Updated affected direct-command tests and fixtures to use the expanded removal command and create event-sourced clubs before activation. Historic backfill expectations now account for `MemberAdded` being appended to the Club stream.

3. Validation

   - TDD red state: focused tests initially failed because `RemoveMember` lacked the new fields.
   - Focused regression suite: 129 tests, 0 failures.
   - Final `PATH="$PWD/bin:$PATH" dev check --quick`: 1,188 tests, 0 failures.
   - `git diff --check`: passed.

4. Todo check-off

   Changed only task 006 from `- [ ]` to `- [x]` in [todo.md](/workspace/memba/docs/iterations/059-populated-clubs-always-have-an-admin/todo.md:8). Task 007 remains first unchecked.

5. Todo structure

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   - ADR 0002: lifecycle decisions now execute in the event-sourced aggregate that owns the relevant roster state.
   - ADR 0007: all changes remain inside the Membership bounded context.
   - ADR 0008: existing event vocabulary and historic streams remain immutable.
   - ADR 0009: existing projections continue consuming `MemberAdded` and `MemberRemoved`.
   - ADR 0011: callers still provide stable typed UUIDs for clubs, people, and memberships; Commanded routes the Club aggregate using its existing `club_id` identity.