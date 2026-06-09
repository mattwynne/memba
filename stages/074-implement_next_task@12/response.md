Implemented task 012.

1. **Selected todo line**
   - `- [ ] 012 Add or update template/unit/LiveView/browser tests for the homepage copy, public club-page Memba link, sign-in email icon/footer, rejection sender name, and rejection footer.`

2. **Changes made**
   - `web/test/memba_web/controllers/page_controller_test.exs`
     - Added homepage assertion that the page still says it is for “volunteer-run groups.”
   - `web/test/memba/accounts/auth_email_test.exs`
     - Added explicit helpers/assertions for:
       - Memba sprig SVG branding in sign-in emails.
       - Absence of the old check-mark icon path.
       - Standard Memba footer content for generic and group-led sign-in emails.
   - `web/test/memba/messaging/inbound_club_rejection_email_test.exs`
     - Added explicit helper/assertions for rejection email standard footer content, including:
       - `Delivered by/for ... Memba`
       - `https://memba.io`
       - recipient line
       - automatic delivery notice
       - reply-to/support guidance
       - no hard-coded `help@memba.io`
   - `docs/iterations/031-brand-email-navigation-polish/todo.md`
     - Checked off task 012 only.

3. **Validation run**
   - Initial preferred focused command:
     - `PATH="$PWD/bin:$PATH" bin/mix test web/test/...`
     - Failed before tests ran due the known Postgres socket readiness mismatch.
   - Started Postgres explicitly:
     - `devenv shell -- bash -lc '... devenv processes up --strict-ports -d postgres ... pg_isready ...'`
     - Result: Postgres accepting connections.
   - Focused tests:
     - `devenv shell -- bash -lc 'real_mix=$(which -a mix | grep -v "$(pwd)/bin/mix" | head -1); cd web; "$real_mix" test test/memba_web/controllers/page_controller_test.exs test/memba/accounts/auth_email_test.exs test/memba/messaging/inbound_club_rejection_email_test.exs'`
     - Result: `52 tests, 0 failures`
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/controllers/page_controller_test.exs test/memba/accounts/auth_email_test.exs test/memba/messaging/inbound_club_rejection_email_test.exs`
     - Result: passed after manually applying the formatter-reported changes because `mix format` could not write root-owned files in this sandbox.
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: `758 tests, 0 failures`
   - Whitespace:
     - `git diff --check`
     - Result: passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 012 Add or update template/unit/LiveView/browser tests for the homepage copy, public club-page Memba link, sign-in email icon/footer, rejection sender name, and rejection footer.`
   - To:
     - `- [x] 012 Add or update template/unit/LiveView/browser tests for the homepage copy, public club-page Memba link, sign-in email icon/footer, rejection sender name, and rejection footer.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan did not explicitly reference ADR files, and no `docs/adr/` files were present to read.
   - This task only strengthened automated tests; it did not change routing, LiveView architecture, email delivery architecture, sender semantics, or club-site URL generation.
   - Existing LiveView/controller rendering and `ClubSite.root_url()` coverage remain intact.