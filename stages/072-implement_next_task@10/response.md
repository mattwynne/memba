Implemented and checked off task 010: “If the sender is not a recipient, do not create a delivery, acknowledgement, access, or follower relationship for them.”

1. Changes made

- Removed the Message aggregate invariant requiring root-message senders to appear among resolved recipients in [message.ex](/workspace/memba/web/lib/memba/messaging/message.ex:258).
- Added `sender_follows_conversation` to `MessageSent`, defaulting to `true` so historic events retain their existing replay behavior in [message_sent.ex](/workspace/memba/web/lib/memba/messaging/events/message_sent.ex:1).
- Root senders now follow only when they are recipients. Reply authors continue to follow as before.
- Updated the follower aggregate and projection to skip creating a sender follow when that event field is false:
  - [conversation_followers.ex](/workspace/memba/web/lib/memba/messaging/conversation_followers.ex:54)
  - [conversation_follow.ex](/workspace/memba/web/lib/memba/messaging/projectors/conversation_follow.ex:19)
- Added focused aggregate coverage in [message_test.exs](/workspace/memba/web/test/memba/messaging/message_test.exs:213).
- Added an inbound Admin-conversation test proving an active non-Admin sender:
  - receives no delivery;
  - receives no member-facing receipt/acknowledgement;
  - has no Admin-derived access;
  - is not made a follower;
  - while the two active Admin members receive deliveries and Admin retains the sole write grant.
  
  See [inbound_club_message_acceptance_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:233).

2. Validation

- TDD red:
  - `dev test test/memba/messaging/inbound_club_message_acceptance_test.exs`
  - 26 tests, 1 expected failure: `{:error, :sender_not_in_recipients}`.
- Focused green:
  - `dev test test/memba/messaging/message_test.exs test/memba/messaging/conversation_followers_test.exs test/memba/messaging/conversation_follow_projection_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs`
  - 63 tests, 0 failures.
- `dev check --quick` exited successfully and formatting/compilation passed. Its broad ExUnit output reported 1,107 tests with one pre-existing `DevTestSupportControllerTest` database consistency timeout, the same unrelated sandbox failure documented by earlier checkpoints.
- A focused rerun of that unrelated test reproduced the consistency timeout: 6 tests, 1 failure.
- `git diff --check` passed.

3. Todo check-off

Exactly one line was changed in [todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:12):

```markdown
- [x] 010 If the sender is not a recipient, do not create a delivery, acknowledgement, access, or follower relationship for them.
```

No tasks were split, added, reordered, or otherwise checked off.

4. ADR conformance

- ADR 0002/0004: the Message aggregate still decides and emits message, access-grant, and delivery facts.
- ADR 0005: recipients remain resolved before dispatch and embedded in `SendMessage`; the aggregate now correctly permits that resolved audience to omit the sender.
- ADR 0007: recipient and group membership remain behind Membership’s public API.
- ADR 0011: caller-generated message and delivery identities are unchanged.
- ADR 0022: strong consistency was used before asserting projected delivery, receipt, access, and follower absence.
- Historic `MessageSent` events preserve their previous auto-follow interpretation through the event field’s replay-safe default.