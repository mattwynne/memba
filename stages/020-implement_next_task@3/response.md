1. **Selected todo line**
   - `003 Build or refine the browser test lifecycle wrapper so it prepares the test database, starts Phoenix, waits for HTTP readiness, captures useful logs, and tears down reliably.`

2. **Changes made**
   - Added `acceptance-tests/features/support/lifecycle.js`:
     - selects runtime ports;
     - ensures Postgres via `bin/dev up`;
     - resets/prepares the test database and event store;
     - starts Phoenix with `MIX_ENV=test`, `PHX_SERVER=true`, and a dynamic `PORT`;
     - polls HTTP readiness before scenarios run;
     - captures command/Phoenix log tails;
     - terminates Phoenix and managed Postgres services on teardown.
   - Updated `acceptance-tests/features/support/world.js`:
     - added Cucumber `BeforeAll`/`AfterAll` lifecycle hooks;
     - keeps browser context isolation per scenario;
     - captures browser console, page errors, request failures, screenshots, and Phoenix log tails on scenario failure.
   - Added `acceptance-tests/test/lifecycle.test.js`:
     - verifies lifecycle ordering for Postgres, DB setup, Phoenix startup, readiness, and teardown;
     - verifies non-dev-shell commands run through `devenv` on the selected Postgres port;
     - verifies Phoenix readiness timeout diagnostics.
   - No `.feature` files were edited.

3. **Focused validation**
   - `cd acceptance-tests && npm run test:config`
     - Passed: 5 tests, 0 failures.
   - `cd acceptance-tests && npm test -- --dry-run`
     - Exited 0.
     - Still reports undefined future browser steps, as expected for later unchecked tasks.
   - `cd acceptance-tests && npx cucumber-js --name "Visiting the homepage"`
     - Lifecycle exercised DB setup and Phoenix startup/readiness.
     - Failed at browser launch because this sandbox is missing the Playwright Chromium executable:
       - `browserType.launch: Executable doesn't exist ...`
     - This is an environment/browser-install issue, not a lifecycle startup failure.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: 109 tests, 0 failures.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Build or refine the browser test lifecycle wrapper so it prepares the test database, starts Phoenix, waits for HTTP readiness, captures useful logs, and tears down reliably.`
   - To:
     - `- [x] 003 Build or refine the browser test lifecycle wrapper so it prepares the test database, starts Phoenix, waits for HTTP readiness, captures useful logs, and tears down reliably.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0003: kept shared `.feature` files as the behavioral contract; added only whole-application/browser harness plumbing.
   - ADR 0010: did not alter Elixir/domain Cucumber discovery or filtering.
   - ADR 0013: did not replace or disturb PhoenixTest-based web test architecture.
   - No new HTTP client dependency was introduced.