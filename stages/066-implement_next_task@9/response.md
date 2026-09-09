Implemented and checked off task 009:

`Emit MemberAdded plus the Admin MemberRoleAssigned event for the first activation in one decision. Emit only MemberAdded for later members.`

Changes:

- Updated [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:446) so activating into an empty roster returns an ordered event list containing:
  - `MemberAdded`
  - `MemberRoleAssigned` for the club’s deterministic Admin role
- Later activations continue to emit only `MemberAdded`.
- Added pure aggregate coverage for first and later activation decisions in [club_test.exs](/workspace/memba/web/test/memba/membership/club_test.exs:198), including reactivation after historical compatibility removal.
- Updated the existing Club routing assertion in [add_member_dispatch_test.exs](/workspace/memba/web/test/memba/membership/add_member_dispatch_test.exs:19) to expect both first-activation events from one dispatch.
- Checked off only task 009 in [todo.md](/workspace/memba/docs/iterations/059-populated-clubs-always-have-an-admin/todo.md:11). No tasks were split, added, or reordered.

Validation:

- TDD red run: 42 tests, 1 expected failure before implementation.
- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs`
  - 42 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs test/memba/membership/club_replay_test.exs test/memba/membership/add_member_dispatch_test.exs`
  - 52 tests, 0 failures.
- `git diff --check`
  - Passed.
- `PATH="$PWD/bin:$PATH" dev check --quick`
  - Reached the test suite but reported 68 downstream failures. These are expected pending-plan conflicts: onboarding still attempts the now-duplicate Admin assignment, and existing fixtures assume first generic members remain ordinary. Those repairs belong to tasks 013 and 020.

ADR conformance: the decision remains event-sourced in the Membership Club aggregate under ADRs 0002 and 0007; existing immutable events and projections remain unchanged under ADRs 0008 and 0009; and all event identities remain caller-provided typed UUIDs, with only the deterministic built-in Admin role derived according to ADR 0011 and the validated plan.