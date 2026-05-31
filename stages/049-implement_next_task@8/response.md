1. **Selected todo line**
   - `- [ ] 008 Run \`bin/dev check\` and fix any route/module/test failures.`

2. **Changes made**
   - Ran the required full validation.
   - No route/module/test failures were found, so no code/config/test fixes were needed.
   - Updated `docs/iterations/009-routing-and-liveview-surface-split/todo.md` to check off task 008.

3. **Focused validation**
   - Command run:
     - `PATH="$PWD/bin:$PATH" bin/dev check`
   - Result:
     - Passed
     - `137 tests, 0 failures`

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 008 Run \`bin/dev check\` and fix any route/module/test failures.`
   - To:
     - `- [x] 008 Run \`bin/dev check\` and fix any route/module/test failures.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADRs were explicitly referenced by the iteration plan.
   - Confirmed relevant accepted ADRs remain satisfied:
     - ADR 0001: Phoenix remains the core application stack.
     - ADR 0013: Phoenix/PhoenixTest testing approach remains intact.
   - No acceptance feature files or out-of-scope routing/auth/member-facing behavior were changed.