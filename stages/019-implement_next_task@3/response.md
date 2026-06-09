1. **Selected todo line**
   - `- [ ] 003 Inspect the transactional email layout/helpers from iteration 024 and identify the canonical footer component or helper.`

2. **Changes made**
   - Updated `docs/iterations/031-brand-email-navigation-polish/todo.md` only.
   - Checked off task 003 and recorded the finding:
     - Iteration 024 introduced `Memba.EmailTemplates`.
     - The canonical standard footer helper is `EmailTemplates.memba_footer/1`, passed through `EmailTemplates.render_shell/1` via the `:footer` option.
     - `EmailTemplates.trust_footer/1` is a separate sign-in/welcome trust panel, not the standard footer itself.

3. **Focused validation**
   - `git diff -- docs/iterations/031-brand-email-navigation-polish/todo.md`
     - Confirmed only task 003 was checked off and annotated.
   - `git diff --check`
     - Passed with no whitespace errors.
   - Did not run `dev check` because this was a docs/todo-only inspection task with no code, config, dependency, acceptance-test, or app-behaviour changes.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 003 Inspect the transactional email layout/helpers from iteration 024 and identify the canonical footer component or helper.`
   - To:
     - `- [x] 003 Inspect the transactional email layout/helpers from iteration 024 and identify the canonical footer component or helper.`

5. **Todo splits/additions/reordering**
   - No splits, additions, or reordering.
   - Added only a finding note beneath the selected task.

6. **ADR conformance evidence**
   - ADR 0001: Inspection confirms the email helpers remain inside the Phoenix/Elixir core app.
   - ADR 0013: No web feature-test changes were needed for this non-behaviour inspection task.
   - ADR 0016: The finding preserves the existing provider-neutral/Swoosh email boundary; it only identifies the shared rendering helper.