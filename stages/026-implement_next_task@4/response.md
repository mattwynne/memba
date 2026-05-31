1. **Selected todo line**
   - `004 Implement homepage browser steps against the real homepage route.`

2. **Changes made**
   - Added `acceptance-tests/features/support/homepage.js`
     - Builds the real root homepage URL from `baseUrl`.
     - Provides reusable homepage visit/assertion helpers.
     - Uses Playwright web-first assertions for URL, title, heading, and homepage link visibility.
   - Updated `acceptance-tests/features/step_definitions/homepage_steps.js`
     - `When I visit the homepage` now navigates explicitly to `/`.
     - `Then I should see the Memba homepage` now asserts browser-visible homepage content, not just the title.
   - Added `acceptance-tests/test/homepage_steps.test.js`
     - Covers URL generation, browser navigation target, and homepage-visible assertions.

3. **Focused validation**
   - `cd acceptance-tests && npm run test:config -- --test-name-pattern homepage`
     - Passed: 8 tests, 0 failures.
   - `cd acceptance-tests && npm run test:config`
     - Passed: 8 tests, 0 failures.
   - `cd acceptance-tests && npm test -- --dry-run --name "Visiting the homepage"`
     - Passed dry-run: 1 scenario, 2 steps, both matched/skipped.
   - `cd acceptance-tests && npm test -- --dry-run`
     - Exited 0.
     - Still reports undefined member/operator steps expected for later unchecked tasks.
   - `cd acceptance-tests && npx cucumber-js --name "Visiting the homepage"`
     - Failed before steps ran because the sandbox is missing the Playwright Chromium executable.
     - Phoenix lifecycle/startup completed far enough to reach browser launch; failure is environmental:
       - `browserType.launch: Executable doesn't exist ... Please run npx playwright install`
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: 109 tests, 0 failures.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Implement homepage browser steps against the real homepage route.`
   - To:
     - `- [x] 004 Implement homepage browser steps against the real homepage route.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0003: kept the shared `.feature` file unchanged and implemented only browser-layer step plumbing.
   - ADR 0010: did not alter Elixir/domain Cucumber discovery or filtering.
   - ADR 0013: did not change PhoenixTest-based web-test architecture.
   - No production UI/routes or feature files were changed.