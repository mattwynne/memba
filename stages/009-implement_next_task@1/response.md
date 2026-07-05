Implemented the first unchecked iteration task.

1. **Selected todo line**
   - `001 Port the app-shell CSS classes (`app-frame`, `app-card`, `app-bar` and its children, `app-menu`, `app-foot`) verbatim from `design-system/` (`memba.css` / `styles.css`) into `web/assets/css/app.css`, keeping names 1:1 with the mirror (daisyUI `dropdown` already exists).`

2. **Changes made**
   - Added shared member app-shell CSS to `web/assets/css/app.css`:
     - `app-frame`
     - `app-card`
     - `app-bar` and children
     - `app-menu` / identity dropdown pieces
     - `app-foot` and footer mark
   - Added `web/test/memba_web/app_shell_css_test.exs` to prove the app stylesheet defines the expected shared shell class selectors.
   - Checked off only task `001` in `docs/iterations/044-shared-app-shell/todo.md`.

3. **Validation**
   - Initial focused test command with repo-relative path failed because `dev test` expects paths relative to `web/`:
     - `PATH="$PWD/bin:$PATH" dev test web/test/memba_web/app_shell_css_test.exs`
   - Corrected focused test passed:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_shell_css_test.exs`
     - Result: `1 test, 0 failures`
   - Full required check passed:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed, including `85 scenarios (85 passed)` / `523 steps (523 passed)`

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 001 Port the app-shell CSS classes ...`
   - To:
     - `- [x] 001 Port the app-shell CSS classes ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADRs were explicitly referenced by the plan.
   - Inspected relevant accepted ADRs:
     - ADR 0001: Phoenix remains the core application stack; this change stays within the Phoenix asset pipeline via `web/assets/css/app.css`.
     - ADR 0015: member app pages should have a consistent app shell; this CSS adds the shared shell foundation without changing routes, controllers, business behaviour, or feature files.