# Kaizen: resumability needs an accessible branch, not just task commits

Date: 2026-05-29

## Context

We attempted to recover the failed iteration implementation run
`01KSR7ATV5Q77HJ5A1SDT3V3A2` for
`docs/iterations/001-event-sourced-foundation/plan.md`.

That run had reached the end of the task list. It had task commits and a
`todo.md` execution file in its sandbox. The failure was not a product-code
failure; it was an external provider/billing failure while validating the final
task.

The resumable workflow design said a follow-up run should reuse those task
commits and the existing `todo.md`, then continue from the first unchecked task
instead of reimplementing earlier tasks.

In practice, that did not happen.

## What we observed

### A fresh run cloned `main` and started over

We launched a new implementation run with the same `plan_path`:

```bash
fabro run .fabro/workflows/iteration-implementation/workflow.toml \
  -I plan_path=docs/iterations/001-event-sourced-foundation/plan.md
```

The workflow prepared a clean `/workspace` by cloning `main` from GitHub. Since
the old run's task commits and `todo.md` were not on `main`, the new run could
not see them.

It regenerated `docs/iterations/001-event-sourced-foundation/todo.md` from the
plan and began again at task 001. It then reimplemented task 001 and task 002.
That is exactly the token burn the kaizen was meant to avoid.

The important detail: `sync_task_list` preserves an existing `todo.md`, but only
if the checkout already contains one. A fresh clone of `main` does not.

### The previous task commits were durable, but not reachable by the new run

The failed run's progress was durable inside the run/sandbox state. It was not
durable in the sense the next fresh workflow could consume.

We looked for a pushed run branch matching the failed run:

```bash
git ls-remote --heads origin 'fabro/run/01KSR*'
```

No branch appeared. Without a branch or merged PR containing the old task
commits, a new clone has no way to pick up the prior execution state.

This exposes an ambiguity in our wording. "Durable task commits" is not enough.
They must be accessible to the next run's checkout.

### `fabro fork` could not use the checkpoint

We tried to fork the failed run from its latest checkpoint:

```bash
fabro fork 01KSR7ATV5Q77HJ5A1SDT3V3A2
```

Fabro replied:

```text
checkpoint @64 has no git_commit_sha; cannot fork
```

So the checkpoint timeline existed, but the checkpoint did not include the Git
commit metadata needed for `fork` to reconstruct a new run from that state.

This is a separate durability gap: the run had enough recorded workflow history
to inspect what happened, but not enough Git checkpoint data to fork reliably.

### `fabro resume` used old workflow state and hit non-idempotent setup

We then tried:

```bash
fabro resume 01KSR7ATV5Q77HJ5A1SDT3V3A2
```

This did not run the current workflow from `main`. It used the old run's
captured workflow definition and state. That matters because workflow fixes
made after the failed run are not automatically part of a resume.

Resume also failed during setup:

```text
Setup command failed (exit code 128): git clone --branch main --single-branch --depth 10 --no-tags https://github.com/mattwynne/memba /workspace
fatal: destination path '/workspace' already exists and is not an empty directory.
```

So resume reached the existing run state, but the prepare step was not
idempotent for a sandbox whose `/workspace` already exists.

### The checkpoint and branch models are different

We are mixing two recovery models:

1. Checkpoint recovery: resume or fork the same Fabro run from its recorded
   execution state.
2. Branch recovery: start a new run from a Git branch that already contains the
   previous task commits and `todo.md`.

The current kaizen text mostly describes branch recovery: a new run reads the
existing `todo.md`, preserves check-offs, and continues from the first unchecked
task.

But the current workflow's prepare step clones `main`, not a prior run branch.
That makes branch recovery impossible unless the old task commits are already
on `main`.

Checkpoint recovery might still work, but it has different constraints: the old
workflow definition is used, checkpoints need Git commit SHAs, and setup must be
safe to re-enter.

## The problem

The resumability contract is underspecified.

We said: "rerun the same plan and it should pick up where the previous run left
off."

That sentence hides the real requirement: the next run must start from a
checkout that contains the previous run's task commits and `todo.md`, or it must
resume/fork a Fabro checkpoint that can restore that checkout.

Today neither path is reliable:

- A fresh run clones `main`, so it cannot see unmerged task commits.
- The failed run did not expose a pushed `fabro/run/...` branch we could reuse.
- `fabro fork` could not proceed because the checkpoint had no `git_commit_sha`.
- `fabro resume` used the old workflow and failed because setup tried to clone
  into an existing non-empty `/workspace`.

As a result, the workflow can preserve `todo.md` within a continuous run, but it
cannot yet guarantee low-cost recovery after an aborted run.

## Why this matters

Long iteration plans are expensive. The task-draining workflow reduces risk by
committing one task at a time, but that only pays off if those commits become a
real recovery point.

If a run fails after eight tasks and the next run starts at task one, the system
has preserved an audit trail, not reusable progress. The operator still pays
again in time, tokens, and attention.

The problem is not the implementor choosing the wrong unchecked task. The
problem is earlier: the implementor is looking at the wrong checkout.

## Open questions

- Should every completed task commit be pushed to a predictable run branch?
- Should `iteration-implementation` accept a `base_ref` or `resume_ref` input
  instead of hardcoding `main`?
- Should fresh reruns be the recommended recovery path, or should recovery use
  `fabro resume` / `fabro fork` only?
- If resume is the intended path, should prepare steps be skipped or made
  idempotent when `/workspace` already exists?
- Why did the failed run's checkpoints have no `git_commit_sha`, and is that
  expected for this Docker workflow?

## Current takeaway

The workflow is resumable only inside the limits of the checkout it starts
from. Preserving `todo.md` is necessary, but not sufficient. The previous
progress must be present in Git where the next run can reach it.

## Resolution

Date: 2026-05-31

Root cause: Checkpoint commits alone were not an operator-friendly resume contract; recovery also needed an accessible branch/run workspace.

Fix applied:

- `b12f326`: restored Fabro-managed iteration clones and run branches, giving resumable work a visible branch/workspace contract.

Validation:

- Historical delivery evidence: the resumability fix is present on `main`.

Remaining follow-up:

- None for this note.
