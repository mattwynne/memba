1. **Selected todo line**
   - `001 Inspect the mockup HTML files and extract reusable layout ideas: staff operations shell, page header, navigation grouping, table density, status chips, action placement, and card/table treatment.`

2. **Changes made**
   - Added `docs/iterations/021-staff-area-redesign/mockup-layout-notes.md`.
   - Captured reusable design guidance from all five supplied mockup HTML files:
     - staff operations shell/nav rhythm;
     - page header/action placement;
     - cards, tables, density;
     - status chip/badge treatment;
     - page-specific adaptations for Clubs, Club detail, People, Messages, Deliveries, and Incoming;
     - explicit guardrails against copying out-of-scope mockup behaviours.
   - Updated only the selected task line in `todo.md`.

3. **Focused validation**
   - Inspected recent Fabro commits:
     - `git log --oneline --decorate -20`
   - Confirmed clean tree before editing:
     - `git status --short`
   - Extracted visible text from each mockup HTML file with a local Python script for review.
   - Checked documentation diff for whitespace errors:
     - `git diff --check -- docs/iterations/021-staff-area-redesign/mockup-layout-notes.md docs/iterations/021-staff-area-redesign/todo.md`
     - Result: passed.
   - Did **not** run `dev check` because this was a docs-only planning/inspection task, consistent with `AGENTS.md`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect the mockup HTML files...`
   - To:
     - `- [x] 001 Inspect the mockup HTML files...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference any ADRs.
   - I inspected the ADR directory and relevant accepted ADRs for context.
   - This task only added implementation notes and did not alter architecture, runtime behaviour, routes, tests, or acceptance files.
   - Notes preserve the plan’s domain guardrails and avoid introducing mockup-only behaviours such as Roles, Incoming, bulk message actions, unsupported filters, plans, lifecycle states, or staff-side message composition.