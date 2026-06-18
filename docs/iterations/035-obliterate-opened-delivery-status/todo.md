# Implementation TODO

- [x] 001 Inventory every `opened`/`Opened` reference in `lib/`, `test/`, and `acceptance-tests/` (baseline grep) and classify each as remove vs retain-as-shim.
- [ ] 002 Delete the `ReportEmailDeliveryOpened` command and any dispatch routing/registration for it.
- [ ] 003 Remove the `"opened"` read-model normalization clauses in `messaging.ex`, the presentation `"opened" -> "delivered"` mapping, and the webhook `"opened"` rejection branch.
- [ ] 004 Reduce the aggregate `apply/2` for `EmailDeliveryOpened` to a documented no-op; reduce the two projectors to documented no-op handling only where replay would otherwise fail, removing all active behaviour.
- [ ] 005 Keep `events/email_delivery_opened.ex` as the deserialization tombstone with a deprecation comment.
- [ ] 006 Update/remove `"opened"` assertions and fixtures across the affected ExUnit suites and acceptance JS step/support files.
- [ ] 007 Add the historic-event replay-safety regression test.
- [ ] 008 Re-run the baseline grep to confirm only the documented shim remains.
- [ ] 009 Run `dev check`.
