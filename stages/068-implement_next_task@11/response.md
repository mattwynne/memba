Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 011 Run the existing browser/domain acceptance suites and \`dev check\`, fixing regressions without weakening fake-provider determinism.`

2. **Changes made**
   - No code/config/test/doc behaviour changes were needed.
   - Installed ignored local browser-test dependencies with locked `npm ci` after `node_modules` was absent.
   - Removed temporary npm cache from `.fabro/tmp`.
   - Checked off only task `011` in `docs/iterations/008-postmark-email-integration/todo.md`.

3. **Validation commands run**
   - `PATH="$PWD/bin:$PATH" dev acceptance`
     - First run failed because `cucumber-js` was missing (`acceptance-tests/node_modules` absent).
   - `cd acceptance-tests && npm_config_cache="$PWD/../.fabro/tmp/npm-cache" npm ci`
     - Passed; installed locked dependencies.
   - `PATH="$PWD/bin:$PATH" dev acceptance`
     - Passed: `11 scenarios (11 passed)`, `92 steps (92 passed)`.
   - Focused Elixir/domain Cucumber acceptance:
     - `MEMBA_POSTGRES_PORT="$port" devenv shell -O services.postgres.port:int "$port" -- bin/mix test test/features/cucumber_configuration_test.exs`
     - Passed: `4 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `129 tests, 0 failures`.
   - Final post-checkoff:
     - `git diff --check && PATH="$PWD/bin:$PATH" dev check`
     - Passed: `129 tests, 0 failures`.
   - Final status:
     - Only tracked change is `docs/iterations/008-postmark-email-integration/todo.md`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 011 Run the existing browser/domain acceptance suites and \`dev check\`, fixing regressions without weakening fake-provider determinism.`
   - To:
     - `- [x] 011 Run the existing browser/domain acceptance suites and \`dev check\`, fixing regressions without weakening fake-provider determinism.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0003 / 0010: Ran both browser Cucumber acceptance and the Elixir/domain Cucumber path against shared feature coverage.
   - ADR 0003: Automated validation stayed on fake/test integration boundaries; no real Postmark sends were enabled.
   - ADR 0004 / 0006 / 0012: No delivery-state/status/open-tracking semantics were changed.
   - ADR 0005 / 0007: No recipient-resolution or context-boundary changes were made.
   - ADR 0013: Existing Phoenix/web feature-style test stack remained unchanged and passing.