# Problem: Plan validation failed because reviewers saw truncated plan text

Date: 2026-06-01

## Context

Matt ran Fabro delivery for iteration 015 after the plan was published:

- Plan: `docs/iterations/015-club-slugs/plan.md`
- Delivery/validation run ID: `01KT2NEZKFQT10R9BAN2HWQSVS`
- Workflow involved: `.fabro/workflows/plan-validation/workflow.fabro`

The plan file is long enough that the validation read stages emitted about 12.7KB of text:

- `read_plan@1` ran `sed -n '1,260p' docs/iterations/015-club-slugs/plan.md`, with `output_bytes: 12741`.
- `read_updated_plan@1` ran `sed -n '1,320p' docs/iterations/015-club-slugs/plan.md`, with `output_bytes: 12753`.

## Expected standard

Plan validation should review the actual plan content before deciding whether a plan is ready. If a read stage output is too large for model context or display, the workflow should make that obvious and recover by reading smaller chunks, not treat hidden sections as absent plan content.

## What happened

The validation failed before implementation started.

Observed from `origin/fabro/meta/01KT2NEZKFQT10R9BAN2HWQSVS`:

- Gemini, Claude, and Codex/GPT review stages all reported `NOT READY` because they could not see the start of the plan.
- Their blockers were about missing sections such as Goal, Scope, Acceptance Criteria, Acceptance Scenarios / Feature Files, and Implementation steps 1-14.
- The missing sections were present in the repository plan file; they were hidden from the reviewers by context/output truncation.
- The synthesis stage set `plan_needs_fix=true` rather than recognizing this as a workflow evidence/readability problem.
- Codex then changed only the plan status from `ready` to `validated`, even though the workflow had not successfully validated the plan.
- Opus recheck correctly identified the problem as a review-context problem, not a plan-content problem, and suggested reading the plan in smaller chunks:
  - `sed -n '1,80p' docs/iterations/015-club-slugs/plan.md`
  - `sed -n '81,160p' docs/iterations/015-club-slugs/plan.md`
  - `sed -n '161,240p' docs/iterations/015-club-slugs/plan.md`
- The workflow ended at `not_ready@1` with:

```text
Plan validation failed: the plan is not ready for implementation. See the Opus report for remaining gaps or decisions that need human input.
```

The final run conclusion was failed with:

```text
goal gate unsatisfied for node not_ready and no retry target
```

## Impact

This blocked delivery before implementation and spent review-model time on a false negative. It also risked corrupting plan state: Codex marked the plan `validated` inside the failed run even though the validation had not actually succeeded.

## What allowed it to happen

The plan-validation workflow relies on a single large `sed` output for plan evidence. When that output is too large or gets truncated in the model-visible context, reviewer prompts interpret missing visible text as missing plan sections.

The workflow lacks a guardrail to distinguish:

- “the plan file lacks required sections”; from
- “the read-stage evidence shown to reviewers was truncated.”

The synthesis stage also lacks a recovery path for unanimous reviewer objections caused by missing/truncated evidence. It routed to plan editing instead of re-reading the plan in smaller chunks.

## Observations

- The plan-validation workflow already has a fail-closed stance when reviewer decisions are missing, but it does not fail closed or recover when reviewer evidence is known to be truncated.
- The reviewer prompts say “Do not assume any missing details,” which is correct for real missing plan content but harmful when the workflow itself hid the content.
- The read stages use `sed -n '1,260p'` and `sed -n '1,320p'`, but line count is not the only limit; output bytes/context rendering can still hide the start of the file from model stages.
- The recheck report contained a concrete safe recovery: read the plan in smaller chunks and rerun readiness checking using the complete untruncated plan.
- The final user-facing failure text pointed to “remaining gaps or decisions that need human input,” but the observed blocker was a tooling/readability failure, not a product decision.

## Why this matters

Longer, well-structured plans can fail validation because the workflow cannot reliably expose them to reviewers. That creates wasted model spend, blocks delivery, and may encourage agents to edit or shorten plans for tooling reasons rather than because the plan is unclear.

## Open questions

- Where exactly does the truncation occur: Fabro context condensation, stage-output rendering, model prompt construction, or the UI/log view?
- Should plan-validation read the plan in fixed-size chunks by default, or should it add a truncation detector and retry only when evidence is incomplete?
- Should Codex be forbidden from marking a plan `validated` unless the workflow is about to publish through `publish_ready`?
- Does `publish_ready.sh` or the wrapper need to repair the local plan status after a failed validation run that changed status in the sandbox only?

## Possible prevention ideas

- Change `read_plan` and `read_updated_plan` to emit chunked sections with explicit markers, for example 1-80, 81-160, 161-240, and 241-320.
- Add a deterministic read-stage check that prints required section headings and line numbers separately from the full text.
- Teach synthesis to classify reviewer blockers such as “first N lines omitted” or “output truncated” as a workflow evidence failure, not a plan-content failure.
- Add a validation fixture with a long ready plan to prove the workflow can validate plans whose full text exceeds a single comfortable output chunk.
- Prevent `codex_update` from changing `Status:` to `validated`; reserve that state transition for `publish_ready.sh` after the final ready gate succeeds.
