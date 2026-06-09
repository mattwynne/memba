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
