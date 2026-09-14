Task 006 is implemented and ready for independent review.

1. Selected task

`- [ ] 006 Respect the departure/rejoin cleanup introduced in 062; no projection-only mutation or restoration shortcut.`

2. Changes made

Added focused lifecycle coverage in [clear_removed_group_member_follows_policy_test.exs](/workspace/memba/web/test/memba/membership/clear_removed_group_member_follows_policy_test.exs:307).

The test proves that:

- Club departure clears the member’s custom-group conversation follow.
- Club rejoin uses a new membership identity.
- Explicit custom-group admission returns a confirmed `:member_added` transition.
- The departed membership remains inactive while the new membership becomes active.
- The former conversation follow remains cleared.
- Membership changes are represented by `GroupMemberAdded`, `GroupMemberRemoved`, and a later `GroupMemberAdded` event, then projected normally.

No production changes were necessary because the accepted tasks 001–005 already use the correct Club aggregate, domain-event, and projection path. No acceptance feature files were changed.

3. Focused validation

- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/clear_removed_group_member_follows_policy_test.exs`
  - 7 tests, 0 failures.

- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/add_custom_group_member_dispatch_test.exs test/memba/membership/clear_removed_group_member_follows_policy_test.exs test/memba/membership/group_projection_test.exs`
  - 21 tests, 0 failures.

- `mix format --check-formatted test/memba/membership/clear_removed_group_member_follows_policy_test.exs`
  - Passed.

- `git diff --check`
  - Passed.

Full `dev check` was not run because it remains the explicit final task 016.

4. Todo state

Still exactly unchecked and ready for independent review:

`- [ ] 006 Respect the departure/rejoin cleanup introduced in 062; no projection-only mutation or restoration shortcut.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0002: the regression requires admission to remain an event-sourced aggregate transition.
- ADR 0007: follow cleanup continues through Membership’s policy collaboration with Messaging’s public API.
- ADR 0009: group membership read state is updated through the existing projector, with no direct projection mutation.
- ADR 0011: departure and rejoin retain distinct caller-generated membership identities.
- ADR 0024: active target validation and custom-group admission remain decisions of the Club consistency boundary.