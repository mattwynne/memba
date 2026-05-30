Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `009 Add @todo-web tags to operator deliverability scenarios that are intentionally not browser-backed in this iteration.`

2. **Changes made**
   - Confirmed `acceptance-tests/features/operator_email_deliverability.feature` already has `@todo-web` on all 5 operator deliverability scenarios.
   - Did **not** edit `.feature` files, per binding rule.
   - Added automated coverage in `web/test/features/cucumber_configuration_test.exs` to assert every operator deliverability scenario remains tagged `@todo-web`.
   - Checked off only task `009` in `docs/iterations/005-browser-acceptance-harness/todo.md`.

3. **Focused validation**
   - `node - <<'NODE' ...`
     - Passed: `Verified 5 operator scenarios are tagged @todo-web.`
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `109 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Note: a direct `cd web && mix test test/features/cucumber_configuration_test.exs` failed outside the dev environment because Postgres was not running at the expected socket; the required `dev check` ran inside the project dev environment and passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 009 Add @todo-web tags to operator deliverability scenarios that are intentionally not browser-backed in this iteration.`
   - To:
     - `- [x] 009 Add @todo-web tags to operator deliverability scenarios that are intentionally not browser-backed in this iteration.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0010 respected: shared feature files remain the shared acceptance source and were not duplicated.
   - ADR 0013 unaffected: no change to the PhoenixTest web-test strategy.
   - Added a narrow ExUnit guard around the shared feature metadata needed by this iteration.