Preserve the preceding focused-review or human-gate finding durably in `docs/code-health.md` for {{ inputs.plan_path }}.

This is a docs-only recording step, not permission to change code, config, tests, product behaviour, ADRs, migrations, production data, security/privacy policy, or acceptance features. Include the date, plan path, stable finding ID when available, factual file/symbol/ADR evidence, risk, disposition, and suggested next action. Include Matt's selected option or freeform guidance from `human.gate` when present. Do not claim the finding is fixed.

If the same finding is already present, make no duplicate edit and explain the no-op. If recording is needed, verify `git diff -- docs/code-health.md`. If you cannot preserve the finding, fail closed.

End with exactly one routing JSON object. Success/no-op:
`{"context_updates":{"code_health_recording_ok":true,"review_disposition":"record"}}`
Failure:
`{"context_updates":{"code_health_recording_ok":false}}`
