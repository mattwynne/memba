Validate the just-completed iteration task for `{{ inputs.plan_path }}`.

You have tool access. Use it. Decide from live repository state, not from summarized context alone. Read `.fabro/tmp/pre-validate-snapshot.md`, run `git status --short`, inspect `git diff`, and read changed files as needed.

Important workflow contract: `implement_next_task` does **not** commit. The deterministic `commit_task` node commits **after** this validation. Therefore, at validation time it is correct and expected that HEAD is the **previous** successful task commit while the current task's new/changed files and the `todo.md` check-off are **uncommitted** in the working tree, often as untracked files.

Validate the working tree, not `git log`. A previous task's commit at HEAD is never, by itself, evidence of stale replay, memoization, lost writes, or a filesystem bridge failure. Do not infer infrastructure faults unless live repository evidence proves the expected files or diffs are genuinely absent.

Do not rely on a selected-task temp file. Instead inspect the plan, `todo.md`, relevant ADRs, current repository diff/status, test evidence, and the preceding implementation summary. Identify the completed task by the working-tree `todo.md` diff: exactly one ordinary task line should have changed from unchecked (`- [ ]`) to checked (`- [x]`) unless there is a clear plan-preserving split/reorder rationale.

## Validate

Accept the task only if all are true:

- The checked-off task is the first unchecked task that existed when the implementor started, or a clearly justified first slice after a plan-preserving split.
- The same task that was implemented has been checked off in `todo.md`.
- The task has concrete code/config/test/documentation evidence as appropriate; a todo-only change is invalid.
- The work stays within the approved plan and preserves plan-required scope.
- Any todo changes split/add/reorder only to satisfy the plan; no plan-required work was deleted, weakened, or silently deferred.
- Relevant automated tests were added/updated and focused tests were run, or a justified blocker was reported.
- Accepted ADR constraints relevant to this task are respected.
- No acceptance feature files (`*.feature`, including under `acceptance-tests/`) were edited.
- The task is small enough to be committed independently with a useful evidence trail.

If validation fails but the task is still clear and safe to attempt again, request a clean retry from the last successful task commit. Do not ask for in-place repair. Only request human input when the task, plan, or repository state is ambiguous, unsafe, repeatedly failing for the same non-transient reason, or blocked by a decision/tooling issue that another clean attempt is unlikely to solve.

## Output format

Return concise Markdown with:

### Decision
One of: **VALID**, **RETRY**, or **HUMAN_INPUT**

### Evidence
- Completed todo/check-off evidence found.
- Implementation artifacts found.
- Tests run/results found.
- ADR/plan conformance notes.

### Retry brief
Only if RETRY: exact reason the attempt was rejected from live working-tree evidence, plus concise guidance for the next clean attempt. The workflow will snapshot the failed working tree before resetting and trying again.

### Human input
Only if HUMAN_INPUT: exact blocker/question.

End your response with exactly one JSON object for Fabro routing, not in a code fence:

- Valid:
  {"context_updates":{"task_valid":true,"task_retry_available":false}}
- Clean retry needed:
  {"context_updates":{"task_valid":false,"task_retry_available":true}}
- Human input required:
  {"context_updates":{"task_valid":false,"task_retry_available":false}}
