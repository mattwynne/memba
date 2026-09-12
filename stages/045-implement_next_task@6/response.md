Implemented and checked off TODO 006: the shared reconnect indicator now has the approved compact, responsive, Memba-branded pill treatment.

1. Selected task

   `006 Implement the approved responsive bottom-centre pill with existing Memba design tokens. Keep state-specific markup minimal and avoid altering the generic <.flash> component used by ordinary messages.`

2. Changes

   - Updated the private shared component in [layouts.ex](/workspace/memba/web/lib/memba_web/components/layouts.ex:507) with:
     - responsive viewport-width constraints;
     - compact pill spacing and typography;
     - paper, sage, and ink design tokens;
     - rounded border, token-based shadow, and backdrop blur;
     - a token-styled 14px spinner.
   - Both client and server states continue to use the same component; only their IDs, selectors, and messages differ.
   - Ordinary flash rendering was unchanged.
   - Added focused presentation coverage in [layouts_test.exs](/workspace/memba/web/test/memba_web/components/layouts_test.exs:369).
   - Added no CSS. Global fixed positioning, safe-area handling, animation, and reduced-motion behaviour remain specifically scoped to TODO 007.

3. Validation

   - Red phase: focused layout suite failed on the missing pill classes as expected.
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs --trace` — passed, 21 tests and 0 failures.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed, 1,221 tests and 0 failures.
   - `PATH="$PWD/bin:$PATH" dev acceptance` — passed with exit status 0.
   - `git diff --check` — passed.
   - The combined `dev check` reached the end of passing acceptance scenarios but exceeded the tool’s 10-minute ceiling before returning its final summary; its quick and acceptance constituent gates both completed successfully when run separately.

4. Todo check-off

   Checked off only TODO 006 in [todo.md](/workspace/memba/docs/iterations/060-calm-liveview-reconnection-feedback/todo.md:8).

5. Todo structure

   No tasks were split, added, removed, or reordered. TODOs 007–010 remain unchecked.

6. ADR conformance

   The plan explicitly references no ADRs. The work remains consistent with ADR 0001’s Phoenix architecture, ADR 0013’s allowance for focused lower-level component tests when inspecting LiveView-specific presentation mechanics, and ADR 0015’s shared LiveView application treatment.