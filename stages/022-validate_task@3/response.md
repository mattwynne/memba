### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found:
  - Live working tree is clean.
  - Recent implementation checkpoint `eec2a06` changed exactly one ordinary todo line:
    - `- [ ] 003 Remove or deprecate the Messaging opened-report command/API/event path from current behaviour:`
    - to `- [x] 003 ...`
  - Parent todo state had `001` and `002` checked and `003` as the first unchecked task.

- Implementation artifacts found:
  - `web/lib/memba/messaging/router.ex` no longer registers `ReportEmailDeliveryOpened`.
  - `web/lib/memba/messaging.ex` no longer builds/dispatches an opened command; `report_email_delivery_opened/2` returns `{:error, :unsupported_delivery_status}` and is hidden from docs.
  - `web/lib/memba/messaging/message.ex` no longer handles opened commands or permits `:delivered -> :opened`; historic `EmailDeliveryOpened` aggregate application is a no-op.
  - Legacy opened command/event modules remain only as compatibility shims with updated moduledocs.
  - Messaging/domain/API tests were updated to cover delivered, delayed, bounced, spam complaint, and unsupported opened behavior.
  - No acceptance `.feature` files were changed in the implementation checkpoint.

- Tests run/results found:
  - I ran live validation: `PATH="$PWD/bin:$PATH" dev check`
  - Result: passed — `354 tests, 0 failures`.

- ADR/plan conformance notes:
  - Work matches task `003` and the plan-required scope for removing the Messaging opened-report command/API/event path from current behavior.
  - Commanded/CQRS aggregate/router structure from accepted ADRs remains intact.
  - The old opened event/command modules were retained as compatibility shims, consistent with the plan’s replay/deserialization caution.
  - Accepted ADR `0012` still documents the old opened behavior, but this task implements the validated newer iteration policy; broader current-documentation cleanup remains scoped to later todo work.

{"context_updates":{"task_valid":true,"task_retry_available":false}}