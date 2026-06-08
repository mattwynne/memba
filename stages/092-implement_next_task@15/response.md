1. **Selected todo line**
   - `015 Remove @todo-domain/@todo-ui from club_membership_administration.feature once implementation passes the scenarios.`

2. **Changes made**
   - Updated `acceptance-tests/features/club_membership_administration.feature`
     - Changed feature tags from:
       - `@iteration-027 @todo-domain @todo-ui`
     - To:
       - `@iteration-027`
   - Updated `docs/iterations/027-membership-administrator-role/todo.md`
     - Checked off task `015` only.

3. **Validation commands run**
   - `ACCEPTANCE_LOG_PROGRESS=1 PATH="$PWD/bin:$PATH" dev acceptance features/club_membership_administration.feature`
     - Passed: `62 scenarios (62 passed), 421 steps (421 passed)`
     - Note: cucumber-js merged the configured feature paths with the CLI path, so this ran the full browser acceptance selection including the newly untagged feature.
   - `devenv shell -- bash -lc 'cd web && mix test test/features/domain_cucumber_acceptance_test.exs test/features/membership_administration_steps_test.exs'`
     - Passed: `51 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including full browser acceptance: `62 scenarios (62 passed), 421 steps (421 passed)`
   - `git diff --check`
     - Passed.
   - Note: two earlier `bin/mix test ...` attempts failed before tests due a wrapper-managed PostgreSQL readiness/socket conflict. The same focused domain tests passed when run inside a single explicit `devenv shell`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 015 Remove @todo-domain/@todo-ui from club_membership_administration.feature once implementation passes the scenarios.`
   - To:
     - `- [x] 015 Remove @todo-domain/@todo-ui from club_membership_administration.feature once implementation passes the scenarios.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read relevant accepted ADRs:
     - `docs/adr/0003-use-cucumber-at-domain-and-application-layers.md`
     - `docs/adr/0010-use-shared-feature-files-with-elixir-cucumber.md`
   - Kept the shared feature file infrastructure-neutral and executable by both layers.
   - Validated both execution layers after removing the temporary tags:
     - Elixir/domain Cucumber via `domain_cucumber_acceptance_test`.
     - Browser Cucumber/Playwright via `dev acceptance` and full `dev check`.
   - Used only the plan-allowed acceptance feature edit for `acceptance-tests/features/club_membership_administration.feature`.