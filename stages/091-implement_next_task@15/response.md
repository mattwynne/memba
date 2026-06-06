1. **Selected todo line**
   - `015 Add or update tests for public form validation/submission, signed-in prepopulation, notification email, staff authorization, active inbox, rejection, conversion, existing-person reuse, slug validation, welcome email, and preservation of existing club creation/slug behaviour.`

2. **Changes made**
   - Updated `web/test/memba_web/live/admin/requests_live/index_test.exs` with focused coverage gaps:
     - Rejection now asserts no club, person, membership, sign-in token, or email side effects.
     - Staff LiveView conversion now asserts a welcome sign-in token and welcome email with club member-home `return_to`.
     - Added staff LiveView conversion test for reusing an existing person by requester email without creating a duplicate person.
     - Extended the local request fixture helper to accept requester email overrides.
     - Added scoped test auth-email configuration helper for welcome-email assertions.
   - Checked off only task `015` in `docs/iterations/022-request-to-club-onboarding/todo.md`.

3. **Validation commands/results**
   - Direct focused run:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/admin/requests_live/index_test.exs`
     - Hit sandbox Postgres `PGHOST` readiness mismatch.
   - Rerun inside devenv shell due that environment mismatch:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/admin/requests_live/index_test.exs`
     - Passed: `8 tests, 0 failures`
   - Broader focused onboarding/auth/staff/slug suite:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/controllers/page_controller_test.exs test/memba_web/auth_gates_test.exs test/memba_web/live/admin/requests_live/index_test.exs test/memba/onboarding_test.exs test/memba/onboarding_conversion_test.exs test/memba/onboarding/welcome_email_test.exs test/memba_web/admin/club_slug_form_test.exs test/memba_web/live/admin/clubs_live/index_test.exs test/memba_web/controllers/auth_controller_test.exs`
     - Passed: `99 tests, 0 failures`
   - Formatting:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix format --check-formatted test/memba_web/live/admin/requests_live/index_test.exs`
     - Passed
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `566 tests, 0 failures`
   - Whitespace:
     - `git diff --check`
     - Passed

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 015 Add or update tests for public form validation/submission, signed-in prepopulation, notification email, staff authorization, active inbox, rejection, conversion, existing-person reuse, slug validation, welcome email, and preservation of existing club creation/slug behaviour.`
   - To:
     - `- [x] 015 Add or update tests for public form validation/submission, signed-in prepopulation, notification email, staff authorization, active inbox, rejection, conversion, existing-person reuse, slug validation, welcome email, and preservation of existing club creation/slug behaviour.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No `docs/adr/**/*.md` files are present.
   - Followed local project testing/LiveView guidance:
     - Used LiveView test helpers and stable element IDs/selectors.
     - Kept changes test-only and focused on plan-required coverage.
     - Did not edit acceptance feature files or step definitions for this task; task `016` remains unchecked for that work.