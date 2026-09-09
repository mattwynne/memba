Implemented and checked off task 005. Historic Everyone events now hydrate Club roster state only until a native membership lifecycle event takes permanent precedence.

1. Selected todo line

   `005 Apply historic Everyone events only where no native marker exists. Make native MemberAdded or MemberRemoved permanently authoritative for that membership while preserving ordinary group state.`

2. Changes made

   - Updated [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:301) so `GroupMemberAdded` and `GroupMemberRemoved` always update normal group-membership state.
   - Deterministic Everyone-group events additionally update the compatibility roster only when that membership ID has no native marker.
   - Native `MemberAdded` or `MemberRemoved` markers permanently prevent later Everyone events from changing roster state.
   - Compatibility roster changes recalculate active Admin membership IDs.
   - Enabled the four previously skipped task-005 replay contracts in [club_replay_test.exs](/workspace/memba/web/test/memba/membership/club_replay_test.exs:15).
   - Added coverage proving non-Everyone group events remain ordinary group state and do not affect the active roster.

3. Validation

   - TDD red state: 7 tests, 2 expected failures showing Everyone events did not yet hydrate roster/Admin state.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_replay_test.exs test/memba/membership/club_test.exs`
     - 41 tests, 0 failures.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - 1,185 tests, 0 failures.
   - `git diff --check`
     - Passed.

4. Todo check-off

   Changed only task 005 from `- [ ]` to `- [x]` in [todo.md](/workspace/memba/docs/iterations/059-populated-clubs-always-have-an-admin/todo.md:7). Task 006 remains the first unchecked task.

5. Todo structure

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   - ADR 0002: roster and Admin decision state remain reconstructed entirely from immutable domain events.
   - ADR 0007: compatibility behavior stays inside the Membership context’s Club aggregate.
   - ADR 0008: historical EventStore facts are interpreted without rewriting event history.
   - ADR 0009: existing group events and their projection behavior are preserved.
   - ADR 0011: deterministic club-scoped Everyone identity is used to distinguish compatibility facts without introducing alternate identities or streams.