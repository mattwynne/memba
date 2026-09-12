Completed TODO 001 as the planned red-phase test checkpoint. The codebase is intentionally not yet `dev check`-green because these tests describe behavior that later TODOs will implement.

1. Selected task

   `001 Add focused failing layout coverage for stable client/server connection-status IDs, exact copy, role="status", polite live-region behaviour, hidden initial state, and absence of close controls.`

2. Changes

   Added focused `flash_group/1` tests in [layouts_test.exs](/workspace/memba/web/test/memba_web/components/layouts_test.exs:293) covering:

   - Unique, initially hidden `#client-error` and `#server-error` elements.
   - Exact approved client and server copy.
   - `role="status"` with `aria-live="polite"`.
   - Absence of close buttons.
   - An exact normalized-text assertion helper.

   No production markup, CSS, LiveView selectors, spinner behavior, or LiveSocket configuration was changed.

3. Validation

   - `mix format --check-formatted test/memba_web/components/layouts_test.exs` — passed.
   - `git diff --check` — passed.
   - `dev test test/memba_web/components/layouts_test.exs` — 16 tests, 4 expected failures:
     - Client copy is still the generated Phoenix copy.
     - Server copy is still the generated Phoenix copy.
     - Both elements still use alert rather than polite status semantics.
     - Both elements still contain close buttons.
   - The stable-ID and initially-hidden coverage passes.

   The first formatting invocation used the repository-relative `web/test/...` path after the Mix wrapper had already entered `web/`; it reported no matching file. Re-running with `test/...` passed.

   Full `dev check` was not run because this task explicitly establishes failing tests; later implementation tasks must make them green before the final quality gate.

4. Todo check-off

   Checked off only task 001 in [todo.md](/workspace/memba/docs/iterations/060-calm-liveview-reconnection-feedback/todo.md:3).

5. Todo structure

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   - The plan explicitly references no ADRs.
   - ADR 0013 permits lower-level Phoenix component/LiveView tests for framework-specific mechanics and requires failing coverage before or alongside implementation; this checkpoint follows that decision.
   - ADR 0015 remains respected by testing the shared LiveView layout component without introducing controller-specific behavior.
   - No acceptance feature files were changed.