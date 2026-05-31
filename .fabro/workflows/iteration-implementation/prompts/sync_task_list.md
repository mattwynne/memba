Synchronize the execution todo list for the validated Memba iteration plan.

Plan path: `{{ inputs.plan_path }}`.
Iteration directory: derive this from the plan path by removing the final `/plan.md` segment.
Todo path: `<iteration directory>/todo.md`.

## Purpose

`plan.md` is the approved source of truth for scope. Once created, `todo.md` is the source of truth for execution state used to drain the implementation one task at a time.

## Resume contract

- Regenerate `todo.md` from `plan.md` only when `todo.md` is absent.
- If `todo.md` already exists, preserve its check-offs, splits, additions, and ordering across runs.
- Never overwrite an existing `todo.md` merely because the workflow was rerun.
- Treat unexpected completed-state inconsistencies as blockers to report, not state to silently repair.

## Instructions

- Read `AGENTS.md`, the plan at `{{ inputs.plan_path }}`, and any ADRs or project guidance referenced by the plan.
- Create `todo.md` if it does not exist.
- If `todo.md` exists, reconcile it with the approved plan without weakening the plan or overwriting execution state.
- Keep the todo file lean:

  ```md
  # Implementation TODO

  - [ ] 001 Short task title
  - [ ] 002 Short task title
  ```

- Preserve checked tasks unless there is clear evidence they were checked incorrectly; if so, stop and report the inconsistency instead of silently changing completed state.
- You may split, add, or reorder unchecked todos only to satisfy dependencies or make the approved plan executable.
- You may add newly discovered technical tasks only when required to satisfy the plan.
- You may not delete, weaken, silently defer, or hide plan-required work.
- If you discover work outside the approved plan, add it under an `## Out of scope / discovered` section or report a blocker; do not mix it into the in-scope task list.
- Do not edit the approved `plan.md`.
- Acceptance feature files (`*.feature`, including files under `acceptance-tests/`) are locked unless the plan has a `## Allowed acceptance feature changes` section naming the exact file and allowed kind of change.

When finished, summarize the todo path and any changes you made to align it with the plan.
