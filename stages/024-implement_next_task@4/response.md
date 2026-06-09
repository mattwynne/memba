1. **Selected todo line**
   - `- [ ] 004 Replace the sign-in email icon with the Memba sprig asset/component used elsewhere in Memba branding.`

2. **Changes made**
   - Updated `web/lib/memba/email_templates.ex`
     - Replaced the shared email Memba mark SVG’s checkmark path with the Memba sprig silhouette paths used by `MembaWeb.Brand.sprig/1`.
     - Preserved the existing email-safe inline SVG approach and existing mark sizing/background usage.
   - Updated `web/test/memba/accounts/auth_email_test.exs`
     - Added sign-in email HTML assertions that the sprig leaf/bud markup is present.
     - Added a regression assertion that the old checkmark path is absent.
   - Updated `web/test/memba/email_templates_test.exs`
     - Added helper-level assertions that `EmailTemplates.memba_header/1` renders the sprig mark, not the checkmark.
   - Updated `docs/iterations/031-brand-email-navigation-polish/todo.md`
     - Checked off task 004 and recorded the implementation note.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format lib/memba/email_templates.ex test/memba/accounts/auth_email_test.exs test/memba/email_templates_test.exs`
     - Passed.
   - `devenv shell -- bin/mix test test/memba/accounts/auth_email_test.exs test/memba/email_templates_test.exs`
     - Passed: `16 tests, 0 failures`.
     - Note: the bare `bin/mix test ...` wrapper could not run because `pg_isready` is not available outside `devenv` in this sandbox, so I used `devenv shell -- ...` for this focused command.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `757 tests, 0 failures`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 004 Replace the sign-in email icon with the Memba sprig asset/component used elsewhere in Memba branding.`
   - To:
     - `- [x] 004 Replace the sign-in email icon with the Memba sprig asset/component used elsewhere in Memba branding.`

5. **Todo splits/additions/reordering**
   - No splits, additions, or reordering.
   - Added only a short implementation note under task 004.

6. **ADR conformance**
   - ADR 0001: Change stays within the Phoenix/Elixir core application.
   - ADR 0016: Email delivery remains behind the existing Swoosh/Mailer boundary; no provider-specific HTTP code or provider lock-in was introduced.
   - ADR 0013: No web feature-test changes were needed; this task is covered with focused email rendering/unit tests.