# Problem: Fabro focused tests can use stale PGHOST and fail despite Postgres being ready

Date: 2026-06-23

## Context

During Fabro implementation run `01KVSMA9D18M6V47C2ZPQ9S83N` for iteration 044, focused test attempts wasted time on Postgres socket/readiness confusion. The broader `bin/dev` quality gate eventually worked, but direct focused test commands did not.

Relevant paths:

- `bin/dev`
- `bin/mix`
- `.fabro/workflows/iteration-implementation/prompts/implement_next_task.md`
- `.fabro/workflows/iteration-implementation/workflow.fabro`

## Expected standard

Fabro agents should have one clear, reliable command contract for focused tests. Stale environment variables from the sandbox image or host should not cause a focused test command to look for Postgres at the wrong socket path after Postgres has started elsewhere.

## What happened

The implementation agent reported multiple Postgres/readiness detours, including:

```text
The first test attempt hit a devenv Postgres readiness/path issue. I’ll retry via the project wrapper from the repository root, which is the workflow-recommended invocation.
```

```text
Postgres is starting, but the wrapper is checking a stale PGHOST path. I’ll inspect the environment and project dev configuration so validation can run against the actual socket path rather than fail on setup.
```

```text
Focused direct bin/mix test remains blocked by the wrapper’s Postgres readiness check, despite Postgres logging ready. The bin/dev quality gate handles this environment correctly, so I’ll use that as the reliable validation path.
```

Follow-up read-only investigation found:

- the agent environment contained stale baked values:

  ```text
  DEVENV_ROOT=/env
  PGHOST=/tmp/devenv/postgres
  PGPORT=15432
  ```

- Postgres logs showed the actual generated socket path:

  ```text
  /tmp/devenv-1d7df38/postgres/.s.PGSQL.15432
  database system is ready
  ```

- `bin/mix` still failed with:

  ```text
  Postgres did not become ready at PGHOST=/tmp/devenv/postgres PGPORT=15432
  ```

- `PATH="$PWD/bin:$PATH" dev check --quick` later passed.

## Impact

This is a hidden tax on implementation nodes. Agents trying to run focused tests can spend time diagnosing the sandbox database environment instead of validating the product change. In broad tasks, that time contributes to node timeouts; in smaller tasks, it may simply disappear into a longer successful run.

## What allowed it to happen

- `bin/dev` sanitizes stale `PGHOST`/`PGPORT` before entering `devenv`, but `bin/mix` trusts caller-provided `PGHOST`/`PGPORT`.
- The implementation prompt currently advertises both `PATH="$PWD/bin:$PATH" bin/mix ...` and `PATH="$PWD/bin:$PATH" dev ...` as sandbox-safe options.
- There is no first-class `dev test` wrapper for focused tests that uses the same sanitized environment path as `dev check`.
- The sandbox environment can contain stale `DEVENV_*` / `PGHOST` values that point at a non-current generated socket path.

## Observations

- The reliable path in this run was the project `bin/dev` wrapper, not direct `bin/mix`.
- Direct focused tests are useful for fast feedback, so the answer should not be to force every task to run full `dev check` for every edit.
- The problem is a command-contract mismatch: either direct `bin/mix` must be made robust in the sandbox, or agents should stop being told to use it there.

## Why this matters

Focused validation should reduce cycle time. If focused commands are unreliable in Fabro sandboxes, agents either waste time debugging the environment or skip to broader checks earlier than necessary. Both hurt delivery flow.

## Open questions

- Should `bin/mix` sanitize stale Fabro/devenv database variables, or should it explicitly refuse and point agents to `dev test`?
- Is `PGHOST=/tmp/devenv/postgres` baked into the sandbox image, inherited from the host, or produced by a previous setup step?
- What focused-test command should be the documented standard inside Fabro sandboxes?

## Possible prevention ideas

- Add a first-class `bin/dev test [args...]` command that starts Postgres through the same sanitized environment path as `dev check` and then runs `mix test` with supplied args.
- Update `.fabro/workflows/iteration-implementation/prompts/implement_next_task.md` to prefer `PATH="$PWD/bin:$PATH" dev test ...` for focused tests in Fabro sandboxes.
- Harden `bin/mix` to detect stale Fabro `PGHOST`/`DEVENV_*` and fail with an explicit “use `dev test`” message instead of attempting readiness against a stale socket.


## Resolution

Date: 2026-06-23

Root cause: The documented focused-test contract for Fabro sandboxes allowed direct `bin/mix test ...`. Unlike `bin/dev`, `bin/mix` trusts caller-provided `PGHOST`/`PGPORT`, so stale sandbox/devenv values could point focused tests at an old Postgres socket even after the managed Postgres process was ready elsewhere.

Fix applied:

- `bin/dev`: added `dev test [args...]`, a focused Elixir test wrapper that enters the sanitized `bin/dev`/devenv environment, starts Postgres through the same helper path as `dev check`, runs setup, and delegates to `mix test` with the supplied arguments.
- `.fabro/workflows/iteration-implementation/prompts/implement_next_task.md`: changed the Fabro sandbox focused-test guidance to prefer `PATH="$PWD/bin:$PATH" dev test ...` and explicitly avoid direct `bin/mix test ...` because of stale `PGHOST`/`PGPORT` risk.
- `docs/kaizen/2026-06-23-fabro-focused-tests-stale-pghost.md`: recorded this resolution.

Validation:

- `bash -n bin/dev bin/mix` — shell syntax is valid.
- `rg -n 'dev test|direct `bin/mix test|dev_test' bin/dev .fabro/workflows/iteration-implementation/prompts/implement_next_task.md` — confirmed the wrapper and prompt contract are present.

Remaining follow-up:

- Consider hardening `bin/mix` with a specific stale-`PGHOST` diagnostic if agents continue to call it directly despite the prompt.
