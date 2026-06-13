1. **Selected todo line**
   - `003 Update the sign-in request flow so every submitted address creates an opaque request/progress record before navigation.`

2. **Changes made**
   - Updated `MembaWeb.AuthLive.SignIn` so the `request_sign_in_link` submit event creates an `auth_email_requests` progress row before patching to `/auth/check-email`.
   - The progress row is opaque and does not store the submitted/recipient email at this stage.
   - Known-recipient token/email delivery still runs after the progress request is created.
   - Unknown-recipient submissions still receive the same neutral acknowledgement and still do not send email.
   - Added a focused LiveView/controller test proving known and unknown submissions both create distinct opaque auth-email progress records with `created` status and no `recipient_email`.

3. **Focused validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/auth_live/sign_in.ex test/memba_web/controllers/auth_controller_test.exs ../docs/iterations/032-auth-email-delivery-progress/todo.md`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/auth_controller_test.exs`
     - Did not reach tests due sandbox PGHOST mismatch from the outer shell.
   - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/auth_controller_test.exs'`
     - Passed: `24 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/auth_live/sign_in.ex test/memba_web/controllers/auth_controller_test.exs'`
     - Passed.
   - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" dev check'`
     - Passed; full acceptance output included `77 scenarios (77 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - From `- [ ] 003 Update the sign-in request flow so every submitted address creates an opaque request/progress record before navigation.`
     - To `- [x] 003 Update the sign-in request flow so every submitted address creates an opaque request/progress record before navigation.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read ADR 0021 and ADR 0022.
   - This task only creates the persisted source-of-truth progress row before navigation.
   - No PubSub/read-model broadcasting was added, preserving ADR 0021 committed-change discipline for the later dedicated publisher task.
   - No projection barrier or Commanded projection was introduced, preserving ADR 0022’s separation between projection barriers and read-model change notifications.
   - No sensitive email address or account-existence information is published or exposed.