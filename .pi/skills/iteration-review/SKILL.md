---
name: iteration-review
description: Run the project's Fabro iteration-review workflow for a completed iteration implementation, using the recorded implementation branch/PR metadata and an isolated worktree. Use when Matt asks to review a completed iteration, run the review workflow, or review an implementation PR.
---

# Iteration Review

## Overview

Review a completed implementation of an iteration plan by running the project's Fabro iteration-review workflow in an isolated worktree. The workflow reviews the implementation branch against its base branch, without switching the main checkout and without disturbing other agents.

<HARD-GATE>
Do not review or modify application code directly as part of this skill. Do not switch the main checkout's branch. Do not edit application code, migrations, tests, acceptance feature files, step definitions, UI, or production docs. This skill may read iteration metadata and execute the committed review workflow. If required metadata is missing, ask Matt for the missing branch/PR/base information or, with explicit approval, record it in the iteration folder.
</HARD-GATE>

## Required metadata

Each implemented iteration should record its implementation target in the iteration folder, next to `plan.md`, in `implementation.md`:

```markdown
# Implementation

Branch: pr/example-branch
Pull request: https://github.com/mattwynne/memba/pull/123
Base ref: origin/main
Base sha: <base-commit-sha>
Status: ready-for-review
```

Required fields:

- `Branch:` — local or remote branch/ref containing the implementation.
- `Base ref:` — comparison base, usually `origin/main`.

Optional but recommended:

- `Base sha:` — concrete base commit SHA for deterministic review diffs. If absent, `bin/dev iteration-review` resolves it locally from `Base ref:`.
- `Pull request:` — GitHub PR URL for human traceability.
- `Status:` — `ready-for-review`, `reviewing`, `reviewed`, or similar.

## Checklist

1. **Check repository state**
   - Run `git status --short --branch`.
   - Do not require a clean working tree, because the review runs in an isolated worktree.
   - If there are unrelated uncommitted changes to review workflow files, scripts, or iteration metadata, mention them before running.

2. **Select the iteration**
   - If Matt specifies an iteration number, folder, title, or plan path, use that.
   - Otherwise read `docs/iterations/README.md` and select the lowest-numbered iteration with status `implemented`, `ready-for-review`, or `reviewing`.
   - If none have those statuses, select the lowest-numbered `ready` iteration only if its folder contains implementation metadata. Otherwise stop and ask Matt which implemented iteration to review.

3. **Read the plan and implementation metadata**
   - Read the selected `plan.md`.
   - Read `<iteration-folder>/implementation.md`.
   - Extract `Branch:`, `Base ref:`, `Base sha:`, and `Pull request:` if present.
   - If `implementation.md` is missing or lacks `Branch:`, first try obvious local evidence:
     - a local branch named like `pr/<iteration-slug>`
     - a remote branch named like `origin/pr/<iteration-slug>`
   - If branch still cannot be determined, stop and ask Matt for the branch/ref. Offer to record it in `implementation.md`.

4. **Verify the review command exists**
   - Ensure `bin/dev` exists and supports `iteration-review`:
     ```bash
     bin/dev iteration-review --help
     ```
   - Ensure `.fabro/workflows/iteration-review/workflow.toml` exists.

5. **Run the review workflow**
   - Run:
     ```bash
     bin/dev iteration-review <branch> <plan-path> <base-ref-or-base-sha>
     ```
   - Capture the Fabro run ID and web UI URL if printed.
   - Do not manually switch branches.

6. **Monitor and report**
   - If Fabro pauses for human input, summarize the question and options for Matt.
   - If Fabro fails, summarize the failed stage, likely cause, and exact retry command.
   - If Fabro succeeds, report the run ID, PR URL if available, and any repairs applied by the review workflow.

7. **After merge, mark the iteration merged**
   - Once the implementation branch is confirmed merged into `origin/main`, update iteration status metadata with:
     ```bash
     bin/dev iteration-mark-merged <plan-path> <branch> origin/main
     ```
   - This command refuses to edit docs unless the branch commit is an ancestor of `origin/main`.
   - Commit the resulting updates to `docs/iterations/README.md`, `<iteration-folder>/plan.md`, and `<iteration-folder>/implementation.md` if they are not already part of the merge.

## Current project command

For iteration 001 at the time this skill was introduced:

```bash
bin/dev iteration-review \
  pr/event-sourced-foundation \
  docs/iterations/001-event-sourced-foundation/plan.md \
  origin/main
```

## Reporting format

When starting a review, report:

- Selected iteration number and title.
- Plan path.
- Implementation branch/ref.
- Base ref and base sha, if known.
- Pull request URL, if known.
- Exact `bin/dev iteration-review ...` command.

When the run completes, report:

- Result: succeeded, failed, blocked, or human input needed.
- Run ID / web UI URL if available.
- PR URL if available.
- Any follow-up Matt needs to do.

## Key principles

- Keep the main checkout branch untouched.
- Use recorded metadata rather than guessing when possible.
- Prefer explicit branch/base inputs over GitHub API or PR scraping.
- Review focuses on simplicity, maintainability, plan fidelity, ADR coherence, and green checks.
