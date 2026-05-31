# Problem: Review workflow accepted code but still failed during finalization

Date: 2026-05-30

## Context

We ran the iteration review workflow for the rescued iteration 006 implementation:

- Implementation commit: `e112917` (`Implement browser Cucumber automation`)
- Plan: `docs/iterations/006-browser-cucumber-automation/plan.md`
- Review run: `01KSY7ZSD15X0ZS9PWQ0H74VKY`
- Review command: `PATH="$PWD/bin:$PATH" dev fabro review review/006-browser-cucumber-automation docs/iterations/006-browser-cucumber-automation/plan.md afb4188dcc5ddfe88d0753add1ec35c8738231d4`

## What happened

The review completed its substantive review stages successfully:

- `dev check` passed in the review sandbox.
- Gemini, Codex, and Claude review branches all succeeded.
- The synthesis accepted the implementation with `implementation_accepted: true` and `review_fixes_available: false`.
- The code-health recording step said no `docs/code-health.md` entry was needed.

After acceptance, the workflow still failed in finalization:

```text
✗ Final Artifact Gate
Error: Acceptance .feature files must not be modified during implementation or review.
```

The workflow then attempted to continue and failed marking the iteration merged:

```text
✗ Finalize Iteration Status
Error: env: ‘python3’: No such file or directory

✗ Fail: Finalize Iteration Status
Error: Iteration review succeeded but could not mark the iteration merged. Rerun review after resolving push/status conflicts.
```

Manual follow-up was needed to push the status changes to `main`.

## Observations

- The review workflow reached a clear semantic decision: the implementation was accepted and no fixes were required.
- A later artifact/finalization gate converted that accepted review into an overall failed Fabro run.
- The same broad `.feature` guard that blocked implementation publish also blocked review finalization, even though iteration 006 intentionally changed `operator_email_deliverability.feature` by adding the temporary `@todo-web` browser-partition tag.
- The finalization script depends on `python3`, but the review sandbox environment did not provide it on `PATH` for that step.
- The final user-facing status was therefore ambiguous: the code review was successful, but the workflow result was `FAILED`.
- This required manual interpretation of run logs and manual status publication.

## Why this matters

A workflow that reports failure after accepting the implementation creates avoidable confusion. It obscures the difference between product/code review findings and delivery-pipeline failures, and it makes operators decide manually whether the implementation is safe to move forward.

## Open questions

- Should review finalization distinguish “review accepted but publish/finalization failed” from “review rejected” in the run result and summary?
- Should the `.feature` guard accept explicitly planned feature-tag changes, or receive a list of permitted `.feature` paths/patches from the implementation workflow?
- Should review sandbox preflight verify that `python3` is available before reaching finalization?
- Should the workflow stop immediately after a failed final artifact gate instead of continuing into status finalization?

## Resolution

Date: 2026-05-31

Root cause: Review finalization used the implementation `base_sha..HEAD` diff to enforce a blanket `.feature` lock, so explicitly planned implementation feature-file changes were treated as forbidden review changes after the review had already accepted the implementation. The final artifact gate also had no explicit failure node, so a policy failure could continue into status finalization and produce an ambiguous "accepted but failed" run. The separate `python3` failure was an environment-contract gap for scripts that run outside `bin/dev`'s devenv shell.

Fix applied:

- `.fabro/workflows/iteration-review/scripts/final_artifact_gate.sh`: extracted the final artifact policy into a tested script. It now applies the implementation workflow's explicit plan-permission guard to implementation feature-file changes since `base_sha`, while separately rejecting any `.feature` changes made during review polish since `.fabro/tmp/review-start-sha.txt`.
- `.fabro/workflows/iteration-review/scripts/test_final_artifact_gate.sh`: added regression coverage for planned implementation feature edits, missing plan permission, and forbidden review-polish feature edits.
- `.fabro/workflows/iteration-review/workflow.fabro`: calls the extracted final artifact gate script, checks for bare `python3` during review preflight before later finalization scripts need it, and routes final artifact policy failures to an explicit accepted-but-final-artifact-failed terminal node instead of continuing toward status finalization.

Validation:

- `.fabro/workflows/iteration-implementation/scripts/test_guard_acceptance_feature_changes.sh` — passed.
- `.fabro/workflows/iteration-review/scripts/test_final_artifact_gate.sh` — passed.
- `fabro validate .fabro/workflows/iteration-review/workflow.toml` — passed with existing goal-gate retry warnings.
- `dev check` — passed (132 ExUnit tests, 0 failures).

Remaining follow-up:

- None for this note.
