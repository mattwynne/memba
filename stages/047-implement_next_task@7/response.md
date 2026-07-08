1. **Selected todo line**
   - `007 Add browser and domain Cucumber step definitions/support for list_members.feature.`

2. **Changes made**
   - Added domain Cucumber plumbing in `web/test/features/step_definitions/membership_steps.exs` for:
     - active member setup,
     - role definition/assignment,
     - member removal,
     - member-list read/assertions for roles, no roles, and removed members.
   - Added focused domain execution coverage:
     - `web/test/features/list_members_steps_test.exs`
   - Added browser acceptance support:
     - `acceptance-tests/features/support/list_members.js`
   - Added browser step definitions:
     - `acceptance-tests/features/step_definitions/list_members_steps.js`
   - Extended browser server-command support:
     - `acceptance-tests/features/support/server_commands.js`
     - new `ensureMemberRoles(...)` helper using existing Membership commands/projections.
   - Checked off only task 007 in:
     - `docs/iterations/049-member-role-badges/todo.md`
   - Did **not** edit `acceptance-tests/features/list_members.feature`; removing `@todo-domain @todo-ui` remains task 008.

3. **Focused validation run**
   - `cd web && mix format --check-formatted test/features/step_definitions/membership_steps.exs test/features/list_members_steps_test.exs`
     - Passed.
   - `node --check acceptance-tests/features/support/list_members.js && node --check acceptance-tests/features/step_definitions/list_members_steps.js && node --check acceptance-tests/features/support/server_commands.js`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev test test/features/list_members_steps_test.exs`
     - Passed: `2 tests, 0 failures`.
   - Focused browser Cucumber run with a temporary config including `@todo-ui` scenarios:
     - `DEVENV_TUI=false devenv shell -- bash -lc 'cd acceptance-tests ... npx cucumber-js --config .tmp-list-members-cucumber.cjs'`
     - Passed: `2 scenarios (2 passed), 13 steps (13 passed)`.
   - Final full check on the exact final diff:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `85 scenarios (85 passed), 523 steps (523 passed)`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 007 Add browser and domain Cucumber step definitions/support for \`list_members.feature\`.`
   - To:
     - `- [x] 007 Add browser and domain Cucumber step definitions/support for \`list_members.feature\`.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference ADRs.
   - Acceptance feature locking was followed: no `.feature` file changes were made for this task.
   - Added only the matching browser/domain step definitions and support required by the approved plan.
   - Kept role setup in acceptance support/test plumbing; no role-management UI or product-scope expansion was introduced.