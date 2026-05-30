Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KSVXRC2PA5BRMA5G8SCDMNEJ
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
- Tokens: 3.3k in / 1.8k out
- Response:
  > {
  >   "context_updates": {
  >     "gemini_review_decision": "NOT READY",
  >     "gemini_review_confidence": "High",
  >     "gemini_review_blocking_gap_count": 4,
  >     "gemini_review_blocking_gaps": "No clear goal or scope defined; Acceptance criteria are not testable; All business decisions are unresolved; Implementation plan is missing",
  >     "gemini_review_required_edits": "Define a specific messaging problem to solve; Write concrete and testable acceptance criteria; Resolve all open business and technical decisions; Write a detailed step-by-step implementation plan"
  >   }
  > }

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 2.1k in / 1.9k out
- Response:
  > # Plan Readiness Review
  > 
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > ## Blocking Gaps
  > 
  > 1. **Goal is not actionable** - "Make messaging better for everyone" does not identify a specific problem, user need, or measurable outcome.
  > 
  > 2. **Scope is completely undefined** - The plan explicitly states "TBD" and lists every possible type of change without committing to any specific work.
  > 
  > 3. **All acceptance criteria are subjective and untestable** - "Messaging is better," "Users are happier," and "It works correctly" cannot be objectively verified.
  > 
  > 4. **Critical business decisions are unresolved** - The plan cannot proceed without deciding who the users are, which messaging problem to solve, what behavior should change, and what success means. These are foundational, not optional.
  > 
  > 5. **Implementation plan is absent** - "Start coding and figure it out" is not a plan. No modules, files, migrations, tests, or sequence of changes are identified.
  > 
  > 6. **All technical decisions are unresolved** - The plan doesn't specify whether this involves UI, domain logic, infrastructure, provider integration, or reporting work. Storage changes and testing approach are undefined.
  > 
  > 7. **New capability is unknown** - The plan explicitly states the new capability is "Unknown," making it impossible to validate success.
  > 
  > 8. **No validation approach** - "Run some tests if there are any" is not a validation plan.
  > 
  > ## Non-blocking Improvements
  > 
  > None identified - all gaps are blocking.
  > 
  > ## Smallest Viable Iteration
  > 
  > Cannot be determined from this plan. The author must first:
  > - Choose one specific messaging problem (e.g., "Users cannot see when their message was delivered" or "Admins cannot filter messages by date range")
  > - Define the minimal change that addresses that problem
  > - Scope to the smallest testable improvement
  > 
  > Example of a viable scope after problem selection: "Add message delivery timestamps visible to message senders in the message list view."
  > 
  > ## Required Plan Edits
  > 
  > The author must completely rewrite this plan:
  > 
  > 1. **Define a specific messaging problem** - Choose one concrete user or operator pain point related to messaging. Name who experiences it and when.
  > 
  > 2. **Write a focused goal** - State what specific outcome the iteration will achieve for whom (e.g., "Enable message senders to see delivery status").
  > 
  > 3. **Bound the scope** - List what is in scope and what is explicitly out of scope. Remove "TBD."
  > 
  > 4. **Resolve all business decisions** before writing the plan - Do not proceed until user type, specific problem, intended behavior change, and success criteria are decided.
  > 
  > 5. **Write testable acceptance criteria** - Define observable behaviors, UI states, data changes, or API responses that can be verified. Cover happy path, error cases, permissions, and edge cases where relevant.
  > 
  > 6. **Create a sequenced implementation plan** - List steps with specific modules, files, schemas, migrations, LiveViews, components, contexts, tests, and integration points. Reference project guidelines and naming conventions.
  > 
  > 7. **Resolve technical decisions** - Specify whether changes involve UI, context functions, schemas, migrations, background jobs, external APIs, or configuration. Name the approach.
  > 
  > 8. **Define new capability** - State exactly what will be possible after this iteration that is not possible now.
  > 
  > 9. **Write a concrete validation plan** - Specify which tests, manual steps, or checks will prove the acceptance criteria are met.
  > 
  > ## Validation Plan
  > 
  > A validation plan cannot be written until the iteration has a defined goal, scope, and acceptance criteria. Once rewritten, the validation plan should:
  > 
  > - Name specific ExUnit tests to run
  > - List manual test scenarios if interactive validation is needed
  > - Define observable success conditions (e.g., "Message list view shows 'Delivered at 2:34 PM' for sent messages")
  > - Include rollback or safety checks if data or behavior changes
  > 
  > ---
  > 
  > {"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":8,"claude_review_blocking_gaps":"Goal is not actionable; Scope is completely undefined; All acceptance criteria are subjective and untestable; Critical business decisions are unresolved; Implementation plan is absent; All technical decisions are unresolved; New capability is unknown; No validation approach","claude_review_required_edits":"Define a specific messaging problem; Write a focused goal; Bound the scope and remove TBD; Resolve all business decisions before writing the plan; Write testable acceptance criteria; Create a sequenced implementation plan with specific modules and files; Resolve technical decisions; Define new capability; Write a concrete validation plan"}}

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 8 |
| claude_review_blocking_gaps | Goal is not actionable; Scope is completely undefined; All acceptance criteria are subjective and untestable; Critical business decisions are unresolved; Implementation plan is absent; All technical decisions are unresolved; New capability is unknown; No validation approach |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Define a specific messaging problem; Write a focused goal; Bound the scope and remove TBD; Resolve all business decisions before writing the plan; Write testable acceptance criteria; Create a sequenced implementation plan with specific modules and files; Resolve technical decisions; Define new capability; Write a concrete validation plan |
| gemini_review_blocking_gap_count | 4 |
| gemini_review_blocking_gaps | No clear goal or scope defined; Acceptance criteria are not testable; All business decisions are unresolved; Implementation plan is missing |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Define a specific messaging problem to solve; Write concrete and testable acceptance criteria; Resolve all open business and technical decisions; Write a detailed step-by-step implementation plan |


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
