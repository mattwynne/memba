Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Extend Postmark webhook handling to route auth-stream delivery/problem events to auth-email progress updates without weakening member-message delivery-status handling.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/postmark_webhook_controller.ex`:
     - Detects Postmark auth-email events by `MessageStream == "outbound-authentication"` or auth request metadata.
     - Routes auth-stream:
       - delivered events → `Accounts.record_auth_email_provider_accepted/3`
       - delayed events → `Accounts.record_auth_email_provider_delayed/3`
       - bounced/spam complaint events → `Accounts.record_auth_email_provider_failed/3`
     - Persists Postmark diagnostic fields: provider, message ID, message stream, event ID/type, and reason where relevant.
     - Ignores auth-stream events with missing/unknown auth request correlation safely, without creating records.
     - Leaves existing member-message webhook handling on the existing `Messaging.report_email_delivery_*` path.
   - Updated `web/test/memba_web/controllers/postmark_webhook_controller_test.exs`:
     - Added auth-stream delivered test.
     - Added delayed/bounced/spam complaint auth-stream progress tests.
     - Added missing-correlation safety test.
     - Existing member-message webhook tests still pass.

3. **Validation commands run**
   - Initial bare wrapper focused test attempt hit sandbox Postgres readiness/env mismatch, so I used `devenv shell` for focused test runs.
   - `devenv shell -- bash -lc 'cd web && mix test test/memba_web/controllers/postmark_webhook_controller_test.exs:190 test/memba_web/controllers/postmark_webhook_controller_test.exs:207 test/memba_web/controllers/postmark_webhook_controller_test.exs:269'`
     - Result: `8 tests, 0 failures, 5 excluded`
   - `devenv shell -- bash -lc 'cd web && mix test test/memba_web/controllers/postmark_webhook_controller_test.exs'`
     - Result: `8 tests, 0 failures`
   - `devenv shell -- bash -lc 'cd web && mix format --check-formatted lib/memba_web/controllers/postmark_webhook_controller.ex test/memba_web/controllers/postmark_webhook_controller_test.exs'`
     - Result: passed
   - `git diff --check`
     - Result: passed
   - `PATH="$PWD/bin:$PATH" dev check`
     - Result: completed successfully with exit code `0`; acceptance reported `77 scenarios (77 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - From: `- [ ] 007 Extend Postmark webhook handling to route auth-stream delivery/problem events to auth-email progress updates without weakening member-message delivery-status handling.`
     - To: `- [x] 007 Extend Postmark webhook handling to route auth-stream delivery/problem events to auth-email progress updates without weakening member-message delivery-status handling.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0021: this task only records committed auth-email progress in the source-of-truth table; publishing committed updates remains reserved for task 008.
   - ADR 0022: no projection barrier/read-your-writes mechanism was introduced or conflated with webhook processing.
   - PubSub/privacy discipline preserved: no new PubSub payloads were added, and webhook routing stores only operational correlation/progress state. User/account-existence disclosure is unchanged.