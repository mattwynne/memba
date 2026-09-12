Implemented and checked off TODO 005. The reconnect states now use one shared connection-status component while ordinary flashes remain unchanged.

1. Selected task

   `005 Replace only the client/server reconnect uses of <.flash> in MembaWeb.Layouts.flash_group/1 with a shared connection-status presentation that preserves the existing targeted phx-disconnected classes and phx-connected hiding.`

2. Changes

   In [layouts.ex](/workspace/memba/web/lib/memba_web/components/layouts.ex:477):

   - Replaced the two reconnect-specific `<.flash>` calls with a private `<.connection_status>` component.
   - Preserved the distinct `.phx-client-error` and `.phx-server-error` selectors.
   - Preserved automatic hiding and restoration of the `hidden` attribute on reconnection.
   - Added the approved exact client/server wording, polite status semantics, and decorative spinner markup.
   - Left the generic informational and error flash calls and `CoreComponents.flash/1` unchanged.
   - Added no CSS; visual styling remains scoped to TODOs 006–007.

3. Validation

   - Red phase: focused layout suite initially reported 20 tests, 6 expected failures.
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs --trace` — passed, 20 tests and 0 failures.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed, 1,220 tests and 0 failures.
   - `PATH="$PWD/bin:$PATH" dev acceptance` — passed with exit status 0.
   - `git diff --check` — passed.

   A combined `dev check` reached the end of passing acceptance scenarios but exceeded the terminal tool’s 10-minute deadline before returning its summary. Its two constituent gates—precommit via `dev check --quick` and browser acceptance via `dev acceptance`—were therefore run separately and both passed.

4. Todo check-off

   Checked off only task 005 in [todo.md](/workspace/memba/docs/iterations/060-calm-liveview-reconnection-feedback/todo.md:7).

5. Todo structure

   No tasks were split, added, removed, or reordered. TODOs 006–010 remain unchecked.

6. ADR conformance

   The plan explicitly references no ADRs. The implementation conforms to ADR 0013 by using focused lower-level component coverage for LiveView-specific mechanics, and to ADR 0015 by keeping the treatment in the shared LiveView layout. ADR 0023 does not require transient connection feedback to become URL-addressable state.