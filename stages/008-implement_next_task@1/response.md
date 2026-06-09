1. **Selected todo line**
   - `001 Inspect the current homepage template/component and identify the smallest copy/template change that restores the volunteering-first hero.`

2. **Changes made**
   - Updated `docs/iterations/031-brand-email-navigation-polish/todo.md` only.
   - Checked off task 001.
   - Added an inspection note identifying:
     - Logged-out homepage hero template: `web/lib/memba_web/controllers/page_html/home.html.heex` lines 157–165.
     - Matching logged-out page title: `web/lib/memba_web/controllers/page_controller.ex` line 55.
     - Smallest future behaviour change: replace only the logged-out hero heading/page title with `Volunteering shouldn’t feel like work.`, keep the volunteer-run eyebrow, and adjust nearby subheadline only enough to stay honest about current private member-message functionality.
     - Signed-in `Your clubs` branch should remain unchanged.

3. **Focused validation**
   - Ran `git diff --check` — passed with no whitespace errors.
   - Did **not** run `dev check` because this was a docs/todo-only inspection note, with no code, config, executable example, or app-behaviour change.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect...`
   - To:
     - `- [x] 001 Inspect...`

5. **Todo splits/additions/reordering**
   - No splits, additions, or reordering.
   - Added only a subordinate inspection-result note under the selected checked task.

6. **ADR conformance evidence**
   - The plan references no ADRs explicitly.
   - I inspected the current ADR list under `docs/adr/` and searched for homepage/marketing/public-template guidance; no relevant accepted ADR constraints applied to this inspection-only task.