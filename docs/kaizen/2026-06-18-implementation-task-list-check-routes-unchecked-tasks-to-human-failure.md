# Problem: implementation task-list check routed unchecked tasks to human failure

Date: 2026-06-18

## Context

We launched Fabro delivery for iteration 034 after marking iteration 033 merged:

```bash
bin/dev fabro deliver docs/iterations/034-member-page-design-system-alignment/plan.md
```

The delivery command reserved the implementation WIP slot, marked iteration 034 as `implementing`, pushed `73971b3f iteration 034: mark implementing`, and started implementation run `01KVC0S9S01WD0AZQ1ZBEE1QMR`.

Relevant workflow files:

- `.fabro/workflows/iteration-implementation/workflow.fabro`
- `.fabro/workflows/iteration-implementation/prompts/check_task_list.md`

## Expected standard

After `sync_task_list` creates `docs/iterations/034-member-page-design-system-alignment/todo.md` with unchecked tasks, the `all_tasks_done` / "Check Task List" node should classify that as normal work remaining:

```json
{"context_updates":{"task_list_complete":false,"task_list_needs_human":false}}
```

The workflow should then follow the `Tasks remain` edge to `implement_next_task` and start implementation.

If a run must be recovered from a checkpoint, `fabro rewind` / `fabro resume` should provide an operator-safe recovery path, or at least fail with a clear actionable command.

## What happened

The run passed the initial deterministic gates:

- `read_plan`: succeeded
- `wip_gate`: succeeded
- `preflight_sandbox`: succeeded
- `resume_gate`: succeeded
- `sync_task_list`: succeeded and created `docs/iterations/034-member-page-design-system-alignment/todo.md` with nine unchecked tasks

Then `all_tasks_done` returned contradictory state. Its command/prompt response identified unchecked tasks, but the context update marked the situation as needing human input:

```json
{"context_updates":{"task_list_complete":false,"task_list_needs_human":true}}
```

That routed the workflow to `task_not_ready`, which failed with:

```text
Iteration implementation failed: task validation requires human input or exceeded retry budget.
```

Fabro recorded the final failure as:

```text
task_not_ready|budget_exhausted|script failed with exit code: <n> ## output iteration implementation failed: task validation requires human input or exceeded retry budget.
```

The run failed before doing any product implementation. Its final patch only added the generated `todo.md`.

A recovery attempt exposed a second abnormality:

```bash
fabro rewind 01KVC0S9S01WD0AZQ1ZBEE1QMR sync_task_list
fabro resume 01KVCC52XM3EHNZD0V8PJ9QD4S -d
```

The rewound run `01KVCC52XM3EHNZD0V8PJ9QD4S` failed immediately with:

```text
Failed to reconnect sandbox for resume
causes: run sandbox missing runtime metadata
```

## Impact

Iteration 034 was left in `implementing` status on `origin/main`, but the implementation run did no product work. The operator had to inspect Fabro state and events manually to discover that the failure was a routing/classification defect in the task-list check, not a real need for product or planning input.

This creates delivery waste and leaves the WIP slot/lifecycle state ambiguous until an operator chooses a safe retry or repair path.

## What allowed it to happen

- The "Check Task List" decision is delegated to an LLM prompt even though the condition is deterministic: whether `todo.md` contains unchecked `- [ ]` lines.
- The prompt had the right rule, but the workflow accepted an incorrect context update and routed to a hard failure.
- The failure message `task validation requires human input or exceeded retry budget` did not name the real abnormality: unchecked tasks were present and should have routed to `implement_next_task`.
- `fabro rewind` produced a new run ID, but `fabro resume` could not reconnect the sandbox because the rewound run lacked runtime metadata. That made the apparent recovery path brittle.

## Observations

- `sync_task_list` created a valid `todo.md`; the unchecked tasks were normal start-of-implementation state.
- The workflow graph already has the correct route for this state: `all_tasks_done -> implement_next_task` when `task_list_complete=false && task_list_needs_human=false`.
- The bad context update came from the `all_tasks_done` prompt/model path, not from the deterministic `sync_task_list` shell script.
- `bin/dev fabro progress docs/iterations/034-member-page-design-system-alignment/plan.md` did not find the run by plan path, so diagnosis required direct `fabro inspect` / `fabro events` commands with the run ID.
- The original run ID was `01KVC0S9S01WD0AZQ1ZBEE1QMR`; the rewound run ID was `01KVCC52XM3EHNZD0V8PJ9QD4S`.

## Why this matters

A first-loop task-list check is part of the implementation factory's core control flow. If it can misclassify ordinary unchecked tasks as human-blocking, a validated plan can be marked implementing and then fail before any work starts. The failure is confusing because it looks like the task itself needs human input when the problem is actually workflow machinery.

## Open questions

- Why did the `output_schema="routing"` prompt produce `task_list_needs_human=true` for the unchecked-task case despite the explicit prompt examples?
- Does this happen only with this model/provider/run, or can any unchecked task list be misrouted?
- What is the intended safe recovery path after a failed/replayed implementation run when the sandbox runtime has already been stopped?
- Should `bin/dev fabro progress` be able to locate an active/failed implementation run from its plan path once the run has reserved the iteration WIP slot?

## Possible prevention ideas

- Replace the LLM-based `all_tasks_done` check with a deterministic shell node that greps `todo.md` and sets routing context itself.
- If the LLM check remains, add a guard that refuses the impossible combination "unchecked tasks exist" plus `task_list_needs_human=true` unless the todo file is missing, empty, or unreadable.
- Make `task_not_ready` include the preceding task-list evidence and distinguish "normal unchecked tasks misrouted" from true human-input cases.
- Document or automate the safe recovery path for a failed run whose sandbox has been stopped, especially after `fabro rewind` creates a new run without runtime metadata.
