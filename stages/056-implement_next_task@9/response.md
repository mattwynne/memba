Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 009 If the footer is already centralized, migrate any remaining current transactional templates to it with focused tests. Do not redesign templates.`

2. **Changes made for this task**
   - Migrated `Memba.Onboarding.WelcomeEmail` from its custom inline footer to the centralized `Memba.EmailTemplates.memba_footer/1`.
   - Updated `Memba.Onboarding.NewRequestEmail` so its HTML body now uses the shared transactional email shell and standard `memba_footer/1` instead of bare `<html><body>` markup.
   - Preserved existing sender/recipient/reply-to/provider option behaviour.
   - Added focused assertions proving:
     - welcome emails render the standard “Delivered for … by Memba” footer;
     - staff new-request emails render the standard “Delivered by Memba” footer;
     - recipient/reason/support footer lines are present;
     - no hard-coded `help@memba.io` appears.

3. **Focused validation**
   - Added footer expectations first; initial focused run failed before implementation as expected, and one early `bin/mix` attempt also hit the known Postgres readiness wrapper issue.
   - Ran focused tests:
     - `devenv shell -- bash -lc 'real_mix=$(which -a mix | grep -v "$(pwd)/bin/mix" | head -1); cd web; "$real_mix" test test/memba/onboarding/welcome_email_test.exs test/memba/onboarding/new_request_email_test.exs'`
     - Result: `3 tests, 0 failures`
   - Checked formatting:
     - `devenv shell -- bash -lc 'real_mix=$(which -a mix | grep -v "$(pwd)/bin/mix" | head -1); cd web; "$real_mix" format --check-formatted lib/memba/onboarding/welcome_email.ex lib/memba/onboarding/new_request_email.ex test/memba/onboarding/welcome_email_test.exs test/memba/onboarding/new_request_email_test.exs'`
     - Result: passed
   - Ran broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: `757 tests, 0 failures`
   - Ran whitespace check:
     - `git diff --check`
     - Result: passed

4. **Todo check-off made**
   - Changed exactly:
     - from `- [ ] 009 If the footer is already centralized, migrate any remaining current transactional templates to it with focused tests. Do not redesign templates.`
     - to `- [x] 009 If the footer is already centralized, migrate any remaining current transactional templates to it with focused tests. Do not redesign templates.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0016 respected:
     - no email provider architecture changed;
     - no direct provider HTTP introduced;
     - Swoosh/Mailer delivery boundary preserved;
     - provider options/message streams/tags remain on the existing paths.