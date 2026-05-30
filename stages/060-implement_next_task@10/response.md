1. **Selected todo line**
   - `010 Configure acceptance-tests/cucumber.js so the default browser Cucumber command uses tags: "not @todo-web".`

2. **Changes made**
   - Updated `acceptance-tests/cucumber.js` default profile with:
     - `tags: "not @todo-web"`
   - Added an automated ExUnit guard in `web/test/features/cucumber_configuration_test.exs` that loads the JS Cucumber config via Node and asserts the default profile uses `not @todo-web`.
   - Did not edit any `.feature` files.

3. **Focused validation**
   - Pre-change failing check confirmed `config.default.tags` was `undefined`.
   - Post-change config assertion:
     - `cd acceptance-tests && node - <<'NODE' ...`
     - Passed: `browser cucumber default tags: not @todo-web`
   - Browser Cucumber dry-run:
     - `cd acceptance-tests && npm test -- --dry-run --format summary`
     - Passed: `8 scenarios (8 skipped)`, confirming the browser default run excludes the 5 `@todo-web` operator scenarios.
   - Required project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `110 tests, 0 failures`
   - `git diff --check`
     - Passed with no output.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 010 Configure ...`
   - To:
     - `- [x] 010 Configure ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0010 respected: shared feature files remain shared and unchanged; the browser-only filtering is isolated to `acceptance-tests/cucumber.js`.
   - ADR 0013 unaffected: no change to PhoenixTest strategy.
   - The domain Cucumber config was not modified; task 011 remains unchecked for explicit verification that domain acceptance still runs all shared scenarios.