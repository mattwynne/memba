### Decision
**RETRY**

### Evidence
- Completed todo/check-off evidence found:
  - Recent checkpoint `0eebff6 fabro(...): implement_next_task (succeeded)` changed exactly one ordinary task line:
    - `- [ ] 001 ...` → `- [x] 001 ...`
  - Task 001 was the first unchecked task from the generated `todo.md`.
- Implementation artifacts found:
  - Live working tree is clean.
  - `git show 0eebff6 --name-only` shows only `docs/iterations/031-brand-email-navigation-polish/todo.md` changed.
  - The only added evidence is an indented finding note inside `todo.md`.
  - No code/config/test/documentation artifact outside the todo file was created or modified.
- Tests run/results found:
  - The implementation summary reports `git diff --check` passed.
  - No focused automated test evidence is present in the repository/checkpoint, which is acceptable for a pure inspection slice only if there is durable non-todo evidence; that is missing.
- ADR/plan conformance notes:
  - The checked task is within the approved plan and no acceptance feature files were edited.
  - However, validation rules explicitly reject todo-only changes: “a todo-only change is invalid.”

### Retry brief
Rejecting because live repository evidence shows the implementation checkpoint changed only `todo.md`. For the clean retry, complete task 001 again but leave durable inspection evidence outside the todo checklist—for example, a focused iteration implementation note documenting the inspected homepage files and the smallest intended copy/title change—then check off only task 001. Do not edit acceptance feature files for this task.

{"context_updates":{"task_valid":false,"task_retry_available":true}}