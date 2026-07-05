Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `002 In Layouts.club_site/1 (web/lib/memba_web/components/layouts.ex), replace the header's left side with the app-bar showing the plain @club_name.`

2. **Changes made**
   - Updated `web/lib/memba_web/components/layouts.ex`:
     - Replaced the club-name header link with the design-system app-bar structure:
       - `.app-bar`
       - `.app-bar__brand`
       - `.app-bar__club`
     - Rendered `@club_name` as plain text in a `<span>`, not a link.
     - Preserved the existing signed-in nav/sign-out area unchanged for later tasks.
   - Updated `web/test/memba_web/components/layouts_test.exs`:
     - Added assertions that `club_site` renders the app-bar.
     - Added assertions that the club name appears in `.app-bar__brand .app-bar__club`.
     - Added assertions that the club name is no longer a header link.

3. **Validation**
   - TDD pre-implementation focused test:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs`
     - Failed as expected because `.app-bar` was not yet present.
   - Post-implementation focused test:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs`
     - Passed: `4 tests, 0 failures`.
   - Full validation on the final worktree, including the todo check-off:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including `85 scenarios (85 passed)` / `523 steps (523 passed)`.

4. **Todo check-off**
   - Changed exactly this line:
     - From: `- [ ] 002 In Layouts.club_site/1 ...`
     - To: `- [x] 002 In Layouts.club_site/1 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001 respected: change stays within the Phoenix app/layout layer.
   - ADR 0015 respected: moves the shared member-facing club surface toward the consistent app shell without changing routing or business behavior.