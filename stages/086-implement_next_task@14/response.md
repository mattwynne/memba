Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 014 Run dev check.`

2. **Changes made**
   - Ran the full project validation.
   - Updated `docs/iterations/029-membership-admin-invitations/todo.md` to check off task 014 only.

3. **Validation commands run**
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - ExUnit: `741 tests, 0 failures`
     - Browser acceptance: `73 scenarios (73 passed), 489 steps (489 passed)`
   - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 014 Run \`dev check\`.`
   - To:
     - `- [x] 014 Run \`dev check\`.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No architecture, routing, domain, UI, or acceptance-feature behaviour changed in this task.
   - Final validation confirms the iteration implementation remains consistent with the accepted project workflow and shared acceptance-test contract.