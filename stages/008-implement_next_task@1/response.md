1. **Selected todo line**
   - `001 Inspect current opened references in web/lib, web/test, acceptance-tests/features, active docs, and Postmark delivery code...`

2. **Changes made**
   - Added `docs/iterations/017-remove-open-tracking/inspection.md` with a scoped inventory of current open-tracking references.
   - Covered:
     - Messaging command/API/event path
     - projections/read models
     - Postmark outbound delivery
     - Postmark/Resend webhook handling
     - member presentation/LiveView/controller tests
     - Memba staff delivery view
     - acceptance feature/support files
     - active docs and ADRs
   - Updated only the selected todo line to checked.

3. **Focused validation run**
   - Ran scoped recursive Python searches for:
     - `opened`
     - `Opened`
     - `track_opens`
     - `open tracking`
     - `open-tracking`
     - `EmailDeliveryOpened`
     - `ReportEmailDeliveryOpened`
     - `report_email_delivery_opened`
   - Results recorded/validated:
     - `web/lib`: 15 files, 47 matching lines
     - `web/test`: 17 files, 106 matching lines
     - `acceptance-tests/features` all files: 2 files, 9 matching lines
     - `acceptance-tests/features/**/*.feature`: 0 files, 0 matching lines
     - active first-party docs: 9 files, 25 matching lines
   - Verified todo check-off with `sed`.
   - Did **not** run `dev check` because this task only added iteration inspection notes and changed todo state; project guidance says not to run `dev check` for docs/planning-only edits unless explicitly required.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect current opened references...`
   - To:
     - `- [x] 001 Inspect current opened references...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Inspected relevant accepted ADRs:
     - `0004-model-message-deliverability-as-a-message-aggregate`
     - `0006-simplify-member-facing-delivery-status`
     - `0012-track-whether-message-delivery-was-opened`
     - `0016-use-resend-as-switchable-email-provider`
   - Made no behaviour or architecture changes in this task.
   - Recorded that existing accepted ADRs still describe opened/open-tracking behaviour and that ADR 0012 conflicts with this iteration’s new policy, to be reconciled in the later documentation task.