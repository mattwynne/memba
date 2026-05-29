# Kaizen: commit_task must tolerate checkpointed task work

Date: 2026-05-29

## Context

We started iteration implementation for `docs/iterations/002-membership-model/plan.md` using the Fabro `iteration-implementation` workflow.

Run:

```text
01KSS97DPE1D5MD7CAZA9M506K
```

Web UI:

```text
https://fabro.home.wynne.family/runs/01KSS97DPE1D5MD7CAZA9M506K
```

The run was meant to drain the iteration task list, committing one completed task at a time so progress is durable and resumable.

## What happened

The workflow made product progress, but failed in `commit_task`.

Fabro reported:

```text
Failure: deterministic failure cycle detected: signature commit_task|deterministic|script failed with exit code: <n> ## output no changes to commit for completed task. repeated 3 times (limit 3)
```

This repeated after tasks 001, 002, and 003.

The final run summary showed implementation evidence anyway:

- `docs/iterations/002-membership-model/todo.md` existed and had tasks 001–003 checked.
- Product files for Person, Membership, projections, projectors, migrations, and query APIs were present in the run branch/final patch.
- Validation reported the task as valid.
- A live `dev check` had passed with `53 tests, 0 failures`.

The final run metadata included:

```text
Run branch: fabro/run/01KSS97DPE1D5MD7CAZA9M506K
Final run commit: 40b9e88c37523d5897ff36b06a428322e20e4de1
Files changed: 30
Additions: 907
Deletions: 5
```

So the failure was not “no implementation happened.” It was “the commit task expected uncommitted working-tree changes, but the implementation work had already been captured elsewhere.”

## Likely mechanism

The workflow’s `commit_task` node assumes this contract:

1. `implement_next_task` edits files and marks exactly one todo item checked.
2. `validate_task` reviews those uncommitted changes.
3. `commit_task` commits those uncommitted changes.

But the run evidence suggests a different runtime contract occurred:

1. `implement_next_task` completed a task.
2. Fabro checkpointed and pushed a run branch after the agent stage.
3. By the time `commit_task` ran, `git status --short` was clean.
4. `commit_task` treated the clean tree as failure, even though the task work was present in the run branch/checkpoint history.

This made `commit_task` non-idempotent with Fabro-managed checkpointing.

## Why this matters

The task-draining workflow is designed to be resumable. Its safety comes from durable per-task progress. But if Fabro itself checkpoints agent work before the workflow’s explicit `commit_task` node runs, the explicit commit node can become stale.

In this failure mode, the workflow burns substantial tokens validating real work and then fails because the working tree is clean.

This is especially costly because the deterministic failure repeated three times and stopped the run after partial implementation, requiring operator diagnosis and possible resume/fork/recovery.

## The problem

`commit_task` uses “dirty working tree” as the only proof that a task needs committing.

That is too narrow in a Fabro-managed clone/checkpoint environment. A clean working tree can mean either:

- no task work happened; or
- task work was already committed/checkpointed/pushed by Fabro before `commit_task` ran.

The workflow currently cannot distinguish these cases.

## Questions to answer

1. Is Fabro auto-committing/checkpointing agent changes between `implement_next_task` and `commit_task`?
2. If yes, should the workflow remove its explicit `commit_task` node and rely on Fabro checkpoints/run branches?
3. If explicit task commits are still desired, can Fabro be configured not to checkpoint before `commit_task`?
4. Should `commit_task` become idempotent by detecting that `HEAD` or the run branch already contains the todo check-off and implementation artifacts?
5. Should validation assert the expected contract before routing to `commit_task`: dirty tree versus already checkpointed commit?
6. Should deterministic “no changes to commit” after a valid task route to resume/continue rather than fail?

## Suggested investigation plan

1. Inspect run `01KSS97DPE1D5MD7CAZA9M506K` around `implement_next_task`, `validate_task`, and `commit_task` events.
2. Compare the Git commit before and after each `implement_next_task` checkpoint.
3. Inspect `fabro/run/01KSS97DPE1D5MD7CAZA9M506K` to see whether task work was committed by Fabro before `commit_task`.
4. Decide on one durable-progress model:
   - workflow-owned task commits, or
   - Fabro-owned checkpoints/run branch commits.
5. Update `commit_task` and `validate_task` so their assumptions match that model.

## Possible fixes

### Option A: Make `commit_task` idempotent

If the working tree is clean, inspect the last commit or run branch diff. If it contains exactly one new todo check-off and non-todo implementation artifacts, treat the task as already committed and continue.

This preserves the workflow shape and makes it robust to checkpoint timing.

### Option B: Remove explicit task commits

If Fabro run branches are the durable source of truth, remove `commit_task` and make `validate_task` verify that the checkpoint contains the task artifacts.

This simplifies the workflow, but changes the audit trail from human-readable task commits to Fabro checkpoint commits.

### Option C: Disable checkpointing before `commit_task`

If explicit task commits are important, configure the workflow/Fabro so agent stages do not leave the working tree clean before `commit_task` runs.

This keeps the current design, but may fight Fabro’s managed-clone/resumability model.

## Current takeaway

The iteration implementation workflow now has two overlapping durability mechanisms: Fabro checkpoints and explicit task commits. They are interfering.

We need one coherent contract for task progress. Until then, a valid task can fail at `commit_task` simply because the work was already captured by Fabro before the commit node ran.
