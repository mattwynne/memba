Implement only the currently selected iteration task.

Plan path: `{{ inputs.plan_path }}`.
Task selection is written by the preceding Pick Next Task stage in `.fabro/tmp/selected-task.txt`. Read that file before editing.
Todo path is derived from the plan path by replacing `/plan.md` with `/todo.md`.

## Binding rules

- `plan.md` remains the source of truth. `todo.md` is derived execution state.
- Implement only the selected unchecked task. Do not opportunistically implement later tasks unless the selected task cannot be completed without splitting/reordering the todo list first.
- You may split the selected task into smaller unchecked tasks, add required technical subtasks, or reorder pending tasks only to satisfy the approved plan.
- You may not delete, weaken, or silently defer plan-required work.
- If the selected task is too large, split it in `todo.md`, leave the parent/current task unchecked or replace it with smaller unchecked tasks, and implement only the first newly available slice.
- Before editing, read every ADR explicitly referenced by the plan and inspect nearby/current ADRs under `docs/adr/` when relevant.
- Treat accepted ADRs as binding architecture constraints.
- Use test-driven development for behaviour changes.
- Add or update automated tests proving the selected task's behaviour/configuration.
- Never edit acceptance feature files (`*.feature`, including files under `acceptance-tests/`). If a feature file appears wrong, stale, or insufficient, stop and report the issue.
- Add acceptance step definitions only where the plan explicitly requires executable plumbing for locked shared feature files.
- Use Req for HTTP requests; do not introduce HTTPoison, Tesla, or `:httpc`.
- Follow relevant project guidance for Phoenix, LiveView, HEEx, Tailwind, Ecto, Elixir, Mix, and tests.
- Do not mark the task done and do not commit. Later workflow nodes validate, update `todo.md`, and commit.
- If you hit a real blocker, stop and report it clearly.

When finished, summarize:

1. Selected task.
2. Code/config/test changes made for this task only.
3. Tests run and results.
4. Evidence that the task is ready to be checked off.
5. Any todo splits/additions/reordering and why they still satisfy the plan.
6. ADR conformance evidence for this task.
