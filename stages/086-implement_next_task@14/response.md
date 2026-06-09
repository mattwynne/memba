Implemented the next unchecked task.

1. **Selected todo line**
   - `014 Remove or narrow @todo-domain/@todo-ui from the new/updated scenarios only when they pass in the relevant runner.`

2. **Changes made**
   - Narrowed the four `@iteration-030` scenarios in `acceptance-tests/features/request_account.feature`:
     - removed `@todo-domain`
     - kept `@todo-ui`
   - Reason: the scenarios now pass in the Elixir/domain Cucumber runner, but the browser runner still has undefined cucumber-js steps for those scenario phrases, so `@todo-ui` remains appropriate.
   - Checked off task `014` in `docs/iterations/030-verified-onboarding-requests/todo.md`.

3. **Validation run**
   - Domain Cucumber validation:
     - `devenv shell -- bash -lc 'cd web && mix test test/features/domain_cucumber_runner_test.exs test/features/domain_cucumber_acceptance_test.exs --seed 0'`
     - Passed: `64 tests, 0 failures`
   - Browser probe with `@todo-ui` temporarily removed showed undefined JS steps, so I narrowed rather than fully removed the todo tags.
   - Full quality gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `754 tests, 0 failures`
       - Browser Cucumber: `73 scenarios, 489 steps passed`

4. **Todo check-off made**
   - Changed:
     - `- [ ] 014 Remove or narrow ...`
   - To:
     - `- [x] 014 Remove or narrow ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Reviewed ADR 0003 and ADR 0010.
   - The shared feature file remains the single behavioural specification.
   - Removing only `@todo-domain` makes the now-supported domain runner execute the scenarios.
   - Keeping `@todo-ui` preserves the explicit runner-specific browser coverage gap instead of hiding a failing browser runner.