1. **Selected todo line**
   - `- [ ] 016 Run \`dev check\`.`

2. **Changes made**
   - Ran the required final validation.
   - No code/config/test changes.
   - Updated only `docs/iterations/031-brand-email-navigation-polish/todo.md` to mark task 016 complete.

3. **Validation commands/results**
   - Ran full final check:
     ```sh
     PATH="$PWD/bin:$PATH" dev check
     ```
     Result: passed.
     - ExUnit: `758 tests, 0 failures`
     - Acceptance: `77 scenarios (77 passed)`, `502 steps (502 passed)`
   - Ran:
     ```sh
     git diff --check
     ```
     Result: passed.

4. **Exact todo check-off**
   ```diff
   -- [ ] 016 Run `dev check`.
   +- [x] 016 Run `dev check`.
   ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference any ADRs for this final validation task.
   - This task made no architectural, behavioural, routing, UI, feature, or acceptance-step changes.
   - Used the project-required `dev check` workflow from `AGENTS.md`, satisfying the iteration’s final validation requirement.