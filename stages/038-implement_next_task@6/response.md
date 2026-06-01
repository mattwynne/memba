1. **Selected todo line**
   - `006 Render the polished message detail page with <Layouts.club_site> and Phoenix/Tailwind styling inspired by receipts.jsx.`

2. **Changes made**
   - Updated the member message detail HEEx template to render a polished receipt-detail page inside `<Layouts.club_site>`.
   - Added a “Who got this” summary section with:
     - segmented status bar;
     - all four statuses in plan order;
     - counts and whole percentages;
     - member-friendly descriptions.
   - Restyled the message header/body and receipt groups with Tailwind classes inspired by `receipts.jsx`.
   - Rendered non-empty receipt groups with icon, label, description, count, and percentage.
   - Preserved existing stable recipient-row attributes while restyling rows:
     - `data-testid="member-receipt"`
     - `data-recipient-name`
     - `data-receipt-status`
   - Added small presentation helpers in `PageHTML` for status slugs, bar widths, status color classes, and safe recipient initials.
   - Added focused LiveView test coverage for the new summary and polished receipt-group rendering.
   - No acceptance feature files were changed.

3. **Validation run**
   - `cd web && mix format --check-formatted lib/memba_web/controllers/page_html.ex lib/memba_web/controllers/page_html/message.html.heex test/memba_web/live/member_message_live/show_test.exs`
     - Passed.
   - `cd web && mix test test/memba_web/live/member_message_live/show_test.exs`
     - Attempted, but failed because unmanaged Postgres was not available at `/tmp/devenv/postgres/.s.PGSQL.5432`; this was an environment/service issue, not a test assertion failure.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - Final result: `226 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Render the polished message detail page with <Layouts.club_site> and Phoenix/Tailwind styling inspired by receipts.jsx.`
   - To:
     - `- [x] 006 Render the polished message detail page with <Layouts.club_site> and Phoenix/Tailwind styling inspired by receipts.jsx.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Continues using Phoenix/LiveView for the web application surface.
   - ADR 0006: Keeps member-facing receipt vocabulary simple and does not expose operator-only delivery details.
   - ADR 0013: Adds automated user-visible LiveView rendering coverage.
   - ADR 0015: Advances the member message detail page as a LiveView-backed member application page.