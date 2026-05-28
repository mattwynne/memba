Validate the currently selected iteration task for `{{ inputs.plan_path }}`.

Read `.fabro/tmp/selected-task.txt`, the plan, `todo.md`, relevant ADRs, current repository changes, and the preceding implementation summary.

## Validate

Accept the task only if all are true:

- The selected task has concrete code/config/test/documentation evidence as appropriate.
- The work stays within the approved plan and preserves plan-required scope.
- Any todo changes split/add/reorder only to satisfy the plan; no plan-required work was deleted, weakened, or silently deferred.
- Relevant automated tests were added/updated and targeted tests were run, or a justified blocker was reported.
- Accepted ADR constraints relevant to this task are respected.
- No acceptance feature files (`*.feature`, including under `acceptance-tests/`) were edited.
- The task is small enough to be committed independently with a useful evidence trail.

If validation fails, provide a concrete repair brief scoped only to the selected task.

## Output format

Return concise Markdown with:

### Decision
One of: **VALID**, **REPAIR**, or **HUMAN_INPUT**

### Evidence
- Task evidence found.
- Tests run/results found.
- ADR/plan conformance notes.

### Repair brief
Only if REPAIR: exact issues to fix, expected files/modules/tests, and constraints.

### Human input
Only if HUMAN_INPUT: exact blocker/question.

End your response with exactly one JSON object for Fabro routing, not in a code fence:

- Valid:
  {"context_updates":{"task_valid":true,"task_repair_available":false}}
- Automatic repair needed:
  {"context_updates":{"task_valid":false,"task_repair_available":true}}
- Human input required:
  {"context_updates":{"task_valid":false,"task_repair_available":false}}
