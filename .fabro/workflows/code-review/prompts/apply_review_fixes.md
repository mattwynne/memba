Apply one bounded healing pass for the focused review of {{ inputs.plan_path }}.

Use only the preceding review's factual evidence. Make the smallest low-risk code/config/test change that preserves existing product behaviour and architecture. Do not make product decisions, ADR/architecture changes, migrations/production-data changes, security/privacy policy changes, broad cross-cutting changes, or acceptance-feature changes.

Do not commit or push. Do not spawn subagents. Run only focused checks directly related to the change. Do not run `dev check`, `dev check --quick`, `dev ci`, or another full suite here; the workflow owns the exact-state full gate. Do not launch background/detached commands.

There is only one automatic repair pass. If the finding cannot be safely fixed, is already fixed, repeats, or would produce no meaningful repository diff, leave clear factual evidence; the deterministic progress check will escalate to Matt rather than loop.

Summarize the finding-to-change mapping, files changed, focused checks and remaining risk.
