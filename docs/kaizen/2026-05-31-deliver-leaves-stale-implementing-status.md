# Problem: failed deliver leaves stale implementing status

Date: 2026-05-31

## Context

We were trying to rerun Fabro delivery for `docs/iterations/009-routing-and-liveview-surface-split/plan.md` after earlier sandbox/image failures.

The command path was `bin/dev fabro deliver docs/iterations/009-routing-and-liveview-surface-split/plan.md`. The delivery helper reserves the implementation WIP slot by marking the iteration as `implementing` in both:

- `docs/iterations/README.md`
- `docs/iterations/009-routing-and-liveview-surface-split/plan.md`

It commits and pushes that status before invoking `.fabro/workflows/iteration-implementation/workflow.toml`.

## Expected standard

A failed implementation launch should not leave the iteration lifecycle metadata in a misleading state. If coding did not start, or if the workflow fails during preflight, the iteration status should remain or return to the state from which a safe retry is possible, such as `validated`.

The WIP check should also make it obvious when the blocker is stale lifecycle metadata rather than another active iteration.

## What happened

The delivery command changed iteration 009 to `implementing` before starting Fabro. Fabro then failed before coding because the sandbox preflight detected a stale image without bare `python3`.

After the image was refreshed, rerunning delivery waited on the implementation WIP slot and printed a blocker for the same iteration:

```text
- 009 Routing and LiveView surface split (implementing) docs/iterations/009-routing-and-liveview-surface-split/plan.md
Waiting 60s for implementation WIP slot to clear...
```

Manual intervention was needed to restore iteration 009 to `validated` and push that change to `origin/main` before the delivery command could proceed.

## Impact

This blocked a straightforward retry and created confusion about where the WIP slot state lives. It also required manual status repair in two places, increasing the chance that `docs/iterations/README.md` and the iteration's `plan.md` disagree.

## What allowed it to happen

The delivery helper treats lifecycle status as persistent state and writes `implementing` before the implementation workflow has passed its startup/preflight boundary. There is no rollback or failure handler around the later `fabro run` call.

The same lifecycle status is duplicated in the iteration index and in the individual plan file. Both copies must be updated consistently, but the status management logic is split across shell code in `bin/dev` and Python code in `.fabro/workflows/scripts/iteration_status.py`.

The WIP slot is inferred from status values in `docs/iterations/README.md`; there is no separate lock file or run record that distinguishes an active implementation from a stale failed launch.

## Observations

- `bin/dev` checks remote WIP state with `git show origin/main:docs/iterations/README.md`, so local repairs do not help until pushed.
- `bin/dev` reserves the WIP slot by invoking `.fabro/workflows/scripts/iteration_status.py mark ... implementing --check-clear-first`, then commits and pushes.
- If the subsequent `fabro run .fabro/workflows/iteration-implementation/workflow.toml` fails, `bin/dev` exits without restoring the previous status.
- Lifecycle status is duplicated in the index and in the plan file.
- There is already a project Python helper for status changes, but it is not exposed as a stable `bin/dev` command for operators and workflows to share.

## Why this matters

Failed preflight should be cheap and easy to retry. Leaving the iteration marked `implementing` after a pre-coding failure turns a recoverable environment issue into a manual lifecycle repair and can block subsequent deliveries.

## Open questions

- Should `implementing` be written only after sandbox preflight passes, rather than before the workflow starts?
- Should failed preflight automatically roll the iteration back to `validated`?
- Should the status live only in `docs/iterations/README.md`, with plan files deriving or omitting status, to avoid duplicated state?
- Should `bin/dev` expose first-class iteration state commands and should Fabro workflows call those instead of a private Python script?

## Possible prevention ideas

- Add `bin/dev iteration status|mark|check-clear` commands as the single public lifecycle interface.
- Make `bin/dev fabro deliver` remember the previous status and restore it when Fabro exits before coding or before a durable implementation artifact exists.
- Have WIP errors distinguish "another iteration is active" from "this same iteration is already marked active; use resume or reset lifecycle state".
- Consolidate status mutation so `docs/iterations/README.md` and `plan.md` cannot drift silently.

## Resolution

Date: 2026-05-31

Root cause: `bin/dev fabro deliver` committed and pushed the `implementing` lifecycle reservation before running Fabro, but it had no failure handler for the implementation workflow. If the implementation workflow failed before publishing anything to `main`, the reservation commit remained as stale WIP state. Status mutation was also only exposed through a private Python helper, encouraging duplicated status-management code in shell and workflow scripts.

Fix applied:

- `bin/dev`: added `bin/dev iteration status|mark|check-clear` as the public lifecycle interface over the existing status helper.
- `bin/dev`: changed `fabro deliver` to use the public iteration commands for local status checks and WIP reservation.
- `bin/dev`: added a guarded rollback path when the implementation workflow exits non-zero. It restores the previous status only if `origin/main` is still exactly the WIP reservation commit and the iteration is still marked `implementing`; if `origin/main` moved, it leaves state alone and asks for inspection.
- `.fabro/workflows/iteration-implementation/workflow.fabro`: changed the WIP gate to use `dev iteration check-clear` rather than duplicating the table-parsing logic inline.

Validation:

- `bash -n bin/dev .fabro/workflows/scripts/iteration_status.py .fabro/workflows/iteration-implementation/workflow.fabro` — passed.
- `MEMBA_DEVENV_SHELL=1 ./bin/dev iteration status docs/iterations/009-routing-and-liveview-surface-split/plan.md` — returned `validated`.
- `MEMBA_DEVENV_SHELL=1 ./bin/dev iteration check-clear docs/iterations/010-shared-magic-link-auth/plan.md --allow-same-iteration` — passed while iteration 010 was marked `implementing`.
- `PATH="$PWD/bin:$PATH" dev check` — passed, 132 tests, 0 failures. The first attempt failed because Hex was missing from `/tmp/home`; running `mix local.hex --force` in the devenv shell repaired the local tool cache before rerunning.

Remaining follow-up:

- Decide later whether status should continue to be duplicated in both the iteration index and individual plan files, or whether one should become derived from the other.
- Consider adding a dedicated resume/reset command that makes same-iteration stale WIP recovery more explicit for operators.
