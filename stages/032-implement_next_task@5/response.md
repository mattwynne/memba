1. **Selected todo line**
   - `- [ ] 005 Ensure the sign-in email uses the standard transactional email footer.`

2. **Changes made for this task only**
   - Updated `web/lib/memba/accounts/auth_email.ex`
     - Replaced the private `auth_footer/1` row with the canonical shared `EmailTemplates.memba_footer/1`.
     - Preserved the existing sign-in-specific `EmailTemplates.trust_footer/1` trust band.
     - Passed both `group_name` and `recipient_email` into the standard footer so:
       - normal sign-in emails render “Delivered by Memba”;
       - group-led sign-in emails render “Delivered for <group> by Memba”.
     - Removed the now-unused private `auth_footer/1`.
   - Updated `web/test/memba/accounts/auth_email_test.exs`
     - Added assertions that sign-in email HTML includes the standard “Delivered by” Memba footer marker.
     - Added group-led sign-in assertion for “Delivered for <group> by”.

3. **Focused validation commands run and results**
   - Initial focused test attempt:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/accounts/auth_email_test.exs`
     - Did not reach ExUnit assertions due stale sandbox `PGHOST` readiness issue.
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/accounts/auth_email.ex test/memba/accounts/auth_email_test.exs`
     - Passed.
   - Focused test in clean project shell:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/accounts/auth_email_test.exs`
     - Passed: `8 tests, 0 failures`.
   - Broad quick validation for non-browser email change:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `757 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Ensure the sign-in email uses the standard transactional email footer.`
   - To:
     - `- [x] 005 Ensure the sign-in email uses the standard transactional email footer.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001 respected: change remains within the existing Phoenix/Elixir application.
   - ADR 0016 respected: no email provider, Swoosh adapter, provider option, or delivery boundary behaviour changed.
   - ADR 0013 not materially affected: this is email rendering, not browser/LiveView feature-style web behaviour; focused ExUnit coverage was updated for the rendered email contract.