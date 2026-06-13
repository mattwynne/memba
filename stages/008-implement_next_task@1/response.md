1. **Selected todo line**
   - `001 Inspect the existing auth LiveView, auth email module, Postmark webhook controller, read-model change publisher, and current delivery-status LiveViews that subscribe to read-model changes.`

2. **Changes made**
   - Added inspection notes:
     - `docs/iterations/032-auth-email-delivery-progress/task-001-inspection.md`
   - The notes document:
     - Current auth route and LiveView flow.
     - Existing neutral known/unknown sign-in behaviour.
     - Auth email construction and provider options.
     - Current auth persistence shape.
     - Postmark webhook handling and member-message idempotency.
     - ADR 0021 read-model-change publishing and LiveView subscription/reload patterns.
     - Implementation notes for later tasks.

3. **Focused validation**
   - Ran:
     - `git diff --check`
   - Result:
     - Passed with no whitespace errors.
   - Did **not** run `dev check` because this was a docs-only inspection/task-note change, per repo workflow guidance.

4. **Todo check-off made**
   - Changed exactly this line in `docs/iterations/032-auth-email-delivery-progress/todo.md`:
     - From `- [ ] 001 Inspect...`
     - To `- [x] 001 Inspect...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read ADR 0021 and ADR 0022.
   - Inspection notes explicitly record:
     - `Memba.ReadModelChanges` implements ADR 0021’s committed-change PubSub pattern.
     - Existing LiveViews subscribe when connected and reload from persistence after relevant broadcasts.
     - Auth progress should use a narrow committed-update publisher after DB commit and should not overload projection barriers, consistent with ADR 0021/0022.