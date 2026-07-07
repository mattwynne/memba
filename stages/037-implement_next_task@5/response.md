Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Port the member-list and member-row CSS (and its children) from design-system/ (memba.css / styles.css) into web/assets/css/app.css, names 1:1 with the mirror.`

2. **Changes made**
   - Added `member-list` / `member-row` CSS to `web/assets/css/app.css`, including:
     - `.member-list`
     - `.member-row`
     - `.member-row:hover`
     - `.member-row:focus-visible`
     - `.member-row__avatar`
     - `.member-row__body`
     - `.member-row__name`
     - `.member-row__meta`
     - `.member-row__role`
   - Added focused CSS coverage in `web/test/memba_web/app_css_test.exs` to guard the new member-list/member-row rules.

3. **Validation run**
   - Focused CSS tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_css_test.exs test/memba_web/app_shell_css_test.exs`
     - Result: `7 tests, 0 failures`
   - Full project check because this is browser-facing UI/CSS:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed, including `85 scenarios (85 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Port the ... CSS ... into web/assets/css/app.css, names 1:1 with the mirror.`
   - To:
     - `- [x] 005 Port the ... CSS ... into web/assets/css/app.css, names 1:1 with the mirror.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no explicit ADRs.
   - No local `docs/adr/**/*.md` files were found to inspect.
   - The change keeps the existing Phoenix/Tailwind setup intact: no Tailwind import changes, no `@apply`, no JS, no feature-file changes, and only app stylesheet/test coverage were updated.