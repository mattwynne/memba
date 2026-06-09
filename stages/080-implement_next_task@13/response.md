Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 013 Remove or narrow @todo-domain/@todo-ui tags from the affected scenarios only when they pass in the relevant runner.`

2. **Changes made**
   - Updated `acceptance-tests/features/club_member_invitations.feature`
     - Removed `@todo-domain @todo-ui` from the four `@iteration-029` Membership Admin invitation scenarios.
     - Left `@iteration-029` intact.
   - Updated `acceptance-tests/features/step_definitions/club_member_invitation_steps.js`
     - Added the missing `assertActiveMember` import needed by the now-enabled browser scenario.
   - Updated `docs/iterations/029-membership-admin-invitations/todo.md`
     - Checked off task 013 only.

3. **Validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix test test/features/domain_cucumber_acceptance_test.exs --only domain_cucumber`
     - Initially hit a sandbox wrapper issue because `pg_isready` was not available in the bare shell.
   - `devenv shell -- which pg_isready && PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/features/domain_cucumber_acceptance_test.exs --only domain_cucumber`
     - Passed: `58 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev acceptance --tags "@iteration-029"`
     - Initially exposed missing JS import; fixed.
   - `node --check acceptance-tests/features/step_definitions/club_member_invitation_steps.js && PATH="$PWD/bin:$PATH" dev acceptance --tags "@iteration-029"`
     - Passed: `4 scenarios (4 passed), 23 steps (23 passed)`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - ExUnit: `741 tests, 0 failures`.
     - Browser acceptance: `73 scenarios (73 passed), 489 steps (489 passed)`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 013 Remove or narrow @todo-domain/@todo-ui tags from the affected scenarios only when they pass in the relevant runner.`
   - To:
     - `- [x] 013 Remove or narrow @todo-domain/@todo-ui tags from the affected scenarios only when they pass in the relevant runner.`

5. **Todo splits/additions/reordering**
   - None.
   - Task 014 remains unchecked even though `dev check` was run as required validation for this feature/step-file change.

6. **ADR conformance**
   - ADR 0003 / ADR 0010: preserved shared feature files and validated the same `@iteration-029` scenarios in both domain and browser Cucumber runners.
   - ADR 0019: no routing/URL strategy changes; existing browser support continues exercising club subdomain routing.
   - Plan’s allowed acceptance feature changes explicitly permitted narrowing/removing `@todo-domain`/`@todo-ui` from `acceptance-tests/features/club_member_invitations.feature` once scenarios passed.