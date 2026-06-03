1. **Selected todo line**
   - `001 Start after iteration 019 is delivered. Do not require manual Resend inbound observation before proceeding; Matt approved moving directly to Postmark after production setup showed the current Resend domain/account cannot receive clubs.memba.io without further provider changes.`

2. **Changes made**
   - Checked off task 001 in `docs/iterations/020-migrate-production-email-to-postmark/todo.md`.
   - No code/config/test/docs content changes beyond the iteration execution-state checkbox.

3. **Focused validation**
   - Ran:
     - `git log --oneline --decorate -20`
       - Confirmed recent context includes `8e58fa0 iteration 019: mark merged`.
     - `git status --short`
       - Confirmed clean working tree before editing.
     - `PATH="$PWD/bin:$PATH" dev iteration check-predecessors docs/iterations/020-migrate-production-email-to-postmark/plan.md`
       - Passed with: `Earlier iterations are merged.`
     - Reviewed diff/status after edit.
   - Did **not** run `dev check` because this was a todo execution-state-only change, not code/config/app-behaviour.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 ...`
   - To:
     - `- [x] 001 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read ADR 0016, which keeps Resend as a first-class switchable provider alongside Postmark and explicitly preserves provider switchability.
   - Also reviewed nearby relevant ADRs 0014 and 0017 for production hosting/release-state context.
   - Task 001 conforms by proceeding only after predecessor delivery was verified, while preserving the plan’s approved decision to move directly toward Postmark without requiring manual Resend inbound observation.