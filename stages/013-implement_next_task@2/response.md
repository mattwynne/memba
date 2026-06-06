1. **Selected todo line**
   - `002 Add shared helper module web/lib/memba/email_templates.ex (Memba.EmailTemplates) for the email HTML shell/components and text-safe helpers. Keep inline styles and avoid external CSS dependencies.`

2. **Changes made**
   - Added `web/lib/memba/email_templates.ex` with `Memba.EmailTemplates`:
     - `render_shell/1` for the v2-compatible 560px single-card email shell.
     - `card_section/2` for table-row card sections with inline styles.
     - `heading/2` and `paragraph/2` text-safe components.
     - `escaped_text/1` for HTML escaping dynamic text.
     - Avoids external CSS dependencies (`<link>` / `@import`); uses conservative table markup and inline styles with a minimal embedded reset/media block.
   - Added `web/test/memba/email_templates_test.exs` covering:
     - shell structure, preheader, card width, presentation tables;
     - no external CSS dependencies;
     - escaping dynamic title/body text;
     - composability of trusted component HTML.
   - Checked off only todo item 002.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format lib/memba/email_templates.ex test/memba/email_templates_test.exs`
     - Passed after normalizing ownership of newly added files.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/email_templates_test.exs`
     - Passed: `3 tests, 0 failures`.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `569 tests, 0 failures`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 002 Add shared helper module ...`
   - To:
     - `- [x] 002 Add shared helper module ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed relevant accepted ADRs:
     - ADR 0001: keeps implementation inside the Phoenix/Elixir core app.
     - ADR 0003: no acceptance feature changes; validation uses automated test seams.
     - ADR 0016: does not alter provider selection or Swoosh delivery boundaries.
     - ADR 0020: does not change production smoke-test scope or external mailbox handling.
   - No provider configuration, domain model, routing, acceptance feature files, or external HTTP/client dependencies were changed.