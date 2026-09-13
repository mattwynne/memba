Implemented task 008 and left it unchecked for independent review.

1. Selected todo line

`- [ ] 008 Close the custom-membership departure gap now.`

2. Changes made

- Extended the Club aggregate’s `RemoveClubMember` decision in [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:150) to emit `GroupMemberRemoved` for every active custom-group membership belonging to the departing club membership.
- Used structural system-group classification, so Everyone and Admin remain under the existing `SystemGroupMembership` policy rather than receiving duplicate removal events.
- Ignored already-inactive custom memberships and sorted generated removals by group ID for deterministic event ordering.
- Preserved the existing single-event return for members without active custom groups.
- Documented the public removal behavior in [membership.ex](/workspace/memba/web/lib/memba/membership.ex:423).
- Added aggregate coverage in [club_test.exs](/workspace/memba/web/test/memba/membership/club_test.exs:340), proving that multiple active custom memberships end in the same decision while system and inactive memberships are excluded.
- No acceptance feature files changed.

3. Focused validation

- TDD red run:
  - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs`
  - Failed as expected because removal initially emitted only `ClubMemberRemoved`.
- Focused passing run:
  - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs`
  - 50 tests, 0 failures.
- Broad non-browser validation:
  - `PATH="$PWD/bin:$PATH" dev check --quick`
  - 1,314 tests, 0 failures.
- `git diff --check` passed.

4. Todo state

The selected line remains unchanged and unchecked:

`- [ ] 008 Close the custom-membership departure gap now.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked.

6. ADR conformance

- ADR 0002: club departure and resulting custom-group removals remain explicit event-sourced domain facts.
- ADR 0007: the change stays within Membership and introduces no Messaging storage dependency.
- ADR 0009: existing projectors consume the emitted events; no direct projection mutation was added.
- ADR 0011/0024: `RemoveClubMember` remains routed through the Club aggregate using the stable membership identity.
- ADR 0024’s last-member and last-Admin checks still execute before any removal events are produced.