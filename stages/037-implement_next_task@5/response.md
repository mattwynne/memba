1. **Selected todo line**
   - `005 Port the delivery-details CSS (`delivery-summary`, `delivery-bar`, `delivery-legend`, `delivery-group`, `recipient`, `deliv-*` tints) from `design-system/` into `web/assets/css/app.css`, names 1:1 with the mirror.`

2. **Changes made for this task only**
   - Added a delivery-details CSS section to `web/assets/css/app.css` for:
     - `.delivery-title`, `.delivery-meta`
     - `.delivery-summary*`
     - `.delivery-bar`
     - `.delivery-legend*`
     - `.delivery-group*`
     - `.recipient*`
     - `.deliv-ok`, `.deliv-snd`, `.deliv-bad`, `.deliv-unknown`
     - `.deliv-tint-ok`, `.deliv-tint-snd`, `.deliv-tint-bad`, `.deliv-tint-unknown`
   - Added CSS regression coverage in `web/test/memba_web/app_css_test.exs` to assert those delivery detail selectors are present.
   - Did not change routes, LiveView markup/behavior, acceptance feature files, or later todo items.

3. **Validation commands run and results**
   - TDD failing check before CSS implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_css_test.exs`
     - Failed as expected on missing `.delivery-title {`.
   - Focused CSS regression after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_css_test.exs`
     - Passed: `3 tests, 0 failures`.
   - Existing app-shell CSS sync guard:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_shell_css_test.exs`
     - Passed: `3 tests, 0 failures`.
   - Formatting for touched Elixir test:
     - `cd web && mix format --check-formatted test/memba_web/app_css_test.exs`
     - Passed.
   - Full browser-facing validation on final working-tree diff:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance suite: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Exact todo check-off made**
   - Changed only task 005:
     - From: `- [ ] 005 Port the delivery-details CSS (...)`
     - To: `- [x] 005 Port the delivery-details CSS (...)`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR files were present under `docs/adr/`.
   - Read the relevant local frontend guidance.
   - Preserved Tailwind v4 import syntax and did not use `@apply`.
   - Kept the work limited to the planned CSS port and selector names matching the delivery-details mirror vocabulary.
   - No acceptance feature files were changed.