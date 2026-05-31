Synthesize the independent implementation reviews for {{ inputs.plan_path }}.

Decide whether the implementation is acceptable now, can be repaired automatically, or needs human input.

## Context and blocker history

Use the prior context from this workflow run:

- The iteration plan text and its explicit requirements.
- Implementation and repair summaries.
- Independent review reports (Claude, Codex, Gemini).
- Plan conformance gate and ADR coherence gate results.
- Previous synthesis decisions and blocker records, if this is a repeated synthesis after repair.
- Current working tree state and successful dev check output.

**Repeated-blocker detection**: If previous synthesis attempts exist in the prior context, extract any blocker IDs and titles from earlier synthesis outputs. Compare them with the current review evidence to determine whether blockers remain unresolved after repair attempts.

## Acceptance standards

- Accept only if the implementation satisfies the plan, avoids out-of-scope work, dev check passed, and no unresolved accepted-ADR violations remain.
- Never accept when unresolved accepted-ADR violations remain.
- Never downgrade a cited ADR's central decision to optional implementation strategy.
- If reviewers agree on an ADR violation, route to FIX or HUMAN_INPUT.
- If ADR rework has already been attempted and the violation remains, route to HUMAN_INPUT.
- If a plan/ADR conflict exists, route to HUMAN_INPUT.
- Treat automated tests/dev check as the behavioural feedback loop. Review-stage automatic fixes should be refactoring/maintainability/convention fixes after the suite is green, not new feature work.
- Request automatic fixes only for concrete, bounded refactoring, maintainability, project-convention, ADR-coherence, or low-risk test-quality issues that an agent can resolve without changing product behaviour or feature files beyond explicit plan permission.
- Do not request edits to acceptance feature files (`*.feature`) unless the plan's `## Allowed acceptance feature changes` section names the exact file and allowed kind of change. If reviewers believe other feature files or acceptance criteria are wrong, route to human input.
- Require human input for unresolved business decisions, ambiguous acceptance criteria, behavioural gaps, missing acceptance coverage that cannot be fixed safely as a test-only improvement, architectural choices outside the plan, or repeated/large failures.

## Explicit plan requirements

- If the plan explicitly says "Implement X", "Add Y", "Configure Z", "Use W", or similar binding requirements, treat those as mandatory deliverables, not optional implementation strategy.
- If reviewers cite missing explicit plan requirements, route to FIX or HUMAN_INPUT. Do not accept by reframing the requirement as optional.
- If multiple reviewers independently identify the same missing explicit plan requirement, that is a blocking gap.
- Passing dev check with a green test suite does not satisfy explicit plan requirements if the tests are insufficient, irrelevant, or do not cover/prove the requirement.
- If the same explicit plan requirement blocker appeared in a previous synthesis and remains unresolved after automatic repair, route to HUMAN_INPUT.

## Repeated-blocker routing

- If a blocker appeared in a previous synthesis attempt (check prior context for synthesis outputs with blocker IDs or titles), and the current reviews still cite the same blocker, do not route to another automatic repair loop.
- If a blocker with a matching ID or substantially similar title/description remains unresolved after one or more repair attempts, route to HUMAN_INPUT.
- Example: if synthesis cycle 1 identified blocker `missing-commanded-eventstore` and routed to FIX, and synthesis cycle 2 still finds that Commanded/EventStore are missing, route to HUMAN_INPUT.
- When detecting repeated blockers, use stable identifiers where possible: ADR numbers, plan requirement text, architectural component names, missing dependency names, or test coverage gaps.

## Output format

Return a concise Markdown synthesis with these sections:

### Decision

One of: **ACCEPTED**, **FIX**, or **HUMAN_INPUT**

### ADR conformance synthesis

- Summary of ADR violations across all reviews.
- Whether ADR coherence gate passed and reviewers agree.
- Any ADR conflicts requiring human decision.

### Repeated blockers from prior cycles

If this is a repeated synthesis after repair:

- List each blocker from the previous synthesis output (by stable ID if available, or by title/description).
- For each prior blocker:
  - **Blocker ID** (stable identifier such as `missing-commanded-eventstore` or `adr-007-violation`)
  - **Blocker title** (short description)
  - **Previous decision** (FIX or HUMAN_INPUT)
  - **Current evidence** (what reviewers say now)
  - **Fixed?** (yes or no)
  - **Routing consequence** (if not fixed after repair: HUMAN_INPUT; if fixed: continue evaluation)

If no prior synthesis exists, state: "First synthesis—no prior blocker history."

### Blocking issues

Grouped by severity. For each new or persisting blocker:

- Stable blocker ID (use a short stable identifier: e.g., `missing-commanded-eventstore`, `adr-007-violation`, `insufficient-acceptance-coverage`)
- Blocker title
- Evidence from reviews
- Severity: critical, high, medium
- Repair feasibility: automatic, requires human input, repeated after repair

### Exact repair brief (if FIX is appropriate)

Concrete, bounded instructions for automatic fixes. Include:

- Issue list with stable IDs.
- Required changes (files, modules, tests, conventions).
- Constraints (no feature files beyond explicit plan permission, no new behaviour, refactoring only).
- Acceptance test for each fix.

### Manual follow-ups (if any)

Actions, questions, or decisions that require human input.

### Blocker registry (structured output)

If blockers exist, list them in a stable format that can be parsed/compared in future synthesis passes:

```
BLOCKER_REGISTRY_START
- id: blocker-id-1
  title: Short blocker title
  status: open|fixed
  first_seen: synthesize_review_cycle_1
  source: claude_review|codex_review|gemini_review|multiple
BLOCKER_REGISTRY_END
```

If no blockers exist, state: "No blockers—implementation accepted."

## Routing JSON

End your response with exactly one JSON object that Fabro can use for routing. The JSON object must be the final text in the response and must not be wrapped in a Markdown code fence.

Use one of these shapes:

- Accepted, no blockers:
  `{"context_updates":{"implementation_accepted":true,"review_fixes_available":false}}`
- Automatic fixes appropriate:
  `{"context_updates":{"implementation_accepted":false,"review_fixes_available":true,"review_blockers":[{"id":"blocker-id-1","title":"Short blocker title","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"}]}}`
- Human input required, including repeated blockers when applicable:
  `{"context_updates":{"implementation_accepted":false,"review_fixes_available":false,"review_blockers":[{"id":"blocker-id-1","title":"Short blocker title","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"}],"repeated_blockers":["blocker-id-1"]}}`

If blockers exist and automatic fixes are requested, or if blockers remain unresolved and human input is required, include `review_blockers` in the single final JSON object. When human input is required for repeated blockers, also include `repeated_blockers` with the stable blocker IDs.
