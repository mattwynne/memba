Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `013 Update docs/human-todo.md or add a runbook under this iteration folder with Matt's manual cutover steps, smoke tests, monitoring checks, and rollback steps to Resend.`

2. **Changes made**
   - Added `docs/iterations/020-migrate-production-email-to-postmark/postmark-production-cutover-runbook.md`.
   - The runbook covers:
     - production cutover scope and provider-alignment warning;
     - pre-cutover release/Fly/Postmark/DNS readiness;
     - exact Postmark Fly secrets for cutover;
     - auth, outbound member-message, inbound accepted, inbound rejection, and rollback-readiness smoke tests;
     - post-cutover monitoring checks;
     - exact Resend rollback secrets and dashboard/DNS rollback steps;
     - explicit note that Resend inbound rollback depends on the `clubs.memba.io` Resend account/domain setup being fixed/available.
   - Updated only the task 013 line in `todo.md` to checked.

3. **Focused validation run**
   - `git diff --check` — passed.
   - `python3 ...` trailing-whitespace/final-newline check for the new runbook and todo — passed.
   - `grep -nE ... postmark-production-cutover-runbook.md` for required runbook topics — passed.
   - `git diff -- docs/iterations/020-migrate-production-email-to-postmark/todo.md` — confirmed only task 013 changed from unchecked to checked.
   - Did **not** run `dev check` because this was docs-only/prose-only, consistent with repo instructions.

4. **Exact todo check-off made**
   ```md
   - [x] 013 Update `docs/human-todo.md` or add a runbook under this iteration folder with Matt's manual cutover steps, smoke tests, monitoring checks, and rollback steps to Resend.
   ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0014: runbook uses Fly production app/secrets/logs/status explicitly.
   - ADR 0016: preserves Postmark and Resend as switchable providers and documents Resend rollback/fallback paths.
   - ADR 0017: treats production release state, smoke tests, monitoring, and rollback as explicit operational artifacts rather than implicit test results.