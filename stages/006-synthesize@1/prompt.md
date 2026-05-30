Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KSVW1ZW2EB3HKDQ5VANV3SHA
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

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.3-codex
- Tokens: 7.2k in / 1.4k out
- Response:
  > {"outcome":"succeeded","preferred_next_label":"revise_plan","context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":8,"codex_review_blocking_gaps":"Goal is vague and unmeasurable; Target user/beneficiary is undefined; Scope is unbounded and TBD; Acceptance criteria are subjective and untestable; Business decisions are unresolved; Implementation plan is non-existent; Technical decisions are unresolved; New capability and validation/stop condition are undefined","codex_review_required_edits":"Define a specific measurable goal and named actor; Bound scope to one coherent outcome and list non-goals; Replace acceptance criteria with objective testable criteria including happy/error/permission/state cases; Resolve all open business decisions in-plan; Resolve all open technical decisions in-plan; Provide ordered implementation steps with likely modules/files/tests; State explicit new capability delivered; Provide concrete validation steps with clear pass/fail stop condition"}}

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 8 |
| claude_review_blocking_gaps | No concrete goal; Undefined scope (TBD); Untestable acceptance criteria; Unresolved business decisions (4); Unresolved technical decisions (3); No implementation plan; Unknown new capability; Inadequate validation plan |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Define specific measurable goal; Identify target user and pain point; Bound scope to one focused area; Write testable acceptance criteria with specific behaviors; Resolve all business decisions; Resolve all technical decisions; Write real implementation plan with files and steps; Define new capability; Write concrete validation plan |
| codex_review_blocking_gap_count | 8 |
| codex_review_blocking_gaps | Goal is vague and unmeasurable; Target user/beneficiary is undefined; Scope is unbounded and TBD; Acceptance criteria are subjective and untestable; Business decisions are unresolved; Implementation plan is non-existent; Technical decisions are unresolved; New capability and validation/stop condition are undefined |
| codex_review_confidence | High |
| codex_review_decision | NOT READY |
| codex_review_required_edits | Define a specific measurable goal and named actor; Bound scope to one coherent outcome and list non-goals; Replace acceptance criteria with objective testable criteria including happy/error/permission/state cases; Resolve all open business decisions in-plan; Resolve all open technical decisions in-plan; Provide ordered implementation steps with likely modules/files/tests; State explicit new capability delivered; Provide concrete validation steps with clear pass/fail stop condition |
| gemini_review_blocking_gap_count | 5 |
| gemini_review_blocking_gaps | No specific goal or target audience defined; Scope is unbounded and TBD; Acceptance criteria are subjective and untestable; Business and technical decisions are completely unresolved; Implementation plan is non-existent |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Define a concrete goal and bounded scope; Write testable acceptance criteria covering happy and unhappy paths; Resolve all open business decisions; Resolve all open technical decisions; Outline a specific implementation plan with identified files and modules |


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
