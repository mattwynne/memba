1. **Selected todo line**
   - `014 Run dev check.`

2. **Changes made**
   - Updated `docs/iterations/029-membership-admin-invitations/todo.md` only.
   - No code/config/test changes were needed because `dev check` passed.

3. **Validation commands run**
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - ExUnit: `744 tests, 0 failures`
     - Acceptance: `69 scenarios (69 passed)`, `466 steps (466 passed)`
   - Re-ran after checking off the todo:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed again with the same successful suite summary.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 014 Run \`dev check\`.`
   - To:
     - `- [x] 014 Run \`dev check\`.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADRs were explicitly referenced by this iteration plan.
   - This task followed the project-required workflow by running full `dev check` for the final validation task.
   - Working tree now only contains the expected final todo check-off in `todo.md`.