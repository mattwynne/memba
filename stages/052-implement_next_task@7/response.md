Implemented task 018’s custom-group email and authorization proof. No production changes were necessary; the existing generic Membership and Messaging APIs already satisfy the behavior.

1. Selected task

`- [ ] 018 Prove custom-group email routing and conversation authorisation using existing public Membership/Messaging APIs.`

2. Changes

Added an end-to-end integration test in [inbound_club_message_acceptance_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:208) that:

- Creates Board through the authenticated `Membership.create_custom_group/2` API.
- Resolves `board@kmc.clubs.memba.io` to that custom group.
- Lets an active club member outside Board start a Board conversation by email.
- Routes the initial delivery only to Board’s active member.
- Keeps the conversation out of Everyone.
- Grants Board write/read access while giving the sender no membership, read access, delivery receipt, or follow.
- Rejects the sender’s subsequent website reply.
- Rejects a forged email reply using another recipient’s outbound message ID.
- Confirms rejected attempts create no reply message and do not mutate follow state.

Acceptance feature files were not changed; executing their tagged scenarios remains task 021.

3. Validation

- Focused new test: 1 selected test passed, 0 failures.
- Inbound, group-send, and reply suites: 50 tests, 0 failures.
- `mix format --check-formatted test/memba/messaging/inbound_club_message_acceptance_test.exs`: passed.
- `git diff --check`: passed.
- `PATH="$PWD/bin:$PATH" dev check --quick`: 1,331 tests, 0 failures.

4. Todo state

The line remains unchanged and unchecked in [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:20):

`- [ ] 018 Prove custom-group email routing and conversation authorisation using existing public Membership/Messaging APIs.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0003: external email delivery remains behind the configured fake/test adapter.
- ADRs 0004 and 0005: the existing message aggregate records the resolved custom-group recipients and conversation access atomically.
- ADR 0007: Messaging uses Membership’s public APIs; the test does not couple Messaging to Membership projection schemas.
- ADR 0009: assertions exercise projected conversation, delivery, access, and follow state.
- ADR 0022: strong-consistency dispatches provide deterministic read-after-write assertions.
- ADR 0024: custom-group creation continues through the Club consistency boundary via the authenticated Membership API.