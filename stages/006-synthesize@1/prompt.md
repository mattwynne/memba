Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KSVYV98XD3Z5M5PTWS0FX6J3
Pipeline progress: 4 of 13 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='.fabro/workflows/plan-validation/test/fixtures/definite-fail/plan.md'
if [ ! -f "$PLAN_PATH" ]; then
  echo "Plan file not found: $PLAN_PATH" >&2
  exit 1
fi
printf 'PLAN_PATH=%s\n\n' "$PLAN_PATH"
sed -n '1,260p' "$PLAN_PATH"`
- Output:
  ```
  PLAN_PATH=.fabro/workflows/plan-validation/test/fixtures/definite-fail/plan.md
  
  # Improve messaging
  
  Date: 2026-05-29
  Status: eval-fixture
  
  ## Goal
  
  Make messaging better for everyone.
  
  ## Background / Context
  
  People use messages and some things are confusing.
  
  ## Scope
  
  TBD. Could include UI changes, data-model changes, provider integration, permissions, analytics, retries, templates, or anything else that seems useful.
  
  ## Acceptance Criteria
  
  - Messaging is better.
  - Users are happier.
  - It works correctly.
  
  ## Open Business Decisions
  
  - Decide who the users are.
  - Decide which messaging problem this iteration solves.
  - Decide what behaviour should change.
  - Decide what success means.
  
  ## Implementation Plan
  
  Start coding and figure it out.
  
  ## Open Technical Decisions
  
  - Decide whether this is UI, domain, infrastructure, provider integration, or reporting work.
  - Decide whether storage changes are needed.
  - Decide how to test it.
  
  ## New Capability
  
  Unknown.
  
  ## Validation Plan
  
  Run some tests if there are any.
  ```

## Stage: gemini_review
- Status: succeeded
- Handler: prompt
- Model: gemini-3.1-pro-preview
- Tokens: 1.6k in / 3.3k out
- Response:
  > {
  >   "markdown_report": "## Review Report\n\n- **Decision:** NOT READY\n- **Confidence:** High\n- **Blocking gaps:**\n  1. Goal is undefined (no specific outcome or beneficiary).\n  2. Scope is TBD and unbounded.\n  3. Acceptance criteria are subjective and untestable.\n  4. All core business decisions are unresolved.\n  5. Implementation plan is missing.\n  6. All core technical decisions are unresolved.\n- **Non-blocking improvements:**\n  1. Provide context on why messages are currently confusing using user feedback or metrics.\n- **Smallest viable iteration:** Identify one specific messaging pain point (e.g., missing timestamps) and address only that.\n- **Required plan edits:**\n  - Define the specific problem being solved.\n  - Write objective, testable acceptance criteria.\n  - Outline concrete technical implementation steps.\n  - Resolve all open business and technical decisions.\n- **Validation plan:** The author must rewrite the plan entirely and submit for re-review. Once implemented, validate by manually verifying the specific fix and checking automated test coverage.",
  >   "context_updates": {
  >     "gemini_review_decision": "NOT READY",
  >     "gemini_review_confidence": "High",
  >     "gemini_review_blocking_gap_count": 6,
  >     "gemini_review_blocking_gaps": "Goal is undefined; Scope is TBD; Acceptance criteria are subjective and untestable; All core business decisions are unresolved; Implementation plan is missing; All core technical decisions are unresolved",
  >     "gemini_review_required_edits": "Define the specific problem being solved; Write objective, testable acceptance criteria; Outline concrete technical implementation steps; Resolve all open business and technical decisions"
  >   }
  > }

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 2.4k in / 1.9k out
- Response:
  > ## Review Report
  > 
  > - **Decision:** NOT READY
  > - **Confidence:** High
  > 
  > ### Blocking gaps
  > 
  > 1. Goal is vague and aspirational ("make messaging better") rather than stating a specific problem and outcome
  > 2. Scope is explicitly "TBD" with no boundaries or focus
  > 3. Acceptance criteria are entirely subjective and untestable ("messaging is better", "users are happier")
  > 4. All business decisions are unresolved: who the users are, which problem to solve, what behavior should change, and what success means
  > 5. Implementation plan is completely missing (literally says "start coding and figure it out")
  > 6. All technical decisions are unresolved: work type, storage changes, testing approach
  > 7. Expected new capability is listed as "Unknown"
  > 8. Validation plan is non-existent ("run some tests if there are any")
  > 
  > ### Non-blocking improvements
  > 
  > None. The plan requires fundamental restructuring before considering refinements.
  > 
  > ### Smallest viable iteration
  > 
  > Cannot recommend without knowing the actual problem being solved. The author must:
  > 
  > 1. Identify ONE specific messaging pain point (e.g., "Users don't know when messages fail to send")
  > 2. Define a single, measurable improvement (e.g., "Show send status for each message")
  > 3. Scope to the minimal change that delivers value (e.g., "Add a status indicator to the message list UI")
  > 
  > ### Required plan edits
  > 
  > 1. Define the specific messaging problem with concrete examples or user feedback
  > 2. Identify the specific user role or actor experiencing the problem
  > 3. Write objective, testable acceptance criteria that can be verified by looking at code, UI, or data
  > 4. Resolve all business decisions before implementation
  > 5. Write concrete implementation steps naming likely files, modules, schemas, tests
  > 6. Resolve all technical decisions (UI vs domain vs infrastructure, storage changes, testing approach)
  > 7. State the new capability in concrete terms (what can users do after this that they cannot do now?)
  > 8. Write a validation plan with specific test scenarios and success metrics
  > 
  > ### Validation plan
  > 
  > The current plan cannot be validated because it lacks definition. After required edits:
  > 
  > 1. Author must completely rewrite the plan
  > 2. Submit rewritten plan for re-review
  > 3. After implementation, validate by:
  >    - Running automated tests covering each acceptance criterion
  >    - Manually verifying the specific fix in the UI/system
  >    - Confirming measurable success metrics (if applicable)
  >    - Checking that no unrelated behavior changed
  > 
  > {"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":8,"claude_review_blocking_gaps":"Goal is vague and aspirational; Scope is TBD with no boundaries; Acceptance criteria are subjective and untestable; All business decisions are unresolved; Implementation plan is missing; All technical decisions are unresolved; Expected capability is unknown; Validation plan is non-existent","claude_review_required_edits":"Define specific problem with examples; Identify specific user role; Write objective testable acceptance criteria; Resolve all business decisions; Write concrete implementation steps; Resolve all technical decisions; State new capability concretely; Write validation plan with test scenarios"}}

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.3-codex
- Tokens: 2.9k in / 1.0k out
- Response:
  > {
  >   "markdown_report": "## Review Report\n\n- **Decision:** NOT READY\n- **Confidence:** High\n\n### Blocking gaps\n\n1. **Goal is not specific**: “Make messaging better for everyone” does not define a concrete problem, outcome, or success target.\n2. **Beneficiary/actor is undefined**: The plan does not identify which user segment is affected or who should experience the improvement.\n3. **Scope is unbounded**: Scope explicitly includes “anything else that seems useful,” spanning UI, data model, integrations, permissions, analytics, retries, templates, etc., with no boundaries or non-goals.\n4. **Acceptance criteria are subjective and untestable**: “Messaging is better,” “Users are happier,” and “It works correctly” cannot be objectively verified.\n5. **Core business decisions are unresolved**: The plan leaves key product decisions open (target users, problem selection, intended behavior change, definition of success).\n6. **Implementation plan is missing**: “Start coding and figure it out” is not an executable plan and provides no ordered steps.\n7. **Core technical decisions are unresolved**: The plan does not decide system area, storage impact, architecture direction, or test strategy.\n8. **Expected capability and validation are undefined**: “New capability: Unknown” and “Run some tests if there are any” provide no clear post-iteration capability, stop condition, or proof of success.\n\n### Non-blocking improvements\n\n1. Add baseline evidence (support tickets, user feedback, funnel drop-off, failure-rate metrics) to justify prioritization and support measurable outcomes.\n\n### Smallest viable iteration\n\nPick **one narrowly defined messaging pain point** for **one user role** and solve only that end-to-end. Example framing:\n- User: authenticated end user sending a message\n- Problem: user cannot tell whether a message send failed\n- Slice: display per-message send status in the existing thread view only\n- Exclusions: no template system, no provider switch, no analytics expansion, no permission model changes\n\n### Required plan edits\n\n1. Rewrite the goal as a single concrete outcome: who, what problem, what behavior changes.\n2. Define explicit scope boundaries and non-goals (what is intentionally excluded this iteration).\n3. Replace acceptance criteria with objective checks (observable UI/system/data outcomes).\n4. Resolve all open business decisions before implementation.\n5. Provide an ordered implementation plan with concrete work items (UI/domain/storage/integration/tests as applicable).\n6. Resolve technical decisions (whether schema changes are needed, integration points, error handling, test coverage approach).\n7. State the exact new capability delivered after completion.\n8. Write a concrete validation plan with specific scenarios and pass/fail conditions.\n\n### Validation plan\n\nThis plan cannot be validated in its current state. After rewrite, validate by:\n1. Mapping each acceptance criterion to at least one verification method (automated test and/or manual scenario).\n2. Executing happy path and failure path scenarios relevant to the defined slice.\n3. Verifying any data/state transitions explicitly (if storage/workflow changes are included).\n4. Confirming role/permission behavior for the named actor(s).\n5. Declaring success only when all criteria pass and scoped exclusions remain unchanged (clear stop condition).",
  >   "context_updates": {
  >     "codex_review_decision": "NOT READY",
  >     "codex_review_confidence": "High",
  >     "codex_review_blocking_gap_count": 8,
  >     "codex_review_blocking_gaps": "Goal is not specific; Beneficiary/actor is undefined; Scope is unbounded; Acceptance criteria are subjective and untestable; Core business decisions are unresolved; Implementation plan is missing; Core technical decisions are unresolved; Expected capability and validation are undefined",
  >     "codex_review_required_edits": "Rewrite goal with specific user/problem/outcome; Define scope boundaries and non-goals; Replace acceptance criteria with objective testable criteria; Resolve all open business decisions; Add ordered concrete implementation steps; Resolve technical decisions including data/integration/testing; State exact new capability; Write explicit validation scenarios and pass/fail stop condition"
  >   }
  > }

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 8 |
| claude_review_blocking_gaps | Goal is vague and aspirational; Scope is TBD with no boundaries; Acceptance criteria are subjective and untestable; All business decisions are unresolved; Implementation plan is missing; All technical decisions are unresolved; Expected capability is unknown; Validation plan is non-existent |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Define specific problem with examples; Identify specific user role; Write objective testable acceptance criteria; Resolve all business decisions; Write concrete implementation steps; Resolve all technical decisions; State new capability concretely; Write validation plan with test scenarios |
| codex_review_blocking_gap_count | 8 |
| codex_review_blocking_gaps | Goal is not specific; Beneficiary/actor is undefined; Scope is unbounded; Acceptance criteria are subjective and untestable; Core business decisions are unresolved; Implementation plan is missing; Core technical decisions are unresolved; Expected capability and validation are undefined |
| codex_review_confidence | High |
| codex_review_decision | NOT READY |
| codex_review_required_edits | Rewrite goal with specific user/problem/outcome; Define scope boundaries and non-goals; Replace acceptance criteria with objective testable criteria; Resolve all open business decisions; Add ordered concrete implementation steps; Resolve technical decisions including data/integration/testing; State exact new capability; Write explicit validation scenarios and pass/fail stop condition |
| gemini_review_blocking_gap_count | 6 |
| gemini_review_blocking_gaps | Goal is undefined; Scope is TBD; Acceptance criteria are subjective and untestable; All core business decisions are unresolved; Implementation plan is missing; All core technical decisions are unresolved |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Define the specific problem being solved; Write objective, testable acceptance criteria; Outline concrete technical implementation steps; Resolve all open business and technical decisions |


You are Claude Opus acting as the repair coordinator for an iteration plan validation loop.

Use the plan text and the three model reviews in context.

The reviewer stages must have exposed both their Markdown reports and these routing context fields. The reviewers run as separate model-review stages so these fields are visible to synthesis:

- Gemini: `gemini_review_decision`, `gemini_review_confidence`, `gemini_review_blocking_gap_count`, `gemini_review_blocking_gaps`, `gemini_review_required_edits`
- Claude: `claude_review_decision`, `claude_review_confidence`, `claude_review_blocking_gap_count`, `claude_review_blocking_gaps`, `claude_review_required_edits`
- Codex/GPT: `codex_review_decision`, `codex_review_confidence`, `codex_review_blocking_gap_count`, `codex_review_blocking_gaps`, `codex_review_required_edits`

Fail closed if you cannot see all three reviewer decisions and blocking-gap summaries. Missing reviewer evidence is a workflow/tooling failure for this validation pass, not proof that the plan is ready.

Your job in this stage is to decide whether the plan is ready, needs only obvious editorial/structural correction, or needs human product/technical decisions before it can be ready.

Readiness standard:

A plan is READY only if an engineer can begin implementation without first resolving material product/business decisions or material technical design decisions, and if a reviewer can objectively validate success at the end.

A plan is NOT READY if any of these are true:

- The goal is materially ambiguous.
- The scope is too broad or lacks a smallest useful slice.
- Acceptance criteria are not concrete/testable enough.
- Important business decisions remain open.
- Implementation steps require major technical choices that are not made.
- The expected new capability or success validation is unclear.

Correction policy:

Codex may only be asked to make obvious plan edits that do not require judgment calls, such as:

- tightening wording without changing meaning
- reorganizing existing content into clearer sections
- turning already-stated expectations into objective acceptance criteria
- making implicit boundaries explicit when the plan already clearly implies them
- removing duplication or contradiction when the intended meaning is obvious

Do not ask Codex to invent product policy, scope, UX, domain, data-model, integration, or technical-design decisions. If the plan needs those decisions, fail the validation and raise them for Matt.

Synthesis instructions:

1. First verify that all three reviewer decisions and blocking-gap summaries are visible in context. If any are missing, route to Matt/human input and explain that validation evidence was incomplete.
2. Compare the three reviews.
3. Include a reviewer decision table with each reviewer's decision, confidence, blocking gap count, and notes.
4. Identify consensus findings.
5. Correct reviewer findings that are wrong, too vague, duplicated, or not actually blocking.
6. Decide whether the plan is already ready, needs only obvious edits, or needs Matt's input.
7. If only obvious edits are needed, produce a concrete repair brief for Codex.
8. If Matt's input is needed, do not produce a repair brief as if Codex can solve it; list the decisions/questions clearly.

Voting/consensus guardrails:

- If two or more reviewers say NOT READY, you must not publish READY unless you explicitly quote or summarize each NOT READY blocker and explain why it is wrong or non-blocking.
- If any reviewer says NOT READY, include a `Reviewer objections addressed` section that accounts for every blocking gap from that reviewer.
- Do not treat successful reviewer node execution as readiness. Only the reviewer decision and findings content can support readiness.
- If your response cannot include a real synthesis report with the sections below, route to Matt/human input rather than READY.

Return a Markdown report with:

1. Provisional decision: READY, OBVIOUS FIXES NEEDED, or NEEDS MATT
2. Reviewer decision table: Reviewer, Decision, Confidence, Blocking gaps count, Notes
3. Consensus findings: 3-6 bullets
4. Reviewer objections addressed: account for every NOT READY blocking gap, or "No reviewer returned NOT READY"
5. Corrected findings: reviewer findings you changed, downgraded, combined, or rejected
6. Blocking gaps: numbered list, each with why it blocks implementation
7. Codex repair brief: exact instructions for obvious edits only, or "None"
8. Questions for Matt: decisions that need human input, or "None"
9. Validation checklist: what to check after any Codex update

At the end of your response, include one final JSON object for workflow routing. It must be the last thing in the response.

If the plan is already READY:

{"context_updates":{"plan_ready":true,"plan_needs_fix":false,"plan_needs_human":false}}

If the plan is NOT READY but Codex should apply only obvious fixes:

{"context_updates":{"plan_ready":false,"plan_needs_fix":true,"plan_needs_human":false}}

If the plan is NOT READY because Matt needs to answer questions or make decisions:

{"context_updates":{"plan_ready":false,"plan_needs_fix":false,"plan_needs_human":true}}
