Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KSVYV98XD3Z5M5PTWS0FX6J3
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

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 8 |
| claude_review_blocking_gaps | Goal is vague and aspirational; Scope is TBD with no boundaries; Acceptance criteria are subjective and untestable; All business decisions are unresolved; Implementation plan is missing; All technical decisions are unresolved; Expected capability is unknown; Validation plan is non-existent |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Define specific problem with examples; Identify specific user role; Write objective testable acceptance criteria; Resolve all business decisions; Write concrete implementation steps; Resolve all technical decisions; State new capability concretely; Write validation plan with test scenarios |
| gemini_review_blocking_gap_count | 6 |
| gemini_review_blocking_gaps | Goal is undefined; Scope is TBD; Acceptance criteria are subjective and untestable; All core business decisions are unresolved; Implementation plan is missing; All core technical decisions are unresolved |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Define the specific problem being solved; Write objective, testable acceptance criteria; Outline concrete technical implementation steps; Resolve all open business and technical decisions |


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
