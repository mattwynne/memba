# Idea: task-draining iteration implementation workflow

Date: 2026-05-28

## Context

Recent `iteration-implementation` runs showed that a single large implementor stage is too brittle for ambitious iteration plans. The implementor can make a partial or wrong-architecture attempt, then later repair stages treat the remaining work as too large or unclear.

We want a more general workflow pattern, not one specialized to a single iteration: drain a task list derived from the approved plan until all tasks are complete, then run the usual whole-iteration gates.

## Goal

Replace the monolithic implementation stage with a Ralph-style loop:

1. Read the iteration plan and todo list.
2. Update/split/add todos where needed.
3. Pick the first unchecked task.
4. Implement only that task.
5. Validate task evidence.
6. Check off the task.
7. Commit.
8. Loop until all tasks are done.
9. Run `dev check`, plan conformance, ADR coherence, reviews, and final artifact gates.

## Proposed artifact

Use a plain markdown todo file in the iteration folder:

```text
docs/iterations/NNN-topic/todo.md
```

The plan remains the approved scope. `todo.md` is execution state derived from the plan.

Keep `todo.md` lean:

```md
# Implementation TODO

- [x] 001 EventStore and projection dependencies
- [ ] 002 Membership Commanded model
- [ ] 003 Messaging aggregate and fake provider
```

Detailed notes should live in the task commit message, not in `todo.md`.

## Todo update rules

Each task implementor may update `todo.md` when it discovers more detail, with guardrails:

- It may split the current task into smaller tasks.
- It may add newly discovered technical tasks needed to satisfy the plan.
- It may reorder pending tasks if dependencies require it.
- It may not delete, weaken, or silently defer plan-required work.
- It may not mark a task done without code/test/config evidence.
- If it discovers work outside the plan, add it under an out-of-scope/discovered section or stop for human input.

## Commit discipline

After each completed task, commit the task result. The commit message is the detailed note/evidence trail.

Example:

```text
Implement iteration 001 task 001

- Added EventStore and projection dependencies
- Configured dev/test EventStore
- Added EventStore smoke test
- Ran targeted test and dev check
```

This should make state durable across Fabro stages and reduce confusion about whether previous changes are visible to later agents.

## Workflow shape

Potential nodes:

- `sync_task_list`: read `plan.md` and create/update `todo.md` without weakening scope.
- `pick_next_task`: select first unchecked task; route to final validation if none remain.
- `implement_task`: implement only the selected task.
- `validate_task`: check task evidence and targeted tests.
- `fix_task`: repair the selected task if validation fails.
- `mark_task_done`: check off the selected task in `todo.md`.
- `commit_task`: commit code and todo update.
- loop back to `sync_task_list` / `pick_next_task`.

Then existing whole-iteration stages run:

- `dev_check`
- `plan_conformance_gate`
- `adr_coherence_gate`
- independent reviews
- final artifact gate

## Open design questions

- Should `sync_task_list` be allowed to edit the approved plan, or only `todo.md`? Current preference: only `todo.md`; plan edits should require explicit human approval unless they are mechanical references to the todo file.
- Should task validation be mostly LLM-based, script-based, or both?
- How should the selected task be passed between nodes: context value, `.fabro/tmp`, or a marker in `todo.md`?
- Should task commits be pushed during the run, or left as Fabro checkpoint commits/PR commits?
- How should the workflow handle a task that is too large: automatic split vs human input?

## Acceptance criteria for this kaizen item

- Iteration implementation no longer depends on one giant implementor prompt.
- Each unchecked todo is implemented and committed independently.
- Agents can add/split/reorder todos only when needed to satisfy the plan.
- Completed tasks have durable commits with evidence in commit messages.
- Whole-plan conformance still runs after all todos are checked off.
