Implemented task 004 and checked it off.

1. Selected todo line

   `004 Extend Club aggregate state with active roster entries, permanent native-lifecycle markers, and active Admins derived by intersecting active roster IDs with active Admin-role assignments.`

2. Changes made

   - Extended [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:37) with:
     - `active_memberships`
     - `native_membership_ids`
     - `active_admin_membership_ids`
   - Added Club replay handling for native `MemberAdded` and `MemberRemoved` events.
   - Native membership IDs remain marked after removal.
   - Role assignment, role removal, membership activation, and membership removal now recalculate active Admin membership IDs.
   - Active Admins are exactly active roster IDs with the club’s deterministic Admin-role assignment. Custom-role assignments and inactive members are excluded.
   - Added executable native-lifecycle replay coverage in [club_replay_test.exs](/workspace/memba/web/test/memba/membership/club_replay_test.exs:130).
   - Narrowed the existing skip tags to only the historic Everyone compatibility examples belonging to task 005.

3. Validation

   - TDD red state confirmed the Club lacked native membership event application.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs test/memba/membership/club_replay_test.exs`
     - 40 tests, 0 failures, 4 task-005 tests skipped.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - 1,184 tests, 0 failures, 4 task-005 tests skipped.
   - `git diff --check`
     - Passed.

4. Todo check-off

   Changed only task 004 from `- [ ]` to `- [x]` in [todo.md](/workspace/memba/docs/iterations/059-populated-clubs-always-have-an-admin/todo.md:6).

5. Todo structure

   No tasks were split, added, removed, or reordered. Task 005 remains the first unchecked task and retains ownership of Everyone compatibility-event precedence.

6. ADR conformance

   - ADR 0002: aggregate state is reconstructed solely from domain events.
   - ADR 0007: all behavior remains within the Membership context’s Club aggregate.
   - ADRs 0008 and 0009: write decisions depend on rehydrated aggregate state, with no projection-backed invariant logic or event-history mutation.
   - ADR 0011: existing event identities are preserved, and the Admin role is resolved through the established deterministic club-scoped identity helper.