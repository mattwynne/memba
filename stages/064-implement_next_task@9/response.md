Implemented focused coverage for task 009 and left it unchecked for independent review.

1. Selected todo line

`- [ ] 009 Native \`RemoveClubMember\` currently emits only \`ClubMemberRemoved\`, and \`SystemGroupMembership\` removes only Everyone/Admin.`

2. Changes made

- Extended the dispatch-level regression in [system_group_membership_policy_dispatch_test.exs](/workspace/memba/web/test/memba/membership/system_group_membership_policy_dispatch_test.exs:92).
- The test now creates an active custom group membership, removes the club member through the real `Membership.App` command path, and verifies:

  - the custom membership is ended by the Club-owned `RemoveClubMember` decision;
  - `SystemGroupMembership` still ends Everyone and Admin memberships;
  - exactly one removal event is recorded for each group, preventing overlap or duplicate custom-group removal.

- Added small trusted-command test helpers for creating the custom group and membership.
- No application behavior required changing because the accepted task 008 checkpoint already closed the native one-event gap.
- No acceptance feature files changed.

3. Validation

- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs test/memba/membership/system_group_membership_policy_dispatch_test.exs`
  - 55 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/system_group_membership_policy_dispatch_test.exs`
  - 5 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev check --quick`
  - 1,314 tests, 0 failures.
- `git diff --check`
  - Passed.

4. Todo state

The selected line remains unchanged and unchecked:

`- [ ] 009 Native \`RemoveClubMember\` currently emits only \`ClubMemberRemoved\`, and \`SystemGroupMembership\` removes only Everyone/Admin.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked.

6. ADR conformance

- ADR 0002: removal outcomes remain explicit event-sourced facts.
- ADR 0007: the test exercises Membership’s public Commanded application without introducing cross-context storage access.
- ADR 0009: projected state is observed only after normal event handling; no projector-side lifecycle behavior was introduced.
- ADR 0011/0024: `RemoveClubMember` remains routed through the Club consistency boundary using stable caller-generated identities.
- The test documents the ownership boundary intended by the plan: the Club decision owns custom-group removals, while `SystemGroupMembership` remains responsible for Everyone/Admin consequences.