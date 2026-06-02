Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 015 Run \`dev check\`.`

2. **Changes made**
   - Ran the required full validation suite.
   - Updated only `docs/iterations/015-club-slugs/todo.md` to mark task 015 complete.
   - No code/config/test files were changed for this task.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `293 tests, 0 failures`
   - Reran after the todo check-off to validate the current tree:
     - `293 tests, 0 failures`
   - `git diff --check` — passed.
   - Verified no unchecked todo items remain.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 015 Run \`dev check\`.`
   - To:
     - `- [x] 015 Run \`dev check\`.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No architecture or application code was changed in this task.
   - Final validation confirms the already-implemented club slug work remains passing under the project’s standard `dev check` workflow.