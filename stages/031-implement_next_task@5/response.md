1. **Selected todo line**
   - `005 Update sign-in call sites only where group context is already available or cheaply derivable, such as club-subdomain sign-in. When no group context is available, keep the Memba-led sign-in subject/heading.`

2. **Changes made**
   - Updated `web/lib/memba_web/live/auth_live/sign_in.ex`:
     - Resolves club context from the request host when `/auth` is visited on a known club subdomain.
     - Passes that context to `AuthEmail.deliver_sign_in_link/3`.
     - Keeps empty context for ordinary/global sign-in requests, preserving Memba-led subject/heading.
   - Updated `web/test/memba_web/controllers/auth_controller_test.exs`:
     - Verifies ordinary sign-in remains Memba-led (`Sign in to Memba`, sender display name `Memba`).
     - Verifies known club-subdomain sign-in is group-led with club name in subject/from/text/html.
     - Verifies same-host club sign-in flow now sends a group-led sign-in email.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/auth_live/sign_in.ex test/memba_web/controllers/auth_controller_test.exs`
     - Passed.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/controllers/auth_controller_test.exs`
     - Passed: `22 tests, 0 failures`.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" dev check`
     - Passed: ExUnit `576 tests, 0 failures`; acceptance `44 scenarios, 291 steps passed`.
     - Note: first `dev check` attempt failed because `acceptance-tests/node_modules` was missing `cucumber-js`; I restored ignored acceptance dependencies with `npm_config_cache=/tmp/memba-npm-cache npm ci`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Update sign-in call sites only where group context is already available or cheaply derivable, such as club-subdomain sign-in. When no group context is available, keep the Memba-led sign-in subject/heading.`
   - To:
     - `- [x] 005 Update sign-in call sites only where group context is already available or cheaply derivable, such as club-subdomain sign-in. When no group context is available, keep the Memba-led sign-in subject/heading.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference ADRs, and no `docs/adr/*.md` files were present in this checkout.
   - Change stays inside the Phoenix app and existing auth email delivery path.
   - No provider configuration, DNS, sender-domain, token lifetime, or sign-in authorization policy changes.
   - Existing `AuthEmail.deliver_sign_in_link/2` remains untouched for no-context callers; the LiveView uses the already-added `/3` context variant only where club context is cheaply derivable.
   - No acceptance feature files or step definitions were changed.