Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 Remove or deprecate the Messaging opened-report command/API/event path from current behaviour:`

2. **Changes made**
   - Removed `ReportEmailDeliveryOpened` from the Messaging command router registration.
   - Stopped the Messaging public API from dispatching opened commands:
     - `Messaging.report_email_delivery_opened/2` now returns `{:error, :unsupported_delivery_status}` and is `@doc false`.
   - Removed the aggregate command handler that emitted `EmailDeliveryOpened`.
   - Removed the valid `:delivered -> :opened` aggregate transition.
   - Kept the legacy opened command/event modules as compatibility shims, with updated moduledocs explaining they are not current behaviour.
   - Changed aggregate handling of historic `EmailDeliveryOpened` events to no-op rather than putting the aggregate into `:opened`.
   - Updated Messaging/domain/API tests so current command/API paths cover only sent, delivered, delayed, bounced, and spam complaint statuses.
   - Updated obsolete tests that still invoked the opened API/command path so `dev check` remains green.
   - Did not edit acceptance `.feature` files.

3. **Focused validation**
   - Formatted changed Elixir files with `mix format`.
   - Ran focused tests:
     - `mix test test/memba/messaging/message_test.exs test/memba/messaging/app_test.exs test/memba/messaging/send_message_dispatch_test.exs test/memba/messaging/status_report_api_test.exs test/memba/messaging/member_email_delivery_projection_test.exs test/memba/messaging/memba_staff_email_delivery_projection_test.exs test/memba_web/controllers/postmark_webhook_controller_test.exs test/memba_web/controllers/resend_webhook_controller_test.exs test/memba_web/live/browser_acceptance_harness_test.exs`
     - Result: `40 tests, 0 failures`
   - Ran compile validation:
     - `mix compile --warnings-as-errors`
     - Result: passed
   - Ran full project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed, `354 tests, 0 failures`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Remove or deprecate the Messaging opened-report command/API/event path from current behaviour:`
   - To:
     - `- [x] 003 Remove or deprecate the Messaging opened-report command/API/event path from current behaviour:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Read relevant ADRs: `0002`, `0004`, `0006`, `0007`, `0012`, and `0016`.
   - Preserved Commanded/CQRS structure from ADRs `0002`, `0004`, and `0007`.
   - Preserved delivered/problem handling from ADR `0006`, while aligning with the newer iteration plan decision that opened is no longer current product behaviour.
   - Kept opened event/command modules as internal compatibility shims rather than deleting them outright, consistent with the plan’s replay/deserialization caution.
   - ADR `0012` still describes the old opened behaviour; this task intentionally implements the iteration plan’s newer policy while leaving broader ADR/documentation reconciliation to the later documentation task.