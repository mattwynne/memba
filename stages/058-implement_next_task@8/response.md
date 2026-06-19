1. **Selected todo line**
   - `008 Render-verify each file with headless Chrome; fix any unstyled/broken components (watch for accidental Tailwind utility usage that won't resolve statically).`

2. **Changes made**
   - Render-verified all six iteration preview files:
     - `design-system/wireframes/onboarding-request-flow.html`
     - `design-system/wireframes/admin-request-review.html`
     - `design-system/emails/new-request-notification.html`
     - `design-system/wireframes/member-empty-first-run-states.html`
     - `design-system/wireframes/club-home.html`
     - `design-system/wireframes/member-messaging.html`
   - No preview fixes were needed: all rendered cleanly with loaded daisyUI CDN styles, no broken images/resource failures, and no unstyled daisyUI probe/components detected.
   - Screenshots were generated under `/tmp/memba-ds-render-check`.
   - Only `todo.md` was edited to check off task 008.

3. **Focused validation commands run and results**
   - `node /tmp/render-ds-previews.js`
     - Result: passed.
     - All 6 previews rendered under Playwright Chromium/headless Chrome.
     - No stylesheet/script/image/font failures.
     - No console errors.
     - No broken images.
     - daisyUI probe styled successfully on every page.
   - Python static class scan for unresolved Tailwind-like utility classes across all six previews
     - Result: passed.
     - `OK: no unresolved Tailwind-like utility classes found in iteration previews.`
   - `git diff --check`
     - Result: passed.
   - `git status --short`
     - Result: only `todo.md` is modified.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 008 Render-verify each file with headless Chrome; fix any unstyled/broken components (watch for accidental Tailwind utility usage that won't resolve statically).`
   - To:
     - `- [x] 008 Render-verify each file with headless Chrome; fix any unstyled/broken components (watch for accidental Tailwind utility usage that won't resolve statically).`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference any ADRs for this task.
   - The work stayed within the approved static design-system-preview scope.
   - No app code, routes, LiveViews, templates, behaviour, or `.feature` files were changed.