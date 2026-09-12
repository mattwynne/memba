Implemented and checked off TODO 008.

1. Selected task

   `008 Exercise public, member, and Staff layout rendering to confirm each includes the shared flash group and connection states without duplicating them.`

2. Changes

   Added focused rendering coverage in [layouts_test.exs](/workspace/memba/web/test/memba_web/components/layouts_test.exs:118) for:

   - public `Layouts.app/1`;
   - member `Layouts.club_site/1`;
   - Staff `Layouts.admin/1`.

   The test verifies each rendered layout contains:

   - its supplied content slot;
   - exactly one `#flash-group`;
   - exactly one `#client-error.connection-status`;
   - exactly one `#server-error.connection-status`;
   - exactly two connection-status elements overall, guarding against duplication.

   No production code, configuration, dependencies, or acceptance feature files changed.

3. Validation

   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs --trace`
     - Passed: 22 tests, 0 failures.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: 1,224 tests, 0 failures.
   - `git diff --check`
     - Passed.

   Full `dev check` remains explicitly assigned to TODO 010.

4. Todo check-off

   Checked off only TODO 008 in [todo.md](/workspace/memba/docs/iterations/060-calm-liveview-reconnection-feedback/todo.md:10).

5. Todo structure

   No tasks were split, added, removed, or reordered. TODOs 009 and 010 remain unchecked.

6. ADR conformance

   The plan references no ADR explicitly. This task conforms to accepted ADR 0013 by using focused Phoenix component rendering tests, and ADR 0015 by covering the shared member LiveView layout alongside public and Staff surfaces. No architectural boundary or dependency changed.