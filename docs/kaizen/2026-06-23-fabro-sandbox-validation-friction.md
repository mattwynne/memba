# Problem: Fabro sandbox validation friction wastes implementation node time

Date: 2026-06-23

## Context

While delivering iteration 044 with Fabro implementation run `01KVSMA9D18M6V47C2ZPQ9S83N`, the selected implementation task was too coarse and eventually timed out. During diagnosis, we also observed several sandbox/workflow frictions that consumed implementation-node time.

This note captures the sandbox friction separately from the coarse-task root cause recorded in:

- `docs/kaizen/2026-06-23-coarse-fabro-todos-timeout.md`

Relevant commands and paths:

```bash
bin/dev fabro deliver docs/iterations/044-conversation-page-alignment/plan.md --poll-interval 30
fabro events 01KVSMA9D18M6V47C2ZPQ9S83N --json
fabro logs 01KVSMA9D18M6V47C2ZPQ9S83N
```

## Expected standard

Fabro sandbox validation should be boring and predictable:

- formatting should be able to rewrite touched files;
- focused tests should have a clear, reliable database environment;
- project wrappers should avoid stale host environment leakage;
- local stream failures should not make remote run state ambiguous;
- guardrails such as read-guards should be understandable and should not surprise agents at the end of a long task.

## What happened

Several sources of sandbox/workflow friction appeared during the implementation node:

### Local stream timed out while remote run continued

The local `bin/dev fabro deliver` process lost the streaming response while the remote run continued:

```text
error decoding response body
error reading a body from connection
timed out
```

This forced manual monitoring to distinguish a local stream failure from a failed remote implementation.

### Formatting was blocked by file ownership

The agent reported that `mix format` could not rewrite touched files because files in the sandbox were root-owned. It had to correct ownership or work around formatting before normal checks could run.

This is delivery machinery friction, not product feedback: formatting should not depend on an agent discovering and correcting ownership during implementation.

### Focused tests hit Postgres/socket confusion

Focused direct test attempts hit Postgres environment/socket confusion. The agent reported stale `PGHOST` / socket-path readiness issues and eventually relied on the project `bin/dev` quality gate as the reliable path.

The relevant agent messages included:

```text
The first test attempt hit a devenv Postgres readiness/path issue. I’ll retry via the project wrapper from the repository root, which is the workflow-recommended invocation.
```

```text
Postgres is starting, but the wrapper is checking a stale PGHOST path. I’ll inspect the environment and project dev configuration so validation can run against the actual socket path rather than fail on setup.
```

```text
Focused direct bin/mix test remains blocked by the wrapper’s Postgres readiness check, despite Postgres logging ready. The bin/dev quality gate handles this environment correctly, so I’ll use that as the reliable validation path.
```

### Read-guard blocked a late todo check-off attempt

Fabro's read-guard blocked a `todo.md` check-off attempt because the agent had not read the exact active path first:

```text
Write blocked: file not read by agent path=/repos/mattwynne/memba/docs/iterations/044-conversation-page-alignment/todo.md
```

The agent read the file and retried successfully, but this happened near the timeout boundary and consumed additional node time.

## Impact

The immediate run failure was caused by an oversized task exhausting the node timeout, but the sandbox friction reduced the available budget for product work and validation.

This is likely a recurring hidden tax. In smaller runs, the same ownership and Postgres/socket issues may merely slow implementation and disappear into successful logs. In broad tasks, the accumulated delay becomes visible as a hard timeout.

## What allowed it to happen

- Sandbox preflight did not catch file ownership or formatter writeability problems before agent work began.
- The validation environment contract is not obvious enough: direct focused commands, project wrappers, `PGHOST`, generated socket paths, and Postgres readiness can disagree.
- Local streaming failure handling left the operator to infer that the remote run was still alive.
- The read-guard error was technically protective, but it appeared late in the task and required extra recovery steps for a routine todo check-off.

## Observations

- The project wrapper `bin/dev` was ultimately the reliable validation path, but the agent spent time discovering that.
- The friction is independent of the product code being implemented. It could affect any future Fabro task that runs formatting or focused tests.
- These issues are easy to undercount because they do not always fail a run; they often only lengthen nodes.
- The root-owned-file symptom and stale `PGHOST`/socket symptom are distinct from the coarse-task root cause and should be investigated separately.

## Why this matters

Implementation node time should be spent on product changes and meaningful validation feedback, not on rediscovering sandbox environment quirks. Hidden sandbox friction lowers delivery throughput, increases variance, and makes otherwise healthy runs more likely to hit timeouts.

## Open questions

- Why are sandbox files root-owned in a way that can block `mix format` for the shell user?
- Which commands are safe and supported inside the Fabro sandbox: direct `bin/mix`, direct `mix`, `PATH="$PWD/bin:$PATH" dev ...`, or only selected wrappers?
- Why do focused direct test commands see stale `PGHOST` / socket readiness issues while `bin/dev` can eventually validate?
- Should sandbox setup sanitize `PGHOST` and related Postgres variables more aggressively before any agent command runs?
- Is the local streaming timeout a Fabro client/server timeout setting, network issue, or long-poll behaviour that should be handled by `bin/dev fabro deliver`?

## Possible prevention ideas

- Add a sandbox preflight check for writable tracked files and formatter ability on a harmless copied fixture.
- Add a small Postgres/test smoke in sandbox preflight that uses the same command contract agents should use later.
- Document and/or enforce the reliable validation path in the sandbox: prefer `PATH="$PWD/bin:$PATH" dev ...` and avoid direct focused commands unless the environment contract is clear.
- Make `bin/dev fabro deliver` detect stream timeout separately from remote run failure and print the run ID plus follow-up monitoring command.
- Consider a specific helper for checking off `todo.md` that handles read-guard expectations safely, or make the implement prompt read the exact todo path immediately before check-off.
