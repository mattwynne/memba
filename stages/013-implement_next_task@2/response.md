Implemented the next unchecked task.

1. **Selected todo line**
   - `002 Add browser routes under the existing browser pipeline:`

2. **Changes made**
   - Added browser LiveView routes in `web/lib/memba_web/router.ex` under the existing `:browser` pipeline:
     - `live "/clubs", ClubsLive.Index`
     - `live "/clubs/:club_id", ClubsLive.Show`
     - `live "/messages/:message_id", MessagesLive.Show`
   - Added minimal LiveView target modules so the router compiles cleanly:
     - `web/lib/memba_web/live/clubs_live/index.ex`
     - `web/lib/memba_web/live/clubs_live/show.ex`
     - `web/lib/memba_web/live/messages_live/show.ex`
   - Added route coverage in:
     - `web/test/memba_web/router_test.exs`
   - The new tests assert each route:
     - resolves via `Phoenix.Router.route_info/4`;
     - uses `Phoenix.LiveView.Plug`;
     - is routed through `[:browser]`;
     - points at the expected LiveView module;
     - captures expected path params.

3. **Focused validation**
   - `cd web && mix format ...`
     - Passed.
   - `cd web && MIX_ENV=test mix compile --warnings-as-errors`
     - Passed.
   - Focused router test run:
     - `cd web && MIX_ENV=test mix run --no-start -e 'ExUnit.start(); Code.require_file("test/memba_web/router_test.exs"); %{failures: failures} = ExUnit.run(); if failures != 0, do: System.halt(1)'`
     - Passed: `3 tests, 0 failures`.
   - Required broader check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Ran successfully through compile and test execution, but failed with the expected remaining TDD failures from task 001:
       - missing `#clubs-index`;
       - missing `#message-show` with message content.
     - Result: `98 tests, 2 failures`.
     - These failures are for later LiveView implementation work in task 005, not route registration.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Add browser routes under the existing browser pipeline:`
   - To:
     - `- [x] 002 Add browser routes under the existing browser pipeline:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0010 respected: no shared `*.feature` files were edited.
   - ADR 0013 respected: existing PhoenixTest browser coverage remains intact; this task added focused lower-level router tests appropriate to route configuration.
   - Phoenix routing guidance followed: routes were added inside the existing `scope "/", MembaWeb` browser scope without extra aliases.