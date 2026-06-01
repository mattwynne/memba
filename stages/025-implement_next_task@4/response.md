Implemented the next unchecked task.

1. **Selected todo line**
   - `004 Replace the club-home inline compose section with a CTA card/link to the new compose route. Preserve stable IDs or update tests/helpers deliberately.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`:
     - Changed the hero “Send club message” shortcut from an in-page anchor to `~p"/messages/new?club_id=#{@selected_club.club_id}"`.
     - Replaced the inline compose form with a CTA card/link.
     - Removed the club-home sender dropdown, subject input, body textarea, and submit button from the rendered page.
     - Preserved the `#member-send-message` section as the CTA card anchor/section.
     - Added `#member-send-message-link` and `#member-compose-cta-summary` selectors for the new CTA surface.
   - Updated `web/test/memba_web/controllers/page_controller_test.exs`:
     - Asserted the CTA links point to `/messages/new?club_id=<club_id>`.
     - Asserted the inline compose form and form fields are no longer rendered on club home.
     - Asserted the new CTA summary renders with the active member count.

3. **Validation run**
   - Focused controller tests:
     - `DEVENV_TUI=false devenv shell -- bash -lc 'set -e; DEVENV_TUI=false devenv processes up --no-strict-ports -d postgres; devenv processes wait --timeout 120; cd web; MIX_ENV=test mix test test/memba_web/controllers/page_controller_test.exs'`
     - Result: `14 tests, 0 failures`
   - Required project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `235 tests, 0 failures`

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 004 Replace the club-home inline compose section with a CTA card/link to the new compose route. Preserve stable IDs or update tests/helpers deliberately.`
   - To:
     - `- [x] 004 Replace the club-home inline compose section with a CTA card/link to the new compose route. Preserve stable IDs or update tests/helpers deliberately.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No `docs/adr/*.md` files are present.
   - Followed the iteration plan and local Phoenix/HEEx guidance: used verified routes, kept unique DOM IDs, and updated tests for the changed UI contract.