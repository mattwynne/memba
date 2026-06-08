# Problem: Fabro prepare_mix timeouts are opaque

Date: 2026-06-08

## Context

While trying to recover and continue iteration 029 (`docs/iterations/029-membership-admin-invitations/plan.md`), several Fabro implementation runs failed before product work began.

Relevant runs:

- `01KTMGR0205JW0DXRQ7DK80NQ6`: fresh retry from `main`.
- `01KTMRPS7NAY7R5NG7JE0CZS7N`: rescue retry from `rescue/iteration-029-from-01KTK`, which was created from the near-complete previous run branch and merged with current `main`.
- `01KTMH67CQ5X0YKQHP6F6C7MZD`: fresh run from `main` that did get past setup and continued implementing the iteration.

The failing command in both failed runs was:

```text
bash /workspace/memba/.fabro/workflows/iteration-implementation/prepare_mix.sh
```

That script enters `devenv shell` and then runs:

```text
mix local.hex --force
mix local.rebar --force
mix deps.get
```

## Expected standard

Fabro setup failures should make the failing boundary visible enough for an operator to distinguish between:

- sandbox/container startup;
- `devenv shell` entry;
- Mix/Hex/Rebar setup;
- dependency fetching;
- Fabro server or host resource issues.

A retry or rescue path should not require guessing where the 5-minute setup budget was spent.

## What happened

Both failed setup runs timed out at approximately the same boundary:

```text
Setup command failed (exit code -1): bash /workspace/memba/.fabro/workflows/iteration-implementation/prepare_mix.sh
Command timed out
```

Run `01KTMGR0205JW0DXRQ7DK80NQ6` log excerpt:

```text
2026-06-08T21:03:23.850508Z  INFO  Setup started command_count=1
2026-06-08T21:08:24.836586Z ERROR Setup command failed command="bash /workspace/memba/.fabro/workflows/iteration-implementation/prepare_mix.sh" index=0 exit_code=-1 exec_stdout_tail_bytes=0 exec_stderr_tail_bytes=17
```

Run `01KTMRPS7NAY7R5NG7JE0CZS7N` log excerpt:

```text
2026-06-08T23:22:31.799164Z  INFO  Setup started command_count=1
2026-06-08T23:27:33.980351Z ERROR Setup command failed command="bash /workspace/memba/.fabro/workflows/iteration-implementation/prepare_mix.sh" index=0 exit_code=-1 exec_stdout_tail_bytes=0 exec_stderr_tail_bytes=17
```

The only captured stderr was:

```text
Command timed out
```

No output showed whether the script reached `devenv shell`, `mix local.hex`, `mix local.rebar`, or `mix deps.get`.

A different run, `01KTMH67CQ5X0YKQHP6F6C7MZD`, completed the same setup in about 63 seconds, then later spent about 264 seconds in `preflight_sandbox`. This suggests the runtime can be healthy but slow enough to approach the same 300-second timeout budget.

During investigation, `fabro doctor` reported:

```text
Fabro server (health check failed)
```

while `fabro server status` still reported the server process running. This may be related infrastructure degradation, but it is not yet proven as the root cause of the prepare timeouts.

## Impact

- Two retries failed before product work began.
- We wasted operator time and model/runtime budget deciding whether to resume, re-run, or rescue from a previous branch.
- The near-complete iteration 029 implementation could not be cheaply restarted because the rescue run hit the same opaque setup timeout.
- The lack of setup-stage progress markers prevented root-cause diagnosis from the run logs.

## What allowed it to happen

- `prepare_mix.sh` wrapped several potentially slow setup operations in one Fabro prepare command without timestamped progress logging.
- The Fabro prepare timeout is 300 seconds, but no inner step emits durable progress before that timeout.
- The setup command output captured by Fabro did not include enough data to locate the stall.
- The retry/rescue workflow depends on healthy sandbox setup, so setup opacity blocks both normal delivery and recovery.

## Observations

- The failures happened after sandbox clone/initialization succeeded, not during git clone.
- Both failing runs timed out after roughly 5 minutes, matching the configured prepare timeout (`timeout_ms = 300000`).
- The successful run proves the command can complete under the same workflow/image, so the issue appears intermittent or load-sensitive rather than a deterministic script error.
- The successful run's later `preflight_sandbox` duration (~264 seconds) suggests that the current timeout budget may be close to ordinary worst-case setup/preflight durations.
- A lightweight observability improvement was applied in branch `improve-fabro-prepare-observability`, commit `b5807f09` (`fabro: log prepare mix steps`), adding timestamped progress logging to:
  - `.fabro/workflows/iteration-implementation/prepare_mix.sh`
  - `.fabro/workflows/iteration-review/prepare_mix.sh`

## Why this matters

Fabro setup is part of the delivery factory. If it fails opaquely, operators cannot tell whether to retry, resume, rescue from a branch, inspect host resources, or fix a product/dependency issue. That creates repeated waste and makes near-complete iteration recovery unreliable.

## Open questions

- Which inner step actually hangs when `prepare_mix.sh` times out: entering `devenv shell`, Hex/Rebar installation, or `mix deps.get`?
- Is the 300-second prepare timeout appropriate for this image and host under load?
- Did concurrent active Fabro runs or host/container resource pressure contribute to the setup timeouts?
- Why did `fabro doctor` fail the server health check while `fabro server status` reported the server running?
- Should setup and preflight have separate, named time budgets with clearer failure categories?

## Possible prevention ideas

- Keep timestamped prepare-step logging in both implementation and review workflows.
- Consider increasing the prepare timeout, but only after the new logs identify where time is being spent.
- Add a lightweight host/server health check before starting parallel Fabro runs.
- Preserve setup command stdout/stderr tails with enough bytes to include the last successful progress marker.
- If timeouts continue, split `prepare_mix.sh` into multiple Fabro prepare steps or workflow stages so Fabro records the exact failing boundary.
