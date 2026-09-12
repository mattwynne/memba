Implemented TODO 004: configure `disconnectedTimeout: 1500` while preserving the existing LiveSocket options.

1. Selected task

   `004 Configure disconnectedTimeout: 1500 in web/assets/js/app.js while retaining the existing CSRF params, hooks, and long-poll fallback.`

2. Changes

   Added `disconnectedTimeout: 1500` to the production `LiveSocket` options in [app.js](/workspace/memba/web/assets/js/app.js:31). The existing `longPollFallbackMs`, CSRF params, and hooks remain unchanged.

   The focused configuration test from TODO 003 required no changes.

3. Validation

   - Confirmed the test’s red phase before implementation: 1 test, 1 expected failure due to the missing option.
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_js_test.exs --trace` — passed, 1 test and 0 failures.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — reached 1,220 tests, with 6 expected failures from the previously committed red-phase layout coverage for pending TODOs 005–007. The new LiveSocket configuration test passes. Full `dev check` therefore remains intentionally pending until those implementation tasks are completed.

4. Todo check-off

   Checked off only TODO 004 in [todo.md](/workspace/memba/docs/iterations/060-calm-liveview-reconnection-feedback/todo.md:6).

5. Todo structure

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   The plan explicitly references no ADRs. The change remains consistent with ADR 0013’s allowance for focused lower-level testing of LiveView mechanics and ADR 0015’s shared LiveView application model. No acceptance feature files, dependencies, transport fallback settings, or reconnect algorithms were changed.