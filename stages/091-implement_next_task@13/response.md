Implemented the next unchecked task.

1. **Selected todo line**
   - `013 Run \`dev check\`.`

2. **Changes made**
   - No code/config/test/doc implementation changes were needed.
   - Updated only `docs/iterations/042-club-email-subdomains/todo.md` to mark task 013 complete.

3. **Validation**
   - Ran full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: **passed**
     - Final rerun was after the todo check-off, on the final working tree state.
     - Acceptance output included: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 013 Run \`dev check\`.`
   - To:
     - `- [x] 013 Run \`dev check\`.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No architecture or behaviour changes were made.
   - Did not mutate Postmark/DNS or run the production smoke test; task 014 remains unchecked pending Matt’s external confirmation.