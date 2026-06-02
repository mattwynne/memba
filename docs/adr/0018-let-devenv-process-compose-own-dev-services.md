# 18. Let devenv/process-compose own development services

Date: 2026-06-02

## Status

accepted

## Context

`./bin/dev check` failed when a local development server was already running. The failure appeared as a Postgres lock-file problem in `.devenv/state/postgres`.

An attempted fix made `bin/dev` more complicated: it inspected Postgres pid files, adopted running Postgres processes, tracked which command had started services, waited for shutdown manually, and used `pg_ctl` as a fallback. That was the wrong lesson. It duplicated responsibility that already belongs to devenv/process-compose.

The actual design mistake was treating Postgres as a process for `bin/dev` to manage directly, instead of treating it as the `postgres` service managed by devenv/process-compose.

## Decision

Keep `bin/dev` as a thin command wrapper. Do not reimplement process-compose service ownership, readiness, restart, or pid-file handling in shell.

Use devenv/process-compose primitives for development services. Local devenv documentation is vendored under [`docs/tools/devenv/`](../tools/devenv/README.md); consult it before changing service orchestration.

- `devenv processes up -d postgres` to start only the Postgres service when a command needs it.
- `devenv processes status postgres` to ask whether process-compose already has the service running.
- `devenv processes wait` to wait for service readiness.
- `devenv processes down` to stop development services when explicitly requested or when `dev up` exits.

`dev up` is the normal interactive command: it starts Postgres, migrates databases, and runs Phoenix.

`dev check`, `dev ci`, and `sandbox-check` may ensure Postgres is running, but they must not stop process-compose services when they finish. They are quality gates, not service owners.

Do not add a public `dev postgres` command unless there is a clear user-facing workflow that needs it. If a one-off command needs only Postgres, call the relevant devenv/process-compose command or add a narrowly named helper with a documented purpose.

## Consequences

`bin/dev` stays simpler and easier to trust. Its job is orchestration of project commands, not low-level process management.

When service behaviour is surprising, the first place to look is devenv/process-compose configuration and commands, not hand-written pid-file logic.

Quality gates can run while `dev up` is serving the app, because they ensure the required service exists without claiming ownership of it.

We rely more directly on devenv/process-compose semantics. That is acceptable because it is the tool already selected to manage development services. If those semantics are unclear, document or test them instead of wrapping them in custom shell machinery.
