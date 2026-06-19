1. **Selected todo line**
   - `007 Render-verify each file with headless Chrome; fix any unstyled/broken components (watch for accidental Tailwind utility usage that won't resolve statically).`

2. **Changes made**
   - Render-verified all four DS preview files:
     - `design-system/wireframes/invite-a-member.html`
     - `design-system/wireframes/profile-completion.html`
     - `design-system/wireframes/check-email-delivery-progress.html`
     - `design-system/components/badges/badges.card.html`
   - No preview fixes were needed.
   - Updated only `docs/iterations/036-ds-catchup-member-management-and-auth/todo.md` to check off task 007.
   - Temporary render artifacts under `.fabro/tmp/` were removed and are not part of the diff.

3. **Focused validation commands/results**
   - `git log --oneline --decorate -20`
     - Inspected recent Fabro checkpoints.
   - `git status --short`
     - Clean before task work.
   - Headless Chromium screenshot render via Nix:
     - Rendered all four files at their declared viewports:
       - `1180x920`
       - `1180x920`
       - `1180x980`
       - `760x236`
     - Chromium exited successfully for each; only expected sandbox DBus warnings appeared.
   - Browser computed-style verification:
     - Confirmed each preview loaded Google Fonts + daisyUI CDN stylesheets.
     - Confirmed body font/background tokens applied.
     - Confirmed daisyUI probes rendered with expected computed styles:
       - `.btn-primary`
       - `.btn-outline-soft`
       - `.badge-success`
     - Result: passed.
   - PNG screenshot sanity verification:
     - Confirmed expected dimensions and non-blank/color-diverse renders for all screenshots.
     - Result: passed.
   - Class-token inspection:
     - Confirmed no obvious Tailwind utility trap; classes are custom preview classes or daisyUI component classes.
   - `git diff --check -- docs/iterations/036-ds-catchup-member-management-and-auth/todo.md`
     - Passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 007 Render-verify each file with headless Chrome; fix any unstyled/broken components (watch for accidental Tailwind utility usage that won't resolve statically).`
   - To:
     - `- [x] 007 Render-verify each file with headless Chrome; fix any unstyled/broken components (watch for accidental Tailwind utility usage that won't resolve statically).`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan references no explicit ADRs.
   - This task changed no app code, routes, LiveViews, templates, acceptance features, or runtime behaviour.
   - Work stayed within the approved static design-system validation scope.
   - Full `dev check` remains for the still-unchecked final validation task 009.