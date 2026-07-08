Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 Remove @todo-domain @todo-ui from the @iteration-049 scenarios once both runners execute them successfully.`

2. **Changes made**
   - Removed `@todo-domain @todo-ui` from both `@iteration-049` scenarios in:
     - `acceptance-tests/features/list_members.feature`
   - Updated browser Cucumber config expectations so `list_members.feature` is now selected by the default browser suite:
     - `acceptance-tests/test/cucumber_config.test.js`
   - Checked off task 008 in:
     - `docs/iterations/049-member-role-badges/todo.md`

3. **Validation run**
   - Domain runner proof before tag removal:
     - `PATH="$PWD/bin:$PATH" dev test test/features/list_members_steps_test.exs`
     - Passed: `2 tests, 0 failures`
   - Browser runner proof with TODO-tagged scenarios included:
     - Initial direct browser command failed with `RPC failed with reason :noconnection`.
     - Retried inside `devenv shell` so the acceptance support could reach the distributed Phoenix node:
       - `DEVENV_TUI=false devenv shell -- bash -lc 'cd acceptance-tests && npx cucumber-js --config ../.fabro/tmp/list-members-cucumber.cjs'`
       - Passed: `2 scenarios (2 passed), 13 steps (13 passed)`
   - Browser config test after enabling the feature:
     - `node --test acceptance-tests/test/cucumber_config.test.js`
     - Passed: `5 tests, 0 failures`
   - Browser runner after tag removal:
     - `DEVENV_TUI=false devenv shell -- bash -lc 'cd acceptance-tests && npx cucumber-js features/list_members.feature --tags @iteration-049 --format progress'`
     - Passed: `2 scenarios (2 passed), 13 steps (13 passed)`
   - Domain runner after tag removal:
     - `PATH="$PWD/bin:$PATH" dev test test/features/list_members_steps_test.exs`
     - Passed: `2 tests, 0 failures`
   - Full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `87 scenarios (87 passed), 536 steps (536 passed)`

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 008 Remove @todo-domain @todo-ui from the @iteration-049 scenarios once both runners execute them successfully.`
   - To:
     - `- [x] 008 Remove @todo-domain @todo-ui from the @iteration-049 scenarios once both runners execute them successfully.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / plan conformance**
   - No ADR was explicitly referenced by this plan.
   - The plan’s `Allowed acceptance feature changes` section explicitly permits removing `@todo-domain` and `@todo-ui` from `acceptance-tests/features/list_members.feature` once matching domain/browser support exists and the scenarios pass.
   - The change only removes the temporary runner-debt tags and updates the browser selection test to reflect that the feature is now executable; scenario wording and coverage were not weakened.