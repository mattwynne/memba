### Decision
**RETRY**

### Evidence
- Completed todo/check-off evidence found:
  - Live `git status --short` shows only untracked `.fabro/tmp/`.
  - Recent checkpoints show `277973f` is `pre_validate_snapshot` and `efcc516` is the implementation checkpoint.
  - `git diff efcc516^ efcc516 -- docs/iterations/031-brand-email-navigation-polish/todo.md` shows exactly one ordinary task checked off:
    - `006 Inspect inbound club-message rejection email construction and the email request/provider shape for display-name support.`
  - Parent todo state had tasks 001–005 checked and task 006 as the first unchecked task.

- Implementation artifacts found:
  - The implementation checkpoint changed only `docs/iterations/031-brand-email-navigation-polish/todo.md`.
  - The added finding is plausible and corroborated by source inspection:
    - `web/lib/memba/messaging/inbound_club_rejection_email.ex` builds/delivers rejection emails and currently derives `from` via `from_address/1`.
    - `web/lib/memba/messaging.ex` passes `club_name: destination.club_name` for resolved club rejection paths.
    - `web/lib/memba/messaging/email_delivery_providers/resend_adapter.ex` supports named `from` tuples.
  - However, under the validation contract, a todo-only change is invalid. There is no concrete documentation artifact outside the todo file, and no code/config/test artifact changed for this task.

- Tests run/results found:
  - `git diff --check efcc516^ efcc516` passes.
  - No focused automated tests were run or needed for a pure inspection, but the only durable change was still todo-only.

- ADR/plan conformance notes:
  - The selected task is in-plan and was the correct next task.
  - No acceptance feature files were edited; checkpoint diff contains only `todo.md`.
  - The finding is consistent with ADR 0016’s provider-boundary constraints, but the evidence trail is not sufficient because it is only stored in the todo file.

### Retry brief
Rejecting from live repository evidence because checkpoint `efcc516` modifies only `docs/iterations/031-brand-email-navigation-polish/todo.md`; the prompt requires concrete code/config/test/documentation evidence as appropriate and says a todo-only change is invalid.

Next clean attempt should keep the same task 006 scope, create a small durable inspection note outside `todo.md` such as `docs/iterations/031-brand-email-navigation-polish/task-006-inbound-rejection-email-inspection.md` with the inspected files/functions, provider-shape findings, and ADR notes, then check off task 006 in `todo.md`. Do not implement task 007 behavior yet.

{"context_updates":{"task_valid":false,"task_retry_available":true}}