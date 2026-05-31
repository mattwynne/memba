Implemented todo 009.

1. **Selected todo**
   - `009 Verify that operator_email_deliverability.feature is excluded only from the browser run and remains covered by the domain runner.`

2. **Changes made**
   - `acceptance-tests/test/cucumber_config.test.js`
     - Added browser config tests that:
       - confirm the default browser-selected shared features are exactly:
         - `homepage.feature`
         - `member_message_deliverability.feature`
       - confirm `operator_email_deliverability.feature` is the only skipped browser feature and is skipped solely because of `@todo-web`.
   - `web/test/features/cucumber_configuration_test.exs`
     - Strengthened the domain Cucumber config test to prove the configured domain feature set includes the `@todo-web` operator feature while domain Cucumber remains unfiltered.
   - `docs/iterations/006-browser-cucumber-automation/todo.md`
     - Checked off todo 009 only.
   - No acceptance `.feature` files were edited.

3. **Validation run**
   - `cd acceptance-tests && npm_config_cache="$PWD/../.fabro/tmp/npm-cache" npm ci`
     - Passed.
   - `cd acceptance-tests && npm run test:config`
     - Passed: 25 tests, 0 failures.
   - Focused Elixir domain Cucumber config/runtime test:
     - `mix test test/features/cucumber_configuration_test.exs`
     - Passed: 4 tests, 0 failures.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: 109 tests, 0 failures.

   Note: an initial `npm run test:config` attempt failed because `node_modules` was absent; installing from `package-lock.json` with a writable npm cache resolved it.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 009 Verify that ...`
   - To:
     - `- [x] 009 Verify that ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0003 / ADR 0010: preserved shared feature files as the acceptance source and verified both execution layers without duplicating or editing feature files.
   - Browser layer remains partitioned with `not @todo-web`.
   - Domain/Elixir layer remains unfiltered and continues to cover the operator scenarios, including the `@todo-web` feature.