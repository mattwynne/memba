Implemented next unchecked task 005.

1. **Selected todo line**
   - `005 Wrap @inner_block in the app-frame / app-card frame; keep the existing "Powered by Memba" app-foot footer and the flash_group.`

2. **Changes made**
   - Updated `Layouts.club_site/1`:
     - `#club-site-layout` now uses `class="app-frame"`.
     - Header + content are wrapped in `.app-card`.
     - `@inner_block` renders inside the card’s `<main>`.
     - Footer now uses `class="app-foot"` and preserves the same “Powered by Memba” link/URL.
     - `<.flash_group flash={@flash} />` remains outside the shell as before.
   - Updated layout tests to assert:
     - `.app-frame`
     - `.app-card`
     - content inside `.app-card > main`
     - `.app-foot` footer preservation
   - Updated the member page design-system guardrail to expect shell classes for the club-site layout.
   - Included formatter-only cleanup in `member_dashboard_live_test.exs` from `dev check` formatting.

3. **Validation run**
   - TDD red check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs`
     - Failed as expected before implementation: missing `#club-site-layout.app-frame`.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs test/memba_web/member_page_design_system_alignment_test.exs`
     - Passed: `7 tests, 0 failures`.
   - Formatter check:
     - `cd web && mix format --check-formatted lib/memba_web/components/layouts.ex test/memba_web/components/layouts_test.exs test/memba_web/member_page_design_system_alignment_test.exs test/memba_web/live/member_dashboard_live_test.exs`
     - Passed.
   - Full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `85 scenarios (85 passed), 523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Wrap ...`
     - to
     - `- [x] 005 Wrap ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs explicitly.
   - No `docs/adr/*.md` files were present to inspect.
   - Change conforms to the accepted plan decision to use the shared `app-frame` / `app-card` / `app-foot` shell classes without changing sign-out behavior or feature files.