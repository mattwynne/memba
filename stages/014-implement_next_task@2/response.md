1. **Selected todo line**
   - `- [ ] 002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.`

2. **Changes made**
   - Updated homepage browser acceptance support to assert the volunteering promise via an accessible heading role, not layout/CSS details:
     - `acceptance-tests/features/support/homepage.js`
   - Added the planned Cucumber step definition:
     - `Then I should see that volunteering should not feel like work`
     - `acceptance-tests/features/step_definitions/homepage_steps.js`
   - Updated homepage acceptance-support unit coverage:
     - `acceptance-tests/test/homepage_steps.test.js`
   - Updated the Phoenix homepage hero heading to the promise identified in task 001 so the new assertion is meaningful and green:
     - `web/lib/memba_web/controllers/page_html/home.html.heex`
   - Updated existing controller assertions for the new homepage copy:
     - `web/test/memba_web/controllers/page_controller_test.exs`

3. **Focused validation**
   - `cd acceptance-tests && node --test test/homepage_steps.test.js` — passed, 5/5 tests.
   - Cucumber dry-run for the planned `@iteration-031 @todo-ui` homepage scenario with an empty temp config — passed with no undefined steps.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed, 757 ExUnit tests, 0 failures.
   - `PATH="$PWD/bin:$PATH" dev check` — passed, 757 ExUnit tests and 73 browser acceptance scenarios.
   - `git diff --check` — passed.
   - Note: a direct focused `bin/mix test web/test/memba_web/controllers/page_controller_test.exs` attempt failed before running tests due the outer sandbox’s stale `PGHOST`/devenv runtime mismatch; the project `dev` wrapper gates above successfully ran the Phoenix test suite.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.`
   - To:
     - `- [x] 002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed relevant ADRs:
     - ADR 0001: Phoenix remains the core application stack; changes stayed in the Phoenix controller template/test and existing browser acceptance support.
     - ADR 0013: user-facing web behaviour is asserted through feature-style/browser-facing helpers; the new assertion uses Playwright accessible role lookup rather than fragile layout selectors.
   - No acceptance `.feature` files were edited; only support/step plumbing was added for the already-planned scenario.