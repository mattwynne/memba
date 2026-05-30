# Problem: plan-validation synthesis dropped independent reviewer findings

Date: 2026-05-29

## Context

We validated the newly planned iteration 006 while iteration 005 was still in progress:

```text
docs/iterations/006-deliveries-overview/plan.md
```

Command:

```bash
fabro run .fabro/workflows/plan-validation/workflow.toml \
  -I plan_path=docs/iterations/006-deliveries-overview/plan.md
```

Run:

```text
01KSVT16Z5WP3SSAT0E8WSFJFC
```

Web UI:

```text
https://fabro.home.wynne.family/runs/01KSVT16Z5WP3SSAT0E8WSFJFC
```

The run completed successfully and marked the plan READY without editing it:

```text
files_changed: 0
additions: 0
deletions: 0
```

## What happened

At first glance this looked like a clean validation pass. On inspection, the independent reviewers had in fact raised substantive issues.

### Gemini review

Decision: READY, with non-blocking improvements:

- Make projection/message-subject handling explicit.
- Put ordering into acceptance criteria.

### Codex review

Decision: NOT READY.

Blocking gaps included:

- Ordering was not explicitly decided: the plan said "preferably newest or most recently updated first".
- Query/API change was underspecified: "for example an options-shaped list function" left too much room.
- Acceptance criteria did not fully define the table contract / visible fields / row identity.
- Auth deferral was not operationally bounded.

### Claude review

Decision: NOT READY.

Blocking gaps included:

- Acceptance criteria missing table structure.
- Ordering missing from acceptance criteria.
- "Stale problem reasons" undefined.
- Empty state not covered.

So two of three reviewers returned NOT READY, and the third returned READY only with overlapping improvement suggestions.

## Failure mode

The synthesis stage still set:

```json
{"plan_ready": true, "plan_needs_fix": false, "plan_needs_human": false}
```

Its recorded response was not a real synthesis report. It looked like tool-call JSON followed by the routing object:

```json
{"cmd": "sed -n '1,220p' docs/iterations/006-deliveries-overview/plan.md && echo '--- git branches ---' && git branch --all --verbose --no-abbrev | sed -n '1,120p' && echo '--- log ---' && git log --oneline --decorate --all -n 30", "timeout_ms": 10000}
{"cmd": "ls"}
{"context_updates":{"plan_ready":true,"plan_needs_fix":false,"plan_needs_human":false}}
```

The stage did not produce the requested Markdown report:

- Provisional decision
- Consensus findings
- Corrected findings
- Blocking gaps
- Codex repair brief
- Questions for Matt
- Validation checklist

The context visible to synthesis contained `parallel.results` with branch IDs/statuses/head SHAs, but apparently not the full reviewer response bodies in a form the synthesizer used. The fan-in selected `claude_review` as the "best" branch, but the actual Claude review body was not reflected in the synthesis response.

## Why this matters

This is a false READY verdict.

The individual review machinery did useful work: it found exactly the kind of planning gaps plan validation is meant to catch. But the synthesis/routing step discarded or failed to consume those findings, then routed to `publish_ready`.

That creates a dangerous failure mode:

- Humans see a successful validation run.
- The plan is marked READY.
- Implementation can start with unresolved decisions.
- The evidence needed to diagnose the bad verdict is buried in event logs rather than surfaced in the final report.

## Observations

Useful commands for diagnosis:

```bash
fabro events 01KSVT16Z5WP3SSAT0E8WSFJFC
fabro logs 01KSVT16Z5WP3SSAT0E8WSFJFC
fabro inspect 01KSVT16Z5WP3SSAT0E8WSFJFC
```

The individual review responses were present in `fabro events` as `prompt.completed` events for:

- `gemini_review`
- `codex_review`
- `claude_review`

The meta branch did not include separate response files for the parallel reviewer stages. It had only:

```text
stages/003-fork@1/parallel_results.json
stages/003-fork@1/prompt.md
stages/003-fork@1/provider_used.json
stages/003-fork@1/status.json
```

This made the review text less discoverable after the run.

## Proposed fixes

### 1. Preserve each reviewer response as a first-class artifact

For every parallel review branch, write the response to metadata, for example:

```text
stages/003-fork@1/gemini_review/response.md
stages/003-fork@1/codex_review/response.md
stages/003-fork@1/claude_review/response.md
```

The synthesis stage should receive these response bodies explicitly, not just head SHAs and statuses.

### 2. Make synthesis fail closed when review bodies are missing

If synthesis cannot see all reviewer reports, it should route to NOT READY or infrastructure failure, not READY.

A validation workflow must not infer readiness from "review stage succeeded". Success only means the reviewer returned something; the content still matters.

### 3. Require a real synthesis report before routing

The synthesis prompt already asks for a Markdown report plus final JSON. Enforce that shape. If the response is only tool-call JSON plus routing, treat it as malformed and fail/retry.

### 4. Add voting/consensus guardrails

Simple deterministic guardrail:

- If two or more independent reviewers say NOT READY, synthesis may not publish READY unless it explicitly quotes each NOT READY blocker and explains why it is wrong or non-blocking.
- If any reviewer says NOT READY, the final report must include a "Reviewer objections addressed" section.

### 5. Surface reviewer decisions in the final summary

The final validation output should include a table:

| Reviewer | Decision | Blocking gaps count | Notes |
| --- | --- | --- | --- |

This would have made the false READY obvious immediately.

## Follow-up for iteration 006

Treat validation run `01KSVT16Z5WP3SSAT0E8WSFJFC` as not trustworthy despite its succeeded status.

Before implementation, update the plan using the real reviewer findings:

- Decide and state table ordering.
- Define the visible table columns and row identity.
- Replace vague "stale problem reasons" wording.
- Decide the query function name/signature and compatibility shape.
- Add/decline an empty state criterion deliberately.
- Bound the auth deferral explicitly.

Then re-run validation only after the synthesis workflow is fixed or manually inspect all reviewer outputs again.
