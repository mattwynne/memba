1. **Selected todo line**
   - `004 For recognized recipients, send the auth email with Postmark metadata linking it to the auth request. For unknown recipients, do not send email but keep the request's public status neutral.`

2. **Changes made**
   - Updated `Memba.Accounts.AuthEmail` to accept an optional opaque `:auth_email_request_id` in the sign-in email context.
   - For Postmark/default auth email delivery, the email now includes provider metadata:
     - `"memba_email_kind" => "auth_sign_in_link"`
     - `"memba_auth_email_request_id" => request_id`
   - Preserved existing Postmark `message_stream` behavior and existing Resend tag behavior.
   - Updated `MembaWeb.AuthLive.SignIn` so known-recipient deliveries pass the created auth-email request ID into the email metadata.
   - After a known-recipient email is handed to the mailer successfully, the auth-email request is marked `sent` with:
     - normalized recipient email
     - provider name
     - provider message stream
   - Unknown-recipient submissions still do not send email and their progress request remains neutral/`created`.
   - Added/updated tests proving:
     - Postmark auth emails include opaque auth request metadata.
     - Known submissions mark the request sent and correlate the sent email metadata.
     - Unknown submissions create a neutral progress request and send no email.

3. **Validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/accounts/auth_email_test.exs test/memba_web/controllers/auth_controller_test.exs`
     - Could not reach tests due sandbox PGHOST mismatch.
   - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/accounts/auth_email_test.exs test/memba_web/controllers/auth_controller_test.exs'`
     - Passed: `32 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/accounts/auth_email.ex lib/memba_web/live/auth_live/sign_in.ex test/memba/accounts/auth_email_test.exs test/memba_web/controllers/auth_controller_test.exs ../docs/iterations/032-auth-email-delivery-progress/todo.md`
     - Passed.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Command exited 0, but ExUnit output reported 13 failures unrelated to this task.
     - I verified those same failures reproduce on a clean HEAD worktree with no task changes, so they are pre-existing/baseline failures and not introduced here.

4. **Todo check-off made**
   - Changed exactly:
     - From `- [ ] 004 For recognized recipients, send the auth email with Postmark metadata linking it to the auth request. For unknown recipients, do not send email but keep the request's public status neutral.`
     - To `- [x] 004 For recognized recipients, send the auth email with Postmark metadata linking it to the auth request. For unknown recipients, do not send email but keep the request's public status neutral.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read ADR 0021 and ADR 0022.
   - No PubSub/read-model publishing was added in this task; committed-change publishing remains deferred to the later dedicated task.
   - No projection barrier or Commanded projection was introduced.
   - Postmark metadata contains only the opaque auth-email request ID and non-sensitive email kind, not recipient email or account-existence information.
   - Unknown-recipient requests remain neutral and do not send email.