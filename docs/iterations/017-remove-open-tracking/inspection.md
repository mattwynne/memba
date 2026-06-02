# Open-tracking reference inspection

Date: 2026-06-02

Scope inspected for task 001:

- `web/lib`
- `web/test`
- `acceptance-tests/features`
- active first-party docs under `docs/`, excluding historical `docs/iterations/**` and vendored/library docs under `docs/tools/**`
- Postmark outbound provider and webhook code

Search terms used:

- `opened`
- `Opened`
- `track_opens`
- `open tracking`
- `open-tracking`
- `EmailDeliveryOpened`
- `ReportEmailDeliveryOpened`
- `report_email_delivery_opened`

The bare sandbox did not have `rg` on `PATH`, so the inventory was produced with
`python3` recursive searches using the same terms and exclusions.

## Summary counts

| Area | Files with matches | Matching lines | Notes |
| --- | ---: | ---: | --- |
| `web/lib` | 15 | 47 | Current domain, projection, provider, webhook, and presentation references. |
| `web/test` | 17 | 106 | Current domain, provider, webhook, LiveView, controller, and cucumber harness expectations. |
| `acceptance-tests/features/**/*.feature` | 0 | 0 | Shared feature files already contain no opened receipt examples. |
| `acceptance-tests/features` support/steps | 2 | 9 | Browser acceptance step/support plumbing still supports opened delivery reports. |
| active first-party docs | 9 | 25 | ADRs and current Postmark/human docs still describe opened/open-tracking behaviour. |

## Current application references by follow-up area

### Messaging command/API/event path

- `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`
- `web/lib/memba/messaging/events/email_delivery_opened.ex`
- `web/lib/memba/messaging/message.ex`
- `web/lib/memba/messaging/router.ex`
- `web/lib/memba/messaging.ex`
- Tests:
  - `web/test/memba/messaging/app_test.exs`
  - `web/test/memba/messaging/message_test.exs`
  - `web/test/memba/messaging/send_message_dispatch_test.exs`
  - `web/test/memba/messaging/status_report_api_test.exs`

Key current behaviours found:

- `ReportEmailDeliveryOpened` is routed and executable.
- `EmailDeliveryOpened` is emitted/applied.
- The aggregate allows `delivered -> opened`.
- `Messaging.report_email_delivery_opened/2` is public API.

### Projections/read models

- `web/lib/memba/messaging/projectors/member_email_delivery.ex`
- `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex`
- Tests:
  - `web/test/memba/messaging/member_email_delivery_projection_test.exs`
  - `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs`
  - `web/test/memba_web/member_message_detail_loader_test.exs`

Key current behaviours found:

- Member delivery projections write `"opened"`.
- Memba staff delivery projections write `"opened"`.
- Loader/presentation tests still include opened summary rows.

### Postmark outbound delivery

- `web/lib/memba/messaging/email_delivery_providers/postmark.ex`
- `web/test/memba/messaging/email_delivery_providers/postmark_test.exs`

Key current behaviours found:

- Outbound Postmark member-message email sets `put_provider_option(:track_opens, true)`.
- The provider test explicitly expects open tracking.

### Provider webhooks

- `web/lib/memba_web/controllers/postmark_webhook_controller.ex`
- `web/lib/memba_web/controllers/resend_webhook_controller.ex`
- Tests:
  - `web/test/memba_web/controllers/postmark_webhook_controller_test.exs`
  - `web/test/memba_web/controllers/resend_webhook_controller_test.exs`

Key current behaviours found:

- Postmark `Open`/`Opened` events map to `:opened` and call `Messaging.report_email_delivery_opened/1`.
- Resend `email.opened`/`opened` events also map to `:opened` and call the same API.
- The iteration plan explicitly names Postmark webhook rejection; Resend still has matching current open-event behaviour because it shares the provider-neutral opened API.

### Member-facing presentation and LiveViews/controllers

- `web/lib/memba_web/member_email_delivery_presentation.ex`
- `web/lib/memba_web/member_dashboard_presentation.ex`
- `web/lib/memba_web/controllers/page_html.ex`
- `web/lib/memba_web/controllers/page_html/message.html.heex`
- Tests:
  - `web/test/memba_web/member_email_delivery_presentation_test.exs`
  - `web/test/memba_web/member_dashboard_presentation_test.exs`
  - `web/test/memba_web/controllers/member_message_detail_test.exs`
  - `web/test/memba_web/live/member_dashboard_live_test.exs`
  - `web/test/memba_web/live/member_message_live/show_test.exs`
  - `web/test/memba_web/live/browser_acceptance_harness_test.exs`

Key current behaviours found:

- Member receipt ordering includes `"opened"`.
- Member copy includes `"Opened"`, `"read it"`, `"arrived, not opened yet"`, and receipt-glance copy such as `"1 of 2 opened"`.
- LiveView tests assert opened groups, toggles, segments, counts, data attributes, and copy.

### Memba staff delivery views

- `web/lib/memba_web/live/admin/deliveries_live/index.ex`
- Tests are mainly covered by the staff projection/webhook/API tests and browser acceptance support.

Key current behaviours found:

- The staff delivery view has an opened-specific status class.

### Acceptance feature tree

- `acceptance-tests/features/member_message_deliverability.feature` has no opened receipt examples.
- `acceptance-tests/features/memba_staff_email_deliverability.feature` has no opened staff scenario.
- Opened support remains in:
  - `acceptance-tests/features/step_definitions/member_message_steps.js`
  - `acceptance-tests/features/support/member_message.js`

### Active docs

- `docs/adr/0004-model-message-deliverability-as-a-message-aggregate.md`
- `docs/adr/0006-simplify-member-facing-delivery-status.md`
- `docs/adr/0012-track-whether-message-delivery-was-opened.md`
- `docs/adr/0016-use-resend-as-switchable-email-provider.md`
- `docs/human-todo.md`
- `docs/kaizen/2026-05-30-iteration-implementation-reset-cycle-limit.md`
- `docs/postmark-email.md`
- `docs/problem-domain-audit-2026-06-01.md`
- `docs/strategy/research/extracted-text/Memba Market and Competitor Research.txt`

Key current behaviours found:

- `docs/postmark-email.md` instructs operators to enable `Open` webhooks, Resend opened events, and Postmark open tracking.
- Accepted ADRs 0004, 0006, 0012, and 0016 still describe opened as part of the model/current provider lifecycle. ADR 0012 directly conflicts with this iteration's new policy and will need historical/superseded treatment or an ADR update in the documentation task.
- The strategy research match is extracted third-party wishlist text about another product's email-open search. It is not current Memba app behaviour.
