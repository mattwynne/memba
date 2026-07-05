1. **Selected todo line**
   - `012 Add/adjust a test that every club_site surface still renders under the new shell (club home, conversation, compose, invitation, public club page).`

2. **Changes made**
   - Added `web/test/memba_web/club_site_shell_surfaces_test.exs`.
   - The new route-level test exercises and verifies the shared `club_site` app shell for:
     - public club page
     - signed-in club home
     - conversation/message detail
     - compose message
     - member invitation
   - The test asserts each surface renders:
     - `#club-site-layout.app-frame[data-surface='club-site']`
     - `.app-card > header > .app-bar`
     - content under `.app-card > main`
     - club name in `.app-bar__club`
     - `app-foot` footer with “Powered by Memba”
     - signed-in identity/sign-out controls only for signed-in surfaces

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/club_site_shell_surfaces_test.exs`
     - First run found a whitespace-sensitive footer text assertion; fixed by normalizing whitespace.
     - Rerun passed: `1 test, 0 failures`
   - `cd web && mix format --check-formatted test/memba_web/club_site_shell_surfaces_test.exs`
     - Passed
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `913 tests, 0 failures`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 012 Add/adjust a test that every club_site surface still renders under the new shell (club home, conversation, compose, invitation, public club page).`
   - To:
     - `- [x] 012 Add/adjust a test that every club_site surface still renders under the new shell (club home, conversation, compose, invitation, public club page).`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Reviewed relevant ADRs:
     - ADR 0013: lower-level Phoenix/LiveView test helpers are acceptable when specific LiveView/layout mechanics need clear assertions.
     - ADR 0015: member app pages are LiveView-first; the test covers the LiveView member surfaces through routed mounts.
     - ADR 0019: test uses configured club subdomain routing via `ClubSite.url/1` / `lvh.me` host setup rather than relying on query-string-only club selection.
   - No acceptance feature files or acceptance-test files were changed.