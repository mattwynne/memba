Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `010 Run dev check and confirm it is green.`

2. **Changes made**
   - No code/config/test changes.
   - Checked off only task 010 in:
     - `docs/iterations/049-member-role-badges/todo.md`

3. **Validation commands/results**
   - Ran full validation before check-off:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed, exit code 0.
   - After checking off the todo line, reran full validation on the final diff state:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed, exit code 0.
     - Browser acceptance summary included: `87 scenarios (87 passed)`, `536 steps (536 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 010 Run \`dev check\` and confirm it is green.`
   - To:
     - `- [x] 010 Run \`dev check\` and confirm it is green.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs.
   - This was a final validation/check-off task only, with no architecture or behaviour changes.

Final ordinary repo diff is limited to the task 010 todo check-off. Untracked `.fabro/tmp/` workflow temp files remain present.