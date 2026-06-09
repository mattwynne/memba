1. **Selected todo line**
   - `- [ ] 001 Inspect the current homepage template/component and identify the smallest copy/template change that restores the volunteering-first hero.`

2. **Changes made**
   - Added durable inspection artifact:
     - `docs/iterations/031-brand-email-navigation-polish/task-001-homepage-hero-inspection.md`
   - The note documents:
     - Current homepage route/template location.
     - Current signed-out hero copy.
     - Existing relevant controller and acceptance test/support locations.
     - The smallest identified follow-up template change: update the signed-out hero `h1` to `Volunteering shouldn’t feel like work.` while preserving the existing structure, volunteer-run positioning, CTAs, preview card, and responsive classes.

3. **Focused validation**
   - `git diff --check` — passed.
   - Verified the inspection artifact is non-empty and that the next unchecked todo is now task 002.
   - Did **not** run `dev check` because this was an inspection/docs-only task with no executable behaviour change.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 Inspect the current homepage template/component and identify the smallest copy/template change that restores the volunteering-first hero.`
   - To:
     - `- [x] 001 Inspect the current homepage template/component and identify the smallest copy/template change that restores the volunteering-first hero.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed relevant ADRs:
     - `docs/adr/0001-use-phoenix-for-the-core-application.md`
     - `docs/adr/0013-use-phoenix-test-for-feature-style-web-tests.md`
   - No architecture or test implementation was changed in this inspection task. The note points future implementation at the existing Phoenix controller-rendered homepage and existing user-visible test locations, consistent with those ADRs.