# Problem: bin/dev fabro deliver stream timeout leaves remote run state ambiguous

Date: 2026-06-23

## Context

We launched Fabro delivery for iteration 044:

```bash
bin/dev fabro deliver docs/iterations/044-conversation-page-alignment/plan.md --poll-interval 30
```

The wrapper marked the iteration `implementing` and started implementation run `01KVSMA9D18M6V47C2ZPQ9S83N`.

Relevant paths:

- `bin/dev`
- `.fabro/workflows/iteration-implementation/workflow.fabro`

## Expected standard

If the local client loses the streaming response while a remote Fabro run continues, `bin/dev fabro deliver` should distinguish local stream failure from remote workflow failure. It should preserve WIP state when the remote run is still active and print the run ID plus exact monitoring/recovery commands.

## What happened

The local `bin/dev fabro deliver` process lost the response stream while the remote implementation run continued:

```text
error decoding response body
error reading a body from connection
timed out
```

The remote run was still active. Manual inspection showed it continued executing and later failed inside `implement_next_task` after a node timeout.

Because the local wrapper treated the non-zero `fabro run` exit as implementation workflow failure, it entered failure handling even though the remote run had not actually stopped. It did not have a structured run-id-aware recovery path for this class of client/stream error.

## Impact

The operator had to manually determine whether implementation had failed or whether only the local stream had failed. That required preserving the run ID from output, inspecting remote status, and starting a separate monitor.

This creates unnecessary uncertainty around the WIP slot and risks wrong recovery actions, such as rolling back iteration state while a remote implementation is still running.

## What allowed it to happen

- `_fabro_deliver` runs `fabro run` synchronously and treats any non-zero client exit as implementation failure.
- The wrapper does not capture the run ID as structured state before waiting on the run.
- On a client/stream error, the wrapper does not immediately call `fabro inspect <run_id>` to determine whether the remote run is still `running`.
- The error text from the Fabro client describes a transport/body read failure, not a workflow status, but the wrapper does not classify it separately.

## Observations

- The run ID was printed before the local stream failure, so a better wrapper could capture it.
- The remote run later failed for its own reasons; that later failure should not be conflated with the earlier local stream timeout.
- This problem affects operator observability and safe recovery, not product code.

## Why this matters

Delivery launch is a control point for WIP lifecycle state. If the local command cannot tell “remote run still executing” from “implementation failed,” the operator has to do manual archaeology before taking the next safe step.

## Open questions

- Does Fabro support a stable detached mode (`fabro run -d` or equivalent) that returns a run ID cleanly?
- Is the response-body timeout configurable in Fabro, or should the project wrapper always prefer detached/polling for long-running implementation workflows?
- What statuses should cause automatic rollback versus “remote run still active; monitor it”?

## Possible prevention ideas

- Change `bin/dev fabro deliver` to start implementation in detached/run-id-aware mode, capture the run ID, and then poll/monitor.
- If attach/wait/streaming fails, run `fabro inspect <run_id>` before any rollback or failure classification.
- If remote status is `running` or unknown, do not roll back iteration state. Print follow-up commands, for example:

  ```bash
  fabro events <run_id> --json
  fabro logs <run_id>
  bin/dev fabro progress <run_id> <plan_path> --watch
  ```

- Record the implementation run ID in `.fabro/tmp/` when delivery starts so a later shell/session can recover it easily.
