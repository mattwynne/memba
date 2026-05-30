---
name: iteration-deliver
description: Pick a ready iteration plan and launch the Fabro iteration-deliver workflow, which validates, implements, reviews, and marks the iteration merged through child runs. Use when Matt asks to deliver a ready iteration or rerun delivery without returning to planning.
---

# Iteration Deliver

## Overview

Pick a ready iteration from `docs/iterations/README.md` or use Matt's specified plan path, then launch the project's `iteration-deliver` workflow.

<HARD-GATE>
Do not implement or review application code directly in the local checkout. This skill only selects/verifies the plan, validates the delivery workflow, starts the Fabro parent run, and reports/monitors high-level stage status when asked.
</HARD-GATE>

## Checklist

1. Check `git status --short --branch`. If required workflow/plan artifacts are uncommitted or unpushed, ask Matt before committing/pushing them.
2. Select the plan:
   - Use Matt's specified iteration number/folder/plan path when provided.
   - Otherwise read `docs/iterations/README.md` and choose the lowest-numbered iteration with status `ready` or `fabro-ready`.
3. Verify the plan file exists and ends with `/plan.md`.
4. Validate the deliver workflow:
   ```bash
   fabro validate .fabro/workflows/iteration-deliver/workflow.toml
   ```
5. Launch delivery:
   ```bash
   fabro run .fabro/workflows/iteration-deliver/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md
   ```
6. Report the selected iteration, plan path, command, run ID/URL if printed, and that child runs will appear under the deliver run's Children tab.

## Result handling

- `validation:not-ready`: summarize blockers and recommend returning to `iteration-planning` to revise the plan.
- `validation:failed`: report as workflow/tooling failure before implementation.
- `implementation:failed`: report as implementation failure; no review ran.
- `delivered:with-review-notes`: delivery landed on `main`; surface review failure/notes as follow-up.
- `delivered:clean`: implementation, review, and merged-status finalization completed.
- `finalize:failed`: implementation/review may have landed, but status metadata push failed; report the exact command to retry if available.

## Key principles

- One parent run, three child runs: validation → implementation → review.
- Review is post-merge and non-blocking.
- The parent owns the final `ready`/`fabro-ready` → `merged` status update.
