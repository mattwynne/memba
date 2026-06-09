Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.`

2. **Changes made**
   - Updated the logged-out homepage hero copy:
     - `web/lib/memba_web/controllers/page_html/home.html.heex`
       - Hero `<h1>` now says: `Volunteering shouldn’t feel like work.`
     - `web/lib/memba_web/controllers/page_controller.ex`
       - Logged-out page title now uses the volunteering promise.
   - Updated homepage controller tests:
     - `web/test/memba_web/controllers/page_controller_test.exs`
       - Asserts the promise through the semantic hero heading, not layout classes.
       - Asserts the hero still communicates `volunteer-run`.
       - Keeps signed-in homepage guarded from showing the logged-out hero.
   - Updated browser acceptance support:
     - `acceptance-tests/features/support/homepage.js`
       - Existing “Memba homepage” support assertion now expects the volunteering heading.
       - No `.feature` files were edited.
   - Updated execution state:
     - `docs/iterations/031-brand-email-navigation-polish/todo.md`

3. **Validation run**
   - Focused controller test:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/controllers/page_controller_test.exs`
     - Result: `39 tests, 0 failures`
   - Full required check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed
       - ExUnit: `756 tests, 0 failures`
       - Acceptance: `73 scenarios (73 passed)`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.`
   - To:
     - `- [x] 002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan references no ADRs explicitly.
   - Inspected ADR inventory under `docs/adr/`.
   - Changes remain consistent with the relevant existing architecture: Phoenix controller/template coverage and existing Cucumber/Playwright browser support were reused; no new architecture, routing, or acceptance feature files were introduced.