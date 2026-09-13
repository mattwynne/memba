1. Selected task

`- [ ] 003 Preserve trusted system/backfill command behaviour and historical events.`

2. Changes made

- Clarified that [CreateGroup](/workspace/memba/web/lib/memba/membership/commands/create_group.ex:1), [AddGroupMember](/workspace/memba/web/lib/memba/membership/commands/add_group_member.ex:1), and [RemoveGroupMember](/workspace/memba/web/lib/memba/membership/commands/remove_group_member.ex:1) remain trusted, actor-free commands for system policies, backfills, replay repair, and fixture setup.
- Documented that user-facing custom creation must use the actor-authorized `Membership.create_custom_group/2` boundary.
- Documented the replay-compatible historical shape of [GroupCreated](/workspace/memba/web/lib/memba/membership/events/group_created.ex:1), with slug assignment and creator membership remaining separate facts.
- Added compatibility guards in [group_command_event_modules_test.exs](/workspace/memba/web/test/memba/membership/group_command_event_modules_test.exs:33) proving:
  - trusted commands do not acquire actor fields;
  - historical group event schemas remain actor-free;
  - `GroupCreated` does not absorb slug or creator-membership data.
- No aggregate decisions, command routing, event structures, or production behavior changed.

3. Validation

- Trusted command, historical slug repair, and public API tests: 41 tests, 0 failures.
- System-group backfill and Club replay tests: 16 tests, 0 failures.
- Full Membership context: 304 tests, 0 failures.
- Final command/event module test: 4 tests, 0 failures.
- `mix format --check-formatted` passed for all touched files.
- `git diff --check` passed.
- Full `dev check` remains assigned to task 021 and the workflow’s final validation stage.

4. Todo state

The exact selected line remains unchecked and ready for independent review:

`- [ ] 003 Preserve trusted system/backfill command behaviour and historical events.`

5. Todo changes

No tasks were split, added, removed, reordered, or checked.

6. ADR conformance

- ADR 0002: historical event facts remain immutable and replayable.
- ADR 0007: trusted group commands and their events remain entirely within Membership.
- ADR 0011: existing caller-generated typed identities are unchanged.
- ADR 0024: Club remains the consistency boundary, while legacy events and trusted system/backfill producers retain their compatibility contracts.