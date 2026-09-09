Implemented task 010: “Reject role assignment to an inactive membership inside Club and enforce the active-Admin floor when handling direct `RemoveMemberRole`.”

1. Changes made

   - [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:218) now:
     - Rejects role assignment unless the membership/person identity is active in aggregate state, returning `{:error, :member_not_active}`.
     - Rejects direct removal of the sole active deterministic Admin assignment, returning `{:error, :last_membership_administrator}`.
     - Allows Admin-role removal when another active Admin remains.
   - [assign_member_role.ex](/workspace/memba/web/lib/memba/membership/commands/assign_member_role.ex:1) documents that active-membership validation is owned by the Club aggregate.
   - [club_test.exs](/workspace/memba/web/test/memba/membership/club_test.exs:1101) adds pure aggregate coverage for inactive assignment, sole-Admin removal, and removal when a replacement Admin exists.
   - [create_club_dispatch_test.exs](/workspace/memba/web/test/memba/membership/create_club_dispatch_test.exs:283) now activates the member before testing role command routing.

2. TDD and focused validation

   - Red run: `dev test test/memba/membership/club_test.exs`
     - 45 tests, 2 expected failures.
   - Green run: same command
     - 45 tests, 0 failures.
   - Combined aggregate/replay/dispatch validation:
     - `dev test test/memba/membership/club_test.exs test/memba/membership/club_replay_test.exs test/memba/membership/create_club_dispatch_test.exs`
     - 59 tests, 0 failures.
   - `git diff --check`
     - Passed.
   - `dev check --quick`
     - Reached the complete 1,187-test suite, with 68 downstream failures—the same count reported after task 009. Those fixture/onboarding conflicts remain assigned to later tasks 013 and 020, so the overall quality gate is not yet green.

3. Todo check-off

   - Checked only [task 010](/workspace/memba/docs/iterations/059-populated-clubs-always-have-an-admin/todo.md:12) from `[ ]` to `[x]`.
   - No todo items were split, added, removed, or reordered.

4. ADR conformance

   - ADR 0002: the invariant is enforced in the event-sourced aggregate decision.
   - ADR 0007: the behavior remains inside the Membership bounded context.
   - ADRs 0008 and 0009: existing event vocabulary and persistence/projection mechanisms remain unchanged.
   - ADR 0011: all member, person, and role identities remain caller-provided typed UUIDs; the built-in Admin role continues to use its established deterministic ID.