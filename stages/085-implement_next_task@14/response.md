1. **Selected todo line**
   - `014 Implement welcome email generation with a magic sign-in token and post-auth destination for the new club member home.`

2. **Changes made**
   - Added `Memba.Onboarding.WelcomeEmail`:
     - Uses existing auth email configuration.
     - Creates a persisted sign-in token with `Accounts.create_sign_in_token/2`.
     - Sends a welcome email via `Memba.Mailer`.
     - Builds the sign-in callback URL on the converted club subdomain.
     - Adds `return_to` pointing at the club member home (`/` on the club subdomain).
     - Includes text + HTML email bodies and provider options.
   - Updated `Memba.Onboarding.convert_request_to_club/3` default welcome behaviour to call `WelcomeEmail.deliver/1`.
   - Updated `MembaWeb.AuthController` to accept a safe `return_to` query param on magic-link callbacks, falling back to the stored session return path.
   - Added tests:
     - Welcome email creates a sign-in token, sends the club-subdomain callback URL, includes the member-home `return_to`, and the token can be consumed.
     - Conversion default welcome email sends the expected link.
     - Auth callback can redirect to a safe post-auth destination without a stored session.
   - Checked off only task `014` in `todo.md`.

3. **Validation commands/results**
   - Initial direct `bin/mix test ...` hit a sandbox Postgres `PGHOST` readiness mismatch, so focused checks were rerun inside `devenv shell`.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/onboarding/welcome_email_test.exs test/memba/onboarding_conversion_test.exs test/memba_web/controllers/auth_controller_test.exs`
     - Passed: `28 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/admin/requests_live/index_test.exs`
     - Passed: `7 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix format --check-formatted ...`
     - Passed
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `565 tests, 0 failures`
     - Acceptance: `38 scenarios (38 passed), 252 steps (252 passed)`
   - `git diff --check`
     - Passed

4. **Todo check-off made**
   - Changed:
     - `- [ ] 014 Implement welcome email generation with a magic sign-in token and post-auth destination for the new club member home.`
   - To:
     - `- [x] 014 Implement welcome email generation with a magic sign-in token and post-auth destination for the new club member home.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No `docs/adr/**/*.md` files are present.
   - Followed local project guidance:
     - Reused existing sign-in token/auth email configuration.
     - Kept email delivery as a post-conversion side effect.
     - Preserved existing magic-link auth flow while adding a safe query-param destination mechanism.
     - Did not edit acceptance feature files for this task.