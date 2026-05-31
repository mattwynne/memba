Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 005 Add auth email delivery:`

2. **Changes made**
   - Added `Memba.Accounts.AuthEmail`
     - Builds concise plain-text and HTML magic-link emails.
     - Normalizes recipient emails.
     - Includes the provided `/auth/...` callback URL in both text and HTML bodies.
     - Sends through `Memba.Mailer`.
     - Adds Postmark `:message_stream` via Swoosh provider options.
     - Returns clear delivery/configuration errors without handing malformed requests to Swoosh.
   - Added `Memba.Accounts.AuthEmailConfig`
     - Supports explicit real auth email enablement with `MEMBA_AUTH_EMAIL_PROVIDER=postmark`.
     - Requires:
       - `MEMBA_POSTMARK_SERVER_TOKEN`
       - `MEMBA_AUTH_EMAIL_FROM_ADDRESS`
       - `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`
     - Provides clear missing/unsupported configuration errors.
   - Updated `web/config/runtime.exs`
     - When auth email Postmark delivery is explicitly enabled, configures `Memba.Mailer` with `Swoosh.Adapters.Postmark`.
     - Configures auth email sender and dedicated message stream.
     - Uses `Swoosh.ApiClient.Req`.
   - Added focused tests:
     - Auth email construction and Swoosh handoff.
     - Postmark message stream provider option.
     - Callback URL inclusion.
     - Missing config failure before Swoosh handoff.
     - Swoosh/API delivery error surfacing.
     - Invalid input rejection.
     - Auth email provider/env config parsing.

3. **Validation commands run**
   - Red TDD check:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/accounts/auth_email_config_test.exs test/memba/accounts/auth_email_test.exs`
     - Failed as expected before implementation with missing `Memba.Accounts.AuthEmailConfig`.
   - Focused tests:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/accounts/auth_email_config_test.exs test/memba/accounts/auth_email_test.exs`
     - Passed: `7 tests, 0 failures`.
   - Formatting:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" devenv shell -- mix format --check-formatted`
     - Passed.
   - Full project check:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" dev check`
     - Passed: `158 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Add auth email delivery:`
   - To:
     - `- [x] 005 Add auth email delivery:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: stays within the Phoenix application and existing Swoosh mailer setup.
   - ADR 0007: auth email delivery is isolated in the Accounts/auth boundary and does not couple Messaging to Membership storage or mutate membership state.
   - ADR 0008 / ADR 0009: no EventStore, Commanded, or projection persistence changes.
   - ADR 0013 / plan constraint: no acceptance `.feature` files or acceptance-test files changed.
   - Project rules: used Swoosh with `Swoosh.ApiClient.Req` for Postmark delivery; did not introduce HTTPoison, Tesla, `:httpc`, or direct Postmark HTTP code.