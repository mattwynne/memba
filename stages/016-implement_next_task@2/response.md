1. **Selected todo line**
   - `002 Confirm the repo preview location and the self-contained head block (daisyUI CDN + theme :root vars from web/assets/css/app.css + needed raw tokens), reusing the phase-2 convention and class-mapping cheat sheet.`

2. **Changes made**
   - Added `docs/iterations/036-ds-catchup-member-management-and-auth/preview-conventions.md`.
   - Confirmed the delivery location as the preferred `design-system/` mirror directory, with prefix-stripping mappings to cloud DS paths.
   - Documented planned repo/cloud paths for:
     - invite-a-member preview
     - profile-completion preview
     - auth check-email preview
     - badges component card
   - Added relative asset path rules.
   - Added a self-contained preview `<head>` template using:
     - Google Fonts
     - daisyUI CDN
     - Memba raw tokens copied from `web/assets/css/app.css`
     - daisyUI light theme vars copied from `web/assets/css/app.css`
     - plain CSS layout guidance
   - Added the phase-2 class-mapping cheat sheet and reiterated the “no Tailwind utilities in static CDN previews” rule.
   - No app code, routes, templates, LiveViews, feature files, or executable scripts changed.

3. **Focused validation run**
   - `git diff --check && git status --short`
     - Passed tracked diff whitespace check.
     - Showed only:
       - modified `todo.md`
       - new `preview-conventions.md`
   - `python3` docs whitespace/final-newline check for both touched files
     - Passed: `docs whitespace check passed`
   - Did **not** run `dev check` because this task is docs-only, and project guidance says not to run `dev check` for docs-only/planning/prose edits unless explicitly requested.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Confirm the repo preview location ...`
   - To:
     - `- [x] 002 Confirm the repo preview location ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference any ADRs.
   - Inspected nearby relevant accepted ADRs:
     - ADR 0006: preserved simplified/provider-neutral delivery-language guidance.
     - ADR 0015: kept this to static DS preview documentation; no member app implementation/routing changes.
     - ADR 0016: kept auth-email progress preview guidance provider-neutral and compatible with switchable email provider boundaries.