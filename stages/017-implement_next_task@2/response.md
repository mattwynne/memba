Implemented the next unchecked task:

`002 Add Club replay tests for historic Everyone membership and role facts, active-Admin reconstruction, and delayed compatibility events after native membership events.`

Changes made:

- Added [club_replay_test.exs](/workspace/memba/web/test/memba/membership/club_replay_test.exs:1) with four focused aggregate replay contracts covering:
  - active-roster hydration from historical Everyone add/remove facts;
  - Admin reconstruction from the intersection of active memberships and historical Admin-role assignments;
  - role assignment/removal ordering and exclusion of inactive Admin assignments;
  - the required `MemberAdded(A)`, `MemberAdded(B)`, `MemberRemoved(A)`, delayed `GroupMemberAdded(A)` case;
  - delayed Everyone removals and permanent native-lifecycle precedence;
  - continued ordinary group-state updates even when compatibility facts cannot alter native roster state.
- Marked these test-first contracts explicitly skipped until tasks 004 and 005 implement the required Club state and event application. This avoids pulling later aggregate work into task 002.
- Checked off only task 002 in [todo.md](/workspace/memba/docs/iterations/059-populated-clubs-always-have-an-admin/todo.md:4).
- No tasks were split, added, removed, or reordered.

Validation:

- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_replay_test.exs`
  - 4 tests, 0 failures, 4 intentionally skipped.
- `PATH="$PWD/bin:$PATH" dev check --quick`
  - 1,182 tests, 0 failures, 4 intentionally skipped.
  - Passed on the exact final worktree.
- `git diff --check`
  - Passed.

ADR conformance:

- ADR 0002: tests exercise Club as an event-rehydrated aggregate and express decision state entirely from historical domain events.
- ADR 0007: all replay behavior remains inside the Membership bounded context.
- ADR 0008: historical events are replayed unchanged; no stream rewriting or projection-based aggregate decisions were introduced.
- ADR 0011: fixtures use caller-generated typed UUID identities and deterministic built-in Admin-role and Everyone-group IDs.