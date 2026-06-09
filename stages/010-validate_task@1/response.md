### Decision

**RETRY**

### Evidence

- Completed todo/check-off evidence found:
  - Latest/recent implementation checkpoint `f79adfa` changed exactly one ordinary todo line:
    - `001 Inspect the current homepage template/component...` from `- [ ]` to `- [x]`.
  - That was the first unchecked task in `docs/iterations/031-brand-email-navigation-polish/todo.md`.
- Implementation artifacts found:
  - Live working tree is clean.
  - `git show f79adfa --name-only` shows only:
    - `docs/iterations/031-brand-email-navigation-polish/todo.md`
  - The checkpoint added an inspection note under the todo item, but no non-todo documentation, code, config, or test artifact was changed.
- Tests run/results found:
  - Implementation summary reports `git diff --check` passed.
  - No focused automated tests were run, with a docs-only rationale.
- ADR/plan conformance notes:
  - The selected task is within the approved plan and was small enough.
  - No acceptance feature files were edited.
  - No relevant ADR files were found in the repository scan.
  - However, validation requires concrete implementation evidence as appropriate, and explicitly rejects todo-only changes. This attempt only modified `todo.md`.

### Retry brief

Rejected because live repository evidence shows the implementation checkpoint `f79adfa` only modified `docs/iterations/031-brand-email-navigation-polish/todo.md`. A todo-only change is invalid for this validation contract, even for an inspection task.

Next clean attempt should redo task 001 and leave durable non-todo evidence, for example a concise iteration implementation/inspection note in the iteration directory documenting the inspected homepage files and the smallest planned copy/template change, then check off the same todo item. Keep the scope to inspection only unless the workflow selects the next implementation task.

{"context_updates":{"task_valid":false,"task_retry_available":true}}