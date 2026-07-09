Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `001 Add a preview element to the club-home conversation row template using message_row.body, clamped to one line with CSS (no server-side character truncation).`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`
     - Added a `data-testid="message-preview"` element in each club-home conversation row.
     - Renders `{message_row.body}` directly.
     - Uses Tailwind `line-clamp-1` for CSS-based one-line clamping; no server-side truncation added.
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Added focused coverage proving the full message body renders in the preview element with the `line-clamp-1` class.

3. **Validation run**
   - TDD check before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:975`
     - Failed as expected because the preview element was not present yet.
   - Focused test after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:975`
     - Passed.
   - Full validation because this changes browser-facing UI:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 Add a preview element...`
   - To:
     - `- [x] 001 Add a preview element...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan references no ADRs explicitly.
   - No `docs/adr/*.md` files were present to inspect.
   - Followed relevant local UI/HEEx/Tailwind guidance from `docs/reference/`.