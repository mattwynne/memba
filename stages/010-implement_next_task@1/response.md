Task 019’s candidate implementation is ready for independent review and remains unchecked.

1. Selected task

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

2. Changes made

- Preserved the existing provider-handoff safety work in [email_delivery_dispatcher.ex](/workspace/memba/web/lib/memba/messaging/email_delivery_dispatcher.ex:125):
  - waits for `Message` and `ConversationGroupAccess`;
  - waits for Membership’s `Membership` and `GroupMembership` projections through the public Membership API;
  - repeats authorization if the event-store checkpoint changes;
  - performs the final stable authorization read immediately before calling the provider.
- Projection timeouts now defer delivery instead of creating a terminal failure:
  - normal dispatch returns to `pending`;
  - manual retry returns to `failed` while preserving its existing diagnostics;
  - neither path increments the attempt count or calls the provider.
- Added a configurable projection timeout for deterministic lag testing while retaining the 5-second production default.
- Extended [send_club_message_test.exs](/workspace/memba/web/test/memba/messaging/send_club_message_test.exs:306) to prove departure/rejoin clears the former member’s follow, denies replies, excludes them from future recipients, and blocks an already-pending private email.
- Added a projection-lag scenario at [send_club_message_test.exs](/workspace/memba/web/test/memba/messaging/send_club_message_test.exs:433):
  - both Membership access projectors are stopped;
  - departure is committed while their read models still incorrectly show access;
  - provider handoff is deferred without exposing content or recording failure;
  - after projections catch up, the departed recipient is permanently rejected while the authorized recipient is delivered normally.
- No dashboard, retry UI, provider transaction, or database lock around an external provider call was introduced.

3. Validation

Passing:

- `PATH="$PWD/bin:$PATH" dev test test/memba/messaging/email_delivery_dispatcher_test.exs test/memba/messaging/send_club_message_test.exs test/memba/messaging/post_message_reply_test.exs test/memba/messaging/conversation_group_access_projection_test.exs test/memba/membership/clear_removed_group_member_follows_policy_test.exs test/memba_web/controllers/conversation_follow_controller_test.exs`
  - 57 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev test test/memba/messaging/send_club_message_test.exs`
  - 13 tests, 0 failures after the final follow-cleanup assertion.
- `MIX_ENV=test mix format --check-formatted lib/memba/messaging/email_delivery_dispatcher.ex test/memba/messaging/send_club_message_test.exs`
  - passed.
- `git diff --check`
  - passed.

The new lag test was first run red and reproduced the defect: projection timeouts marked deliveries failed with `recipient_access_projection_timeout`. It passed after implementing deferral.

`dev check --quick` was attempted but could not complete because its formatter tried to rewrite sandbox-owned modified files and received `permission denied`. The unrelated formatting mutation it made before stopping was reverted. Per the task workflow, full `dev check` remains explicitly owned by pending task 021.

4. Exact unchecked line

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0007: Messaging obtains membership authorization through Membership’s public API; it does not query Membership projection schemas directly.
- ADR 0009: the implementation treats projection state as asynchronous read models and does not move cross-context side effects into projectors.
- ADR 0021: existing committed read-model notifications remain unchanged.
- ADR 0022: authorization uses explicit event-store checkpoints and projection barriers for all four required projectors.
- ADR 0024: Club remains the authoritative owner of membership departure and custom-group removal facts.
- ADRs 0004 and 0005: the existing Message aggregate and resolved-recipient delivery model remain intact.