# Problem: coarse Fabro todos exhausted an implementation node timeout

Date: 2026-06-23

## Context

We launched Fabro delivery for iteration 044:

```bash
bin/dev fabro deliver docs/iterations/044-conversation-page-alignment/plan.md --poll-interval 30
```

The command marked iteration 044 as `implementing` and started implementation run `01KVSMA9D18M6V47C2ZPQ9S83N`.

Relevant workflow files:

- `.fabro/workflows/iteration-implementation/prompts/sync_task_list.md`
- `.fabro/workflows/iteration-implementation/prompts/implement_next_task.md`
- `.fabro/workflows/iteration-implementation/workflow.fabro`

The run branch preserved the partial implementation at:

- `origin/fabro/run/01KVSMA9D18M6V47C2ZPQ9S83N`

## Expected standard

`sync_task_list` should turn a validated implementation plan into executable todos that are small enough for one `implement_next_task` node to complete, validate, and check off within the node timeout.

When a plan step contains multiple substantive sub-bullets or spans multiple behaviours, the generated `todo.md` should split those sub-bullets before implementation starts, or fail early with a clear "task list too coarse" blocker.

## What happened

`sync_task_list` generated this todo list:

```md
# Implementation TODO

- [ ] 001 `PageHTML.message` (`message.html.heex`):
- [ ] 002 `MemberMessageLive.Show` / `MemberMessageDetail`: supply a reply count, per-reply
- [ ] 003 When the reply count is zero, render neither the "Replies · N" header nor the reply
- [ ] 004 No changes to commands, projections, or follow/reply behaviour.
```

Task 001 came from the first numbered item in the plan's Implementation Plan, but that numbered item contained several sub-bullets:

- replace the follow-control button card with a toggle;
- wrap delivery receipt summary/detail in a collapsed disclosure;
- move the reply composer below the reply list and trim helper copy;
- add a "Replies · N" heading;
- add timestamps to reply cards;
- add the sent date to the original-message meta line.

The implementation agent selected task 001 and did not split it. It described the task as "broad but template-only" and proceeded.

The agent made product-code/test changes and reported green validation. The run branch shows task 001 checked off in `todo.md`, and the diff from the WIP-reservation base includes:

```text
web/lib/memba_web/controllers/page_html.ex
web/lib/memba_web/controllers/page_html/message.html.heex
web/test/memba_web/live/member_message_live/show_reply_test.exs
web/test/memba_web/live/member_message_live/show_test.exs
docs/iterations/044-conversation-page-alignment/todo.md
```

However, the `implement_next_task` stage failed after the 40-minute node timeout:

```text
handler timed out after 2400000ms
```

The workflow then routed to `task_not_ready` and failed with:

```text
Iteration implementation failed: task validation requires human input or exceeded retry budget.
```

Review did not launch.

## Impact

The implementation run performed useful, apparently validated work, but failed before the workflow could continue to independent validation, publication, or review. Iteration 044 remained `implementing`, occupying the implementation WIP slot until a human inspected the run and chose a salvage/retry path.

## What allowed it to happen

- `sync_task_list` generated todos by flattening numbered plan items, not by splitting substantive sub-bullets into one-node-sized execution tasks.
- The prompt says `todo.md` should be lean, and `implement_next_task` says an agent may split an oversized selected task, but neither step enforces granularity before implementation begins.
- The selected task looked like one file (`message.html.heex`) but actually contained several independent UI behaviours plus tests and full browser-facing validation.
- The workflow timeout is attached to the whole `implement_next_task` node, so implementation, debugging, formatting, acceptance feedback, todo check-off, and validation all compete for the same 40-minute budget.
- The failure message collapsed the cause into "task validation requires human input or exceeded retry budget," which did not make the real pattern obvious: green-ish work plus a coarse task hit a node timeout.

## Observations

- The deepest root cause for this run was task granularity: task 001 should have been split before implementation.
- The existing `sync_task_list` resume contract preserves manually split todos, but the initial generation path did not split the plan's sub-bullets.
- The existing `implement_next_task` prompt gives the implementing agent permission to split a task, but relying on the implementer to notice and stop before starting broad work is too weak.
- The run branch is recoverable, so Fabro's run-branch preservation worked better here than in earlier no-branch rescue incidents.

## Why this matters

Single-piece-flow delivery depends on tasks being small, observable, and recoverable. If coarse todos reach implementation, normal development feedback can turn useful validated work into a failed run. That creates manual salvage work, blocks the WIP slot, and makes delivery reliability depend on model judgement rather than workflow guardrails.

## Open questions

- Should `sync_task_list` always split numbered plan sub-bullets into separate todos unless the sub-bullets are purely explanatory?
- What objective heuristics should mark a generated task as too broad: multiple sub-bullets, multiple UI behaviours, browser-facing validation, multiple files, or estimated command runtime?
- Should `sync_task_list` fail early when it cannot split confidently, rather than leaving splitting to `implement_next_task`?

## Possible prevention ideas

- Update `sync_task_list.md` so initial todo generation splits substantive plan sub-bullets into separate execution tasks.
- Add deterministic or prompt-level checks that reject todos containing multiple semicolon-separated behaviours, multiple plan sub-bullets, or broad phrases such as "PageHTML.message" with a trailing colon and hidden child bullets.
- Teach plan validation or delivery launch to report the generated task list before marking the iteration `implementing`, at least when tasks are broad.
- Add diagnostics to `task_not_ready` timeout failures that summarize whether the selected todo was checked off, whether validation reportedly passed, and how much time was spent in validation commands versus implementation.
