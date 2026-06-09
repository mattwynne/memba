1. **Selected todo line**
   - `- [ ] 003 Inspect the transactional email layout/helpers from iteration 024 and identify the canonical footer component or helper.`

2. **Changes made for this task only**
   - Added inspection notes:
     - `docs/iterations/031-brand-email-navigation-polish/task-003-email-footer-inspection.md`
   - Identified the canonical standard transactional footer helper as:
     - `Memba.EmailTemplates.memba_footer/1`
   - Documented that:
     - `Memba.EmailTemplates.render_shell/1` provides the shared shell and accepts a `:footer` fragment.
     - `Memba.EmailTemplates.trust_footer/1` is a sign-in/security trust band, not the general standard footer.
     - Sign-in currently uses `trust_footer/1` plus private `auth_footer/1`, so later footer work should replace the private row with `memba_footer/1` while preserving the trust band.
     - Inbound rejection already uses `memba_footer/1`.

3. **Focused validation run**
   - `git diff --check` — passed.
   - No `dev check` run because this was a docs-only inspection note, matching the project guidance not to run `dev check` for docs-only/prose-only edits.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Inspect the transactional email layout/helpers from iteration 024 and identify the canonical footer component or helper.`
   - To:
     - `- [x] 003 Inspect the transactional email layout/helpers from iteration 024 and identify the canonical footer component or helper.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan does not explicitly reference any ADRs.
   - Relevant ADRs inspected:
     - ADR 0001: Phoenix remains the core app stack; no app architecture changes were made.
     - ADR 0016: email provider choice remains behind existing Swoosh/provider boundaries; no provider or delivery behaviour changed.
     - ADR 0013: no web/acceptance test behaviour changed for this inspection-only task.
   - This task only records the existing helper decision needed for the next implementation tasks.