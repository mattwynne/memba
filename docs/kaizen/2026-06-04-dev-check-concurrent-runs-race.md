# Problem: Concurrent `dev check` runs race over shared test resources

Date: 2026-06-04

## Context

We were discussing whether multiple coding agents should be able to run the project's required local quality gate at the same time.

Relevant workflow step: agents are instructed to run `dev check` after code, config, dependency, migration, acceptance-test, or app-behaviour changes.

Matt supplied the immediate prevention direction: "add the lock. you can install flock with devenv if you want."

## Expected standard

`dev check` should give a reliable local quality signal. If multiple agents are working in the repository, one agent's check should not corrupt, interrupt, or blur another agent's check result.

If concurrent full checks are not safe, the command or workflow should make that constraint explicit and enforce it before destructive/shared setup begins.

## What happened

Inspection showed that the default `dev check` path is not concurrency-safe:

- `bin/dev check` runs `precommit` and then browser `acceptance` unless `--quick` is passed.
- `precommit` runs `mix precommit` in `web/`.
- `web/mix.exs` defines `precommit` to include `test`, and the `test` alias drops and recreates the test database before running tests.
- `acceptance-tests/features/support/lifecycle.js` also drops and recreates the test database/event store before browser acceptance starts.
- The default test database is `memba_test#{System.get_env("MIX_TEST_PARTITION")}` in `web/config/test.exs`, so normal runs without a unique partition share the same database.
- The browser acceptance lifecycle also uses shared ports/state unless explicitly isolated.

This means two default `dev check` processes can run destructive setup against the same database and acceptance environment at the same time.

## Impact

Concurrent agent checks can produce false failures, mask the real cause of a failure, waste repair effort, and reduce trust in the mandatory quality gate. The risk is highest in multi-agent/Fabro workflows where more than one agent may independently follow the instruction to finish by running `dev check`.

## What allowed it to happen

The workflow requires agents to run `dev check`, but the command does not advertise or enforce a single-run constraint. The test and acceptance setup paths perform destructive global resets against shared default resources, while the orchestration instructions do not reserve those resources or route full checks through a single owner.

The deeper system weakness is a missing guardrail around a shared validation boundary: the command assumes exclusive access to the default test database, event store, ports, and acceptance lifecycle, but nothing prevents another agent from entering the same boundary concurrently.

## Observations

- This is delivery-machinery friction, not an ordinary product bug.
- The current acceptance parallelization note already records that browser acceptance depends on shared global state and should stay serial until isolated shards are reliable.
- Serializing the full `dev check` is a pragmatic guardrail for today's shared-state harness.
- True concurrent full checks would require isolated resources per agent or per check run.

## Why this matters

The local quality gate is supposed to be the trusted final signal before handoff. If the gate can fail because another agent happened to run it at the same time, repair agents may chase harness races instead of product regressions, and successful work may be delayed or misdiagnosed.

## Open questions

- Should the lock cover only `dev check`, or also `dev ci`, `dev acceptance`, and any workflow nodes that invoke those commands directly?
- Should lock waiting be the default, or should agent/Fabro contexts fail fast with a clear message when another full check is already running?
- Is a repo-local lock enough, or do Fabro worktrees/sandboxes need a shared lock path when they target the same Postgres instance?

## Possible prevention ideas

- Add an explicit lock around full shared-resource gates such as `dev check` and possibly `dev ci`.
- Print a clear message when waiting for or failing on the lock, so agents do not mistake serialization for a hang.
- For future parallelism, give each agent/check run isolated `MIX_TEST_PARTITION`, database/event store, Phoenix port, and acceptance lifecycle.
- Update multi-agent workflow guidance so targeted tests can run independently, but the full `dev check` is owned by one finalizing agent unless isolation is configured.

## Resolution

Date: 2026-06-09

Root cause: `dev check`, `dev ci`, `precommit`, `acceptance`, and setup shared destructive test resources, but the command wrapper did not serialize access to those resources.

Fix applied:

- `bin/dev`: added a repo/tooling quality-gate lock keyed by the configured Postgres port, with stale-lock cleanup and waiting messages.
- `bin/dev`: routes `check`, `ci`, `precommit`, `acceptance`, and setup through `with_quality_gate_lock`, while allowing nested calls via `MEMBA_QUALITY_GATE_LOCK_HELD` so one `dev check` does not deadlock itself.

Validation:

- Existing evidence: `bin/dev` now contains `quality_gate_lock_*` helpers and wraps the shared-resource quality gates.
- No command rerun for this backfill; this change only records the already-applied resolution.

Remaining follow-up:

- True parallel full checks still require isolated databases, event stores, ports, and acceptance lifecycle per run. The current fix intentionally serializes the shared default harness.
