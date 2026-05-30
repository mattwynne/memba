Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KSVZSQKZB3P1GVJTC7PJTSFN
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
- Tokens: 1.6k in / 3.7k out
- Response:
  > {
  >   "markdown_report": "- Decision: NOT READY\n- Confidence: High\n- Blocking gaps:\n  1. Goal and target audience are completely undefined.\n  2. Scope is explicitly TBD, making the effort unbounded.\n  3. Acceptance criteria are subjective and untestable.\n  4. Core business decisions (problem definition, behaviour changes, success metrics) are unresolved.\n  5. Implementation plan is missing entirely (\"Start coding and figure it out\").\n  6. All technical decisions (architecture layer, storage, testing) are unresolved.\n- Non-blocking improvements:\n  1. Add background context detailing specific examples of what is currently confusing about messaging.\n- Smallest viable iteration: Identify one specific messaging pain point for one specific user persona and resolve just that (e.g., \"Add read receipts for direct messages between admins and users\").\n- Required plan edits:\n  1. Define a concrete goal and beneficiary.\n  2. Define strict scope boundaries and explicit non-goals.\n  3. Write objective, testable acceptance criteria.\n  4. Resolve all open business decisions prior to implementation.\n  5. Create a step-by-step implementation plan including specific files, modules, and tests.\n  6. Resolve all open technical decisions.\n  7. Define the new capability clearly and specify how it will be validated.\n- Validation plan: Validate that the specific messaging problem identified in the revised goal is solved through clear, reproducible manual or automated tests against defined acceptance criteria.",
  >   "context_updates": {
  >     "gemini_review_decision": "NOT READY",
  >     "gemini_review_confidence": "High",
  >     "gemini_review_blocking_gap_count": 6,
  >     "gemini_review_blocking_gaps": "Goal and audience are undefined; Scope is TBD and unbounded; Acceptance criteria are subjective and untestable; Core business decisions are unresolved; Implementation plan lacks technical details; Technical decisions are unresolved",
  >     "gemini_review_required_edits": "Define specific goal and beneficiary; Define strict scope boundaries; Write objective testable acceptance criteria; Resolve open business decisions; Create step-by-step implementation plan; Resolve open technical decisions"
  >   }
  > }

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 2.5k in / 2.0k out
- Response:
  > # Plan Review: Improve messaging
  > 
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > ## Blocking Gaps
  > 
  > 1. **Goal is meaningless** - "Make messaging better for everyone" provides no actionable direction or measurable outcome
  > 2. **Beneficiary is undefined** - The plan explicitly lists "Decide who the users are" as an open question
  > 3. **Scope is unbounded** - Explicitly marked "TBD" with a laundry list of potential areas and no focus
  > 4. **Acceptance criteria are untestable** - "Messaging is better," "Users are happier," and "It works correctly" cannot be objectively verified
  > 5. **All business decisions are unresolved** - Problem definition, behavior changes, and success metrics are all explicitly undecided
  > 6. **Implementation plan is absent** - "Start coding and figure it out" is not a plan
  > 7. **All technical decisions are unresolved** - Application layer, storage changes, and testing approach are all explicitly undecided
  > 8. **New capability is unknown** - The plan explicitly states this is "Unknown"
  > 9. **Validation approach is undefined** - "Run some tests if there are any" provides no validation strategy
  > 
  > ## Non-Blocking Improvements
  > 
  > None. The plan requires fundamental restructuring before improvements can be suggested.
  > 
  > ## Smallest Viable Iteration
  > 
  > Select one concrete messaging problem for one specific user role. Examples:
  > - "Enable admins to see read receipts for messages sent to users in the admin panel"
  > - "Add message edit capability within 5 minutes of sending for workspace members"
  > - "Display message delivery status (sent/delivered/failed) for customer support agents"
  > 
  > Each of these is testable, focused, and delivers a discrete capability.
  > 
  > ## Required Plan Edits
  > 
  > 1. **Define a concrete goal** - State what specific problem will be solved for which user type
  > 2. **Identify the beneficiary** - Replace "everyone" with a specific user role or persona
  > 3. **Set strict scope boundaries** - Choose one messaging aspect (delivery, editing, history, notifications, etc.) and explicitly state non-goals
  > 4. **Write objective acceptance criteria** - Define specific behaviors, UI elements, data states, and error conditions that can be verified
  > 5. **Resolve all business decisions** - Decide the problem, the behavior change, and success metrics before writing implementation steps
  > 6. **Create detailed implementation steps** - List specific files, modules, schemas, migrations, LiveView components, and tests to create or modify
  > 7. **Resolve all technical decisions** - Specify whether this is UI, domain model, integration work; whether database changes are needed; and what testing approach to use
  > 8. **Define the new capability clearly** - State exactly what will be possible after this iteration that isn't possible now
  > 9. **Specify concrete validation** - Describe specific manual or automated test scenarios that prove the acceptance criteria are met
  > 
  > ## Validation Plan
  > 
  > After the plan is properly scoped: Validate that the specific problem identified in the revised goal is solved by executing the concrete test scenarios from the acceptance criteria. Confirm that the new capability works as specified and that non-goal areas are unchanged.
  > 
  > {"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":9,"claude_review_blocking_gaps":"Goal is meaningless; Beneficiary is undefined; Scope is unbounded and TBD; Acceptance criteria are untestable; Business decisions are unresolved; Implementation plan is absent; Technical decisions are unresolved; New capability is unknown; Validation approach is undefined","claude_review_required_edits":"Define concrete goal; Identify specific beneficiary; Set strict scope boundaries; Write objective acceptance criteria; Resolve business decisions; Create detailed implementation steps; Resolve technical decisions; Define new capability; Specify concrete validation"}}

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.3-codex
- Tokens: 3.2k in / 1.1k out
- Response:
  > {
  >   "markdown_report": "## Decision: NOT READY\n\n## Confidence: High\n\n## Blocking gaps\n\n1. **Goal is not actionable**: “Make messaging better for everyone” does not define a specific user outcome or business result.\n2. **Beneficiary is undefined**: the plan explicitly leaves “who the users are” undecided.\n3. **Scope is unbounded**: scope is “TBD” and includes many unrelated areas (UI, data model, provider integration, analytics, permissions, retries, templates, etc.).\n4. **No boundaries or non-goals**: nothing states what is out of scope, so the iteration has no stop line.\n5. **Acceptance criteria are untestable**: “Messaging is better,” “Users are happier,” and “It works correctly” are subjective and not objectively verifiable.\n6. **Core business decisions are unresolved**: problem definition, behavior change, and success metric are all open.\n7. **Implementation plan is absent**: “Start coding and figure it out” is not an ordered implementation plan.\n8. **Technical decisions are unresolved**: architecture layer, storage changes, and test strategy are all left open.\n9. **Expected capability and validation are undefined**: “New Capability: Unknown” and “Run some tests if there are any” do not define what success looks like or how to prove it.\n\n## Non-blocking improvements\n\n1. Add concrete background examples (current user flow, failure points, and impact) to justify prioritization.\n\n## Smallest viable iteration\n\nPick **one user role + one messaging problem + one behavior change**. Example slice:\n- “For support agents, show message delivery status (sent/delivered/failed) on outbound messages in the conversation view.”\n\nThis is small, user-visible, and testable.\n\n## Required plan edits\n\n1. Replace the goal with a concrete outcome in the format: **[actor] can [new capability] so that [business/user value]**.\n2. Define the beneficiary explicitly (single role/persona).\n3. Narrow scope to one coherent capability and add explicit non-goals.\n4. Replace acceptance criteria with objective checks (UI behavior, state changes, permissions, error handling, edge cases).\n5. Resolve all open business decisions before implementation (problem chosen, expected behavior, success metric).\n6. Write an ordered implementation plan with specific components likely to change (contexts, schemas/migrations if needed, LiveViews/components, integration points, tests).\n7. Resolve open technical decisions (data/storage, integration approach, retry/failure behavior, test strategy).\n8. Define the “New Capability” in one clear sentence describing what is newly possible after release.\n9. Replace the validation section with concrete test scenarios and a clear stop condition.\n\n## Validation plan\n\nAfter revising the plan, validate readiness and execution success by:\n\n1. **Traceability check**: each acceptance criterion maps to at least one implementation step and at least one test.\n2. **Functional scenarios**: execute explicit happy-path and failure-path tests for the chosen capability.\n3. **Permissions checks**: confirm allowed/denied behavior for relevant roles.\n4. **State verification**: confirm required data/state transitions (and no unintended changes outside scope).\n5. **Regression check**: verify stated non-goals remain unchanged.\n6. **Stop condition**: iteration is complete only when all acceptance criteria pass and no open business/technical decisions remain.\n",
  >   "context_updates": {
  >     "codex_review_decision": "NOT READY",
  >     "codex_review_confidence": "High",
  >     "codex_review_blocking_gap_count": 9,
  >     "codex_review_blocking_gaps": "Goal is not actionable; Beneficiary is undefined; Scope is unbounded and TBD; Non-goals/boundaries are missing; Acceptance criteria are subjective and untestable; Core business decisions are unresolved; Implementation plan is absent; Technical decisions are unresolved; New capability and validation are undefined",
  >     "codex_review_required_edits": "Define concrete goal outcome and beneficiary; Narrow to one scoped capability with explicit non-goals; Replace acceptance criteria with objective testable checks; Resolve business decisions before implementation; Provide ordered implementation steps with likely code/test touchpoints; Resolve technical decisions including data and testing approach; Define new capability clearly; Provide concrete validation scenarios and stop condition"
  >   }
  > }

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 9 |
| claude_review_blocking_gaps | Goal is meaningless; Beneficiary is undefined; Scope is unbounded and TBD; Acceptance criteria are untestable; Business decisions are unresolved; Implementation plan is absent; Technical decisions are unresolved; New capability is unknown; Validation approach is undefined |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Define concrete goal; Identify specific beneficiary; Set strict scope boundaries; Write objective acceptance criteria; Resolve business decisions; Create detailed implementation steps; Resolve technical decisions; Define new capability; Specify concrete validation |
| codex_review_blocking_gap_count | 9 |
| codex_review_blocking_gaps | Goal is not actionable; Beneficiary is undefined; Scope is unbounded and TBD; Non-goals/boundaries are missing; Acceptance criteria are subjective and untestable; Core business decisions are unresolved; Implementation plan is absent; Technical decisions are unresolved; New capability and validation are undefined |
| codex_review_confidence | High |
| codex_review_decision | NOT READY |
| codex_review_required_edits | Define concrete goal outcome and beneficiary; Narrow to one scoped capability with explicit non-goals; Replace acceptance criteria with objective testable checks; Resolve business decisions before implementation; Provide ordered implementation steps with likely code/test touchpoints; Resolve technical decisions including data and testing approach; Define new capability clearly; Provide concrete validation scenarios and stop condition |
| gemini_review_blocking_gap_count | 6 |
| gemini_review_blocking_gaps | Goal and audience are undefined; Scope is TBD and unbounded; Acceptance criteria are subjective and untestable; Core business decisions are unresolved; Implementation plan lacks technical details; Technical decisions are unresolved |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Define specific goal and beneficiary; Define strict scope boundaries; Write objective testable acceptance criteria; Resolve open business decisions; Create step-by-step implementation plan; Resolve open technical decisions |


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
