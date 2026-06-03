1. **Selected todo line**
   - `001 Start after iteration 019 is delivered and inbound club-message behaviour has been manually observed working with Resend.`

2. **Changes made**
   - Updated only `docs/iterations/020-migrate-production-email-to-postmark/todo.md`.
   - Checked off task `001`.
   - No code, config, tests, feature files, or docs beyond the todo state were changed.

3. **Focused validation run**
   - Inspected current plan/todo.
   - Inspected recent commits with `git log --oneline --decorate -20`.
   - Verified iteration 019 evidence:
     - `docs/iterations/019-inbound-club-messages-by-email/plan.md` status is `merged`.
     - `docs/iterations/README.md` lists iteration 019 as `merged`.
     - Commit `71e224c` records `Validation: dev check passed; plan conformance passed`.
     - Commit `8e58fa0` marks iteration 019 merged.
   - Ran:
     - `PATH="$PWD/bin:$PATH" dev iteration check-predecessors docs/iterations/020-migrate-production-email-to-postmark/plan.md`
   - Result:
     - Passed: `Earlier iterations are merged.`

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Start after iteration 019 is delivered and inbound club-message behaviour has been manually observed working with Resend.`
   - To:
     - `- [x] 001 Start after iteration 019 is delivered and inbound club-message behaviour has been manually observed working with Resend.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read accepted ADR `docs/adr/0016-use-resend-as-switchable-email-provider.md`.
   - Task 001 conforms by starting Postmark migration only after Resend is established as a first-class, switchable provider and iteration 019’s Resend inbound email slice is merged.
   - No architecture/code changes were made, so no ADR constraints were altered.