1. **Selected todo line**
   - `- [ ] 012 Run \`dev check\`.`

2. **Changes made**
   - No code/config/test changes.
   - Updated only `docs/iterations/024-email-template-designs/todo.md` to mark task 012 complete.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - ExUnit: `585 tests, 0 failures`
     - Acceptance: `44 scenarios (44 passed)`, `291 steps (291 passed)`
   - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 012 Run \`dev check\`.`
   - To:
     - `- [x] 012 Run \`dev check\`.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR-specific implementation changes were needed for this validation-only task.
   - Acceptance feature files remained unchanged.
   - Full project validation passed through the project’s standard `dev check` workflow.