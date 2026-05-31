1. **Selected todo line**
   - `002 Configure the browser Cucumber default command to exclude @todo-web, while leaving the Elixir/domain Cucumber runner unfiltered.`

2. **Changes made**
   - Updated `acceptance-tests/cucumber.js`:
     - Added default Cucumber tag expression: `tags: "not @todo-web"`.
   - Updated `acceptance-tests/package.json`:
     - Added `npm run test:config` for lightweight browser Cucumber config checks.
   - Added `acceptance-tests/test/cucumber_config.test.js`:
     - Verifies the default browser Cucumber profile excludes `@todo-web`.
     - Verifies the browser profile still loads the shared feature suite.
   - Updated `web/test/features/cucumber_configuration_test.exs`:
     - Added a test proving the Elixir/domain Cucumber configuration has no `@todo-web` tag filter and still discovers `operator_email_deliverability.feature`.
   - Did **not** edit any `.feature` files.

3. **Focused validation run**
   - `cd acceptance-tests && npm run test:config`
     - Passed: 2 tests, 0 failures.
   - `cd acceptance-tests && npm test -- --dry-run`
     - Passed as dry-run.
     - Still reports existing undefined browser steps for later tasks, as expected.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: 109 tests, 0 failures.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Configure the browser Cucumber default command to exclude @todo-web, while leaving the Elixir/domain Cucumber runner unfiltered.`
   - To:
     - `- [x] 002 Configure the browser Cucumber default command to exclude @todo-web, while leaving the Elixir/domain Cucumber runner unfiltered.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0003: kept shared feature files as shared behavioural specs; browser filtering lives in the browser Cucumber config only.
   - ADR 0010: preserved Elixir/domain Cucumber discovery of shared feature files and added a regression test that no domain tag filter is configured.
   - ADR 0013: did not alter the PhoenixTest/web-test architecture.