Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KSVW1ZW2EB3HKDQ5VANV3SHA
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
- Tokens: 1.6k in / 1.6k out
- Response:
  > {
  >   "context_updates": {
  >     "gemini_review_decision": "NOT READY",
  >     "gemini_review_confidence": "High",
  >     "gemini_review_blocking_gap_count": 5,
  >     "gemini_review_blocking_gaps": "No specific goal or target audience defined; Scope is unbounded and TBD; Acceptance criteria are subjective and untestable; Business and technical decisions are completely unresolved; Implementation plan is non-existent",
  >     "gemini_review_required_edits": "Define a concrete goal and bounded scope; Write testable acceptance criteria covering happy and unhappy paths; Resolve all open business decisions; Resolve all open technical decisions; Outline a specific implementation plan with identified files and modules"
  >   }
  > }

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 2.1k in / 2.1k out
- Response:
  > # Iteration Plan Review
  > 
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > This plan fails every readiness criterion. It appears to be intentionally incomplete, with fundamental decisions explicitly deferred and implementation details entirely absent.
  > 
  > ## Blocking Gaps
  > 
  > 1. **No concrete goal**: "Make messaging better for everyone" is unmeasurable and aspirational, not a concrete outcome
  > 2. **Undefined scope**: Scope is explicitly "TBD" with no boundaries or focus area identified
  > 3. **Untestable acceptance criteria**: All three criteria ("better," "happier," "works correctly") are subjective and unmeasurable
  > 4. **Unresolved business decisions**: All four listed business decisions are critical and unresolved, including who the users are and which problem this solves
  > 5. **Unresolved technical decisions**: All three technical decisions are unresolved, including the basic nature of the work
  > 6. **No implementation plan**: "Start coding and figure it out" is not a plan
  > 7. **Unknown capability**: The "New Capability" section explicitly states "Unknown"
  > 8. **Inadequate validation plan**: "Run some tests if there are any" provides no validation strategy
  > 
  > ## Non-blocking Improvements
  > 
  > None. The blocking gaps are comprehensive.
  > 
  > ## Smallest Viable Iteration
  > 
  > Cannot recommend a smallest slice because no problem, user, or goal is defined. The author must first answer:
  > - Which specific messaging problem affects which users?
  > - What measurable outcome would solve it?
  > 
  > Example viable iterations might be:
  > - "Support agents can see message delivery status in conversation view"
  > - "Failed SMS messages retry automatically with exponential backoff"
  > - "Message templates reduce agent response time for common questions"
  > 
  > But these are hypothetical—the plan provides no basis for choosing one.
  > 
  > ## Required Plan Edits
  > 
  > 1. **Define specific goal**: Replace vague goal with concrete, measurable user outcome (e.g., "Support agents can identify failed messages without checking logs")
  > 2. **Identify target user and pain point**: State who experiences the problem and what currently goes wrong
  > 3. **Bound the scope**: Choose one focused area (e.g., delivery status visibility, retry logic, or template support—not all)
  > 4. **Write testable acceptance criteria**: Include specific behaviors, UI elements, data states, permissions, error cases, and success conditions
  > 5. **Resolve all business decisions**: Answer who the users are, which problem is being solved, what behavior changes, and what success means
  > 6. **Resolve all technical decisions**: State whether work is UI/domain/infrastructure/provider/reporting, whether storage changes are needed, and how to test
  > 7. **Write implementation plan**: List specific steps, files, modules, schemas, tests, and integration points in order
  > 8. **Define new capability**: State what users/system can do after this iteration that they cannot do now
  > 9. **Write validation plan**: Describe specific test scenarios, manual steps, or success criteria to prove the iteration succeeded
  > 
  > ## Validation Plan
  > 
  > This plan cannot be validated because it defines no success criteria, capability, or testable outcomes. After required edits, validation should include:
  > 
  > - Unit tests for new domain logic
  > - Integration tests for any provider/external system changes
  > - UI tests for any user-facing changes
  > - Manual verification of acceptance criteria
  > - Confirmation that open decisions are resolved
  > 
  > ---
  > 
  > {"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":8,"claude_review_blocking_gaps":"No concrete goal; Undefined scope (TBD); Untestable acceptance criteria; Unresolved business decisions (4); Unresolved technical decisions (3); No implementation plan; Unknown new capability; Inadequate validation plan","claude_review_required_edits":"Define specific measurable goal; Identify target user and pain point; Bound scope to one focused area; Write testable acceptance criteria with specific behaviors; Resolve all business decisions; Resolve all technical decisions; Write real implementation plan with files and steps; Define new capability; Write concrete validation plan"}}

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 8 |
| claude_review_blocking_gaps | No concrete goal; Undefined scope (TBD); Untestable acceptance criteria; Unresolved business decisions (4); Unresolved technical decisions (3); No implementation plan; Unknown new capability; Inadequate validation plan |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Define specific measurable goal; Identify target user and pain point; Bound scope to one focused area; Write testable acceptance criteria with specific behaviors; Resolve all business decisions; Resolve all technical decisions; Write real implementation plan with files and steps; Define new capability; Write concrete validation plan |
| gemini_review_blocking_gap_count | 5 |
| gemini_review_blocking_gaps | No specific goal or target audience defined; Scope is unbounded and TBD; Acceptance criteria are subjective and untestable; Business and technical decisions are completely unresolved; Implementation plan is non-existent |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Define a concrete goal and bounded scope; Write testable acceptance criteria covering happy and unhappy paths; Resolve all open business decisions; Resolve all open technical decisions; Outline a specific implementation plan with identified files and modules |


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
