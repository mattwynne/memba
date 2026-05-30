---
name: iteration-implementation
description: Pick the next ready iteration plan from docs/iterations and execute it through the Fabro iteration-implementation workflow. Use when Matt asks to implement, run, execute, or start the next ready iteration.
---

# Iteration Implementation

## Overview

Manual escape hatch: pick the next ready iteration from `docs/iterations/README.md`, submit it directly to the project's Fabro iteration-implementation workflow, and monitor the run until it is complete or blocked. Normal delivery should use the `iteration-deliver` skill/workflow so validation, implementation, review, and status finalization are orchestrated together.

The workflow is intentionally test-first-at-runtime:

- The implementer uses automated tests as the primary feedback loop.
- `dev check` must pass before model review starts.
- Review feedback is for refactoring, maintainability, conventions, and low-risk test-quality improvements after the suite is green.
- Acceptance feature files are locked during implementation runs.

<HARD-GATE>
Do not implement the iteration directly in the local checkout. Do not edit application code, migrations, tests, acceptance feature files, step definitions, UI, or production docs as part of this skill. This skill executes the committed Fabro workflow and reports the result. If the workflow or plan is missing, stale, uncommitted, or otherwise not visible to Fabro's sandbox, fix only skill/workflow/planning metadata when Matt explicitly asks; otherwise stop and report the blocker.
</HARD-GATE>

## Checklist

1. **Check repository state**
   - Run `git status --short`.
   - If there are unrelated uncommitted changes, stop and ask Matt whether to continue, stash, or commit them. Do not include unrelated changes in an implementation run.

2. **Find the next ready iteration**
   - Read `docs/iterations/README.md`.
   - Select the lowest-numbered iteration whose status is `ready` or `fabro-ready` and whose plan link exists.
   - If no ready iteration exists, stop and report that there is nothing ready to implement.
   - If there are multiple ready iterations, pick the lowest numbered one unless Matt specified another.

3. **Verify the plan and acceptance criteria**
   - Read the selected `plan.md`.
   - Confirm it has a concrete goal, scope, acceptance criteria, implementation plan, and validation plan.
   - Note any acceptance feature files listed in the iteration index or plan. They are locked inputs, not files to edit during implementation.
   - If the plan is not ready enough to implement, stop and recommend running the `iteration-planning` skill or Fabro plan validation first.

4. **Verify the implementation workflow**
   - Ensure `.fabro/workflows/iteration-implementation/workflow.toml` exists.
   - Ensure it uses the project implementation workflow and `dev check` quality gate.
   - Run:
     ```bash
     fabro validate .fabro/workflows/iteration-implementation/workflow.toml
     ```
   - If validation fails, report the error and stop.

5. **Ensure Fabro can see the inputs**
   - The plan, acceptance feature files, implementation workflow, prompts, and `dev check` script must be committed and pushed before a remote/clone-based Fabro run can use them.
   - Check whether the current branch has unpushed commits with:
     ```bash
     git status --short --branch
     ```
   - If required artifacts are uncommitted, stop and ask Matt to approve committing them.
   - If required commits are not pushed, ask Matt before pushing.

6. **Execute the iteration**
   - Run Fabro with the selected plan path:
     ```bash
     fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md
     ```
   - Capture the run ID and web UI URL if printed.
   - If the command fails before creating a run, report the exact error and provide the retry command.

7. **Monitor and handle results**
   - Follow the run using the Fabro CLI output, web UI URL, or appropriate `fabro events` / `fabro logs` commands.
   - If Fabro pauses for human input, summarize the question and options for Matt.
   - If Fabro fails, classify the failure before reporting it:
     - **Implementation failure**: the plan/code/tests could not be completed even though the workflow machinery behaved as designed. Summarize the failed stage, likely cause, and exact retry/resume command if available.
     - **Workflow failure**: the run failed because the Fabro workflow, prompts, routing, sandbox setup, resume/checkpoint contract, metadata handoff, PR creation, or other automation machinery behaved incorrectly or opaquely. Summarize the failed stage, likely cause, and exact retry/resume command if available, then write a kaizen note as described below.
   - If Fabro succeeds, capture the implementation branch/ref, PR URL if available, base ref, and whether auto-merge was enabled/accepted.

8. **Write a kaizen note for workflow failures**
   - When the completed Fabro run failed for a workflow reason, write an observations note in `docs/kaizen/` for later investigation.
   - Use a filename in this form: `docs/kaizen/YYYY-MM-DD-short-workflow-problem.md`.
   - Do this before ending the skill, unless Matt explicitly asks not to create the note.
   - Keep the note factual and diagnostic, not a speculative fix plan. Include:
     - Title: `# Problem: <short description>`
     - Date
     - Selected iteration and plan path
     - Fabro run ID and web UI URL, if available
     - Failed stage/status and the exact failure text
     - Commands used to inspect the run, such as `fabro events` or `fabro logs`
     - Observations explaining why this is a workflow/tooling problem rather than an ordinary implementation failure
     - Any retry/resume command that Fabro printed or that is clearly safe
   - Do not edit application code while writing the kaizen note.
   - Ask Matt before committing the kaizen note.

9. **Record review handoff metadata**
   - After a successful implementation run, write `<iteration-folder>/implementation.md` so the `iteration-review` skill can find the implementation without switching the main checkout.
   - Use this format:
     ```markdown
     # Implementation

     Branch: <implementation-branch-or-ref>
     Pull request: <pr-url-or-none>
     Base ref: origin/main
     Base sha: <base-commit-sha>
     Status: ready-for-review
     ```
   - The branch/ref should be the PR branch when available, for example `pr/event-sourced-foundation`; otherwise use the Fabro run branch/ref printed by the workflow.
   - Resolve and record `Base sha:` locally from the implementation branch and base ref (usually the merge-base with `origin/main`) so `iteration-review` can diff deterministically without sandbox merge-base archaeology.
   - Update `docs/iterations/README.md` status for the iteration to `ready-for-review`.
   - Commit and push only this review handoff metadata when Matt approves committing it. Do not include unrelated changes.

## Selection Rules

Use the iteration index table as the source of truth. Status meanings for this skill:

- `ready` — eligible for implementation.
- `fabro-ready` — eligible for implementation.
- `draft`, `needs-revision`, `implemented`, `done`, or any other status — not eligible unless Matt explicitly chooses it.

When Matt specifies an iteration number, title, folder, or plan path, use that instead of auto-selecting, but still verify the plan exists and is ready.

## Fabro Command Template

```bash
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=<plan-path>
```

Example:

```bash
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/001-member-message-deliverability/plan.md
```

## Reporting Format

When starting a run, report:

- Selected iteration number and title.
- Plan path.
- Acceptance feature files treated as locked inputs.
- Fabro command run.
- Run ID / web UI URL if available.

When the run completes, report:

- Result: succeeded, failed, blocked, or human input needed.
- Run ID / web UI URL.
- Failure classification when failed: implementation failure or workflow failure.
- Kaizen note path and commit status when a workflow failure note was written.
- Implementation branch/ref.
- PR URL and auto-merge status if available.
- Review handoff metadata path (`<iteration-folder>/implementation.md`) and whether it was written/committed.
- Any follow-up Matt needs to do.

## Key Principles

- Pick the smallest-numbered ready iteration by default.
- Do not implement locally; execute the Fabro workflow.
- Do not edit acceptance feature files during implementation.
- Automated tests and `dev check` are the behavioural feedback loop.
- Reviews happen after green checks and should focus on refactoring/maintainability.
- Preserve Matt's control before committing, pushing, or answering human gates.
