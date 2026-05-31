# Idea: simplify iteration task loop ownership

Date: 2026-05-28

## Context

The task-draining iteration workflow split a single task across several workflow nodes:

1. `pick_next_task` selected the first unchecked todo and wrote it to `.fabro/tmp/selected-task.txt`.
2. `implement_task` implemented that selected task.
3. `validate_task` reviewed the result.
4. `mark_task_done` checked off the selected task.
5. `commit_task` committed the result.

This separation created fragile handoff state. In one run, task 005 implementation files were created as untracked files, but the separate `mark_task_done` agent checked off task 004 again. The following commit contained only the todo check-off, and the next reset cleaned away the untracked task-005 files.

The problem is not that the implementor cannot write files. The problem is that ownership of task identity is split across nodes.

## Goal

Simplify the per-task loop so the implementor owns the task selection and check-off for one task from beginning to end.

Keep independent validation and deterministic commit guardrails, but remove separate LLM nodes that can drift from the selected task.

## Proposed workflow shape

Replace this loop:

```text
sync_task_list
  -> check_task_list
  -> pick_next_task
  -> implement_task
  -> validate_task
  -> mark_task_done
  -> commit_task
  -> sync_task_list
```

with this loop:

```text
sync_task_list
  -> check_task_list
  -> implement_next_task
  -> validate_task
  -> commit_task
  -> sync_task_list
```

`implement_next_task` is responsible for:

- reading the iteration `todo.md`;
- picking the first unchecked task;
- implementing that task only;
- running focused validation appropriate to that task;
- checking off the same task line it implemented;
- leaving a concise implementation summary for validation.

`validate_task` remains an independent gate, but validates the completed task by inspecting the todo diff, implementation artifacts, and test evidence rather than relying on a separate selected-task file.

`commit_task` remains deterministic and refuses unsafe commits.

## Deterministic guardrails

`commit_task` should fail when:

- no working-tree changes exist;
- locked acceptance feature files changed;
- only `todo.md` changed;
- more than one ordinary todo line changed from unchecked to checked without an explicit split/merge rationale;
- no implementation artifact or test/config/doc artifact is staged alongside the todo check-off.

The workflow may still allow `todo.md` splitting/reordering when needed, but the commit gate should make accidental check-off-only commits impossible.

## Retry behaviour

Do not use in-place repair for selected tasks.

If `validate_task` rejects a task but considers another clean attempt safe, route to a deterministic reset node:

```text
git reset --hard HEAD
git clean -fd ...
```

Then run `implement_next_task` again from the last successful task commit. This preserves prior successful task commits inside the run while discarding the failed attempt.

If a task repeatedly fails after clean retries, stop for human input.

## Acceptance criteria

- There is no separate `pick_next_task` node.
- There is no separate LLM `mark_task_done` node.
- There is no `fix_task` repair node for per-task failures.
- The implementor picks, implements, tests, and checks off one task in a single node.
- Validation can request either `VALID`, `RETRY`, or `HUMAN_INPUT`.
- Retry resets to the last successful task commit and reruns the implementor.
- Commit guardrails prevent check-off-only commits.
- The workflow validates with `fabro validate .fabro/workflows/iteration-implementation/workflow.toml`.

## Resolution

Date: 2026-05-31

Root cause: The iteration task loop had too much ownership ambiguity between workflow orchestration and task-level agents.

Fix applied:

- `abbb391`: simplified the Fabro iteration task loop.

Validation:

- Historical delivery evidence: the simplified task-loop commit is present on `main`.

Remaining follow-up:

- None for this note.
