1. **Selected todo line**
   - `003 Implement safe helpers in Memba.EmailTemplates for:`

2. **Changes made**
   - Extended `web/lib/memba/email_templates.ex` with safe reusable helpers for:
     - `sanitize_header_text/1` for CR/LF/control-character-safe email header text.
     - `plaintext_to_html/2` for escaped paragraph/line-break rendering from plaintext message bodies.
     - `primary_action/3` for bulletproof primary button + printed fallback URL.
     - `group_header/2` and `memba_header/1` for group-led and Memba-led email card headers.
     - `memba_footer/1` and `trust_footer/1` for ambient/trust footers without hard-coded support addresses.
   - Added focused tests in `web/test/memba/email_templates_test.exs` covering escaping, header sanitization, plaintext conversion, button/fallback URL rendering, headers, and footers.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/email_templates.ex test/memba/email_templates_test.exs`
     - Passed.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/email_templates_test.exs`
     - Passed: `8 tests, 0 failures`.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `574 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 003 Implement safe helpers in Memba.EmailTemplates for:`
   - To:
     - `- [x] 003 Implement safe helpers in Memba.EmailTemplates for:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: work remains inside the Phoenix/Elixir core app.
   - ADR 0016: no email provider selection/configuration or Swoosh provider boundary changes.
   - ADR 0020: no production smoke-test or external mailbox automation changes.
   - ADR 0004: no messaging domain/deliverability aggregate changes.
   - No acceptance feature files were changed.