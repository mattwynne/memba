Implemented the task 019 revision and left it unchecked for independent validation.

1. Selected task

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

See [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:21).

2. Changes made

- [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:110) now waits for the conversation-follow projection to reach the captured checkpoint before resolving reply recipients. If it cannot catch up within the authorization deadline, the reply fails closed.
- New-message recipient resolution filters projected group members through Membership’s authoritative Club aggregate query.
- Reply recipient resolution filters projected followers through authoritative active-club membership while preserving existing follower-only semantics.
- Inbound new messages and replies now derive a deterministic message ID from the inbound receipt identity.
- A retry that finds the deterministic message already committed verifies that it matches the intended destination/sender before recording `InboundClubEmailAccepted`. This closes the `MessageSent`-before-acceptance failure window and makes concurrent provider retries converge on one message.
- [send_club_message_test.exs](/workspace/memba/web/test/memba/messaging/send_club_message_test.exs:620) covers:
  - departure committed while group-member projections remain stale;
  - departure, rejoin to Everyone only, stale recipient/follow projections, fail-closed behavior, and successful retry after catch-up without restoring the private recipient.
- [inbound_club_message_acceptance_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:2035) covers:
  - recovery after `MessageSent` committed but receipt acceptance did not;
  - concurrent retries producing exactly one message, delivery, and acceptance event.

3. Validation

- `dev test test/memba/messaging/send_club_message_test.exs test/memba/messaging/post_message_reply_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs`
  - 58 tests, 0 failures.
- `dev test test/memba/messaging`
  - 268 tests, 0 failures.
- Final focused send suite:
  - 15 tests, 0 failures.
- `bin/mix format --check-formatted ...`
  - Passed for all touched files.
- `git diff --check`
  - Passed.
- Final exact-worktree `dev check --quick`
  - 1,341 tests, 0 failures.

The browser-inclusive full `dev check` remains assigned to task 021 and the workflow’s final gate.

4. Task remains unchecked

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked off.

6. ADR conformance

- ADR 0004: each message and its deliveries remain owned by one Message aggregate.
- ADR 0005: recipients are still resolved before dispatch and supplied in the message command.
- ADR 0007: Messaging accesses authoritative membership state only through Membership’s public API.
- ADR 0009: projections remain read models; no cross-context side effects were added to projectors.
- ADR 0021/0022: reply resolution now explicitly uses the projection barrier before consuming projected follow state.
- ADR 0024: active club and group authority remains in the Club aggregate.
- Existing provider-handoff reauthorization and already-handed-off email semantics remain unchanged.