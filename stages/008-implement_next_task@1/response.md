1. **Selected todo line**
   - `001 Inspect the current /get-started controller/templates or LiveView, auth sign-in token creation, return-to handling, Staff request inbox, and onboarding request creation/notification code.`

2. **Changes made**
   - Added durable inspection notes:
     - `docs/iterations/030-verified-onboarding-requests/inspection-notes.md`
   - The notes capture:
     - `/get-started` route/controller/template flow.
     - Current signed-out vs signed-in request behaviour.
     - Current onboarding request creation and Staff notification path.
     - Auth sign-in token creation and return-to handling.
     - Staff active request inbox/rejection/conversion code paths.
     - Existing relevant test coverage.
     - Implementation seams for later tasks.
     - ADR conformance notes.

3. **Focused validation**
   - Ran:
     - `git diff --check`
   - Result:
     - Passed with no whitespace errors.
   - Did **not** run `dev check` because this task made docs-only inspection/todo changes, and project guidance says not to run `dev check` for docs-only/prose-only edits unless requested.

4. **Todo check-off made**
   - Changed exactly this line:
     - `- [ ] 001 Inspect ...`
   - To:
     - `- [x] 001 Inspect ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR was explicitly referenced by the plan.
   - Inspected relevant accepted ADRs and recorded conformance notes in `inspection-notes.md`:
     - ADR 0001 Phoenix core app.
     - ADR 0002 Commanded/event sourcing.
     - ADR 0009 Commanded Ecto projections.
     - ADR 0010 shared feature files.
     - ADR 0013 PhoenixTest for feature-style web tests.
     - ADR 0021 committed read-model changes.
     - ADR 0022 projection barriers.