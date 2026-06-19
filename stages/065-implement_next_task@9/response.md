1. **Selected todo line**
   - `009 Ensure @dsCard headers and relative asset paths are correct on every new/changed file.`

2. **Changes made**
   - Verified all six iteration preview files:
     - `design-system/wireframes/onboarding-request-flow.html`
     - `design-system/wireframes/admin-request-review.html`
     - `design-system/emails/new-request-notification.html`
     - `design-system/wireframes/member-empty-first-run-states.html`
     - `design-system/wireframes/club-home.html`
     - `design-system/wireframes/member-messaging.html`
   - Confirmed each file has exactly one first-line `@dsCard` header with `group`, `viewport`, `name`, and `subtitle`.
   - Confirmed asset references follow the DS preview conventions:
     - no Phoenix/app static paths
     - no app build CSS links such as `app.css`, `styles.css`, or `memba.css`
     - no invalid root-relative asset paths
     - CDN stylesheet links are limited to the expected Google Fonts and daisyUI references
   - Only changed `todo.md` to check off task 009.

3. **Focused validation commands run**
   - Python static validation for `@dsCard` headers and asset-path conventions:
     - Result: `OK: @dsCard headers and relative asset-path conventions verified for 6 iteration previews.`
   - `git diff --check`
     - Result: passed.
   - `git status --short`
     - Result: only `docs/iterations/037-ds-catchup-onboarding-requests-and-refresh/todo.md` is modified.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 009 Ensure @dsCard headers and relative asset paths are correct on every new/changed file.`
   - To:
     - `- [x] 009 Ensure @dsCard headers and relative asset paths are correct on every new/changed file.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan does not explicitly reference any ADRs for this task.
   - Work followed the local DS preview conventions from:
     - `docs/iterations/037-ds-catchup-onboarding-requests-and-refresh/preview-conventions.md`
     - `docs/iterations/036-ds-catchup-member-management-and-auth/preview-conventions.md`
   - No app code, routes, LiveViews, templates, behavior, or `.feature` files were changed.