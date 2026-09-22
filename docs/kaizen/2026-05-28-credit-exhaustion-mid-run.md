# Kaizen: validator fix confirmed; long runs die opaquely when Anthropic credits run out

Date: 2026-05-28

## Why (run 01KSR7ATV5Q77HJ5A1SDT3V3A2)

This was the rehearsal of the validator fix from
`2026-05-28-blind-validator-false-reset.md`, run against
`docs/iterations/001-event-sourced-foundation/plan.md` (9 tasks).

### Headline: the validator fix worked

Hard evidence from the event log (`fabro events 01KSR7ATV5Q77HJ5A1SDT3V3A2`):

- `reset_task_attempt` started **0 times** — no false RETRYs at all.
- Every `validate_task` returned **VALID** on the first attempt.
- The implementor reached **all 9 tasks** (`implement_next_task@1..@9`).
- `commit_task` succeeded **8 times** — tasks 001–008 are durable commits.

The previous run (`01KSR32M…`) stalled and failed at task 4 because the
tool-less validator hallucinated a "stale commit replay / writes not persisting"
fault and triggered a destructive reset. With the live-evidence snapshot and the
tool-enabled, working-tree-aware validator, that class of failure is gone: the
loop drained the entire plan with zero resets.

### Why it still failed: Anthropic credit exhaustion

The run ended with:

```
reason: workflow_error
detail: deterministic failure cycle detected: signature
        validate_task|deterministic|api_deterministic|anthropic|invalid_request
        repeated 3 times (limit 3)
```

The underlying error on each failed stage was:

```
LLM error: Invalid request to anthropic: Your credit balance is too low to
access the Anthropic API. Please go to Plans & Billing to upgrade or purchase
credits.
```

`validate_task` (model `claude-opus-4-6`) and `all_tasks_done`
(`claude-sonnet-4-6`) are the two Anthropic-backed nodes. During task 009's
validation the Anthropic balance hit zero, both nodes began failing with the
billing error, and Fabro's deterministic-failure circuit breaker aborted the run
after the same signature repeated 3 times. The implementor node
(`gpt-5.5`, OpenAI) was unaffected and kept working — only the Anthropic nodes
broke.

So: this was an **account/billing failure**, not a workflow-logic failure. It
struck on the last task (009 of 009), after 8 durable task commits.

## Learnings / kaizen

1. **The validator-evidence fix is validated.** 0 resets, all-VALID, full plan
   drained. Close the loop on `2026-05-28-blind-validator-false-reset.md`: it
   solved the task-4 stall.

2. **Credit/auth exhaustion currently surfaces as an opaque `workflow_error`.**
   The run looks like a workflow defect ("deterministic failure cycle detected")
   when the real cause is "out of Anthropic credits." This wasted operator time
   to diagnose. Options to make it legible:
   - A cheap **preflight connectivity/credit ping** to each configured provider
     (a 1-token request per provider) at the start of a run, failing fast with a
     clear "provider X rejected auth/credit" message — analogous to
     `preflight_sandbox`.
   - Or rely on operator discipline: check provider billing before kicking off a
     long (9-task, ~$ and ~hour-long) run.

3. **Durable progress means cheap recovery — rehearse resume.** 8 task commits
   exist on the run branch. Top up Anthropic credits, then re-run the same plan;
   the resume gate + `sync_task_list` should pick up the existing `todo.md`
   (001–008 checked) and start at task 009 with no re-implementation. This is
   exactly the property the resumable-iteration kaizen promised — verify it now
   that we finally have a real mid-run failure to resume from.

4. **Cost/model exposure.** `validate_task` runs on the most expensive model
   (`claude-opus-4-6`) once per task, and it is on the provider that ran dry.
   Consider whether the now-evidence-based validator needs opus, or whether a
   cheaper model (with the precomputed `pre-validate-snapshot.md` doing the
   heavy lifting) is sufficient — both to cut cost and to reduce single-provider
   dependence for a long run.

5. **Minor / note for later.** Every `dev check` printed
   `Manager did not shut down within 30 seconds, sending SIGKILL` after passing.
   Benign (validation succeeded), but it adds ~30s per task and noise; worth a
   look at devenv/process-compose teardown in `bin/dev` eventually.

## Next action

- Restore Anthropic API credits.
- Re-run `iteration-implementation` against
  `docs/iterations/001-event-sourced-foundation/plan.md`.
- Confirm it resumes at task 009 with no rework (resume rehearsal), then let it
  finish and hand off to `iteration-review`.

## Resolution

Date: 2026-05-31

Root cause: Long runs could fail opaquely when Anthropic credits were exhausted because model routing still depended on Anthropic-backed providers.

Fix applied:

- `357e9d7`: switched workflow/model usage away from Anthropic models for the affected path.

Validation:

- Historical delivery evidence: the model-routing fix is present on `main`.

Remaining follow-up:

- None for this note.
