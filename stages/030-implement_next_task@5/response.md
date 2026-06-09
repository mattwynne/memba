1. **Selected todo line**
   - `- [ ] 005 Ensure the sign-in email uses the standard transactional email footer.`

2. **Changes made**
   - Updated `web/lib/memba/accounts/auth_email.ex`
     - Replaced the custom `auth_footer/1` markup with `EmailTemplates.memba_footer/1`.
     - Kept the sign-in trust panel (`EmailTemplates.trust_footer/1`) above the standard footer.
     - Passed `group_name` and `recipient_email` into the standard footer so Memba-led emails say “Delivered by Memba” and group-led emails say “Delivered for <group> by Memba”.
   - Updated `web/lib/memba/email_templates.ex`
     - Adjusted the `memba_footer/1` docstring so it no longer incorrectly says it is only for non-auth transactional emails.
   - Updated `web/test/memba/accounts/auth_email_test.exs`
     - Added assertions that Postmark and Resend sign-in emails include the standard delivered-by footer, recipient line, and support guidance.
     - Added assertions that group-led sign-in emails include the standard delivered-for footer and recipient line.
   - Updated `docs/iterations/031-brand-email-navigation-polish/todo.md`
     - Checked off task 005 and added a short implementation note.

3. **Focused validation commands run**
   - `devenv shell -- bin/mix format --check-formatted lib/memba/accounts/auth_email.ex lib/memba/email_templates.ex test/memba/accounts/auth_email_test.exs`
     - Passed.
   - `devenv shell -- bin/mix test test/memba/accounts/auth_email_test.exs test/memba/email_templates_test.exs`
     - Passed: `16 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `757 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Note: I initially tried the preferred bare `PATH="$PWD/bin:$PATH" bin/mix ...` path, but this sandbox hit environment/permission issues (`Postgres did not become ready...` and root-owned files prevented format writes), so I used `devenv shell -- ...` for focused Mix commands.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 005 Ensure the sign-in email uses the standard transactional email footer.`
   - To:
     - `- [x] 005 Ensure the sign-in email uses the standard transactional email footer.`

5. **Todo splits/additions/reordering**
   - No splits, additions, or reordering.
   - Added only an implementation note under task 005.

6. **ADR conformance evidence**
   - ADR 0001: Change stays inside the Phoenix/Elixir core application.
   - ADR 0016: Email delivery remains behind the existing Swoosh/Mailer boundary; no provider-specific HTTP or delivery integration was introduced.
   - ADR 0013: No browser/UI feature-test changes were needed for this email-rendering task; focused unit tests cover the observable email output.