Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KSVXRC2PA5BRMA5G8SCDMNEJ
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

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.3-codex
- Tokens: 8.0k in / 1.4k out
- Response:
  > {"outcome":"succeeded","preferred_next_label":"revise_plan","context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":8,"codex_review_blocking_gaps":"Goal is vague and non-actionable; Scope is undefined and unbounded; Acceptance criteria are subjective and untestable; Core business decisions are unresolved; Implementation plan is absent; Technical decisions are unresolved; New capability is unknown; Validation approach is non-actionable","codex_review_required_edits":"Define a specific user/problem/outcome goal; Replace TBD scope with explicit in-scope and out-of-scope boundaries; Rewrite acceptance criteria as objective and testable checks including edge/error/permission cases; Resolve all listed open business decisions before implementation; Provide a sequenced implementation plan with concrete modules/files/tests; Resolve technical approach decisions including data/storage/integration/testing; State explicit new capability after iteration; Define a concrete validation plan with clear stop condition"}}

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 8 |
| claude_review_blocking_gaps | Goal is not actionable; Scope is completely undefined; All acceptance criteria are subjective and untestable; Critical business decisions are unresolved; Implementation plan is absent; All technical decisions are unresolved; New capability is unknown; No validation approach |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Define a specific messaging problem; Write a focused goal; Bound the scope and remove TBD; Resolve all business decisions before writing the plan; Write testable acceptance criteria; Create a sequenced implementation plan with specific modules and files; Resolve technical decisions; Define new capability; Write a concrete validation plan |
| codex_review_blocking_gap_count | 8 |
| codex_review_blocking_gaps | Goal is vague and non-actionable; Scope is undefined and unbounded; Acceptance criteria are subjective and untestable; Core business decisions are unresolved; Implementation plan is absent; Technical decisions are unresolved; New capability is unknown; Validation approach is non-actionable |
| codex_review_confidence | High |
| codex_review_decision | NOT READY |
| codex_review_required_edits | Define a specific user/problem/outcome goal; Replace TBD scope with explicit in-scope and out-of-scope boundaries; Rewrite acceptance criteria as objective and testable checks including edge/error/permission cases; Resolve all listed open business decisions before implementation; Provide a sequenced implementation plan with concrete modules/files/tests; Resolve technical approach decisions including data/storage/integration/testing; State explicit new capability after iteration; Define a concrete validation plan with clear stop condition |
| gemini_review_blocking_gap_count | 4 |
| gemini_review_blocking_gaps | No clear goal or scope defined; Acceptance criteria are not testable; All business decisions are unresolved; Implementation plan is missing |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Define a specific messaging problem to solve; Write concrete and testable acceptance criteria; Resolve all open business and technical decisions; Write a detailed step-by-step implementation plan |


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
