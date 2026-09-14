1. Selected task

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

2. Changes made

- Added an aggregate-backed active-club-membership query through Membership’s public API in [membership.ex](/workspace/memba/web/lib/memba/membership.ex:1357).
- Updated the inbound group-email posting policy to use authoritative Club state instead of potentially stale Membership projections in [group_email_posting_policy.ex](/workspace/memba/web/lib/memba/messaging/group_email_posting_policy.ex:45).
- Authorization now runs at a stable event-store checkpoint and is repeated immediately before creating a new inbound conversation in [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:356) and [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:1477). A departure committed during earlier email parsing therefore fails closed and records the normal sender-not-active rejection.
- Replaced access-projector notification dependence with a coalesced dispatcher retry timer in [email_delivery_dispatcher.ex](/workspace/memba/web/lib/memba/messaging/email_delivery_dispatcher.ex:242). Deferred pending deliveries now resume even when the lagging projector catches up exclusively through irrelevant events and emits no read-model-change message.
- Added deterministic projection-lag coverage for departed inbound senders in [inbound_club_message_acceptance_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:1929).
- Extended provider-handoff coverage to prove timer-driven recovery after silent projector catch-up in [send_club_message_test.exs](/workspace/memba/web/test/memba/messaging/send_club_message_test.exs:442).
- Converted posting-policy fixtures to aggregate-backed membership histories and retained coverage for active club members posting to groups they have not joined.
- No acceptance feature files were changed.

3. Validation

TDD regressions first failed as intended:

- The projection-lag inbound test created a conversation after departure.
- The silent projector catch-up test received no retry nudge.

Final validation passed:

- Focused task-019 regression set covering dispatcher, inbound email, posting policy, messaging authorization, follow cleanup, controllers, and compose LiveView:
  - `103 tests, 0 failures`.
- Full inbound-email file:
  - `33 tests, 0 failures`.
- Posting-policy file:
  - `5 tests, 0 failures`.
- `MIX_ENV=test mix format --check-formatted ...`
  - Passed for all seven revised files.
- `git diff --check`
  - Passed.

Full `dev check` was not run in this per-task node because pending task 021 explicitly owns the exact final-state gate.

4. Exact task still awaiting independent review

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0007: Messaging uses Membership’s public authoritative API and does not inspect Membership aggregate or projection storage directly.
- ADR 0009: projections remain asynchronous read models, not authorization authorities.
- ADR 0021: dispatcher recovery no longer assumes irrelevant events publish committed read-model changes.
- ADR 0022: privacy-sensitive authorization and provider handoff retain explicit stable-checkpoint and projection-barrier checks.
- ADR 0024: the Club aggregate remains authoritative for active membership and departure.
- ADRs 0004/0005: existing Message aggregate ownership and resolved-recipient delivery semantics remain unchanged.