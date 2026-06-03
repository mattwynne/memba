Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `016 Run \`dev check\`.`

2. **Changes made**
   - Ran the full project validation suite.
   - Checked off only task 016 in `docs/iterations/020-migrate-production-email-to-postmark/todo.md`.
   - No code/config/test/doc content changes were needed beyond the todo check-off.

3. **Validation commands run**
   - Full final validation:
     ```sh
     PATH="$PWD/bin:$PATH" dev check
     ```
     Result:
     - ExUnit: `491 tests, 0 failures`
     - Acceptance: `31 scenarios (31 passed)`, `205 steps (205 passed)`

   - Todo diff/whitespace validation:
     ```sh
     git diff -- docs/iterations/020-migrate-production-email-to-postmark/todo.md
     git diff --check -- docs/iterations/020-migrate-production-email-to-postmark/todo.md
     ```
     Result: passed; diff is the expected one-line task check-off.

4. **Exact todo check-off made**
   ```md
   - [x] 016 Run `dev check`.
   ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - This was the final validation task required by the plan.
   - Full `dev check` passed, proving the implemented Postmark migration slice remains compatible with project-wide tests and acceptance coverage.
   - Resend fallback support remains covered by prior targeted validation and unchanged by this task.