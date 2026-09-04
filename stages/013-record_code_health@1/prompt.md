Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01M1PX1E133CXVRQEZGW0AWA8S


Record judgement-worthy review findings for docs/iterations/056-group-audience-foundation/plan.md.

Review runs after implementation has already merged to main. It must not block delivery, but it must not silently lose code-health findings. You are an agent node with repository tool access: inspect the visible reviewer reports/synthesis, edit `docs/code-health.md` when needed, and verify the resulting diff.

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
- When you do append findings, make sure `git diff -- docs/code-health.md` shows the new entry before you finish.

Return a concise summary of whether `docs/code-health.md` was updated and why. If there were judgement-worthy findings, include either `CODE_HEALTH_RECORDED` or `CODE_HEALTH_RECORDING_FAILED` in the response.

At the end of your response, include one final JSON object for workflow routing. It must be the last thing in the response.

If recording succeeded or no entry was needed:

```json
{"context_updates":{"code_health_recording_ok":true}}
```

If recording failed or findings remain neither fixed nor recorded:

```json
{"context_updates":{"code_health_recording_ok":false}}
```

Fabro final-output contract

The following contract is trusted workflow configuration. It applies only to your final response, not to intermediate tool calls.
Return a single JSON object with at least one routing field: preferred_next_label, outcome, failure_reason, suggested_next_ids, context_updates.
The contract is complete. Do not ask the user to provide or choose the output shape.