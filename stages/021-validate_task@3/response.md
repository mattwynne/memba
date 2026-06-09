### Decision
**RETRY**

### Evidence
- Completed todo/check-off evidence found:
  - Live working tree has no tracked diff; only untracked `.fabro/tmp/`.
  - Recent checkpoint `7b37c91 fabro(...): implement_next_task (succeeded)` changed only `docs/iterations/031-brand-email-navigation-polish/todo.md`.
  - Diff from the prior checkpoint shows task 003 changed from unchecked to checked, and the prior todo state shows task 003 was the first unchecked task.
- Implementation artifacts found:
  - The only changed artifact is the todo file itself, with a finding naming `Memba.EmailTemplates.memba_footer/1` and `render_shell/1`’s `:footer` option.
  - Existing source does contain `web/lib/memba/email_templates.ex` with `render_shell/1`, `memba_footer/1`, and `trust_footer/1`, corroborating the finding.
  - However, the attempt is todo-only. The validation contract explicitly says a todo-only change is invalid.
- Tests run/results found:
  - No live repository test evidence beyond the implementor’s summary of `git diff --check`.
  - No code/app behavior changed, so focused executable tests are not inherently required for this inspection slice, but the lack of any non-todo artifact still fails validation.
- ADR/plan conformance notes:
  - The checked task is in plan order and within scope.
  - No acceptance `*.feature` files were edited.
  - No ADR issue found, but the checkpoint is too thin to satisfy the required evidence trail.

### Retry brief
Rejecting because live repository evidence shows the just-completed checkpoint changed only `todo.md`; the validator requires concrete evidence beyond a todo-only check-off. On the next clean attempt, complete task 003 with a small plan-preserving artifact outside the todo file, such as an iteration implementation note documenting the inspected source locations and canonical footer/helper decision, then check off task 003 and run at least `git diff --check` with a brief justification that no executable tests apply to the inspection-only slice.

{"context_updates":{"task_valid":false,"task_retry_available":true}}