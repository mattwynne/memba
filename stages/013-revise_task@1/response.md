Task 019’s revised candidate implementation is complete and ready for independent review. The task remains unchecked.

1. Selected task

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

2. Changes made

- Added a narrow public Membership API that checks active group membership from authoritative Club aggregate state, avoiding stale access projections at privacy-sensitive action boundaries: [membership.ex](/workspace/memba/web/lib/memba/membership.ex:1359).
- Updated Messaging’s member-facing reply, follow, unfollow, and compose operations to authorize against authoritative Membership and Message aggregate state at a stable event-store checkpoint: [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:85).
- Added `send_club_message_as_current_member/2` and routed the compose LiveView through it, so an already-open compose page fails closed after committed departure: [new.ex](/workspace/memba/web/lib/memba_web/live/member_message_live/new.ex:428).
- Kept provider handoff guarded by stable projection barriers. Projection-lag timeouts defer pending deliveries without contacting the provider or recording a delivery attempt.
- Extended the supervised dispatcher to treat Membership and conversation-access projector catch-up notifications as dispatch nudges. Deferred deliveries now recover automatically after projections catch up, without a manual sweep: [email_delivery_dispatcher.ex](/workspace/memba/web/lib/memba/messaging/email_delivery_dispatcher.ex:233).
- Added regression coverage for stale reply/follow/compose authorization and automatic deferred-delivery recovery: [send_club_message_test.exs](/workspace/memba/web/test/memba/messaging/send_club_message_test.exs:437), [new_send_test.exs](/workspace/memba/web/test/memba_web/live/member_message_live/new_send_test.exs:388).
- Converted affected custom-group test fixtures to aggregate-backed Membership history, ensuring projection-only discovery does not confer participation rights: [conversation_group_access_projection_test.exs](/workspace/memba/web/test/memba/messaging/conversation_group_access_projection_test.exs:306).
- No acceptance feature files were changed.

3. Focused validation

Passed:

- `PATH="$PWD/bin:$PATH" dev test test/memba/messaging/conversation_group_access_projection_test.exs:306`
  - 1 selected test passed; 0 failures.
- Full task-019 regression set across dispatcher, messaging, departure cleanup, controllers, and member-message LiveViews:
  - 68 tests, 0 failures.
- `MIX_ENV=test mix format --check-formatted ...`
  - Passed for all seven changed files.
- `git diff --check`
  - Passed.
- Worktree inspection confirms only the seven task-019 implementation/test files are modified.

Full `dev check` was not run in this per-task node because pending task 021 explicitly owns the final exact-state gate.

4. Exact unchecked task

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0007: Messaging obtains membership authority through Membership’s public API.
- ADR 0009: asynchronous projections remain read models; no cross-context side effects were placed in projectors.
- ADR 0021: existing committed read-model notifications provide bounded catch-up nudges.
- ADR 0022: authorization and provider handoff use explicit event-store checkpoint stability.
- ADR 0024: Club aggregate state remains authoritative for departure and group membership.
- ADRs 0004 and 0005: Message aggregates and resolved-recipient delivery semantics remain intact.