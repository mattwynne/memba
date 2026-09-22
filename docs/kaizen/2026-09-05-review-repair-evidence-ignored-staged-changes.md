# Problem: review repair evidence ignored staged changes

Date: 2026-09-05

## Observation

Iteration 057 review run `01M1RBYHQRP1MNP5PXSAS6S2XP` applied requested documentation and test-support repairs, then `verify_review_repair@1` failed with:

```text
review repair produced no working-tree diff change since repair started.
```

The repair agent had staged its changes. The verifier examined only unstaged `git diff`, so it reported no change even though the repository contained a valid staged repair. The graph's unconditional route still proceeded to `dev_check`; later validation and final artifact checks passed and the review completed successfully.

The same run's generated final summary also described a different set of five code-health findings from the five entries actually published in `docs/code-health.md`. Repository state was correct, but the human-facing summary was not grounded in exact final code-health evidence.

## Impact

- A healthy repair node was falsely marked failed, making run history misleading.
- The final review summary could not be trusted as an exact account of published follow-up work.
- Operators had to inspect `origin/main` and `docs/code-health.md` to reconcile the report.

## Resolution

Date: 2026-09-05

Root cause: the repair snapshot/verifier modeled only an unstaged working-tree patch. It did not preserve the baseline `HEAD` or compare the complete repository state, so staged or committed repair changes were invisible. Separately, the final artifact gate listed changed paths but did not provide the actual code-health diff, leaving the final-summary model to reconstruct findings from earlier synthesis context.

Fix applied:

- `.fabro/workflows/iteration-review/scripts/verify_review_repair.sh`: compare the complete staged, unstaged, and committed repository state against the captured baseline commit; retain the no-op and locked-feature protections.
- `.fabro/workflows/iteration-review/workflow.fabro`: capture baseline `HEAD` and delegate verification to the tested script.
- `.fabro/workflows/iteration-review/scripts/test_verify_review_repair.sh`: prove staged and committed repairs pass, while no-op repairs and staged acceptance-feature changes fail.
- `.fabro/workflows/iteration-review/scripts/final_artifact_gate.sh`: emit the exact `docs/code-health.md` diff recorded since review start.
- `.fabro/workflows/iteration-review/scripts/test_final_artifact_gate.sh`: prove the final evidence includes the exact staged code-health heading.
- `.fabro/workflows/iteration-review/prompts/final_summary.md`: require the summary to use that exact diff rather than substitute findings from earlier reviewer/synthesis responses.

Validation:

- `bash .fabro/workflows/iteration-review/scripts/test_verify_review_repair.sh` — passed all staged, committed, no-op, and locked-feature cases.
- `bash .fabro/workflows/iteration-review/scripts/test_final_artifact_gate.sh` — passed and proved the final evidence includes the exact staged code-health heading.
- `fabro validate .fabro/workflows/iteration-review/workflow.toml --no-upgrade-check` — `Validation: OK`; only the existing intentional finalization goal-gate warning remains.
- Shell syntax checks for all changed scripts — passed.
- `env -u MEMBA_DEVENV_SHELL ./bin/dev check` — 1,129 tests with 0 failures; 122 browser scenarios and 877 steps passed.
- Independent Claude review — approved with no blockers.

Remaining follow-up:

- Confirm exact code-health grounding in the next review run; do not rerun the already accepted iteration 057 review solely to regenerate its prose summary.
