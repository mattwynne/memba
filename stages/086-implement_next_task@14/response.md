Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `013 Restyle /admin/messages/:message_id consistently without changing diagnostics semantics.`

2. **Changes made**
   - Updated `web/lib/memba_web/live/admin/messages_live/show.ex`
     - Restyled `/admin/messages/:message_id` to match the staff operations treatment used by Messages and Deliveries.
     - Added stable structure/selectors:
       - `data-admin-page="message-diagnostics"`
       - `#message-diagnostics-summary-cards`
       - `#message-diagnostics-note`
       - `#message-body-card`
       - `#addressed-recipients-card`
       - `#delivery-records-card`
       - `#member-receipts-card`
     - Preserved existing diagnostics semantics:
       - same message lookup: `Messaging.get_message/1`
       - same addressed/email delivery query: `Messaging.list_recipient_deliveries/1`
       - same member receipt query: `Messaging.list_member_email_deliverys/1`
       - same stream IDs and data attributes used by existing tests/acceptance support
       - same “Back to club” link and existing read-only behaviour
       - did not add resend/delete/bulk/filter/composer behaviour
     - Added display-only count assigns and status chip styling.
   - Updated `web/test/memba_web/live/admin_diagnostics_live_test.exs`
     - Added assertions for the new stable page/card selectors.
     - Kept existing assertions for subject/body, recipients, delivery IDs, raw delivery status, member receipt status, and provider reason absence.
   - Updated `docs/iterations/021-staff-area-redesign/todo.md`
     - Checked off only task `013`.

3. **Validation commands/results**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/admin/messages_live/show.ex test/memba_web/live/admin_diagnostics_live_test.exs`
     - Initially failed on line wrapping; fixed manually because formatter write hit a sandbox permission issue.
     - Final result: passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/admin_diagnostics_live_test.exs test/memba_web/live/browser_acceptance_harness_test.exs`
     - Hit sandbox Postgres readiness path mismatch before tests ran.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix test test/memba_web/live/admin_diagnostics_live_test.exs test/memba_web/live/browser_acceptance_harness_test.exs'`
     - Passed: `6 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `524 tests, 0 failures`
       - Acceptance: `34 scenarios (34 passed), 215 steps (215 passed)`
   - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 013 Restyle /admin/messages/:message_id consistently without changing diagnostics semantics.`
   - To:
     - `- [x] 013 Restyle /admin/messages/:message_id consistently without changing diagnostics semantics.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001 / 0015: Work remains in Phoenix LiveView.
   - ADR 0004: Did not change message/delivery aggregate semantics.
   - ADR 0006: Preserved distinction between staff/raw delivery records and member-facing receipt statuses.
   - ADR 0007: No Membership/Messaging boundary changes.
   - ADR 0009: No projection plumbing or read-model schema changes.
   - ADR 0013: Browser-facing selectors and behaviours remain covered by focused Phoenix/PhoenixTest-style tests.