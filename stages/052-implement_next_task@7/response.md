Implemented and checked off TODO 007: the reconnect indicator now has named global CSS for fixed positioning, safe-area placement, pointer pass-through, spinner motion, and reduced-motion behavior.

1. Selected task

   `007 Add only the CSS needed for global fixed positioning, safe-area handling, and reduced-motion behaviour that is clearer as a named connection-status concept than as an opaque HEEx utility list.`

2. Changes

   - Added the connection-status rules in [app.css](/workspace/memba/web/assets/css/app.css:136):
     - fixed bottom-centre positioning with `z-index: 50`;
     - `max(18px, env(safe-area-inset-bottom))` safe-area offset;
     - `pointer-events: none` so the underlying page remains usable;
     - a named 850ms spinner animation;
     - reduced-motion rules that remove transitions and spinner animation while retaining a clear solid sage indicator.
   - Added focused CSS coverage in [app_css_test.exs](/workspace/memba/web/test/memba_web/app_css_test.exs:147).
   - No HEEx, generic flash behavior, dependencies, or acceptance features changed.

3. Validation

   - Red phase: focused CSS suite failed with 2 missing-rule failures.
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_css_test.exs --trace` — passed, 8 tests and 0 failures.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed, 1,223 tests and 0 failures.
   - `PATH="$PWD/bin:$PATH" dev acceptance` — passed with exit status 0.
   - `git diff --check` — passed.
   - The combined full `dev check` reached successful acceptance browser teardown but exceeded the fixed 10-minute tool limit before returning its final summary. I am therefore recording the separately passing quick and acceptance gates rather than claiming that timed-out invocation passed.

4. Todo check-off

   Checked off only TODO 007 in [todo.md](/workspace/memba/docs/iterations/060-calm-liveview-reconnection-feedback/todo.md:9). TODOs 008–010 remain unchecked.

5. Todo structure

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   The plan explicitly references no ADRs. The change conforms to accepted ADR 0001 by remaining in Phoenix’s existing asset pipeline, ADR 0013 by using focused lower-level coverage for a CSS-specific presentation mechanism, and ADR 0015 by preserving the shared LiveView treatment. No new architecture or dependency was introduced.