1. **Selected todo line**
   - `009 Run dev check and confirm it is green.`

2. **Changes made**
   - No code/config/test changes.
   - Updated only `docs/iterations/050-club-home-conversation-and-member-row-fidelity/todo.md` to mark task 009 complete.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - Final rerun was after the todo check-off, against the final worktree state.
     - Acceptance summary included: `88 scenarios (88 passed)`, `541 steps (541 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 009 Run \`dev check\` and confirm it is green.`
   - To:
     - `- [x] 009 Run \`dev check\` and confirm it is green.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan does not explicitly reference ADRs.
   - This task was validation-only and changed no architecture or app behavior.

Final `git status --short` shows only the expected todo file modification.