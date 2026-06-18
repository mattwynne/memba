Result: IMPLEMENTED_AND_PUBLISHED

Plan path: `docs/iterations/035-obliterate-opened-delivery-status/plan.md`

## Summary of delivered capability

Iteration 035 removed Memba’s deprecated/unsupported `"opened"` email delivery status from active product behaviour while preserving replay safety for historic event-store data.

Delivered outcomes:

- Removed active command/reporting path for `ReportEmailDeliveryOpened`.
- Removed active `"opened"` read-model normalization and presentation behaviour.
- Removed webhook handling that treated `"opened"` as a supported/rejected delivery status branch.
- Removed member/staff UI, dashboard, diagnostics, and test expectations for opened delivery counts/statuses.
- Preserved only the documented replay-only `EmailDeliveryOpened` tombstone/shim needed for historic event deserialization/rebuild safety.
- Added regression coverage proving a historic `EmailDeliveryOpened` event can be replayed without affecting projections/read models.

## Plan conformance summary

Plan conformance gate reported `PLAN_CONFORMANT`.

Evidence cited by the workflow:

- Todo list fully checked for all 9 implementation-plan items.
- Command, routing/registration, read-model normalization, presentation mapping, webhook branch, UI/status/count references, and active test expectations for `opened` were removed.
- Remaining `opened`/`Opened` source references are limited to documented replay-only tombstone/shim paths.
- Historic-event replay-safety regression test exists and passes.
- No acceptance `.feature` files were changed.
- `dev ci` / `dev check` passed on a clean state.
- Working tree was clean.

The final artifact gate also confirmed implementation evidence and reported:

- “No acceptance .feature changes detected.”
- “Final artifact evidence confirmed.”
- “Final artifact gate passed.”

## Key files changed

From the final artifact gate / publish output, the implementation changed 32 files total. Key files by area:

### Iteration documentation

- `docs/iterations/035-obliterate-opened-delivery-status/inventory.md`
- `docs/iterations/035-obliterate-opened-delivery-status/todo.md`
- `docs/iterations/035-obliterate-opened-delivery-status/plan.md`

### Acceptance test support / JS steps

- `acceptance-tests/features/step_definitions/member_message_steps.js`
- `acceptance-tests/features/support/member_message.js`
- `acceptance-tests/test/member_message_steps.test.js`

### Messaging domain and replay shim

- `web/lib/memba/messaging.ex`
- `web/lib/memba/messaging/commands/report_email_delivery_opened.ex` — deleted
- `web/lib/memba/messaging/events/email_delivery_opened.ex`
- `web/lib/memba/messaging/message.ex`
- `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex`
- `web/lib/memba/messaging/projectors/member_email_delivery.ex`

### Web controllers / presentation

- `web/lib/memba_web/controllers/postmark_webhook_controller.ex`
- `web/lib/memba_web/member_email_delivery_presentation.ex`

### Feature / step-definition tests

- `web/test/features/cucumber_configuration_test.exs`
- `web/test/features/step_definitions/messaging_steps.exs`

### Messaging regression and projection tests

- `web/test/memba/messaging/email_delivery_opened_replay_test.exs` — added
- `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs`
- `web/test/memba/messaging/member_email_delivery_projection_test.exs`
- `web/test/memba/messaging/message_test.exs`
- `web/test/memba/messaging/send_message_dispatch_test.exs`
- `web/test/memba/messaging/status_report_api_test.exs`

### Web controller/live/presentation tests

- `web/test/memba_web/controllers/member_message_detail_test.exs`
- `web/test/memba_web/controllers/postmark_webhook_controller_test.exs`
- `web/test/memba_web/controllers/resend_webhook_controller_test.exs`
- `web/test/memba_web/live/deliveries_live_test.exs`
- `web/test/memba_web/live/member_dashboard_live_test.exs`
- `web/test/memba_web/live/member_message_live/show_test.exs`
- `web/test/memba_web/member_dashboard_presentation_test.exs`
- `web/test/memba_web/member_email_delivery_presentation_test.exs`

### Test support

- `web/test/support/event_sourced_case.ex`

## Published commit on main

Publish-to-main succeeded.

Published implementation to `main`:

- `21b902b7581accdfda3a782fca36e9b693619d6a`

Publish output also recorded:

- Commit subject: `iteration 035: Obliterate the deprecated "opened" email delivery status`
- `32 files changed, 407 insertions(+), 506 deletions(-)`
- Created:
  - `docs/iterations/035-obliterate-opened-delivery-status/inventory.md`
  - `docs/iterations/035-obliterate-opened-delivery-status/todo.md`
  - `web/test/memba/messaging/email_delivery_opened_replay_test.exs`
- Deleted:
  - `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`
- “No acceptance .feature changes detected.”
- “Marked docs/iterations/035-obliterate-opened-delivery-status/plan.md as merged in plan and iteration index.”

## Commit trailer metadata present

Commit trailer metadata is present via the Fabro/publish workflow metadata in the published implementation.

Relevant commit evidence from publish output:

- Published commit on main: `21b902b7581accdfda3a782fca36e9b693619d6a`
- Commit subject: `iteration 035: Obliterate the deprecated "opened" email delivery status`

## Tests and validation run

Validation completed successfully.

Commands / workflow validation cited:

- `PATH="$PWD/bin:$PATH" dev check`
  - Passed.
  - ExUnit: `799 tests, 0 failures`
  - Acceptance: `82 scenarios (82 passed)`, `493 steps (493 passed)`
- Final workflow `dev_check` stage ran `PATH="$PWD/bin:$PATH" dev ci`
  - Passed.
  - Acceptance output: `82 scenarios (82 passed)`, `493 steps (493 passed)`
- Plan conformance gate passed.
- Final artifact gate passed.
- Publish-to-main succeeded.

## Manual demo/checks still recommended

None required for delivery.

Optional smoke checks if desired:

- Open a member message detail page and confirm delivery status/count surfaces no longer mention “opened.”
- Open staff delivery diagnostics and confirm “opened” is absent.
- Replay/projection rebuild can be trusted from the added regression test, but a staging rebuild could be run if operational confidence is desired.

## Non-blocking follow-ups

- If production event-store inspection later confirms there are zero historic `EmailDeliveryOpened` events, a future iteration could remove the replay-only tombstone/shim entirely.
- Keep the replay-only comments in place until that confirmation exists, so future cleanup does not accidentally break historic event deserialization/rebuilds.