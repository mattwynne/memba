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

## Investigation findings (2026-05-29)

### Failed run `01KSRSQZ7E64JK56P8CNG426X1` — events

```
sandbox.git.started  02:41:49Z  branch=pr/event-sourced-foundation  url=https://github.com/mattwynne/memba
sandbox.git.failed   02:46:49Z  error="Failed to clone repo into Docker sandbox: Command timed out"
sandbox.failed                  duration_ms=300396
```

The clone started correctly — right branch, right URL, detected from the worktree. It ran for exactly the Fabro clone timeout (300 000 ms = 5 minutes) with no other error, which is the signature of a transient network connectivity failure between the Fabro server and GitHub, not a structural problem.

The branch `pr/event-sourced-foundation` exists on the remote:

```
a5a53307a23a0aeadac74884b3d128b9b5088f8b	refs/heads/pr/event-sourced-foundation
```

### Re-run `01KSS5RWAN6X9DZCFRFVACAYFQ` — outcome

Re-run from the same worktree. Clone completed in **2 313 ms**:

```
sandbox.git.started    06:12:01.999Z
sandbox.git.completed  06:12:04.312Z  duration_ms=2313
sandbox.ready          06:12:04.312Z
sandbox.initialized                   clone_branch=pr/event-sourced-foundation
                                      primary_repo_link=/workspace/memba
                                      repo_cloned=true
```

Run continued past sandbox into `prepare_mix.sh` and then into the workflow.

## Conclusion

The original failure was a transient network timeout on the Fabro server. No workflow, image, or clone-strategy change is needed. Fabro-managed clone works correctly for `iteration-review` from a git worktree context.

## Success criteria (met)

- A review run can reliably enter the first workflow stage for PR #1. ✓ (run `01KSS5RWAN6X9DZCFRFVACAYFQ` passed sandbox and is running)
- The main-checkout isolation requirement is preserved: worktree is used, main checkout is undisturbed. ✓

## Resolution

Date: 2026-05-31

Root cause: Review sandbox setup could fail opaquely during clone/setup, leaving the operator without a usable recovery path.

Fix applied:

- `48edd9c`: recorded the clone-timeout finding.
- `d136afb`: fixed iteration-review run branch handling so review evidence collection targets the intended branch/workspace.
- `23d7eeb`: made iteration review evidence failures diagnostic.

Validation:

- Historical delivery evidence: the branch-handling and diagnostic evidence commits are present on `main`.

Remaining follow-up:

- None for this note.
