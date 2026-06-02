1. **Selected todo line**
   - `001 Inspect current opened references in web/lib, web/test, acceptance-tests/features, active docs, and Postmark delivery code...`

2. **Changes made**
   - Added `docs/iterations/017-remove-open-tracking/opened-reference-inventory.md`
     - Captures inspected scope, search evidence, file counts, and references by area:
       - shared acceptance
       - Messaging domain/API
       - projections/read models
       - Postmark provider/webhook
       - Resend webhook references found during inspection
       - member-facing presentation/tests
       - Memba staff delivery view/tests
       - active docs
       - ADRs/model docs
   - Updated only the selected task line in `docs/iterations/017-remove-open-tracking/todo.md`.

3. **Focused validation run**
   - `git diff --check`
     - Passed with no whitespace errors.
   - `grep -nE '^- \[[ x]\] 001|opened-reference-inventory' docs/iterations/017-remove-open-tracking/todo.md docs/iterations/017-remove-open-tracking/opened-reference-inventory.md`
     - Confirmed task 001 is checked off.
   - `git status --short`
     - Shows only the intended doc/todo changes.
   - I did **not** run `dev check` because this task was docs/inspection-only and project instructions say not to run it for docs-only/planning-only edits unless explicitly requested.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect current opened references...`
   - To:
     - `- [x] 001 Inspect current opened references...`

5. **Todo splits/additions/reordering**
   - None. No tasks were split, added, reordered, or otherwise changed.

6. **ADR conformance evidence**
   - The plan references no ADR explicitly.
   - I inspected relevant nearby accepted ADRs:
     - ADR 0004: message deliverability aggregate
     - ADR 0006: simplified member-facing delivery status
     - ADR 0012: opened delivery status
     - ADR 0016: Resend provider
   - The inventory records that ADR 0012 currently conflicts with this iteration’s approved plan because it requires `opened`; the iteration plan is the current source of truth for removing open tracking.