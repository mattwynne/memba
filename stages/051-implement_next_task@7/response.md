1. **Selected todo line**
   - `011 Update LiveView/layout tests: app-bar renders @club_name; identity dropdown gated on @current_identity; Sign out posts to DELETE /auth; content sits in the app-card.`

2. **Changes made**
   - Updated `web/test/memba_web/components/layouts_test.exs` only:
     - Tightened the app-card content assertion to prove the slot is a direct child of `#club-site-layout > .app-card > main`.
     - Tightened the app-bar assertion to prove `.app-bar` sits directly under the app-card header.
     - Added an explicit assertion that the sign-out button renders the visible `Sign out` label, alongside the existing `DELETE /auth` form assertions.

3. **Focused validation run**
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs`
     - Passed: `6 tests, 0 failures`
   - `cd web && mix format --check-formatted test/memba_web/components/layouts_test.exs`
     - Passed
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `912 tests, 0 failures`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 011 Update LiveView/layout tests: app-bar renders ...`
   - To:
     - `- [x] 011 Update LiveView/layout tests: app-bar renders ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No `docs/adr/*.md` files are present.
   - Changes stay within the approved plan scope: test-only coverage for the shared `club_site` app-shell chrome.
   - No acceptance `.feature` files or acceptance-test files were changed.