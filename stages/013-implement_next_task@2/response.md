1. **Selected todo line**
   - `- [ ] 002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.`

2. **Changes made**
   - Updated homepage hero copy:
     - `web/lib/memba_web/controllers/page_html/home.html.heex`
       - Hero now says: `Volunteering shouldn’t feel like work.`
     - `web/lib/memba_web/controllers/page_controller.ex`
       - Signed-out page title now matches the volunteering promise.
   - Updated homepage controller coverage:
     - `web/test/memba_web/controllers/page_controller_test.exs`
       - Asserts the volunteering promise via page text, not layout/selector details.
       - Ensures signed-in member home does not show the signed-out volunteering hero.
   - Updated browser acceptance support:
     - `acceptance-tests/features/support/homepage.js`
       - `assertMembaHomepage` now checks the volunteering promise using visible text, not a heading role/name.
       - Added reusable `assertHomepageVolunteeringPromise`.
     - `acceptance-tests/features/step_definitions/homepage_steps.js`
       - Added support for the planned step: `Then I should see that volunteering should not feel like work`
   - Did **not** edit acceptance `.feature` files.

3. **Focused validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix test web/test/memba_web/controllers/page_controller_test.exs`
     - Failed before running tests due sandbox Postgres readiness/path issue:
       - `Postgres did not become ready at PGHOST=/tmp/devenv/postgres PGPORT=15432`
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `757 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" dev check`
     - First run exposed stale homepage acceptance support expecting the old heading.
     - After updating acceptance support, passed:
       - ExUnit: `757 tests, 0 failures`
       - Acceptance: `73 scenarios (73 passed), 489 steps (489 passed)`
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.`
   - To:
     - `- [x] 002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.`

5. **Todo splits/additions/reordering**
   - No splits, additions, or reordering.
   - Checked off only task 002.

6. **ADR conformance evidence**
   - ADR 0001: Kept the change within the Phoenix core application stack.
   - ADR 0013: Covered user-visible homepage behaviour through existing web/controller coverage and browser acceptance support, with assertions phrased around visible user text rather than fragile template/layout internals.