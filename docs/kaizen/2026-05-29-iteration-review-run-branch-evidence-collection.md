# Kaizen: iteration review cannot reliably collect evidence from Fabro run branches

Date: 2026-05-29

## Context

After iteration 002 implementation completed, we recorded review handoff metadata:

```text
Branch: fabro/run/01KST2YJGFYEGE4CAR6JK5JF8H
Pull request: none
Base ref: origin/main
Status: ready-for-review
```

The implementation run had succeeded according to Fabro and produced a pushed run branch:

```text
fabro/run/01KST2YJGFYEGE4CAR6JK5JF8H
```

We then attempted to run the iteration review workflow using:

```bash
bin/dev iteration-review \
  fabro/run/01KST2YJGFYEGE4CAR6JK5JF8H \
  docs/iterations/002-membership-model/plan.md \
  origin/main
```

## What happened

### First review run failed during sandbox clone

Run:

```text
01KSTA51KVN9N2CBPA09Y9999J
```

Web UI:

```text
https://fabro.home.wynne.family/runs/01KSTA51KVN9N2CBPA09Y9999J
```

Failure:

```text
Sandbox: docker failed: Failed to clone repo into Docker sandbox: fatal: Remote branch HEAD not found in upstream origin
```

Cause: `bin/dev iteration-review` created an isolated worktree from the remote run ref in detached-HEAD state. Fabro then detected the current branch as `HEAD` and tried to clone remote branch `HEAD`, which does not exist.

We worked around this by creating a local tracking branch:

```bash
git branch --track \
  fabro/run/01KST2YJGFYEGE4CAR6JK5JF8H \
  origin/fabro/run/01KST2YJGFYEGE4CAR6JK5JF8H
```

Then we removed the failed review worktree and retried.

### Second review run passed sandbox but failed collecting evidence

Run:

```text
01KSTA62PGSK1BZXAE1451QE0D
```

Web UI:

```text
https://fabro.home.wynne.family/runs/01KSTA62PGSK1BZXAE1451QE0D
```

This time the sandbox started successfully:

```text
Worktree: /workspace/memba
Base: fabro/run/01KST2YJGFYEGE4CAR6JK5JF8H (31c69dd95de9)
```

Preflight and dev check passed.

Then `Collect Implementation Evidence` failed:

```text
Error: * [new branch]      main       -> origin/main
```

The command failed before producing the expected evidence output. The run then routed to `collect_evidence_failed` and failed the review:

```text
Iteration review failed before gates: implementation evidence could not be collected. Check base_ref and branch visibility, then retry.
```

The recorded command for evidence collection attempted to fetch/verify `origin/main`, compute a merge base, and diff from merge base to `HEAD`.

The only captured output was Git fetch noise:

```text
From https://github.com/mattwynne/memba
 * [new branch]      main       -> origin/main
```

No actual diff evidence was collected.

## The problem

Iteration review is not robust when the implementation branch is a Fabro run branch rather than a normal PR branch.

There are two distinct failure modes:

1. **Detached worktree branch detection**: when the review worktree is created from `origin/fabro/run/...`, it can be detached. Fabro sees the current branch as `HEAD` and attempts to clone a remote branch named `HEAD`.
2. **Evidence collection exits on harmless pipeline/no-match conditions**: after using a local tracking branch, evidence collection still failed even though `origin/main` was fetched and dev check passed. The only captured output was benign Git fetch output. The evidence script likely exited because a later command in a `set -e` pipeline returned non-zero, possibly `grep` when no changed files matched its excerpt filter, or another unguarded command after fetch.

The result is that review cannot reach the model review gates even though:

- the implementation branch exists remotely;
- the review sandbox can clone it when a real local branch exists;
- `dev check` passes in the review sandbox;
- the implementation diff should be available by comparing the run branch to `origin/main`.

## Why this matters

The implementation workflow may not always create PR branches. When it leaves work on `fabro/run/<run_id>`, the review handoff metadata currently has to point at that run branch.

If iteration review only works reliably with normal PR branches, then a successful implementation run without PR creation is not actually reviewable by the standard workflow.

That breaks the intended handoff:

```text
implementation run -> implementation.md -> iteration-review workflow
```

It also increases manual intervention: the operator has to inspect run branches, create local tracking branches, retry, and diagnose shell-script evidence failures.

## Desired behaviour

Iteration review should accept any valid implementation ref recorded in `implementation.md`, including:

- `pr/...` branches;
- `fabro/run/...` branches;
- `origin/...` remote refs;
- possibly raw commit SHAs.

The review command should create an isolated worktree in a way that preserves a valid branch name for Fabro sandbox clone, or explicitly pass the intended clone branch/ref to Fabro rather than relying on branch auto-detection.

Evidence collection should treat benign fetch output as normal and should not fail just because an excerpt filter finds no matching files. If the implementation diff is empty, it should print a clear “empty diff” diagnostic with branch, base, HEAD, merge base, and `git status`, rather than failing with only Git fetch noise.

## Questions to answer

1. Should `bin/dev iteration-review` always create a local tracking branch for remote refs before creating the review worktree?
2. Should it reject detached worktrees before invoking Fabro?
3. Should it pass an explicit branch/ref input to Fabro so the sandbox does not infer `HEAD`?
4. Why did `Collect Implementation Evidence` exit after printing only the `git fetch` output?
5. Is the evidence script vulnerable to `grep` returning 1 under `set -e` when no changed files match the excerpt filter?
6. Should implementation runs create review-friendly `pr/...` branches, rather than requiring review of `fabro/run/...` branches?

## Suggested fixes

### Worktree/ref handling

- In `bin/dev iteration-review`, if the requested branch is `origin/foo` or resolves only as a remote ref, create or update a local branch `foo` tracking `origin/foo` before `git worktree add`.
- Fail fast if `git -C "$worktree" branch --show-current` is empty.
- Include a diagnostic that prints the worktree branch, HEAD SHA, upstream, and remote ref before invoking `fabro run`.

### Evidence collection

- Make fetch quiet or redirect fetch output into diagnostics:

  ```bash
  git fetch --quiet origin "$branch:refs/remotes/origin/$branch" || true
  ```

- Guard no-match pipelines:

  ```bash
  changed_files=$(git diff --name-only "$merge_base"..HEAD)
  printf '%s\n' "$changed_files" |
    grep -E '^(web/(lib|config|test|priv/repo/migrations|mix\.exs|mix\.lock)|bin/|docs/iterations/)' || true
  ```

- If the changed-file list is empty, print a structured failure with:
  - branch name;
  - HEAD SHA;
  - base ref;
  - merge base;
  - `git log --oneline --decorate --max-count=10 --all`;
  - `git branch -vv`;
  - `git diff --stat "$base_ref"..HEAD`.

### Handoff model

- Prefer implementation handoff branches that are review-friendly, for example `pr/<iteration-slug>` or `review/<iteration-slug>`, even when no GitHub PR exists yet.
- If the canonical implementation artifact is a Fabro run branch, make that an explicitly supported path in the review workflow.

## Current takeaway

Iteration review currently assumes too much about branch shape and shell evidence collection. A valid implementation on a Fabro run branch can pass dev check yet fail before review because the sandbox cloned `HEAD` or because evidence collection exits on a benign/no-match condition.

The review handoff contract needs to support Fabro run branches as first-class implementation refs, or implementation must always publish a review-friendly branch before handoff.
