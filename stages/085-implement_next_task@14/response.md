Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `014 Update ADR/documentation as needed to reflect that Postmark is the intended primary production provider after approval, while Resend remains a first-class fallback.`

2. **Changes made**
   - Updated `docs/adr/0016-use-resend-as-switchable-email-provider.md` to record:
     - Postmark is now the intended primary production email provider after approval/setup.
     - Resend remains a first-class fallback, not deprecated.
     - Postmark inbound club-message email uses the distinct route `POST /webhooks/postmark/inbound`.
     - Resend support should continue to be tested and documented unless a later ADR/iteration explicitly replaces the rollback strategy.
   - Updated only task 014 in `docs/iterations/020-migrate-production-email-to-postmark/todo.md` from unchecked to checked.

3. **Focused validation commands run**
   - `git diff -- docs/adr/0016-use-resend-as-switchable-email-provider.md docs/iterations/020-migrate-production-email-to-postmark/todo.md`
     - Confirmed intended ADR/todo diff only.
   - `git diff --check -- docs/adr/0016-use-resend-as-switchable-email-provider.md docs/iterations/020-migrate-production-email-to-postmark/todo.md`
     - Passed.
   - `grep -nE "Postmark is the intended primary production provider|Resend remains a first-class fallback|POST /webhooks/postmark/inbound|\\[x\\] 014" ...`
     - Passed.
   - Python final-newline/trailing-whitespace check for touched files
     - Passed.

   I did **not** run `dev check` because this task was docs/ADR-only; the explicit `dev check` task remains task 016.

4. **Exact todo check-off made**
   ```md
   - [x] 014 Update ADR/documentation as needed to reflect that Postmark is the intended primary production provider after approval, while Resend remains a first-class fallback.
   ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0016 is now updated to match iteration 020’s provider posture: Postmark primary after approval, Resend retained as switchable fallback.
   - ADR 0014 remains respected: production cutover still uses Fly secrets/config rather than code-time production changes.
   - ADR 0017 remains respected: the provider cutover remains tied to explicit release/smoke-test documentation rather than assuming green local tests prove production readiness.