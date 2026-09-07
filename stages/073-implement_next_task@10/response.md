Implemented task 010 and left the exact staged diff passing `dev check`, with no unstaged changes.

1. Selected task

   `010 Follow the referenced design's desktop/mobile layout and accessible nav/tab semantics.`

2. Changes made

   - Added the design’s wide, flush-content club-site layout variant in [layouts.ex](/workspace/memba/web/lib/memba_web/components/layouts.ex:297).
   - Implemented the desktop two-column group rail and content layout, plus a compact horizontally scrollable mobile group chooser in [styles.css](/workspace/memba/styles.css:308).
   - Added selected, hover, and keyboard-focus treatments; responsive group headers; safe wrapping for long names and email addresses; and mobile action sizing.
   - Moved “New message” into the group header’s action area, matching the reference design. Group-aware composition remains deferred to tasks 013–015.
   - Completed tab accessibility in [club.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/club.html.heex:5):
     - horizontal tab orientation;
     - selected/inactive roving `tabindex`;
     - reciprocal tab/panel ARIA relationships;
     - keyboard navigation for Arrow Left/Right, Home, and End;
     - focusable active panels.
   - Changed the selected group’s `aria-current` token from `page` to `true`, accurately representing the current group even on its Members route.
   - The keyboard hook is limited to tab interaction and does not implement browser-local group persistence owned by task 011.
   - Added focused layout, CSS, LiveView, and accessibility coverage. No acceptance feature files were changed.

3. Validation

   - Initial red run: 50 tests, 8 expected failures.
   - Focused green run:

     `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_shell_css_test.exs test/memba_web/components/layouts_test.exs test/memba_web/live/member_dashboard_live_test.exs`

     Result: 50 tests, 0 failures.

   - Formatting check passed for all touched Elixir and HEEx files.
   - `git diff --check` passed.
   - `PATH="$PWD/bin:$PATH" dev gallery-walk` passed and captured 69 desktop/mobile screenshots without browser errors.
   - Final `PATH="$PWD/bin:$PATH" dev check` passed on the exact staged diff, including the full ExUnit and browser acceptance suites.

4. Todo check-off

   Changed exactly:

   `- [ ] 010 Follow ...` → `- [x] 010 Follow ...`

   See [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:12).

5. Todo structure

   No tasks were split, added, removed, or reordered. Task 011 remains the next unchecked task.

6. ADR conformance

   - ADR 0013: added user-facing LiveView and rendered-layout tests before implementation.
   - ADR 0015: retained the club home as a LiveView-backed member application page.
   - ADR 0019: preserved host-based club routing without introducing club query parameters.
   - ADR 0023: tabs and groups remain URL-addressable LiveView patch states; keyboard tab activation follows those routes instead of maintaining separate client-only state.