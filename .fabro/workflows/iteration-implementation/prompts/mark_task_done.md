Mark the validated selected task done in the iteration todo file.

Plan path: `{{ inputs.plan_path }}`.
Read `.fabro/tmp/selected-task.txt` and the todo file derived by replacing `/plan.md` with `/todo.md`.

Rules:

- Mark only the selected task done, unless the implementor deliberately split it; in that case mark only the concrete completed checked item(s) that have validation evidence and leave remaining split tasks unchecked.
- Do not mark unrelated pending tasks done.
- Do not delete, weaken, or defer plan-required work.
- Keep `todo.md` lean; do not add detailed notes beyond concise task lines.
- Never edit acceptance feature files (`*.feature`).
- Do not commit; the next workflow node commits the task.

When finished, summarize exactly which todo line(s) you checked off and the evidence supporting each.
