# Problems

## The deprecated "opened" email delivery status should be obliterated

Observed: 2026-06-17

Status: Unresolved

Surfaced while building realistic dev seeds for the gallery walk: there is no way to seed an `"opened"` delivery, because reporting "opened" is already deprecated — `Memba.Messaging.Commands.ReportEmailDeliveryOpened` is a retained no-op compatibility struct, the Postmark webhook explicitly rejects the `"opened"` record type as unsupported, and `MemberEmailDeliveryPresentation` collapses `"opened" -> "delivered"`. So "opened" is no longer produced, yet the concept still threads through the codebase as dead/confusing surface area:

- Command: `lib/memba/messaging/commands/report_email_delivery_opened.ex`
- Event: `lib/memba/messaging/events/email_delivery_opened.ex`
- Aggregate apply: `EmailDeliveryOpened` clause in `lib/memba/messaging/message.ex`
- Projectors: `EmailDeliveryOpened` clauses in `member_email_delivery.ex` and `memba_staff_email_delivery.ex`
- Read normalization: `status: "opened"` clauses in `lib/memba/messaging.ex`
- Presentation: `"opened" -> "delivered"` in `lib/memba_web/member_email_delivery_presentation.ex`
- Webhook: the `"opened"` rejection branch in `postmark_webhook_controller.ex`
- Tests referencing `"opened"` across messaging unit, projection, presentation, LiveView, controller, and acceptance step suites

This half-removed state misleads: the design system and member dashboard still imply an "opened" count, the seeds/gallery can't represent it, and contributors can't tell whether "opened" is a supported status. We should obliterate it entirely rather than leave a deprecated husk.

Note (event sourcing): removing the `EmailDeliveryOpened` event type needs a deliberate plan for any historic events already persisted in the event store — e.g. an upcaster/rewrite, or keeping a minimal ignore-on-replay shim — so a hard delete does not break projection rebuilds.

Expected:

- No `opened` delivery status concept remains in the domain (command, event, aggregate apply, projectors) or in read models, presentation, and webhooks — or it is consciously and consistently supported end to end, not both.
- Delivery status surfaces (member dashboard, member message detail, staff diagnostics/deliveries, the design system) reflect only the statuses Memba actually tracks.
- Historic event-store data is handled safely (replay/rebuild still works) as part of removal.
- Tests no longer assert behaviour for a status the product does not support.
