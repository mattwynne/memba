# Problem: Iteration review accepted despite failing to record code-health findings

Date: 2026-06-09

## Context

We checked whether the Fabro workflow reviewed iteration 031, `docs/iterations/031-brand-email-navigation-polish/plan.md`.

Relevant run:

- Workflow: `iteration-review`
- Run ID: `01KTP93QJMPN6T387GRBVC1QXN`
- Base SHA: `f8dc9335a51468eb9e94b0e2a8637d22ea75be8e`
- Reviewed implementation commit: `f074e5bf54aca593d2f5a17d7c976a4807544727`
- Final run status: `SUCCEEDED`

The review ran Claude, Codex/GPT, and Gemini reviewers. All accepted the implementation and identified no blocking issues, but they did identify judgement-worthy non-blocking code-health observations.

## Expected standard

The iteration-review workflow is expected to preserve review findings after implementation has merged.

Current standard work says:

- `.fabro/workflows/iteration-review/prompts/synthesize_review.md` requires judgement-worthy non-blocking findings to be preserved in a `Code-health findings for human judgement` section.
- `.fabro/workflows/iteration-review/prompts/record_code_health.md` requires the `Record Code Health Findings` step to append judgement-worthy findings to `docs/code-health.md`.
- The same prompt says: if the step cannot edit `docs/code-health.md`, it must return `CODE_HEALTH_RECORDING_FAILED:` and explain the findings that still need recording.
- `.fabro/workflows/iteration-review/prompts/final_summary.md` requires unrecorded findings to be called out explicitly as a workflow failure/gap.

## What happened

The review workflow reached `Record Code Health Findings` and the step detected findings that should have been recorded, but it did not edit `docs/code-health.md`.

The step response included:

```text
CODE_HEALTH_RECORDING_FAILED: I could not edit `docs/code-health.md` because this chat has no repository file-editing/tool access available.
```

The final summary correctly reported this as not recorded:

```text
Because `docs/code-health.md` is not listed in the final artifact gate evidence, the non-blocking findings remain unrecorded. This should be treated as a workflow failure/gap, not as completed code-health tracking.
```

Despite that abnormality, the workflow continued through:

- `Final Artifact Gate` — passed
- `Publish Review Polish to Main` — succeeded with no staged review diff
- `Finalize Iteration Status` — succeeded
- `Final Summary` — succeeded
- Final run status — `SUCCEEDED`

The local `docs/code-health.md` still contains only its initial heading and explanatory sentence.

## Impact

Severity: quality-risk signal / review-accountability gap.

The implementation was accepted correctly, but code-health findings from the review were not captured in the repository. This means future maintainers cannot discover the review debt from the normal `docs/code-health.md` channel. The run summary preserves the evidence for now, but that evidence requires Fabro run archaeology and may be harder to find later.

The workflow also spends reviewer time identifying maintainability risks, then allows the final status to look successful even when the preservation step failed.

## What allowed it to happen

The workflow treats `record_code_health` as an ordinary prompt node with an unconditional edge to `final_artifact_gate`:

```text
record_code_health -> final_artifact_gate
```

There is no gate between the code-health recording step and final artifact publication that checks whether:

- the response contained `CODE_HEALTH_RECORDING_FAILED`;
- judgement-worthy findings existed but `docs/code-health.md` was unchanged;
- `record_code_health` emitted tool-call-looking text instead of making a repository edit;
- the step had the tool/file-edit capability needed to satisfy its contract.

The final summary prompt made the abnormality visible, but it was observational only. It did not change the run outcome, stop finalization, or create a durable repository note.

## Observations

- The independent review stages worked and produced useful non-blocking findings.
- The recorder prompt already has a fail-signal vocabulary: `CODE_HEALTH_RECORDED` and `CODE_HEALTH_RECORDING_FAILED`.
- The workflow did not route differently when the fail signal appeared.
- The final artifact gate only verified final artifact policy and changed files; it did not enforce the code-health recorder contract.
- The publish step reported: `No staged review diff remains after squash reset; main remains unchanged.`
- The final summary was honest about the gap, but the terminal Fabro status was still `SUCCEEDED`.

## Why this matters

The iteration-review workflow is the last delivery-machine step intended to catch and preserve maintainability, ADR, and code-health signals after implementation. If it can succeed while known code-health findings are not recorded, review debt can disappear from the normal project memory and trust in successful review runs is weakened.

## Open questions

- Why did the `record_code_health` prompt believe it had no repository file-editing/tool access in this Fabro run?
- Should failed code-health recording make the review run fail, or should it succeed only after creating an alternative durable artifact?
- Should the final artifact gate or a dedicated code-health gate inspect `docs/code-health.md` diffs when findings are present?
- Is this the same underlying tool-access problem as earlier prompt responses that emitted tool-call-looking JSON instead of editing, or a separate node/tool configuration issue?

## Possible prevention ideas

- Add a deterministic gate after `record_code_health` that fails if `CODE_HEALTH_RECORDING_FAILED` appears in the response.
- Require a `docs/code-health.md` diff when reviewer/synthesis context contains judgement-worthy findings.
- Make `record_code_health` a script-backed or tool-enabled step with a clear edit mechanism, instead of relying on a prompt node that may lack file-edit access.
- Teach the publish/finalization path not to mark review fully succeeded when known findings remain neither fixed nor recorded.

## Resolution

Date: 2026-06-09

Root cause: `record_code_health` was configured as a prompt-only `shape=tab` node even though its contract required editing `docs/code-health.md`. Fabro prompt nodes do not have live repository tool access, so the node could only report `CODE_HEALTH_RECORDING_FAILED`. The workflow then had an unconditional edge from `record_code_health` to `final_artifact_gate`, so that failure signal did not affect routing and the review could still finalize as succeeded.

Fix applied:

- `.fabro/workflows/iteration-review/workflow.fabro`: changed `record_code_health` to an agent node (`shape=box`) with routing output so it can inspect/edit the repository and report whether recording succeeded.
- `.fabro/workflows/iteration-review/workflow.fabro`: added a dedicated `code_health_recording_failed` terminal gate and routed `record_code_health` to final artifact publication only when `context.code_health_recording_ok=true`.
- `.fabro/workflows/iteration-review/prompts/record_code_health.md`: updated the prompt to reflect agent-node tool access and require a final routing JSON object for successful/no-op recording versus failed/unrecorded findings.
- `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`: added guard assertions for the code-health recording node shape and failure route.

Validation:

- `bash .fabro/workflows/iteration-review/scripts/test_review_report_routing.sh` — passed.
- `fabro validate .fabro/workflows/iteration-review/workflow.toml --no-upgrade-check` — passed; expected goal-gate retry warnings remain, including the new code-health recording failure gate.
- `dev check --quick` — passed: 758 tests, 0 failures.
- `dev check` — failed in browser acceptance at the pre-existing/unrelated `Staff create a club with the suggested slug` scenario (`#club-slug-input` remained empty). This workflow-only fix does not touch that product/browser path; a rerun of the acceptance command also showed the same scenario can pass, but full `dev check` still reproduced the failure.

Remaining follow-up:

- A future real review run should confirm the agent node can append `docs/code-health.md` when judgement-worthy findings are present.
- The `Staff create a club with the suggested slug` acceptance instability remains outside this kaizen fix.

Review repair:

- `.fabro/workflows/iteration-review/workflow.fabro`: extracted implementation evidence collection to a script-backed step so the excerpt policy can be tested directly.
- `.fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh`: expanded review evidence excerpts to include changed `.fabro/workflows/` and `docs/kaizen/` files as well as existing product, bin, iteration, and ADR paths.
- `.fabro/workflows/iteration-review/scripts/test_collect_implementation_evidence.sh`: added a focused regression test proving workflow and kaizen changes appear in collected evidence.
- `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`: added a guard that the workflow uses the script-backed evidence collector.

Review repair validation:

- `bash .fabro/workflows/iteration-review/scripts/test_review_report_routing.sh` — passed.
- `bash .fabro/workflows/iteration-review/scripts/test_collect_implementation_evidence.sh` — passed.
- `bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh 745e53ab293802c5ced1a4c877e3c604a996469e | grep -E '^(=== \\.fabro/workflows/iteration-review/(workflow\\.fabro|prompts/record_code_health\\.md|scripts/test_review_report_routing\\.sh) ===|=== docs/kaizen/2026-06-09-iteration-review-code-health-recording-failure\\.md ===|--- changed source/config/test/workflow/kaizen file excerpts ---)'` — passed.
- `dev check --quick` — passed: 758 tests, 0 failures.

Second review repair:

- `.fabro/workflows/iteration-review/workflow.fabro`: replaced the `verify_review_repair` patch comparison from `cmp -s` with `git diff --no-index --quiet`, and made unexpected comparison statuses fail the verification step instead of silently passing.
- `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`: added guard assertions that the repair verifier no longer depends on `cmp` and includes the checked comparison failure path.

Follow-up sharp-edge repair:

- Observation: running `iteration-review` against this kaizen note published review polish successfully, then failed in `finalize_iteration_status` because the path was not an iteration `*/plan.md` file.
- Root cause: `finalize_iteration_status.sh` assumed every review target was an iteration plan even though the workflow is useful for kaizen/workflow review targets too.
- `.fabro/workflows/iteration-review/scripts/finalize_iteration_status.sh`: now skips iteration-status finalization for non-`docs/iterations/*/plan.md` targets instead of failing after publish.
- `.fabro/workflows/iteration-review/scripts/test_finalize_iteration_status.sh`: added a regression test for non-iteration review targets.

Follow-up validation:

- `bash .fabro/workflows/iteration-review/scripts/test_finalize_iteration_status.sh` — passed.
- `bash .fabro/workflows/iteration-review/scripts/test_review_report_routing.sh` — passed.
- `bash .fabro/workflows/iteration-review/scripts/test_collect_implementation_evidence.sh` — passed.
- `fabro validate .fabro/workflows/iteration-review/workflow.toml --no-upgrade-check` — passed with expected goal-gate retry warnings.
- `dev check --quick` — passed: 758 tests, 0 failures.

### Additional observation: 2026-09-04 — review recorded and published code-health findings but still ended failed

#### Context

After iteration 056 implementation reached `main`, we ran the isolated review workflow against `1d11137ca64b0b9dda2a71ff920a2d10b6c81581..70abb33129f595d9dd62a8bcf14f7d9060774f6f`.

Review run `01M1PX1E133CXVRQEZGW0AWA8S` completed independent Claude, Codex, and Gemini reviews; the synthesis accepted the implementation; `Record Code Health Findings`, final artifact gate, review-polish publication, and iteration-status finalization all reported success.

#### What happened

The review committed and pushed:

```text
1c83009f852e520adff4e319e89e77a0270d9326
review polish: iteration 056
```

The commit added the expected judgement-worthy observations to `docs/code-health.md`. The final summary said `REVIEW_ACCEPTED`, all reviewer findings were handled, and the final artifact gate passed.

Despite those durable artifacts, Fabro returned:

```text
Failure: goal gate unsatisfied for node code_health_recording_failed and no retry target
```

The same run also logged managed run-branch push warnings. `origin/main` nevertheless contained the review-polish commit and preserved iteration 056 as `merged`.

#### Impact

A successful review was externally indistinguishable from a failed one unless the operator inspected the repository and final-summary evidence. This is especially misleading because the previous defect in this note was the opposite: unrecorded code-health findings could be hidden by a successful status. Here recorded findings and a successful publish were hidden by a failed status.

#### What allowed it to happen

The review graph retains `code_health_recording_failed` as a `goal_gate=true` terminal node. A positive success path can therefore still end with an unsatisfied failure-node gate under Fabro's terminal gate semantics, even when `record_code_health` succeeded and the review reached publication. The stage's routing and terminal gate configuration are not proved together by a real success-path regression.

#### Cross-reference

See also [implementation-workflow-terminal-success-gate](2026-09-04-implementation-workflow-terminal-success-gate.md), whose additional 2026-09-04 observation records a separate implementation-run mismatch caused by post-publish run-branch checkpoint status. Both failures require checking durable `origin/main` artifacts, but this note is specifically about iteration-review goal-gate routing.

#### Open questions

- Why was `code_health_recording_failed` treated as unsatisfied after the successful `Record Code Health Findings` node?
- Should all failure-message terminal nodes be non-goal nodes, leaving only positive gates such as successful review publication/finalization?
- What workflow simulation test can prove that a success path with recorded code-health findings ends `succeeded`, while a true recording failure ends `failed`?
