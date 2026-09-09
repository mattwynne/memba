Implemented task 011: “Enforce final-member precedence and sole-Admin protection in Club’s `RemoveMember`; apply success to both roster and active-Admin decision state.”

- [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:116) now evaluates removal entirely from rehydrated Club state:
  - Final active member removal returns `{:error, :last_active_member}`.
  - This check runs first, giving it precedence when the member is also the sole Admin.
  - Removing the sole active Admin while other members remain returns `{:error, :last_membership_administrator}`.
  - Removing an Admin succeeds when another active Admin remains.
  - Applying the successful `MemberRemoved` event removes the membership from the active roster and recomputes the active-Admin set.
- [club_test.exs](/workspace/memba/web/test/memba/membership/club_test.exs:256) proves all three decisions and verifies both aggregate state collections after successful removal.
- The obsolete expectation that the newly activated first/only member could immediately be removed was deleted.

Validation:

- Red TDD run: `dev test test/memba/membership/club_test.exs`
  - 48 tests, 2 expected failures for the missing removal guards.
- Green focused run: same command
  - 48 tests, 0 failures.
- Aggregate and replay regression run:
  - `dev test test/memba/membership/club_test.exs test/memba/membership/club_replay_test.exs`
  - 55 tests, 0 failures.
- `git diff --check`
  - Passed.
- `dev check --quick`
  - Reached the 1,190-test suite but remains red with 74 downstream failures. These include application API and fixture assumptions addressed by later routing, onboarding, and fixture-repair tasks; this iteration is not yet at its final green gate.

Checked off exactly [task 011](/workspace/memba/docs/iterations/059-populated-clubs-always-have-an-admin/todo.md:13). No tasks were split, added, removed, or reordered.

ADR conformance:

- ADR 0002: both membership-floor invariants are enforced by the event-sourced aggregate decision.
- ADR 0007: behavior remains within the Membership bounded context.
- ADRs 0008 and 0009: existing `MemberRemoved` events and persistence/projection mechanisms are unchanged.
- ADR 0011: caller-generated typed identities remain unchanged; the Club aggregate uses them only to validate the active roster and Admin state.