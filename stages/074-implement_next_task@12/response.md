Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 012 Run \`bin/dev check\` and fix regressions.`

2. **Changes made**
   - Ran the full project check.
   - No regressions were found, so no code/config/test fixes were needed.
   - Checked off task 012 in `docs/iterations/010-shared-magic-link-auth/todo.md`.

3. **Focused validation**
   - `env -u MEMBA_DEVENV_SHELL bin/dev check`
     - Passed.
     - Result: `192 tests, 0 failures`.
   - Reran after the todo check-off:
     - `env -u MEMBA_DEVENV_SHELL bin/dev check`
     - Passed.
     - Result: `192 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Note: devenv printed the usual post-success manager shutdown SIGKILL message after tests completed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 012 Run \`bin/dev check\` and fix regressions.`
   - To:
     - `- [x] 012 Run \`bin/dev check\` and fix regressions.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan does not explicitly reference an ADR for this final validation task.
   - No architecture, HTTP, Phoenix, Ecto, or acceptance feature changes were made.
   - The codebase is left passing `bin/dev check`.