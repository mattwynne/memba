Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KSVX5JWJ3WB2JWHVMDSHMVRA
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

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.3-codex
- Tokens: 3.0k in / 1.2k out
- Response:
  > {
  >   "Decision": "NOT READY",
  >   "Confidence": "High",
  >   "Blocking gaps": [
  >     "Goal is too vague (“Make messaging better for everyone”) and does not define a specific user/business outcome.",
  >     "Primary beneficiary/actor is undefined (the plan explicitly says to decide who the users are).",
  >     "Scope is undefined (“TBD”) and spans many unrelated domains (UI, data model, integration, permissions, analytics, retries, templates).",
  >     "Boundaries and non-goals are missing, so there is no controllable iteration size.",
  >     "Acceptance criteria are subjective and not objectively testable (“better”, “happier”, “works correctly”).",
  >     "Core business decisions are unresolved (who, what problem, desired behavior change, success definition).",
  >     "Implementation plan is absent (“Start coding and figure it out” is not executable planning).",
  >     "Technical decisions are unresolved (work type, storage changes, testing strategy).",
  >     "Expected new capability is unknown, so there is no clear post-iteration state.",
  >     "Validation plan is non-specific (“Run some tests if there are any”) and has no stop condition."
  >   ],
  >   "Non-blocking improvements": [
  >     "None. The plan needs fundamental rewrite before optimization-level suggestions are useful."
  >   ],
  >   "Smallest viable iteration": "Pick one messaging problem for one actor and one observable behavior change. Example shape (not a mandated solution): “For support agents, when a message send fails, show a visible failure status and allow one retry from the message row.” Keep this to a single workflow and avoid broader provider/analytics/template changes.",
  >   "Required plan edits": [
  >     "Rewrite Goal as a single measurable outcome: who benefits, what changes, and why it matters.",
  >     "Define Scope with explicit in-scope items and explicit non-goals/out-of-scope items.",
  >     "Resolve all Open Business Decisions in the plan text (user, problem, behavior change, success metric).",
  >     "Replace Acceptance Criteria with objective, testable statements (UI/API/state expectations).",
  >     "Add edge-case criteria: failure handling, empty/loading states, and permission behavior where relevant.",
  >     "Write a concrete Implementation Plan with ordered steps and named components/files/modules/tests.",
  >     "Resolve Open Technical Decisions (data/storage changes, integration points, background jobs, test strategy).",
  >     "Define “New Capability” as a clear before/after statement.",
  >     "Provide a concrete Validation Plan: automated tests + manual checks + explicit pass/fail stop condition."
  >   ],
  >   "Validation plan": [
  >     "After rewriting the plan, validate readiness first: all business/technical decisions closed and no TBD/Unknown placeholders remain.",
  >     "For execution success, require objective acceptance checks per criterion (each criterion maps to at least one test or manual verification step).",
  >     "Include automated tests for happy path and key error path(s), with expected UI/API outputs and data-state assertions.",
  >     "Include permission checks if multiple roles can access messaging workflows.",
  >     "Include manual verification steps for user-visible behavior (exact screens/actions/results).",
  >     "Define stop condition: iteration is complete only when all acceptance criteria are demonstrably met and all listed validation checks pass."
  >   ]
  >   
  >   ,
  >   "context_updates": {
  >     "codex_review_decision": "NOT READY",
  >     "codex_review_confidence": "High",
  >     "codex_review_blocking_gap_count": 10,
  >     "codex_review_blocking_gaps": "Goal is vague and unmeasurable; Beneficiary/actor is undefined; Scope is TBD and overly broad; Boundaries and non-goals are missing; Acceptance criteria are subjective and untestable; Core business decisions are unresolved; Implementation plan is missing; Technical decisions are unresolved; New capability is unknown; Validation plan lacks concrete pass/fail criteria",
  >     "codex_review_required_edits": "Define a specific user/problem/outcome goal; Set concrete scope and non-goals; Resolve all open business decisions; Replace acceptance criteria with objective testable conditions; Add edge-case and permission/error criteria where relevant; Write ordered implementation steps with named modules/files/tests; Resolve technical decisions on data/integration/testing; Define explicit new capability before/after; Provide concrete validation steps and stop condition"
  >   }
  > }

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 9 |
| claude_review_blocking_gaps | Goal is vague and unmeasurable; Scope is completely undefined; All acceptance criteria are subjective; Target users are undefined; Problem statement is missing; No implementation plan exists; Work category is unknown; Expected capability is unknown; Validation approach is missing |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Define specific messaging problem and target users; Replace TBD scope with concrete boundaries; Resolve all open business decisions; Write objectively testable acceptance criteria; Resolve all open technical decisions; Write step-by-step implementation plan with specific files and modules; Define new capability; Create concrete validation plan with test scenarios |
| codex_review_blocking_gap_count | 10 |
| codex_review_blocking_gaps | Goal is vague and unmeasurable; Beneficiary/actor is undefined; Scope is TBD and overly broad; Boundaries and non-goals are missing; Acceptance criteria are subjective and untestable; Core business decisions are unresolved; Implementation plan is missing; Technical decisions are unresolved; New capability is unknown; Validation plan lacks concrete pass/fail criteria |
| codex_review_confidence | High |
| codex_review_decision | NOT READY |
| codex_review_required_edits | Define a specific user/problem/outcome goal; Set concrete scope and non-goals; Resolve all open business decisions; Replace acceptance criteria with objective testable conditions; Add edge-case and permission/error criteria where relevant; Write ordered implementation steps with named modules/files/tests; Resolve technical decisions on data/integration/testing; Define explicit new capability before/after; Provide concrete validation steps and stop condition |
| gemini_review_blocking_gap_count | 5 |
| gemini_review_blocking_gaps | Goal and scope are completely undefined; Acceptance criteria are subjective and untestable; Fundamental business decisions are open; Implementation plan is missing; Technical decisions are unresolved |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Define the specific messaging problem and scope; Replace subjective acceptance criteria with objectively testable conditions; Resolve all Open Business Decisions; Write a step-by-step Implementation Plan; Resolve all Open Technical Decisions |


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
