Repair the currently selected task for `{{ inputs.plan_path }}` using the preceding Validate Task repair brief.

Read `.fabro/tmp/selected-task.txt`, the plan, `todo.md`, and the validation output.

Rules:

- Fix only the concrete task-validation gaps identified by the validator.
- Stay within the selected task and approved plan.
- Do not broaden the implementation to later unchecked tasks.
- Do not delete, weaken, or defer plan-required work from `todo.md`.
- Add/update automated tests needed to prove the selected task.
- Never edit acceptance feature files (`*.feature`, including files under `acceptance-tests/`).
- Do not commit and do not mark the task done; later nodes handle those steps.
- If the repair requires a plan change, feature-file change, or product/architecture decision, stop and request human input.

When finished, summarize the repair, tests run, and remaining risks.
