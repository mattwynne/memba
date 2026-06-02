# Problem: `dev check` cannot run beside `dev up`

Date: 2026-05-31

## Context

While preparing `docs/design-gap-analysis/index.html`, I ran the app locally with `./bin/dev up` so Playwright could capture screenshots from `http://localhost:4000/`. After the report was written, I ran the required project quality gate, `./bin/dev check`.

The expected workflow was:

1. Keep a local app server available for browser inspection and screenshots.
2. Run the independent quality gate before handing over.
3. Have both commands use isolated runtime resources, or at least fail with a clear instruction if they cannot.

Matt confirmed the desired standard: these commands should be able to run side by side.

## Expected standard

`./bin/dev` already tries to choose a free Postgres port when entering its devenv shell:

```bash
memba_postgres_port="${MEMBA_POSTGRES_PORT:-$(find_free_port)}"
```

That suggests multiple dev-command invocations should be able to avoid port conflicts. `dev check` should therefore be safe to run while `dev up` is still serving the app, or should have an explicit guardrail explaining why not.

## What happened

With `./bin/dev up` still running, `./bin/dev check` failed before tests ran. The command attempted to start Postgres and reported repeated lock-file errors against the shared Postgres data directory:

```text
FATAL:  lock file "postmaster.pid" already exists
HINT:  Is another postmaster (PID 76364) running in data directory "/Users/matt/git/mattwynne/memba/.devenv/state/postgres"?
...
FATAL:  the database system is shutting down
Postgres did not become ready at PGHOST=/tmp/devenv-a03f43c/postgres PGPORT=5432
```

After I stopped the manually-started app/Postgres processes and retried, `./bin/dev check` passed:

```text
198 tests, 0 failures
```

## Impact

This slowed the handoff and made the quality-gate failure look like a possible product/test failure until the local service conflict was diagnosed. It also creates avoidable friction for any workflow where a developer keeps the app running while asking an agent or another terminal to run checks.

Severity: minor friction today, but likely repeated. It can waste time and reduce confidence in `dev check` failures.

## What allowed it to happen

The command appears to isolate the port (`MEMBA_POSTGRES_PORT`) but not the full Postgres/process state. The observed failure references a shared data directory:

```text
.devenv/state/postgres
```

So a side-by-side invocation can still collide on Postgres runtime state even if it has a different intended port. The script also does not detect “another Memba dev server is running” and explain the safe path.

## Observations

- `./bin/dev up` and `./bin/dev check` both go through `start_services` in `bin/dev`.
- `start_services` calls `devenv_with_postgres_port processes down` before starting Postgres when it thinks the current `PGHOST`/`PGPORT` is not ready.
- The failure surfaced as low-level Postgres lock-file output rather than a purpose-built dev-script message.
- The check succeeded after stopping the app/Postgres processes, so the product code and tests were not the cause.
- Matt wants these commands to run side by side rather than requiring the app to be stopped.

## Why this matters

Developers and agents often need a browser session open while running tests or checks. If the standard quality gate cannot run independently of a local server, people have to remember a manual sequencing rule that is not encoded in tooling. That increases context switching and makes failures less trustworthy.

## Open questions

- Should `dev check` use a fully isolated Postgres data directory/process-compose runtime, not just a free port?
- Should `dev up` and `dev check` share a running Postgres when it is healthy instead of trying to start or stop services independently?
- How much of this behaviour comes from devenv/process-compose defaults versus `bin/dev` wrapper choices?

## Possible prevention ideas

- Give each `./bin/dev` invocation that selects a free port an isolated Postgres state directory as well as an isolated port.
- Or teach `dev check` to reuse an existing healthy project Postgres service instead of bringing its own service up/down.
- Add a preflight check that detects the current impossible side-by-side state and prints a clear message until true isolation is implemented.
- Add a regression test or script smoke test that starts `dev up` and then runs `dev check` concurrently enough to prove the desired contract.

## Resolution

Date: 2026-06-01

Root cause: `bin/dev` was partially reimplementing process-compose ownership and readiness. `dev check` used a custom adoption path plus an `EXIT` trap that could stop a Postgres service it had not started, and the script reset process-compose before starting Postgres instead of asking process-compose for the `postgres` service state.

Fix applied:

- `bin/dev`: simplified Postgres startup to use `devenv processes status postgres`, `devenv processes up -d postgres`, and `devenv processes wait`; removed custom pid-file adoption, owner tracking, `pg_ctl` fallback, and the public `dev postgres` command.
- `bin/dev`: `dev check`, `dev ci`, and `sandbox-check` now ensure Postgres is running but do not stop process-compose services when they finish; `dev up` remains the command that starts Postgres plus Phoenix and stops services on exit.
- `docs/kaizen/2026-05-31-dev-check-cannot-run-beside-dev-up.md`: recorded the root cause, simplification, validation, and follow-up.

Validation:

- `./bin/dev check` — passed, 315 tests, 0 failures.
- Running `./bin/dev check` again with Postgres already managed by process-compose — passed, 315 tests, 0 failures; process-compose kept the same Postgres PID.

Remaining follow-up:

- Add a dedicated automated shell smoke test for `dev up` + `dev check` side-by-side if this workflow keeps regressing.
