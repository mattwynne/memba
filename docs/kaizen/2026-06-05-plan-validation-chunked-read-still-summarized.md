# Problem: Plan validation failed because chunked plan reads were still summarized

Date: 2026-06-05

## Context

Matt ran Fabro delivery for iteration 022 after the plan was published:

- Plan: `docs/iterations/022-request-to-club-onboarding/plan.md`
- Delivery/validation run reported by Matt: `01KTD1SE938RNE62BNWPRQJW4J`
- Reproduced validation run: `01KTD220HT0QNQ3V119DSCHJRK`
- Workflow involved: `.fabro/workflows/plan-validation/workflow.fabro`
- Read helper involved: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh`

This is a recurrence of the same class of problem captured in `docs/kaizen/2026-06-01-plan-validation-truncated-read-false-negative.md`, after the workflow had been changed to read plans in 60-line chunks.

## Expected standard

Plan validation should expose the complete plan text to reviewers before deciding whether a plan is ready. The chunked read stages were expected to prevent model-visible truncation: each `print_plan_chunk.sh` stage should provide a bounded, reviewable slice of the plan with explicit line markers.

If Fabro cannot show the complete evidence to the reviewers, the failure should be reported as a workflow evidence problem with a clear recovery path, not as a plan readiness problem requiring human product decisions.

## What happened

`bin/dev fabro validate-plan docs/iterations/022-request-to-club-onboarding/plan.md` produced run `01KTD220HT0QNQ3V119DSCHJRK`. The workflow failed at `Fail: Plan Not Ready` even though reviewers did not identify a substantive product/planning blocker.

The run's checkpoint context showed all three reviewers classified the plan as `NOT READY` because the evidence shown to them had omissions:

- Gemini: `Workflow-evidence gap: Required chunks of the plan text are omitted from the provided context (e.g., 15 lines omitted) preventing complete review`.
- Claude: `Workflow-evidence gap: Plan chunks omit lines 1-15, 61-75, 121-135, and 181-193, preventing complete review of goal, acceptance criteria, implementation steps, and decisions`.
- Codex/GPT: `Workflow-evidence gap: required plan chunks are omitted/truncated in the provided context, so the full plan cannot be reviewed`.

The reviewers also noted that the visible portions of the plan appeared strong: BDD integration, scope boundaries, reuse of existing slug behaviour, transactional thinking, validation, and follow-up awareness.

The local helper script itself still appears to print the requested line ranges:

```bash
.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh '{{ inputs.plan_path }}' 1 60 360 'original plan chunk 001-060'
```

uses `sed -n "${START_LINE},${END_LINE}p" "$PLAN_PATH"`. This points to the evidence being summarized or compacted after command output capture, before the reviewer prompts could see the full chunk text.

A secondary friction appeared when trying to inspect progress for the validation run:

```text
bin/dev fabro progress 01KTD220HT0QNQ3V119DSCHJRK
× Failed to download /workspace/memba/docs/iterations/022-request-to-club-onboarding/todo.md from container
```

`progress` assumes an implementation run with `todo.md`, so it is not useful for plan-validation failure diagnosis.

## Impact

The iteration was blocked before implementation could start, despite no confirmed issue with the plan content. The failed validation spent review-model time on a false negative and required manual archaeology through `fabro inspect` / `fabro events` output to discover the real cause.

The misleading terminal failure text said:

```text
Plan validation failed: the plan is not ready for implementation. See the Opus report for remaining gaps or decisions that need human input.
```

But the observed blocker was not a human product decision; it was incomplete workflow evidence.

## What allowed it to happen

The previous fix reduced each plan read to 60-line chunks, but the workflow still relies on command-stage output being preserved verbatim in model-visible context. Fabro's context/fidelity handling can still summarize command output with omissions such as `(15 lines omitted)`, even for chunked reads.

The workflow lacks a deterministic guardrail that verifies each reviewer actually received complete chunk content. It also lacks a recovery route for unanimous `Workflow-evidence gap` results: synthesis set `plan_needs_human=true` and routed to `not_ready` instead of treating this as a validation-infrastructure failure or re-reading the evidence differently.

The wrapper command `bin/dev fabro progress` also assumes the presence of an implementation `todo.md`, which made validation-run inspection noisier.

## Observations

- This was not a product-code failure or an ordinary plan-content failure.
- The same failure mode survived the earlier chunking repair because the chunk size alone did not guarantee prompt-visible evidence.
- The reviewer prompts correctly failed closed when evidence was missing, but the synthesis/output path presented the result as a plan readiness failure needing human input.
- The evidence needed to diagnose the issue was available in `fabro events`, especially the `checkpoint.completed` context values, but the local helper for `progress` could not surface it for validation runs.
- The visible plan content received positive comments from reviewers, suggesting the plan likely needs no product decision before retrying once evidence handling is fixed.

## Why this matters

If plan validation can fail because its own evidence is summarized, longer or detailed plans will be blocked unpredictably. This creates wasted model spend, delays delivery, and can send agents looking for nonexistent product gaps instead of fixing the delivery machinery.

## Open questions

- Where exactly is the omission introduced: command output capture, checkpoint context compaction, prompt construction, model-context fidelity, or UI/log rendering?
- What maximum command output size, if any, is safe from summary omissions in reviewer-visible context?
- Should plan validation attach plan text as files/artifacts or use prompt-time file reads rather than relying on summarized command output?
- Should `bin/dev fabro progress` detect plan-validation runs and show reviewer decisions/context instead of trying to download `todo.md`?

## Possible prevention ideas

- Add a deterministic preflight or review-stage guard that proves all expected chunk markers and line ranges are visible before invoking reviewers.
- Make synthesis route unanimous `Workflow-evidence gap` decisions to a tooling/evidence failure, not to `plan_needs_human=true`.
- Reduce chunk sizes further only if evidence proves size is the cause; otherwise use a different evidence channel less likely to be summarized.
- Add a plan-validation fixture that deliberately checks reviewer-visible evidence for every chunk, not just script stdout locally.
- Add a `bin/dev fabro validation-report <run_id>` or improve `progress` so validation failures surface reviewer decisions and blocking gaps without assuming `todo.md` exists.

## Resolution

Date: 2026-06-05

Root cause: Plan validation used command-stage stdout as the evidence channel for prompt-only reviewer nodes. Fabro captured the command output completely, but under `summary:high` fidelity the prompt preamble renderer omitted the beginning of each chunk before constructing reviewer prompts. Chunking lowered raw stdout size but did not guarantee prompt-visible plan text.

Evidence:

- `fabro dump --output /tmp/fabro-01KTD220-dump 01KTD220HT0QNQ3V119DSCHJRK` showed complete `stages/002-read_plan_001_060@1/output.log` and `stages/003-read_plan_061_120@1/output.log` files.
- The dumped reviewer prompt `stages/008-gemini_review@1/prompt.md` already contained `(15 lines omitted)` and `(13 lines omitted)` markers in the rendered stage-output transcript.
- `fabro events 01KTD220HT0QNQ3V119DSCHJRK` confirmed `graph.default_fidelity` and `internal.fidelity` were `summary:high`, all read stages succeeded, and reviewers failed closed on workflow-evidence gaps.

Fix applied:

- `.fabro/workflows/plan-validation/workflow.fabro`: replaced prompt-only reviewer nodes with agent nodes (`shape=box`) that have tool access, removed the chunked read stages and updated-read stages from the graph, and routed reviewers directly from `start` to synthesis. Reviewer nodes use `fidelity="truncate"` so each reviewer reads the plan independently instead of inheriting summarized prior context.
- `.fabro/workflows/plan-validation/prompts/gemini_review.md`, `.fabro/workflows/plan-validation/prompts/claude_review.md`, and `.fabro/workflows/plan-validation/prompts/codex_review.md`: instructed reviewer agents to read `{{ inputs.plan_path }}` directly with file-reading tools, not rely on summarized context, and not edit files.
- `.fabro/workflows/plan-validation/prompts/recheck.md`: instructed the recheck agent to read the current plan file directly after any Codex repair.
- `.fabro/workflows/plan-validation/prompts/synthesize.md`: clarified that synthesis should use reviewer reports and routing fields, not require plan text in its own summarized context.
- `.fabro/workflows/plan-validation/test.sh`: removed the unused chunk-printing helper from the eval input guard.

Validation:

- `fabro validate .fabro/workflows/plan-validation/workflow.toml --no-upgrade-check` — passed; workflow now has 12 nodes and 15 edges.
- `fabro preflight .fabro/workflows/plan-validation/workflow.toml -I plan_path=docs/iterations/022-request-to-club-onboarding/plan.md -I publish=false --no-upgrade-check` — passed; repository access, Docker sandbox, and Claude/Gemini/GPT model probes all succeeded.
- `dev check` — passed; 528 ExUnit tests and 38 acceptance scenarios passed.

Remaining follow-up:

- Run `.fabro/workflows/plan-validation/test.sh` after the workflow changes are pushed to `origin/main`. The eval harness intentionally refuses to run when visible workflow inputs differ from `origin/main`, because Fabro sandboxes clone origin rather than the local dirty working tree.
- Consider deleting `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh` once no other workflow references it.
- Consider improving `bin/dev fabro progress` or adding a validation-report command for plan-validation run diagnostics.
