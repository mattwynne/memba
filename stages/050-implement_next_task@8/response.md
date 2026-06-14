Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 Publish auth-email progress changes after the relevant DB update commits, using the ADR 0021 discipline. The auth progress record is not a Commanded projection; use a small committed-update publisher with a narrow auth-progress topic and reload from persistence in the LiveView after broadcast.`

2. **Changes made**
   - Added `Memba.AuthEmailProgressChanges.publish/1`:
     - Uses the existing narrow per-request topic.
     - Broadcasts only `{:auth_email_progress_changed, %{request_id: request_id}}`.
     - Does not publish recipient email or account-existence details.
   - Updated `Memba.Accounts`:
     - Publishes after successful committed updates from:
       - `mark_auth_email_sent/3`
       - provider progress updates via `record_auth_email_provider_accepted/3`, `record_auth_email_provider_delayed/3`, and `record_auth_email_provider_failed/3`
     - Publishing happens after `Repo.transaction/1` returns successfully, not inside the transaction.
   - Added/updated tests:
     - Added context test proving sent/provider progress commits publish narrow notifications and persisted state is reloadable.
     - Updated LiveView test to rely on the committed update publishing automatically instead of manually broadcasting.

3. **Focused validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/accounts/auth_email_request_test.exs test/memba_web/controllers/auth_controller_test.exs`
     - Failed due sandbox Postgres `PGHOST` mismatch/stale devenv socket issue.
   - `devenv shell -- bash -lc 'cd web && mix test test/memba/accounts/auth_email_request_test.exs test/memba_web/controllers/auth_controller_test.exs'`
     - Passed: `36 tests, 0 failures`.
   - `devenv shell -- bash -lc 'cd web && mix test test/memba_web/controllers/postmark_webhook_controller_test.exs'`
     - Passed: `8 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `77 scenarios (77 passed)`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - From: `- [ ] 008 Publish auth-email progress changes after the relevant DB update commits, using the ADR 0021 discipline. The auth progress record is not a Commanded projection; use a small committed-update publisher with a narrow auth-progress topic and reload from persistence in the LiveView after broadcast.`
     - To: `- [x] 008 Publish auth-email progress changes after the relevant DB update commits, using the ADR 0021 discipline. The auth progress record is not a Commanded projection; use a small committed-update publisher with a narrow auth-progress topic and reload from persistence in the LiveView after broadcast.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0021: auth-email progress notifications are published only after committed source-of-truth DB updates complete, using Phoenix PubSub.
   - ADR 0022: no projection barrier or read-your-writes mechanism was introduced or conflated with PubSub notifications.
   - Privacy: PubSub payloads contain only opaque auth-email request IDs; LiveView continues to reload persisted state before rendering and no email/account-existence data is broadcast.