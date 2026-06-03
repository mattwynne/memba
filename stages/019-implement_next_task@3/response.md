1. **Selected todo line**
   - `003 Inspect existing Postmark outbound member-message provider, Postmark delivery-status webhook controller, auth email Postmark configuration, and docs/postmark-email.md.`

2. **Changes made**
   - Added the inspection artifact:
     - `docs/iterations/020-migrate-production-email-to-postmark/task-003-postmark-existing-email-inspection.md`
   - The artifact documents:
     - Existing Postmark outbound member-message provider behaviour/config/tests.
     - Postmark delivery-status webhook route/controller behaviour/tests.
     - Auth email Postmark config/runtime behaviour/tests.
     - Current `docs/postmark-email.md` coverage and gaps for later tasks.
     - Carry-forward observations, including that member-message Postmark delivery currently sends metadata but does not set a Postmark `MessageStream`, which task 009 should verify/fix.
   - Updated only the task 003 checkbox in:
     - `docs/iterations/020-migrate-production-email-to-postmark/todo.md`

3. **Focused validation**
   - Ran:
     - `git diff --check`
   - Result:
     - Passed.
   - Also reviewed focused diff/status for changed task files.
   - Did **not** run `dev check` because this was a docs-only inspection/prose task with no code/config/app-behaviour change; final `dev check` remains task 016.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 003 Inspect existing Postmark outbound member-message provider, Postmark delivery-status webhook controller, auth email Postmark configuration, and docs/postmark-email.md.`
   - To:
     - `- [x] 003 Inspect existing Postmark outbound member-message provider, Postmark delivery-status webhook controller, auth email Postmark configuration, and docs/postmark-email.md.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed ADR 0016 and preserved its direction: Postmark and Resend remain first-class switchable providers, with provider-specific parsing/config at the boundary and shared domain APIs behind them.
   - Reviewed ADRs 0014 and 0017 for production/Fly/runbook implications carried forward to later documentation tasks.
   - Reviewed ADR 0018; no devenv/process-compose changes were made.