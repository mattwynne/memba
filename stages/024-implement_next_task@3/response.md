Implemented TODO 003 as the planned red-phase coverage checkpoint.

1. Selected task

   `003 Add proportionate direct coverage for the LiveSocket 1500 option, extracting a small importable configuration value only if useful and avoiding broad asset refactoring or tests of LiveView's timer implementation.`

2. Changes made

   Added [app_js_test.exs](/workspace/memba/web/test/memba_web/app_js_test.exs:1), which:

   - Reads the production `app.js`.
   - Locates the options passed to the actual `new LiveSocket("/live", Socket, {...})` constructor.
   - Requires `disconnectedTimeout` to be configured exactly once.
   - Requires its exact value to be `1500`.
   - Avoids testing LiveView’s internal timer implementation.

   No production JavaScript or configuration was changed, leaving TODO 004 as the implementation step. No JavaScript test framework or broader asset refactoring was needed.

3. Focused validation

   - `mix format --check-formatted test/memba_web/app_js_test.exs` — passed.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_js_test.exs --trace` — one expected red-phase failure:
     - Expected `disconnectedTimeout: 1500`.
     - Found no configured timeout in the LiveSocket options.

   Full `dev check` was not run because this checkpoint intentionally introduces a failing test for TODO 004 to satisfy.

4. Todo check-off

   Checked off only TODO 003 in [todo.md](/workspace/memba/docs/iterations/060-calm-liveview-reconnection-feedback/todo.md:5).

5. Todo structure

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   - The iteration plan explicitly references no ADRs.
   - ADR 0013 permits lower-level testing for LiveView-specific mechanics; this narrowly verifies production client configuration rather than substituting for user-facing coverage.
   - ADR 0015 remains respected because the configuration applies to the shared LiveView client.
   - No acceptance feature files were changed.