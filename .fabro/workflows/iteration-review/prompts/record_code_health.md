Record judgement-worthy review findings for {{ inputs.plan_path }}.

Review runs after implementation has already merged to main. It must not block delivery. Use the review synthesis and reviewer reports to decide whether any finding needs human judgement rather than bounded automatic polish. Do not emit shell-command/tool-call JSON; either edit `docs/code-health.md` when needed or return a concise prose summary.

Rules:

- If there are no judgement-worthy findings, do not edit files. Say that no code-health entry is needed.
- If the review synthesis lists any `Code-health findings for human judgement`, append them to `docs/code-health.md` under a dated section for this iteration.
- If independent reviewer reports include judgement-worthy findings but synthesis omitted them, append the supported findings and mention that synthesis omitted them.
- If there are judgement-worthy findings, append them to `docs/code-health.md` under a dated section for this iteration.
- Do not log issues that were already fixed during this review run.
- Keep entries factual and actionable. Include the plan path, the finding, evidence, risk, and a suggested next action.
- Do not edit acceptance feature files.
- Do not change product behaviour in this step.
- Do not silently drop findings. If you cannot edit `docs/code-health.md` for any reason, return a response starting with `CODE_HEALTH_RECORDING_FAILED:` and explain the exact findings that still need recording.
- When you do append findings, make sure `git diff -- docs/code-health.md` would show the new entry before you finish.

Return a concise summary of whether `docs/code-health.md` was updated and why. If there were judgement-worthy findings, include either `CODE_HEALTH_RECORDED` or `CODE_HEALTH_RECORDING_FAILED` in the response.
