Implemented task 005 and left it unchecked for independent review.

1. Selected todo line

`- [ ] 005 Emit the existing group-created, slug-assigned and creator-added facts as one successful decision.`

2. Changes made

- Preserved the existing aggregate implementation in [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:774), which returns `GroupCreated`, `GroupEmailSlugAssigned`, and `GroupMemberAdded` in one ordered decision.
- Strengthened [create_custom_group_dispatch_test.exs](/workspace/memba/web/test/memba/membership/create_custom_group_dispatch_test.exs:21) by subscribing to the Club stream and proving all three persisted facts arrive in one event-store batch from the creation command.
- Documented the atomic event contract in [create_custom_group.ex](/workspace/memba/web/lib/memba/membership/commands/create_custom_group.ex:2).
- Existing assertions continue to prove the resulting aggregate state, addressable group projection, and active creator membership.
- No later projection, lifecycle, UI, messaging, or acceptance work was introduced.

3. Focused validation

- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/create_custom_group_dispatch_test.exs`
  - 13 tests, 0 failures.
- `mix format --check-formatted lib/memba/membership/commands/create_custom_group.ex test/memba/membership/create_custom_group_dispatch_test.exs`
  - Passed.
- `git diff --check`
  - Passed.
- Full `dev check` was not run in this ordinary per-task node, as required by the workflow.

4. Todo state

The selected line remains unchanged and unchecked:

`- [ ] 005 Emit the existing group-created, slug-assigned and creator-added facts as one successful decision.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked.

6. ADR conformance

- ADR 0002: creation is represented as one explicit aggregate decision containing three immutable domain facts.
- ADR 0007: all affected behavior remains within Membership’s public API and event stream.
- ADR 0011: the caller-generated group identity remains unchanged across all three facts.
- ADR 0024: all facts are decided and atomically appended on the Club consistency-boundary stream.