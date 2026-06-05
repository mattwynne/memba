# Problem: Acceptance tests cannot safely run in parallel because scenarios share global state

Date: 2026-06-04

## Context

We were checking whether browser acceptance tests are the long pole in `bin/dev check`, then considering whether Cucumber acceptance tests could be parallelized.

Relevant files inspected:

- `bin/dev` runs `precommit` and then `acceptance` for normal `dev check`.
- `acceptance-tests/cucumber.js` has no Cucumber `parallel` setting.
- `acceptance-tests/features/support/world.js` starts one browser acceptance lifecycle in `BeforeAll` and calls `/dev/test-support/reset` before every scenario.
- `acceptance-tests/features/support/lifecycle.js` manages Phoenix, database setup, Postgres, assets, and app readiness for the acceptance suite.

Measured locally during the investigation:

- `bin/dev check --quick`: about 9.9 seconds wall-clock, with ExUnit reporting 8.3 seconds.
- `bin/dev acceptance`: about 203 seconds wall-clock on a failing run, with Cucumber reporting 2m22s executing steps.

## Expected standard

The quality gate should provide fast enough feedback for everyday development. If browser acceptance tests dominate the gate, the test harness should make safe parallelization either available or clearly ruled out.

## What happened

Cucumber JS supports parallel execution with `--parallel N`, but the current acceptance harness is not safe to parallelize by simply adding that flag.

The current harness relies on shared global state:

- One acceptance app lifecycle is started for the suite.
- A shared test database/event-store is dropped, recreated, migrated, and initialized during lifecycle startup.
- Each scenario performs a global reset through `/dev/test-support/reset`.
- Test mailbox and provider configuration APIs appear process-wide rather than scenario-scoped.

Running multiple Cucumber workers against this model would make workers race over the same app, same database, same mailbox, same provider configuration, and same reset endpoint.

## Impact

Acceptance tests are the long pole in `dev check`, but the obvious Cucumber parallel flag is unsafe. This keeps the local quality gate slow and makes future speedups require harness design work rather than a small config change.

## What allowed it to happen

The acceptance harness optimizes for serial isolation by resetting shared state before each scenario. That makes individual scenarios easy to write, but it creates a hidden coupling: scenario isolation depends on no other scenario running at the same time.

The harness does not currently have a guardrail that prevents accidental `--parallel` use or a standard for scenario-scoped data isolation.

## Observations

- This is delivery-pipeline friction, not a product bug.
- The slow part of `dev check` is browser acceptance, not ExUnit/precommit.
- The current global reset model is incompatible with safe parallel workers.
- A likely improvement path is “single shared app, isolated scenario data”: stop resetting global state before every scenario, give each scenario unique clubs/people/email addresses, and scope mailbox/test-support APIs by scenario.
- A safer short-term guardrail may be to make the harness detect Cucumber parallel mode and fail with a clear error until isolation is implemented.

## Why this matters

Slow acceptance feedback increases waiting time and discourages frequent full checks. A naive attempt to parallelize could introduce flakes that are harder to diagnose than the current slowness.

## Open questions

- Which scenario data can be made unique with naming conventions alone?
- Which test-support endpoints need explicit scenario IDs?
- Can the mailbox API be filtered by scenario/run without changing product code paths?
- Which current scenarios genuinely require a clean empty system, and can they be rewritten to assert on scoped data instead?
- What level of Cucumber parallelism gives the best speedup without overloading Phoenix, Postgres, or Playwright?

## Possible prevention ideas

- Add a documented acceptance parallelization plan before changing `cucumber.js`.
- Add a guardrail that fails fast if Cucumber parallel mode is enabled while global reset remains in use.
- Introduce a scenario/run ID in the Cucumber world and propagate it into generated names, emails, mailbox filtering, and test-support APIs.
- Replace global reset-before-each-scenario with scoped data factories plus cleanup only where necessary.
- Measure `--parallel 2` only after scenario-scoped isolation is in place.

## Resolution

Date: 2026-06-04

Root cause: The browser acceptance harness still isolates scenarios by resetting shared suite-level state, but there was no explicit guardrail preventing Cucumber's parallel worker mode from being used against that shared state.

Fix applied:

- `acceptance-tests/features/support/parallel_guard.js`: added a small guard that detects Cucumber worker processes through `CUCUMBER_PARALLEL=true` and explains why parallel acceptance is currently unsafe.
- `acceptance-tests/features/support/world.js`: runs the guard before starting the Phoenix browser acceptance lifecycle, so `--parallel` fails before touching the shared app/database lifecycle.
- `acceptance-tests/test/cucumber_config.test.js`: covers both the failing parallel-worker case and the normal serial case.

Validation:

- `cd acceptance-tests && npm run test:config` — passed, 49 tests.
- `bin/dev check --quick` — blocked before project tests by existing `memba_test` database connections: PostgreSQL reported 52 other sessions using the database.
- `MEMBA_POSTGRES_PORT=15433 bin/dev check --quick` — same database-in-use failure, so the full local gate could not complete in the current environment.

Remaining follow-up:

- Implement scenario-scoped data isolation before enabling Cucumber parallelism.
- Re-run `bin/dev check --quick` or full `bin/dev check` once the existing test database sessions have been cleared.
