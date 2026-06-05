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

## Resolution plan: isolated acceptance shards

Date: 2026-06-04

Root cause: The shared-app parallelization spike showed that making one Phoenix app safe for concurrent Cucumber workers requires broad aliasing of names, slugs, emails, mailbox assertions, provider state, and smoke-test fixtures. That added too much harness complexity before reliability was proven. A safer path is to preserve today's serial scenario model and run multiple isolated serial shards instead.

Plan:

1. Run N independent acceptance processes concurrently. Each shard uses the same Postgres server/port but gets a unique `MIX_TEST_PARTITION`, unique Phoenix `ACCEPTANCE_PORT`, its own Phoenix BEAM process, its own Swoosh mailbox, and its own app-global provider configuration.
2. Keep Cucumber serial inside each shard. Use Cucumber's `--shard i/n` to divide scenarios between processes rather than `--parallel N` workers inside one process.
3. Preserve existing Gherkin and fixture assumptions. Keep per-scenario `/dev/test-support/reset`, literal club names, literal slugs such as `kmc`, fixed smoke-test fixtures, and fixed staff/member emails within each isolated shard.
4. Add or verify lifecycle tests proving `MIX_TEST_PARTITION` propagates into all database setup commands and the Phoenix server command.
5. Avoid asset build races by building assets once in a parent/orchestrator step, then letting shard lifecycles skip asset building with a new option such as `ACCEPTANCE_SKIP_ASSET_BUILD=1`.
6. Avoid Postgres startup races by having the parent/orchestrator start/wait for Postgres once before launching shard processes.
7. Add a sharded runner, probably `bin/dev acceptance-sharded 2`, that launches commands shaped like:

   ```bash
   MIX_TEST_PARTITION=_acceptance_1 ACCEPTANCE_PORT=4101 npm test -- --shard 1/2
   MIX_TEST_PARTITION=_acceptance_2 ACCEPTANCE_PORT=4102 npm test -- --shard 2/2
   ```

   The runner should prefix logs by shard and exit non-zero if any shard fails.
8. Measure `time bin/dev acceptance` against `time bin/dev acceptance-sharded 2`. Try 3 shards only if 2 is stable and faster.
9. Keep `bin/dev check` on the serial acceptance suite until sharded acceptance is demonstrably reliable. Once stable, switch `dev check` to the sharded command while keeping `bin/dev acceptance` as a serial escape hatch.

Risks and checks:

- Partitioned database setup should be straightforward because `web/config/test.exs` already names test databases with `MIX_TEST_PARTITION`; verify this rather than assuming it.
- Concurrent database setup may stress Postgres but should not conflict if partitions are unique.
- Concurrent asset builds can race on shared output files; prevent this explicitly.
- Cucumber shards may not balance scenario duration evenly, so wall-clock gains may be less than the shard count suggests.
- Multiple Phoenix/Playwright processes may overload CPU or memory; tune shard count empirically.

Status: recommended next approach after reverting the shared-app aliasing spike.

## Progress update: serial suite speedups before sharding

Date: 2026-06-05

Relevant work completed before implementing isolated shards:

- Batched acceptance setup through Elixir RPC helpers, so grouped Given steps no longer create people/members one process or one browser interaction at a time.
- Converted non-behavioural Given setup for slugs, smoke-test club data, and person email addresses away from staff-browser setup and into application-level setup helpers.
- Reused signed-in staff/member harness contexts within each scenario, removing repeated browser contexts and magic-link login work for consecutive assertions by the same actor.
- Reused one Chromium browser for the full Cucumber run while keeping a fresh browser context/page per scenario for isolation.
- Avoided redundant page opens for repeated assertions where the browser is already on the correct page.

Validation:

- `cd acceptance-tests && npm run test:config` — passed.
- `cd acceptance-tests && ACCEPTANCE_LOG_PROGRESS=1 ACCEPTANCE_SLOW_STEP_THRESHOLD_MS=1000 npm test` — passed, 34 scenarios / 215 steps, about 1m01s.
- `dev check` — passed, including 511 ExUnit tests and the browser acceptance suite.

Impact:

- The serial browser acceptance suite dropped from roughly 1m47–1m51 to roughly 1m01 on local runs.
- This reduces the urgency of sharding, but does not remove the original global-state blocker: the suite still performs per-scenario global reset and remains unsafe for Cucumber worker parallelism inside one shared app.
- The isolated-shards plan remains the safer parallelization path if the serial suite again becomes the long pole.
