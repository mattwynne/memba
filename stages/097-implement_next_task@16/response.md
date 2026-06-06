1. **Selected todo line**
   - `016 Add acceptance step support for request_account.feature and remove @wip once the scenarios pass.`

2. **Changes made**
   - Added browser Cucumber support for `request_account.feature`:
     - `acceptance-tests/features/support/request_account.js`
     - `acceptance-tests/features/step_definitions/request_account_steps.js`
   - Removed the feature-level `@wip` tag from:
     - `acceptance-tests/features/request_account.feature`
   - Updated browser Cucumber config expectations so `request_account.feature` is now selected in the default browser run:
     - `acceptance-tests/test/cucumber_config.test.js`
   - Fixed acceptance reset isolation by truncating `onboarding_requests` between browser scenarios:
     - `web/lib/memba_web/controllers/dev_test_support_controller.ex`
   - Checked off only todo `016`.

3. **Validation run**
   - `cd acceptance-tests && node --test test/cucumber_config.test.js`
     - Passed: 5 tests, 0 failures.
   - `node --check acceptance-tests/features/support/request_account.js && node --check acceptance-tests/features/step_definitions/request_account_steps.js`
     - Passed.
   - Targeted browser acceptance:
     - `PATH="$PWD/bin:$PATH" dev acceptance -- --config .tmp-cucumber-request.cjs features/request_account.feature --require 'features/support/**/*.js' --require 'features/step_definitions/**/*.js' --tags 'not @todo-web and not @wip' --format progress`
     - Passed: 6 scenarios, 39 steps.
   - Full quality gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: 566 ExUnit tests, 44 browser acceptance scenarios / 291 steps.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 016 Add acceptance step support for request_account.feature and remove @wip once the scenarios pass.`
   - To:
     - `- [x] 016 Add acceptance step support for request_account.feature and remove @wip once the scenarios pass.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No `docs/adr/**/*.md` files are present.
   - Followed the approved plan’s allowed acceptance feature change: removed `@wip` only after the new scenarios passed, and added executable acceptance support for the request-account lifecycle.