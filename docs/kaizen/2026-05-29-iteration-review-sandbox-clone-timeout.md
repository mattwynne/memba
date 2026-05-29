# Problem: iteration review sandbox clone timed out

Date: 2026-05-29

## Context

After adding the `iteration-review` skill and `bin/dev iteration-review`, we tried to review PR #1:

```bash
bin/dev iteration-review \
  pr/event-sourced-foundation \
  docs/iterations/001-event-sourced-foundation/plan.md \
  origin/main
```

The first review run exposed a workflow prompt bug: the plan conformance gate emitted shell-command JSON as text instead of using real repository evidence, then routed to `plan_conformant=false` without explanation.

That was fixed in commit `0ec9644` by adding a command stage that collects implementation evidence before routing gates.

After that fix, the next review run failed earlier, during Fabro sandbox initialization:

```text
Run: 01KSRSQZ7E64JK56P8CNG426X1
Status: FAILED
Failure: Failed to initialize sandbox
  caused by: Failed to clone repo into Docker sandbox: Command timed out
```

This looks like a recurrence of the sandbox/clone class of problems we worked through before.

## Relevant prior work

Before changing the review workflow or Fabro sandbox setup further, we should re-read and learn from the prior sandbox work:

- `docs/notes/2026-05-27-fabro-sandbox-debugging-lessons.md`
- `docs/retros/2026-05-27-fabro-sandbox-followup.md`
- `docs/reference/fabro-devenv.md`
- `docs/kaizen/2026-05-29-return-to-fabro-managed-clone-for-resumability.md`
- `docs/kaizen/2026-05-29-resume-contract-gap-between-checkpoints-and-branches.md`

The important historical lesson from `2026-05-29-return-to-fabro-managed-clone-for-resumability.md` is Chesterton's fence: manual clone paths were previously introduced because built-in clone failures happened too early and were hard to observe. Later image fixes made Fabro-managed clone viable again, but clone initialization remains a sensitive boundary.

## Observations from this incident

- The local isolated worktree was created successfully at:

  ```text
  /Users/matt/git/mattwynne/memba-review-pr-event-sourced-foundation
  ```

- The command intentionally runs the review workflow from the main checkout's workflow file, while reviewing the PR worktree. This lets workflow fixes on `main` review an older PR branch.
- Fabro did start the run and reported the workflow graph before failing in sandbox initialization.
- The failure happened before workflow stages ran, so ordinary workflow command logging was unavailable.
- The failure was specifically clone-timeout, not test failure, prompt failure, or plan-conformance failure.

## Problem statement

Iteration review currently depends on Fabro's Docker sandbox being able to clone the repository during sandbox initialization. When that clone times out, the review cannot proceed and the failure is too early to benefit from workflow-level diagnostics.

We need a reliable, observable review-run startup path that preserves the advantages of Fabro-managed clones/run branches without reintroducing the opaque failure modes that previous sandbox work was designed to avoid.

## Questions to answer

1. Is the timeout caused by GitHub/network latency, authentication, clone size, Fabro server state, Docker image state, or branch/ref selection?
2. Does this reproduce consistently, or was it transient?
3. Does `fabro inspect`, `fabro logs`, `fabro events`, or server-side logs expose the exact clone command and timeout duration?
4. Are the previous image-level fixes still present in the environment used by iteration-review?
5. Is the review command's use of an absolute workflow path from another checkout affecting Fabro's clone-source detection or branch choice?
6. Should review runs use a pushed review-control branch containing workflow fixes, rather than an absolute workflow path from `main`?
7. Should Fabro expose clone stderr/progress/timeout configuration better for early sandbox failures?

## Suggested investigation plan

1. Inspect the failed run:

   ```bash
   fabro inspect 01KSRSQZ7E64JK56P8CNG426X1
   fabro events 01KSRSQZ7E64JK56P8CNG426X1
   fabro logs 01KSRSQZ7E64JK56P8CNG426X1
   ```

2. Compare its clone metadata with successful managed-clone smoke runs from `2026-05-29-return-to-fabro-managed-clone-for-resumability.md`.
3. Re-run a minimal managed-clone smoke workflow from the same branch/worktree context used by `bin/dev iteration-review`.
4. Re-run the iteration review once to check whether the timeout was transient.
5. If it recurs, decide whether to:
   - fix Fabro clone timeout/observability,
   - adjust the review command's checkout/workflow-path strategy,
   - or temporarily use a more observable prepare-step clone for review runs only.

## Success criteria

- A review run can reliably enter the first workflow stage for PR #1.
- If clone/setup fails, the failure includes actionable evidence: clone URL form, branch/ref, timeout duration, and stderr/progress.
- We preserve the main-checkout isolation requirement: running review must not switch the main checkout's branch or disturb other agents.
