# Notes: task-draining Fabro iteration workflow lessons

Date: 2026-05-28

Related kaizen docs:

- `docs/kaizen/2026-05-27-iteration-implementation-adr-gate-plan.md`
- `docs/kaizen/2026-05-27-iteration-implementation-hardening-plan.md`
- `docs/kaizen/2026-05-28-task-draining-iteration-workflow.md`

## Context

We were trying to get the `iteration-implementation` Fabro workflow to implement `docs/iterations/001-member-message-deliverability/plan.md`.

Earlier hardening work had already added:

- sandbox preflight checks;
- a plan conformance gate;
- an ADR coherence gate;
- review/repair evidence gates;
- final artifact checks.

Those changes caught important failures, but the workflow still had one large `Implement Iteration` node. The plan was large enough that the implementor either under-delivered or used the wrong architecture, then the repair stages treated the remaining work as too large.

## What we changed

### 1. Captured the kaizen idea

We wrote `docs/kaizen/2026-05-28-task-draining-iteration-workflow.md`.

The idea is to replace a monolithic implementor with a Ralph-style task-draining loop:

1. Read the plan and todo list.
2. Update/split/add todos if needed.
3. Pick the first unchecked task.
4. Implement only that task.
5. Validate that task.
6. Mark it done.
7. Commit it.
8. Loop until all tasks are done.
9. Then run whole-iteration gates (`dev check`, plan conformance, ADR coherence, reviews, final artifact gate).

The plan remains the source of truth. `todo.md` is derived execution state.

### 2. Added an implementation subagent

The existing subagents were read-only review agents:

- `deep-review-codex`
- `deep-review-claude`
- `deep-review-gemini`

They correctly refused to edit files. We added a new project-local implementation agent:

- `.pi/agents/implementation-codex.md`

This agent can edit repository files and run validation, while preserving unrelated working-tree changes and avoiding commits unless requested.

### 3. Implemented a task-draining workflow

The new workflow replaces `implement -> dev_check` with a loop roughly shaped as:

```text
preflight_sandbox
  -> sync_task_list
  -> all_tasks_done?
    -> dev_check if all tasks checked
    -> pick_next_task otherwise
  -> implement_task
  -> validate_task
  -> fix_task if needed
  -> mark_task_done
  -> commit_task
  -> sync_task_list
```

New prompts:

- `.fabro/workflows/iteration-implementation/prompts/implement_task.md`
- `.fabro/workflows/iteration-implementation/prompts/validate_task.md`
- `.fabro/workflows/iteration-implementation/prompts/fix_task.md`
- `.fabro/workflows/iteration-implementation/prompts/mark_task_done.md`

The workflow commits each completed task with evidence in the commit message. That makes state durable between task iterations and gives an audit trail.

### 4. Made task-list sync deterministic

The first version used an LLM prompt for `sync_task_list`. In the first task-draining run, the prompt claimed it had created:

```text
docs/iterations/001-member-message-deliverability/todo.md
```

but the next script node could not find the file.

We replaced `sync_task_list` with a script node that deterministically derives `todo.md` from the numbered `## Implementation Plan` section in `plan.md`.

Lesson: if a workflow requires a file to exist for later script nodes, create it with a script, not an LLM prompt that may only describe the intended edit.

### 5. Fixed repair snapshot portability

Earlier repair evidence gates used:

```sh
shasum -a 256 | awk '{print $1}'
```

The Fabro sandbox image did not have `shasum`/`awk`, causing repair snapshot stages to fail. The workflow now uses portable `git diff --binary` patch snapshots and `cmp` instead.

Lesson: script gates should either preflight their tools or use commands already known to exist in the sandbox.

### 6. Adjusted task-loop visit budgets

The second task-draining run got through task 001 and began task 002, but then failed with:

```text
node "fix_task" visited 3 times (node limit 3); run is stuck in a cycle
```

We learned that `max_visits` is counted per node across the whole run, not per selected todo task. A looping workflow that reuses `fix_task` for many tasks needs a much larger visit budget.

We raised:

- graph `max_node_visits` from `80` to `300`;
- `fix_task max_visits` from `3` to `100`.

Lesson: Fabro node visit limits are global to the run. In a task-draining loop, set budgets for the full iteration, not a single task.

## What we learned from the runs

### The task loop works better than a monolithic implementor

The task-draining run made real incremental progress:

- It created a todo list.
- It selected task 001.
- It implemented task 001.
- It validated and repaired task 001.
- It marked task 001 done.
- It committed task 001.
- It moved on to task 002.

That is a much better failure mode than a single giant implementation that claims success while missing most of the plan.

### Validation can now be narrower and more useful

The `validate_task` gate produced concrete repair briefs scoped to the selected task. For task 002, it identified missing EventStore configuration and gave exact expected config/test evidence.

This suggests the pattern is sound: validate the smallest current deliverable, repair it, commit it, and only later run whole-plan conformance.

### The workflow should prefer deterministic state transitions

Good candidates for script nodes:

- deriving `todo.md` path from `plan_path`;
- creating a first-pass todo list from numbered plan tasks;
- picking the first unchecked task;
- committing completed task changes;
- checking for locked `.feature` edits;
- detecting whether all tasks are complete.

Good candidates for prompt nodes:

- deciding whether to split/add/reorder todos;
- implementing a selected task;
- validating task evidence;
- marking done when a task is semantically complete.

### Commit messages are enough for notes

We decided not to put detailed notes in `todo.md`. Keep `todo.md` lean and let each task commit message carry detailed evidence:

- files changed;
- tests run;
- why the selected task is complete;
- remaining risks.

### Implementors may update todos, with guardrails

Task agents may:

- split a too-large task;
- add technical subtasks required by the plan;
- reorder pending tasks when dependencies require it.

They may not:

- delete plan-required work;
- weaken scope;
- mark work done without evidence;
- edit locked acceptance feature files.

## Current state / next things to watch

- The latest workflow changes have been pushed.
- The next run should test whether the larger visit budgets let the task loop continue past task 002.
- Watch whether task commits inside the sandbox interact well with Fabro checkpointing and final PR creation.
- Watch cost/runtime: task loops read a lot of context repeatedly. We may need better context compaction or narrower per-task prompts.
- Consider adding a task-level static evidence collector if LLM validation remains too vague.

## Open questions

- Should `todo.md` be committed during the run with each task? Current workflow commits task changes and todo updates together.
- Should `sync_task_list` update an existing todo when `plan.md` changes, or only create it when missing? Current deterministic sync creates when missing and otherwise trusts the existing todo.
- Should task selection skip parent tasks that have been split into child tasks? This may need a convention in `todo.md`.
- Should each task have an explicit validation command in `todo.md`, or should the validator infer it from the task and plan?
