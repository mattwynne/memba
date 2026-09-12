Completed TODO 002 as the planned red-phase coverage checkpoint.

1. Selected task

   `002 Extend that layout coverage to require distinct phx-disconnected selectors, phx-connected dismissal, a shared visual class, and spinner decoration.`

2. Changes made

   Extended [layouts_test.exs](/workspace/memba/web/test/memba_web/components/layouts_test.exs:334) with focused tests that verify:

   - Client and server statuses use distinct `.phx-client-error` and `.phx-server-error` selectors.
   - `phx-connected` hides each status and restores its `hidden` attribute.
   - Both statuses require the shared `connection-status` class.
   - Each status requires an `aria-hidden="true"` `connection-status__spinner`.
   - Encoded LiveView JS commands are decoded through a small test helper for structural assertions.

   No production markup, CSS, or JavaScript configuration was changed.

3. Focused validation

   - `mix format --check-formatted test/memba_web/components/layouts_test.exs` — passed.
   - `git diff --check` — passed.
   - `dev test test/memba_web/components/layouts_test.exs --trace` — 20 tests, 6 expected red-phase failures.
     - The new selector and reconnection-dismissal tests pass.
     - The new shared-class and decorative-spinner tests fail until later implementation tasks add the presentation.
     - Four failures from TODO 001 remain intentionally unresolved.

   Full `dev check` was not run because this checkpoint deliberately adds failing tests for later implementation tasks.

4. Todo check-off

   Checked off only TODO 002 in [todo.md](/workspace/memba/docs/iterations/060-calm-liveview-reconnection-feedback/todo.md:4).

5. Todo structure

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   - The plan explicitly references no ADRs.
   - ADR 0013 permits lower-level Phoenix component tests for LiveView-specific mechanics; these assertions cover encoded LiveView JS commands and rendered component structure.
   - ADR 0015 remains respected by covering the shared LiveView layout component.
   - No acceptance feature files were changed.