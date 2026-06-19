1. **Selected todo line**
   - `002 Confirm the repo preview location/convention from 036 and the self-contained head block (daisyUI CDN + theme :root vars + needed raw tokens), reusing the phase-2 convention and class-mapping cheat sheet.`

2. **Changes made**
   - Added `docs/iterations/037-ds-catchup-onboarding-requests-and-refresh/preview-conventions.md`
     - Confirms the 036-established `design-system/` mirror directory convention.
     - Defines 037 repo/cloud path mappings for onboarding request flow, staff request review, new-request email, member empty states, club home, and member messaging.
     - Captures relative asset path rules.
     - Includes the self-contained daisyUI CDN + app theme `:root` head-block template.
     - Documents the email-preview exception/convention using conservative email markup and inline styles.
     - Reuses/extends the phase-2 class-mapping cheat sheet and warns against Tailwind utility usage in static previews.
   - Updated only the selected todo line from unchecked to checked.

3. **Focused validation**
   - `git diff --check` — passed.
   - Python whitespace/final-newline check for touched markdown files — passed.
   - Confirmed changed paths are limited to:
     - `docs/iterations/037-ds-catchup-onboarding-requests-and-refresh/todo.md`
     - `docs/iterations/037-ds-catchup-onboarding-requests-and-refresh/preview-conventions.md`
   - Did not run `dev check` because this task is docs-only/convention documentation; the repo instructions reserve `dev check` for code/config/app-behaviour changes or the final validation task.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 002 Confirm the repo preview location/convention...`
   - To:
     - `- [x] 002 Confirm the repo preview location/convention...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan does not explicitly reference ADRs.
   - Current relevant ADR context remains respected:
     - ADR 0015: member app pages use LiveView by default — this task only documents preview conventions and does not change app rendering architecture.
     - ADR 0016: email provider remains switchable — this task documents provider-neutral email preview conventions and does not alter email delivery boundaries.