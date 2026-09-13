1. Selected task

`- [ ] 010 Extend the Club-owned lifecycle to emit custom removals for the departing membership and keep legacy/replay handling safe.`

2. Changes made

Added a focused replay regression in [club_replay_test.exs](/workspace/memba/web/test/memba/membership/club_replay_test.exs:147). It proves that:

- Legacy `MemberAdded` facts hydrate enough Club state for the current `RemoveClubMember` decision.
- Departure emits explicit `ClubMemberRemoved` and `GroupMemberRemoved` facts.
- Replaying the complete event history leaves the custom membership inactive.
- The custom group itself remains intact rather than being deleted or archived.

The accepted task 008 implementation already supplied the production behavior, so no application code required further changes. No acceptance feature files changed.

3. Focused validation

- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_replay_test.exs`
  - 9 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs test/memba/membership/club_replay_test.exs test/memba/membership/system_group_membership_policy_dispatch_test.exs`
  - 64 tests, 0 failures.
- `mix format --check-formatted test/memba/membership/club_replay_test.exs`
  - Passed.
- `git diff --check`
  - Passed.

Per the per-task workflow instructions, the full `dev check` remains with the explicit final-validation task and deterministic workflow gate.

4. Todo state

The selected line remains unchanged and unchecked for independent review:

`- [ ] 010 Extend the Club-owned lifecycle to emit custom removals for the departing membership and keep legacy/replay handling safe.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked.

6. ADR conformance

- ADR 0002: lifecycle outcomes remain explicit event-sourced facts and are verified through replay.
- ADR 0007: all changes stay within Membership; no Messaging access or cross-context storage coupling was added.
- ADR 0009: no side effects were introduced into projectors.
- ADR 0011 and ADR 0024: caller-generated identities remain stable, while `RemoveClubMember` continues to make the custom-removal decision inside the Club consistency boundary.