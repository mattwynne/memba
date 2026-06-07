1. **Selected todo line**
   - `004 Update web/lib/memba/accounts/auth_email.ex to render the new sign-in template while preserving provider options and error handling. Keep deliver_sign_in_link/2; add an optional context/options variant for group-led sign-in where callers can provide group name/context.`

2. **Changes made**
   - Updated `web/lib/memba/accounts/auth_email.ex` to use `Memba.EmailTemplates` for v2 sign-in email HTML:
     - single-column shell/card rendering;
     - Memba-led header for no-context sign-in;
     - group-led header when group/club context is supplied;
     - primary “Sign in” button plus printed fallback URL;
     - expiry, one-use, ignore-if-unrequested reassurance;
     - “Secured by Memba” trust footer;
     - recipient footer without hard-coded unconfirmed support addresses.
   - Kept `deliver_sign_in_link/2` working for existing callers.
   - Added `deliver_sign_in_link/3` accepting keyword/map context such as `group_name: ...`, `club_name: ...`, `club: %{name: ...}`, or `group: %{name: ...}`.
   - Preserved provider options:
     - Postmark/local `:message_stream`;
     - Resend tags.
   - Preserved existing invalid input/config/delivery error handling.
   - Added/updated tests in `web/test/memba/accounts/auth_email_test.exs` for:
     - no-context Memba-led sign-in email;
     - group-led subject/from/header/trust content;
     - nested club context;
     - HTML escaping and CR/LF header sanitization;
     - fallback URL rendering and URL escaping;
     - provider options.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/accounts/auth_email.ex test/memba/accounts/auth_email_test.exs`
     - Passed.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/accounts/auth_email_test.exs`
     - Passed: `8 tests, 0 failures`.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `576 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 004 ...`
   - To:
     - `- [x] 004 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: changes stay inside the Phoenix/Elixir core app.
   - ADR 0016: preserved the Swoosh/Mailer provider boundary and Postmark/Resend provider-option paths; no provider selection/configuration changes.
   - ADR 0020: no production smoke-test or external mailbox automation changes.
   - No acceptance feature files were changed.