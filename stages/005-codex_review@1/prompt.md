Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KSVZSQKZB3P1GVJTC7PJTSFN
Pipeline progress: 3 of 13 stages completed

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

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 9 |
| claude_review_blocking_gaps | Goal is meaningless; Beneficiary is undefined; Scope is unbounded and TBD; Acceptance criteria are untestable; Business decisions are unresolved; Implementation plan is absent; Technical decisions are unresolved; New capability is unknown; Validation approach is undefined |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Define concrete goal; Identify specific beneficiary; Set strict scope boundaries; Write objective acceptance criteria; Resolve business decisions; Create detailed implementation steps; Resolve technical decisions; Define new capability; Specify concrete validation |
| gemini_review_blocking_gap_count | 6 |
| gemini_review_blocking_gaps | Goal and audience are undefined; Scope is TBD and unbounded; Acceptance criteria are subjective and untestable; Core business decisions are unresolved; Implementation plan lacks technical details; Technical decisions are unresolved |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Define specific goal and beneficiary; Define strict scope boundaries; Write objective testable acceptance criteria; Resolve open business decisions; Create step-by-step implementation plan; Resolve open technical decisions |


You are independently reviewing an iteration plan before implementation.

Use the plan text from the preceding `Read Iteration Plan` stage. Do not assume any missing details. Be strict, practical, and specific.

Review the plan against these readiness questions:

1. Goal clarity
   - Is the goal clearly articulated?
   - Does it state the user/business outcome, not just tasks?
   - Is the intended beneficiary or actor clear?

2. Scope focus
   - Is the scope focused on one coherent outcome?
   - Could the iteration be any smaller while still useful?
   - Are non-goals and boundaries clear?

3. Acceptance criteria and business decisions
   - Are acceptance criteria concrete, clear, complete, and objectively testable?
   - Do they cover happy paths, important edge cases, permissions, error states, and data/state changes where relevant?
   - Are any business, product, policy, copy, workflow, or domain decisions still unresolved?

4. Implementation plan and technical decisions
   - Are implementation steps clear, ordered, and specific?
   - Are likely files, modules, migrations, tests, interfaces, and integration points named where useful?
   - Are data model, API, UI, workflow, integration, and background-job changes clear enough?
   - Are any technical decisions still unresolved?

5. Expected capability and validation
   - What should we be able to do after this iteration that we cannot do now?
   - How will we prove success?
   - Is there a clear stop condition?

Return a Markdown report with:

- Decision: READY or NOT READY
- Confidence: High, Medium, or Low
- Blocking gaps: numbered list
- Non-blocking improvements: numbered list
- Smallest viable iteration: your recommended smallest useful slice
- Required plan edits: concrete edits the author should make
- Validation plan: how to prove the iteration succeeded

At the end of your response, include one final JSON object for workflow routing. It must be the last thing in the response and must not be wrapped in a Markdown code fence.

Use these keys exactly so the synthesis stage can fail closed if reviewer findings are not visible in context:

- `codex_review_decision`: `READY` or `NOT READY`
- `codex_review_confidence`: `High`, `Medium`, or `Low`
- `codex_review_blocking_gap_count`: integer count of blocking gaps
- `codex_review_blocking_gaps`: concise semicolon-separated blocking gaps, or `None`
- `codex_review_required_edits`: concise semicolon-separated required edits, or `None`

Examples:

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":2,"codex_review_blocking_gaps":"Ordering is not decided; Acceptance criteria omit visible table columns","codex_review_required_edits":"State ordering; Define table columns and row identity"}}
