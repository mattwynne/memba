Implemented task 004 and left it unchecked for independent review.

1. Selected todo line

`- [ ] 004 Use a retry-stable group ID so retry does not silently become a second creation or change its address.`

2. Changes made

- Documented in [membership.ex](/workspace/memba/web/lib/memba/membership.ex:61) and [create_custom_group.ex](/workspace/memba/web/lib/memba/membership/commands/create_custom_group.ex:1) that callers generate a group ID once and reuse it when retrying an uncertain dispatch.
- Tightened retry recognition in [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:749):
  - an exact retry with the original creator is a successful no-op;
  - the stored name and email address remain unchanged;
  - no duplicate events are appended;
  - another admin cannot reuse the ID and receive an apparent successful retry.
- Added focused integration coverage in [create_custom_group_dispatch_test.exs](/workspace/memba/web/test/memba/membership/create_custom_group_dispatch_test.exs:100), including a retry after another group has taken the colliding `board-2` address.
- No projections, event schemas, acceptance features, or later-task behavior were changed.

3. Focused validation

- TDD red run: 13 tests, 1 expected failure proving another creator could previously reuse the ID as an apparent retry.
- Final focused test: 13 tests, 0 failures.
- Full Membership context: 306 tests, 0 failures.
- `mix format --check-formatted` passed for all four touched files.
- `git diff --check` passed.
- Full `dev check` was not run in this ordinary per-task node; it remains explicitly assigned to task 021 and the workflow’s final gate.

4. Todo state

The selected line remains unchanged and unchecked:

`- [ ] 004 Use a retry-stable group ID so retry does not silently become a second creation or change its address.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked.

6. ADR conformance

- ADR 0002: retries are decided from aggregate state and append no duplicate facts.
- ADR 0007: the behavior remains entirely within the Membership context.
- ADR 0011: the caller-generated typed group ID is retained as the stable retry identity.
- ADR 0024: exact retry matching is authoritative within the serialized Club aggregate boundary, without projection-backed preflight authority.