Implemented the next unchecked task.

1. **Selected todo line**
   - `- [ ] 010 Inspect public club-page template/layout and add a clear link to the main Memba homepage.`

2. **Changes made**
   - Updated `MembaWeb.PublicClubPageLive`:
     - Changed the secondary public club-page CTA from “Back to Memba” to clearer visible text: `Visit Memba home`.
     - Added `id="public-club-page-memba-home-link"` and `aria-label="Visit Memba home"`.
   - Updated `Layouts.club_site/1`:
     - Turned the existing “Powered by Memba” footer branding into a Memba home link.
     - Added `id="club-site-footer-memba-home-link"` and `aria-label="Visit Memba home"`.
   - Updated focused tests:
     - `web/test/memba_web/controllers/page_controller_test.exs`
     - `web/test/memba_web/components/layouts_test.exs`
   - Added whitespace-normalized text assertions where the footer text now spans an anchor.

3. **Validation run**
   - Focused tests:
     - `devenv shell -- bash -lc 'real_mix=$(which -a mix | grep -v "$(pwd)/bin/mix" | head -1); cd web; "$real_mix" test test/memba_web/controllers/page_controller_test.exs test/memba_web/components/layouts_test.exs'`
     - Result: `44 tests, 0 failures`
   - Format check:
     - `devenv shell -- bash -lc 'real_mix=$(which -a mix | grep -v "$(pwd)/bin/mix" | head -1); cd web; "$real_mix" format --check-formatted lib/memba_web/live/public_club_page_live.ex lib/memba_web/components/layouts.ex test/memba_web/controllers/page_controller_test.exs test/memba_web/components/layouts_test.exs'`
     - Result: passed
   - Full required validation for browser-facing UI change:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `757 tests, 0 failures`; `73 scenarios (73 passed)`
   - Whitespace:
     - `git diff --check`
     - Result: passed

4. **Todo check-off made**
   - Changed exactly:
     - from `- [ ] 010 Inspect public club-page template/layout and add a clear link to the main Memba homepage.`
     - to `- [x] 010 Inspect public club-page template/layout and add a clear link to the main Memba homepage.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADR was explicitly referenced by the plan.
   - Checked relevant accepted ADRs:
     - ADR 0015: preserved the existing LiveView-based public/member club surface.
     - ADR 0019: did not change club subdomain routing or URL-generation architecture.
   - This task intentionally leaves the root-host absolute URL behaviour for the next todo item (`011`).