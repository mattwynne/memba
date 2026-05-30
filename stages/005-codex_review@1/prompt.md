Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KSVX5JWJ3WB2JWHVMDSHMVRA
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
- Tokens: 1.6k in / 2.5k out
- Response:
  > {
  >   "context_updates": {
  >     "gemini_review_decision": "NOT READY",
  >     "gemini_review_confidence": "High",
  >     "gemini_review_blocking_gap_count": 5,
  >     "gemini_review_blocking_gaps": "Goal and scope are completely undefined; Acceptance criteria are subjective and untestable; Fundamental business decisions are open; Implementation plan is missing; Technical decisions are unresolved",
  >     "gemini_review_required_edits": "Define the specific messaging problem and scope; Replace subjective acceptance criteria with objectively testable conditions; Resolve all Open Business Decisions; Write a step-by-step Implementation Plan; Resolve all Open Technical Decisions"
  >   }
  > }

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 2.1k in / 2.4k out
- Response:
  > # Plan Validation Review
  > 
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > This plan fails all five readiness criteria. It appears to be intentionally incomplete, with fundamental aspects explicitly marked as unresolved or unknown.
  > 
  > ## Blocking gaps
  > 
  > 1. **Goal is vague and unmeasurable** - "Make messaging better for everyone" provides no specific outcome or success metric
  > 2. **Scope is completely undefined** - Explicitly marked "TBD" with a list of possibilities spanning UI, data model, integrations, permissions, analytics, retries, and templates
  > 3. **All acceptance criteria are subjective** - "Messaging is better," "Users are happier," and "It works correctly" cannot be objectively verified
  > 4. **Target users are undefined** - "Decide who the users are" is listed as an open business decision
  > 5. **Problem statement is missing** - "Decide which messaging problem this iteration solves" remains open
  > 6. **No implementation plan exists** - The plan is literally "Start coding and figure it out"
  > 7. **Work category is unknown** - Open technical decision about whether this is UI, domain, infrastructure, provider integration, or reporting work
  > 8. **Expected capability is unknown** - Explicitly stated as "Unknown" in the plan
  > 9. **Validation approach is missing** - "Run some tests if there are any" is not a validation plan
  > 
  > ## Non-blocking improvements
  > 
  > None identified - the plan requires fundamental rewriting before non-blocking improvements would be relevant.
  > 
  > ## Smallest viable iteration
  > 
  > Cannot recommend a smallest viable iteration because the problem domain, target users, and desired outcome are all undefined. 
  > 
  > To identify a smallest viable iteration, the author must first:
  > - Choose one specific messaging problem affecting one specific user group
  > - Define one concrete behavior that needs to change
  > - Scope to the minimum change that would provide measurable value
  > 
  > Examples of what a smallest viable iteration might look like after these decisions:
  > - "Agent can see delivery status for sent messages"
  > - "User receives error notification when message fails to send"
  > - "Admin can retry failed messages from the UI"
  > 
  > ## Required plan edits
  > 
  > 1. **Replace vague goal with specific outcome** - Define exactly what messaging problem this solves and for whom
  > 2. **Define concrete scope** - Remove "TBD" and specify exactly what is in scope (one UI change, one data model addition, one integration point, etc.)
  > 3. **Resolve all business decisions** - Answer: who are the users, what specific problem are we solving, what behavior changes, how do we measure success
  > 4. **Write objectively testable acceptance criteria** - Replace subjective criteria with verifiable conditions (e.g., "Message list shows 'delivered', 'pending', or 'failed' status for each message")
  > 5. **Resolve all technical decisions** - Determine the work category, required storage changes, and testing approach
  > 6. **Write step-by-step implementation plan** - List specific files, modules, LiveViews, schemas, migrations, tests, and integration points
  > 7. **Define new capability** - State what users/agents/admins will be able to do after this iteration that they cannot do now
  > 8. **Create concrete validation plan** - Specify test scenarios, edge cases, and manual verification steps
  > 
  > ## Validation plan
  > 
  > A validation plan cannot be defined until the iteration's goal, scope, and acceptance criteria are specified. 
  > 
  > Once those are defined, the validation plan should include:
  > - Specific test cases covering happy paths and edge cases
  > - Data setup requirements
  > - Expected UI states or API responses
  > - Performance or reliability criteria if relevant
  > - Manual verification steps if automated testing is insufficient
  > 
  > ---
  > 
  > {"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":9,"claude_review_blocking_gaps":"Goal is vague and unmeasurable; Scope is completely undefined; All acceptance criteria are subjective; Target users are undefined; Problem statement is missing; No implementation plan exists; Work category is unknown; Expected capability is unknown; Validation approach is missing","claude_review_required_edits":"Define specific messaging problem and target users; Replace TBD scope with concrete boundaries; Resolve all open business decisions; Write objectively testable acceptance criteria; Resolve all open technical decisions; Write step-by-step implementation plan with specific files and modules; Define new capability; Create concrete validation plan with test scenarios"}}

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 9 |
| claude_review_blocking_gaps | Goal is vague and unmeasurable; Scope is completely undefined; All acceptance criteria are subjective; Target users are undefined; Problem statement is missing; No implementation plan exists; Work category is unknown; Expected capability is unknown; Validation approach is missing |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Define specific messaging problem and target users; Replace TBD scope with concrete boundaries; Resolve all open business decisions; Write objectively testable acceptance criteria; Resolve all open technical decisions; Write step-by-step implementation plan with specific files and modules; Define new capability; Create concrete validation plan with test scenarios |
| gemini_review_blocking_gap_count | 5 |
| gemini_review_blocking_gaps | Goal and scope are completely undefined; Acceptance criteria are subjective and untestable; Fundamental business decisions are open; Implementation plan is missing; Technical decisions are unresolved |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Define the specific messaging problem and scope; Replace subjective acceptance criteria with objectively testable conditions; Resolve all Open Business Decisions; Write a step-by-step Implementation Plan; Resolve all Open Technical Decisions |


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
