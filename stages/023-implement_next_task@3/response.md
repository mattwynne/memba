1. **Selected todo line**
   - `003 Port the row-relevant .conversation/.conversation__*/.avatar-stack classes into app.css (mirroring memba.css's definitions for those classes).`

2. **Changes made**
   - Updated `web/assets/css/app.css` with a new **Club-home conversation list** section:
     - `.conversation-list`
     - `.conversation`
     - `.conversation__avatar`
     - `.conversation__body`
     - `.conversation__head`
     - `.conversation__subject`
     - `.conversation__date`
     - `.conversation__preview`
     - `.conversation__participants`
     - `.conversation__replies`
     - `.avatar-stack`
     - `.avatar-stack > span`
     - `.avatar-stack > .avatar`
     - `.avatar-stack > .is-more`
   - Added CSS support for both the static wireframe-style avatar stack spans and the Phoenix `<.avatar>` component expected by the next task.
   - Updated `web/test/memba_web/app_css_test.exs` with focused assertions proving the required conversation/avatar-stack CSS classes and key properties exist.

3. **Validation run**
   - TDD red run before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_css_test.exs`
     - Result: failed as expected, missing `.conversation-list`.
   - Focused green run:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_css_test.exs`
     - Result: `5 tests, 0 failures`.
   - Existing CSS sync coverage:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_shell_css_test.exs`
     - Result: `3 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format --check-formatted test/memba_web/app_css_test.exs`
     - Result: passed.
   - Full required check for browser-facing CSS:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed, including acceptance suite: `88 scenarios (88 passed)`, `541 steps (541 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Port the row-relevant ...`
   - to:
     - `- [x] 003 Port the row-relevant ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The iteration plan references no ADRs.
   - Checked for local ADR files with `docs/adr/**/*`; none were present.
   - Followed relevant local frontend guidance: preserved Tailwind v4 import syntax and did not use `@apply`.