# Problem: dev fabro progress exits before rendering when no tasks are complete

Date: 2026-06-23

## Context

While checking the implementation progress for Fabro run `01KVSMA9D18M6V47C2ZPQ9S83N`, we ran:

```sh
dev fabro progress 01KVSMA9D18M6V47C2ZPQ9S83N
```

The run inputs inferred `docs/iterations/044-conversation-page-alignment/plan.md`, and the sandbox contained `docs/iterations/044-conversation-page-alignment/todo.md` with four unchecked implementation tasks.

## Expected standard

`bin/dev fabro progress <run_id>` should show a useful progress summary for an implementation run whenever the sandbox `todo.md` exists, including the normal start-of-run state where zero tasks have been checked off.

A zero-complete task list should render as `0/N`, not as a command failure.

## What happened

The command printed only:

```text
Iteration: conversation page alignment
```

and exited with status `1` before showing the progress bar.

Manual inspection showed that `dev fabro pull-todo 01KVSMA9D18M6V47C2ZPQ9S83N docs/iterations/044-conversation-page-alignment/plan.md <tmp>` succeeded and downloaded a valid todo file:

```md
# Implementation TODO

- [ ] 001 `PageHTML.message` (`message.html.heex`):
- [ ] 002 `MemberMessageLive.Show` / `MemberMessageDetail`: supply a reply count, per-reply
- [ ] 003 When the reply count is zero, render neither the "Replies · N" header nor the reply
- [ ] 004 No changes to commands, projections, or follow/reply behaviour.
```

Tracing `bin/dev` showed `_fabro_render_progress` counted total tasks successfully, then exited while assigning the completed-task count:

```sh
done=$(grep -E '^[[:space:]]*- \[[xX]\]' "$todo_file" | wc -l | tr -d ' ')
```

Because no checked tasks existed, `grep` returned `1`. `bin/dev` runs with `set -euo pipefail`, so the no-match count pipeline aborted the helper before it could render `0/4`.

## Impact

This is minor operational friction, but it appears at a high-frequency workflow moment: the beginning of an implementation run, when zero completed tasks is normal. The helper hides the available progress information and forces manual diagnosis with `fabro inspect`, `fabro sandbox cp`, or shell tracing.

## What allowed it to happen

The progress helper uses `grep | wc -l` count pipelines under `set -euo pipefail` without treating "no matches" as a valid count of zero. There is no script test or smoke check covering the zero-completed `todo.md` case.

The failure mode is also opaque: the visible output stops after the iteration heading, without explaining that the renderer crashed while counting checked tasks.

## Observations

- The run itself was still running; the failure was in the local `bin/dev fabro progress` wrapper, not in the Fabro implementation workflow.
- The inferred plan path was correct: `docs/iterations/044-conversation-page-alignment/plan.md`.
- Pulling the sandbox `todo.md` directly worked, so the progress helper had enough data to render a progress bar.
- The abnormal state was not the unchecked todo list. Four unchecked tasks is normal at the start of implementation.
- A similar pattern may affect other `grep` lookups in `_fabro_render_progress`, such as finding the next unchecked task after all tasks are complete.

## Why this matters

Progress reporting should make the implementation factory observable, especially during early run triage. If the helper fails on normal states, operators lose trust in it and fall back to slower manual inspection.

## Open questions

- Are there other `bin/dev fabro` helpers that count optional matches with `grep` under `pipefail`?
- Does `_fabro_render_progress` also fail when all tasks are complete because the `next_task` grep finds no unchecked lines?

## Possible prevention ideas

- Count todo states with a method that returns success for zero matches, such as `awk`, or explicitly tolerate no-match grep results.
- Add a lightweight script-level regression check for `todo.md` examples with zero complete, some complete, and all complete tasks.
- Make `dev fabro progress` report a clear error if rendering fails after successfully pulling `todo.md`.
