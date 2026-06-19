1. **Selected todo line**
   - `008 Ensure @dsCard headers and relative asset paths are correct on every new/changed file.`

2. **Changes made**
   - Verified all four DS preview files have first-line `@dsCard` headers with expected metadata:
     - `design-system/wireframes/invite-a-member.html`
     - `design-system/wireframes/profile-completion.html`
     - `design-system/wireframes/check-email-delivery-progress.html`
     - `design-system/components/badges/badges.card.html`
   - Fixed one root-absolute static-preview link:
     - Changed `href="/auth"` to `href="#"` in `check-email-delivery-progress.html`, matching the other non-navigating static preview links and avoiding an incorrect root-relative path in the DS environment.
   - Checked off only todo item 008.

3. **Focused validation run**
   - `git log --oneline --decorate -20` — inspected recent Fabro checkpoints.
   - `git status --short` — clean before edits.
   - Python validation script over the four DS preview files:
     - Confirmed first-line `@dsCard` headers.
     - Confirmed expected viewport metadata.
     - Confirmed no broken relative `href/src` targets and no root-absolute local paths.
     - Result: passed.
   - `git diff --check` — passed.
   - Final `git status --short` shows only:
     - `M design-system/wireframes/check-email-delivery-progress.html`
     - `M docs/iterations/036-ds-catchup-member-management-and-auth/todo.md`

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 008 Ensure @dsCard headers and relative asset paths are correct on every new/changed file.`
   - To:
     - `- [x] 008 Ensure @dsCard headers and relative asset paths are correct on every new/changed file.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no explicit ADRs.
   - This task stayed within the static design-system preview scope.
   - No app code, routes, LiveViews, templates, behaviour, or acceptance `.feature` files were changed.
   - Full `dev check` remains for the still-unchecked final task 009.