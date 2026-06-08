1. **Selected todo line**
   - `013 Remove or narrow @todo-domain/@todo-ui tags from the affected scenarios only when they pass in the relevant runner.`

2. **Changes made**
   - Updated `acceptance-tests/features/club_member_invitations.feature`
     - Removed `@todo-domain` from the four `@iteration-029` Membership Admin invitation scenarios.
     - Kept `@todo-ui` because the browser/UI runner is still configured to skip these scenarios and the JS browser step definitions do not yet cover the Membership Admin-specific wording.
   - Updated `docs/iterations/029-membership-admin-invitations/todo.md`
     - Checked off task `013` only.

3. **Focused validation commands run**
   - Attempted root wrapper:
     - `PATH="$PWD/bin:$PATH" bin/mix test web/test/features/domain_cucumber_acceptance_test.exs web/test/features/domain_cucumber_runner_test.exs web/test/features/cucumber_configuration_test.exs`
     - Did not reach tests due an existing Postgres `postmaster.pid` lock in the root wrapper startup.
   - Successful focused domain validation:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && MIX_ENV=test ../bin/mix test test/features/domain_cucumber_acceptance_test.exs test/features/domain_cucumber_runner_test.exs test/features/cucumber_configuration_test.exs'`
     - Passed: `63 tests, 0 failures`
   - Targeted JS Cucumber tag/filter validation:
     - `cd acceptance-tests && node --test test/cucumber_config.test.js`
     - Passed: `4 tests, 0 failures`
   - Whitespace:
     - `git diff --check`
     - Passed.
   - Note: `cd acceptance-tests && npm run test:config` was also attempted, but that broad script includes unrelated support tests already failing on homepage text/payload expectation drift. The targeted Cucumber config test above passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 013 Remove or narrow \`@todo-domain\`/\`@todo-ui\` tags from the affected scenarios only when they pass in the relevant runner.`
   - To:
     - `- [x] 013 Remove or narrow \`@todo-domain\`/\`@todo-ui\` tags from the affected scenarios only when they pass in the relevant runner.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADRs were explicitly referenced by this iteration plan.
   - The plan’s `Allowed acceptance feature changes` section explicitly permits edits to `acceptance-tests/features/club_member_invitations.feature` for removing/narrowing `@todo-domain`/`@todo-ui` after relevant runner success.
   - The change preserves shared feature coverage and narrows only the domain debt tag now that the domain runner includes and passes these scenarios.