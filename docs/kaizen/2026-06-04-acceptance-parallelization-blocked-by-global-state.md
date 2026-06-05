# Problem: Browser acceptance tests are slow, and shared global state blocks the parallelism that should speed them up

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

The quality gate should provide fast enough feedback for everyday development. When browser acceptance tests dominate the gate, we should be able to use Cucumber's worker parallelism to reduce wall-clock time, provided scenarios use isolated data and do not race over shared test-support state.

## What happened

Cucumber JS supports parallel execution with `--parallel N`, and that is the speedup path we want. The current acceptance harness is not safe to parallelize by simply adding that flag because scenario isolation depends on global reset state.

The current harness relies on shared global state:

- One acceptance app lifecycle is started for the suite.
- A shared test database/event-store is dropped, recreated, migrated, and initialized during lifecycle startup.
- Each scenario performs a global reset through `/dev/test-support/reset`.
- Test mailbox and provider configuration APIs appear process-wide rather than scenario-scoped.

Running multiple Cucumber workers against this model would make workers race over the same app, same database, same mailbox, same provider configuration, and same reset endpoint.

## Impact

Acceptance tests are the long pole in `dev check`. If scenario data were isolated, Cucumber workers could run scenarios concurrently and reduce the wall-clock time of the browser acceptance stage. Because the current harness depends on shared global state, that speedup is blocked until the harness is made parallel-safe.

## What allowed it to happen

The acceptance harness optimizes for serial isolation by resetting shared state before each scenario. That makes individual scenarios easy to write, but it creates a hidden coupling: scenario isolation depends on no other scenario running at the same time.

The harness does not currently have a standard for scenario-scoped data isolation, so tests that are individually isolated in serial become coupled when run concurrently.

## Observations

- This is delivery-pipeline friction, not a product bug.
- The slow part of `dev check` is browser acceptance, not ExUnit/precommit.
- The current global reset model is incompatible with safe parallel workers.
- The desired outcome is to make `cucumber-js --parallel N` safe and useful for the browser acceptance suite.
- A likely improvement path is “single shared app, isolated scenario data”: stop resetting global state before every scenario, give each scenario unique clubs/people/email addresses, and scope mailbox/test-support APIs by scenario.

## Why this matters

Slow acceptance feedback increases waiting time and discourages frequent full checks. Parallel execution is the intended improvement path, but attempting it before removing the shared-state coupling would introduce flakes that are harder to diagnose than the current slowness.

## Open questions

- Which scenario data can be made unique with naming conventions alone?
- Which test-support endpoints need explicit scenario IDs?
- Can the mailbox API be filtered by scenario/run without changing product code paths?
- Which current scenarios genuinely require a clean empty system, and can they be rewritten to assert on scoped data instead?
- What level of Cucumber parallelism gives the best speedup without overloading Phoenix, Postgres, or Playwright?

## Improvement ideas

- Add a documented acceptance parallelization plan that targets safe `cucumber-js --parallel N` execution.
- Introduce a scenario/run ID in the Cucumber world and propagate it into generated names, emails, mailbox filtering, and test-support APIs.
- Replace global reset-before-each-scenario with scoped data factories plus cleanup only where necessary.
- Identify and rewrite scenarios that require an empty system so they assert on their own scoped data instead.
- Measure `--parallel 2` after scenario-scoped isolation is in place, then tune worker count for the best wall-clock speedup without overloading Phoenix, Postgres, or Playwright.
