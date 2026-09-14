Implemented the two requested task 019 recovery fixes. The task remains unchecked for independent validation.

1. Selected todo

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

See [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:21).

2. Changes made

- [email_delivery_dispatcher.ex](/workspace/memba/web/lib/memba/messaging/email_delivery_dispatcher.ex:198) now issues an enabled-only pending-work nudge on startup. Pending deliveries deferred because authorization projections timed out therefore recover after dispatcher or application restart.
- The startup path uses the existing claim → stable recipient authorization → provider handoff flow. The provider-handoff linearization point was not moved or weakened.
- [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:310) now treats only terminal accepted/rejected receipts as completed duplicates. A duplicate receipt whose aggregate status remains `nil` resumes destination resolution, current authorization, posting or rejection.
- Authorization stability accepts a zero timeout so the timeout/retry regression can deterministically create the exact receipt-only state without scheduling races.
- [send_club_message_test.exs](/workspace/memba/web/test/memba/messaging/send_club_message_test.exs:441) proves that a projection-timeout deferral survives dispatcher termination and is reclaimed by the restarted dispatcher’s startup nudge.
- [inbound_club_message_acceptance_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:1991) proves the first provider call records `InboundEmailReceived` and times out, then the retry completes exactly one message and one acceptance instead of returning a `nil`-status duplicate.
- [show_test.exs](/workspace/memba/web/test/memba_web/live/member_message_live/show_test.exs:396) now uses authoritative event-sourced fixtures for its positive follow-action test. The broad check exposed that its old projection-only fixture could no longer satisfy task 019’s authoritative action boundary.
- Formatting normalized one existing assertion in `system_group_membership_policy_dispatch_test.exs`; there was no behavioral change there.

3. Validation

- Focused restart recovery: 1 test, 0 failures.
- Focused inbound timeout/provider retry: 1 test, 0 failures.
- Adjacent dispatcher, outbound message, and inbound message suites: 66 tests, 0 failures.
- Focused LiveView follow regression: 1 test, 0 failures.
- `PATH="$PWD/bin:$PATH" dev check --quick`: 1,337 tests, 0 failures.
- `git diff --check`: passed.

The full browser-inclusive `dev check` was not run in this per-task node, consistent with the workflow’s ordinary-task constraint; final full validation remains explicitly owned by task 021 and the workflow gate.

4. Exact unchecked line

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked off.

6. ADR conformance

- ADR 0004/0005: message and delivery ownership and resolved-recipient command semantics remain unchanged.
- ADR 0007: Messaging continues to depend on Membership through its public API; no cross-context projector mutation or direct Membership read-model coupling was introduced.
- ADR 0009/0021/0022: the dispatcher reacts to committed projection state and uses the existing projection-barrier authorization path. Startup is only an additional pending-work nudge.
- ADR 0024: current membership authority remains in the Club aggregate and is reached through Membership’s authoritative public queries.
- Existing already-handed-off email semantics remain intact: every recovered pending delivery still passes through the same final stable authorization immediately before the provider call.