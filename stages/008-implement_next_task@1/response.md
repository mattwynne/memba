1. **Selected todo line**
   - `- [ ] 001 Inspect the current homepage template/component and identify the smallest copy/template change that restores the volunteering-first hero.`

2. **Changes made**
   - Updated `docs/iterations/031-brand-email-navigation-polish/todo.md` only.
   - Recorded the inspection finding:
     - Homepage hero template: `web/lib/memba_web/controllers/page_html/home.html.heex`
     - Matching signed-out page title: `web/lib/memba_web/controllers/page_controller.ex`
     - Smallest identified future change: replace the public hero `h1` with `Volunteering shouldn’t feel like work.` and update the matching signed-out `page_title`.
     - Existing eyebrow/body copy already preserve volunteer-run/product-honesty context.

3. **Focused validation**
   - `git diff --check` — passed.
   - `git status --short` — confirmed only `todo.md` changed.
   - Did not run `dev check` because this was a docs/planning-only inspection task, consistent with `AGENTS.md`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect the current homepage template/component and identify the smallest copy/template change that restores the volunteering-first hero.`
   - To:
     - `- [x] 001 Inspect the current homepage template/component and identify the smallest copy/template change that restores the volunteering-first hero.`

5. **Todo splits/additions/reordering**
   - No splits or reordering.
   - Added one indented finding note under task 001 to preserve the inspection result for the next task.

6. **ADR conformance evidence**
   - Reviewed ADR 0001: Phoenix is the accepted core application stack; identified Phoenix controller/template files accordingly.
   - Reviewed ADR 0013: feature-style web tests should use PhoenixTest where relevant; no test changes were made in this inspection-only task, but the next homepage test task should follow that guidance.