Record judgement-worthy review findings for {{ inputs.plan_path }}.

Review runs after implementation has already merged to main. It must not block delivery. Use the review synthesis and reviewer reports to decide whether any finding needs human judgement rather than bounded automatic polish.

Rules:

- If there are no judgement-worthy findings, do not edit files. Say that no code-health entry is needed.
- If there are judgement-worthy findings, append them to `docs/code-health.md` under a dated section for this iteration.
- Do not log issues that were already fixed during this review run.
- Keep entries factual and actionable. Include the plan path, the finding, evidence, risk, and a suggested next action.
- Do not edit acceptance feature files.
- Do not change product behaviour in this step.

Return a concise summary of whether `docs/code-health.md` was updated and why.
