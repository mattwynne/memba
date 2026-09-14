Implemented the task 019 revision and left it unchecked for independent validation.

1. Selected task

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

See [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:21).

2. Changes made

- [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:1344) now reconciles an already-committed deterministic inbound message before repeating mutable sender authorization. It verifies the message’s sender, club, destination, subject, body, and reply reference before recording the receipt as accepted.
- Concurrent rejection processing now inspects the `RejectInboundClubEmail` execution result. Only the caller that emitted `InboundClubEmailRejected` sends the rejection email; callers receiving the idempotent no-event result return the duplicate outcome without another side effect.
- Reply recipient resolution now requires both an active projected follow and authoritative conversation access through the root message’s current group grants and the Club aggregate’s current group membership.
- [inbound_club_message_acceptance_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:2035) proves:
  - a committed message is accepted after its sender departs, without recording or emailing a rejection;
  - eight concurrent rejected retries produce one rejection event and one rejection email.
- [send_club_message_test.exs](/workspace/memba/web/test/memba/messaging/send_club_message_test.exs:684) now recreates the actual policy-lag race: the conversation-access projector misses the conversation during departure cleanup, the stale follow remains after an Everyone-only rejoin, and reply resolution still excludes the former private-group member.
- [post_message_reply_test.exs](/workspace/memba/web/test/memba/messaging/post_message_reply_test.exs:134) now explicitly verifies that projected followers without authoritative conversation access receive no reply delivery.

3. Validation

- Focused four-regression run: 59 tests discovered, 4 selected, 0 failures.
- Complete send-message suite: 15 tests, 0 failures.
- Complete Messaging suite: 269 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev check --quick`: 1,342 tests, 0 failures.
- Formatter check for all touched files: passed.
- `git diff --check`: passed.

The browser-inclusive full `dev check` remains assigned to task 021 and the workflow’s final validation gate.

4. Task remains unchecked

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked off.

6. ADR conformance

- ADR 0004: messages and their deliveries remain owned by one Message aggregate.
- ADR 0005: recipients remain resolved before message dispatch; reply resolution now excludes followers without authoritative access.
- ADR 0007: Messaging uses Membership’s public authoritative APIs and does not access Membership aggregates or schemas directly.
- ADR 0009 and 0021: projections remain read models; rejection side effects are owned by the caller that records the aggregate outcome, not by a projector.
- ADR 0022: existing projection-barrier synchronization remains in place for projected follow state.
- ADR 0024: current club and group membership authority remains with the Club aggregate.
- Provider-handoff behavior and already-handed-off email semantics were not changed.