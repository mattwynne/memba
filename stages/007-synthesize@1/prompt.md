Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01M1PJPFCVQD55XG64GE4RZYZQ
Pipeline progress: 2 of 10 stages completed

## Stage: review_fork
- Status: partially_succeeded
- Handler: parallel
- Notes: Parallel node dispatched 3 branches (2 succeeded, 1 failed)

## Stage: review_merge
- Status: succeeded
- Handler: parallel.fan_in
- Notes: Joined 3 parallel branches

## Current context
| Key | Value |
|-----|-------|
| parallel.branch_count | 3 |
| parallel.results | [{"id":"gemini_review","index":0,"status":"succeeded","context_updates":{"gemini_review_blocking_gap_count":8,"gemini_review_blocking_gaps":"Goal is completely undefined; Scope is unbounded; Acceptance criteria are subjective and untestable; Missing BDD/feature file decision; All business decisions are explicitly open; No implementation plan exists; All technical decisions are open; Missing expected capability and validation plan","gemini_review_confidence":"High","gemini_review_decision":"NOT READY","gemini_review_required_edits":"Define a specific goal and user; Define strict scope boundaries; Write concrete testable acceptance criteria; Add Acceptance Scenarios / Feature Files section; Resolve all business and technical decisions; Detail specific implementation steps; Define validation plan","last_response":"# Plan Validation Review\n\n- **Decision:** NOT READY\n- **Confidence:** High\n- **Blocking gaps:**\n  1. Goal is completely undefined (\"Make messaging better for everyone\" lacks specific business or user ","last_stage":"gemini_review","response.gemini_review":"# Plan Validation Review\n\n- **Decision:** NOT READY\n- **Confidence:** High\n- **Blocking gaps:**\n  1. Goal is completely undefined (\"Make messaging better for everyone\" lacks specific business or user outcomes).\n  2. Scope is unbounded and explicitly \"TBD\", with no non-goals or boundaries defined.\n  3. Acceptance criteria are purely subjective and untestable (\"Messaging is better\", \"Users are happier\").\n  4. Missing classification of the iteration (behaviour-facing vs technical) and a missing `## Acceptance Scenarios / Feature Files` section for BDD scenario decisions.\n  5. All business decisions (users, problem, behaviour, success metrics) are explicitly listed as open and unresolved.\n  6. No implementation plan exists (\"Start coding and figure it out\" is not actionable).\n  7. All technical decisions (UI/domain/infrastructure categorization, storage changes, testing strategy) are open.\n  8. Missing expected new capability and a concrete validation plan.\n- **Non-blocking improvements:**\n  1. None. The entire plan requires a fundamental rewrite before non-blocking refinements can be considered.\n- **Smallest viable iteration:** \n  - Cannot be determined from the current text. The author must identify one specific, concrete problem for a well-defined user persona (e.g., \"Allow admins to retry failed email deliveries\") and scope the iteration entirely around that single capability.\n- **Required plan edits:**\n  - Define a specific, concrete goal and identify the intended beneficiary.\n  - Define strict scope boundaries and explicit non-goals.\n  - Replace subjective statements with concrete, objectively testable acceptance criteria.\n  - Include an explicit acceptance scenarios/feature files section (or a rationale for omitting Gherkin).\n  - Resolve all listed open business and technical decisions prior to implementation.\n  - Detail specific implementation steps, naming files, modules, or interfaces where possible.\n  - Define the concrete new capability and exactly how it will be validated.\n- **Validation plan:**\n  - Currently undefined. Once the plan is rewritten with a concrete goal, the validation plan must detail exactly how to prove that specific goal succeeded (e.g., through specific automated tests and manual verification steps).\n\n{\"context_updates\":{\"gemini_review_decision\":\"NOT READY\",\"gemini_review_confidence\":\"High\",\"gemini_review_blocking_gap_count\":8,\"gemini_review_blocking_gaps\":\"Goal is completely undefined; Scope is unbounded; Acceptance criteria are subjective and untestable; Missing BDD/feature file decision; All business decisions are explicitly open; No implementation plan exists; All technical decisions are open; Missing expected capability and validation plan\",\"gemini_review_required_edits\":\"Define a specific goal and user; Define strict scope boundaries; Write concrete testable acceptance criteria; Add Acceptance Scenarios / Feature Files section; Resolve all business and technical decisions; Detail specific implementation steps; Define validation plan\"}}"}},{"id":"claude_review","index":1,"status":"failed","context_updates":{"claude_review_blocking_gap_count":9,"claude_review_blocking_gaps":"Goal has no concrete outcome or actor; Scope is unbounded/TBD with no non-goals; Acceptance criteria are not testable; No behaviour-vs-technical classification or Feature Files section despite behaviour-facing signals; Core business decisions (users, problem, behaviour change, success definition) left open; Implementation plan has no real steps or named files/tests; Core technical decisions (work category, storage, test approach) left open; New Capability is 'Unknown'; Validation plan is not actionable","claude_review_confidence":"High","claude_review_decision":"NOT READY","claude_review_required_edits":"Define the specific user/problem before writing goal/scope; Rewrite Goal naming actor and outcome; Bound Scope with explicit non-goals; Rewrite Acceptance Criteria as testable statements covering edge/permission/error cases; Classify iteration as behaviour-facing or technical and add Acceptance Scenarios/Feature Files section or rationale; Resolve all Open Business Decisions; Rewrite Implementation Plan with ordered steps and named files/tests; Resolve all Open Technical Decisions; Define New Capability concretely; Rewrite Validation Plan with concrete tests and stop condition","last_response":"{\"context_updates\":{\"claude_review_decision\":\"NOT READY\",\"claude_review_confidence\":\"High\",\"claude_review_blocking_gap_count\":9,\"claude_review_blocking_gaps\":\"Goal has no concrete outcome or actor; Sc","last_stage":"claude_review","response.claude_review":"{\"context_updates\":{\"claude_review_decision\":\"NOT READY\",\"claude_review_confidence\":\"High\",\"claude_review_blocking_gap_count\":9,\"claude_review_blocking_gaps\":\"Goal has no concrete outcome or actor; Scope is unbounded/TBD with no non-goals; Acceptance criteria are not testable; No behaviour-vs-technical classification or Feature Files section despite behaviour-facing signals; Core business decisions (users, problem, behaviour change, success definition) left open; Implementation plan has no real steps or named files/tests; Core technical decisions (work category, storage, test approach) left open; New Capability is 'Unknown'; Validation plan is not actionable\",\"claude_review_required_edits\":\"Define the specific user/problem before writing goal/scope; Rewrite Goal naming actor and outcome; Bound Scope with explicit non-goals; Rewrite Acceptance Criteria as testable statements covering edge/permission/error cases; Classify iteration as behaviour-facing or technical and add Acceptance Scenarios/Feature Files section or rationale; Resolve all Open Business Decisions; Rewrite Implementation Plan with ordered steps and named files/tests; Resolve all Open Technical Decisions; Define New Capability concretely; Rewrite Validation Plan with concrete tests and stop condition\"},\"outcome\":\"failed\",\"failure_reason\":\"Plan reviewed and determined NOT READY for implementation: 9 blocking gaps identified (unclear goal, unbounded scope, untestable acceptance criteria, missing behaviour/technical classification, unresolved business and technical decisions, absent implementation plan, unknown capability, non-actionable validation plan). Plan must not be marked validated.\",\"preferred_next_label\":\"NOT_READY\"}"}},{"id":"codex_review","index":2,"status":"succeeded","context_updates":{"codex_review_blocking_gap_count":5,"codex_review_blocking_gaps":"Goal lacks a concrete outcome and beneficiary; Scope and boundaries are unresolved; Acceptance criteria, business behaviour, iteration classification, and scenario decision are absent; Implementation approach and technical decisions are unresolved; New capability, validation evidence, and stop condition are undefined","codex_review_confidence":"High","codex_review_decision":"NOT READY","codex_review_required_edits":"Define the actor, problem, and measurable outcome; Select one bounded smallest useful slice with non-goals; Resolve product decisions and write objective acceptance criteria; Classify the iteration and add named acceptance feature scenarios or an explicit Gherkin rationale; Specify ordered implementation steps and settle technical choices; Define the new capability, validation procedure, and stop condition","last_response":"{\"outcome\":\"succeeded\",\"failure_reason\":\"The plan is NOT READY: the user outcome, scope, product behaviour, technical approach, acceptance evidence, and success condition remain unresolved.\",\"suggeste","last_stage":"codex_review","response.codex_review":"{\"outcome\":\"succeeded\",\"failure_reason\":\"The plan is NOT READY: the user outcome, scope, product behaviour, technical approach, acceptance evidence, and success condition remain unresolved.\",\"suggested_next_ids\":[\"review_merge\",\"synthesize\"],\"report\":\"# Plan readiness review\\n\\n## Decision: NOT READY\\n\\n## Confidence: High\\n\\nThe complete 47-line plan was read directly from `.fabro/workflows/plan-validation/test/fixtures/definite-fail/plan.md`. It should not be marked validated, and no files were edited.\\n\\n## Blocking gaps\\n\\n1. **The goal does not identify a concrete outcome or beneficiary.** “Make messaging better for everyone” does not say which actor has which problem, what behaviour should improve, or what valuable outcome the iteration should produce.\\n\\n2. **The scope is entirely unresolved.** The plan explicitly leaves UI, data-model, provider, permissions, analytics, retry, and template work open. It defines neither a coherent smallest useful slice nor non-goals and boundaries.\\n\\n3. **Acceptance and business behaviour are undefined.** “Messaging is better,” “Users are happier,” and “It works correctly” are not objectively testable. The plan leaves the users, problem, behaviour, and meaning of success undecided. It also does not classify the iteration as behaviour-facing or technical/engineering and has no `## Acceptance Scenarios / Feature Files` section naming shared Cucumber scenarios or explaining why Gherkin would not help. Consequently, happy paths, edge cases, permissions, errors, and state changes cannot be assessed.\\n\\n4. **The implementation approach and technical decisions are absent.** “Start coding and figure it out” provides no ordered steps, likely modules or files, interfaces, migrations, tests, or integration points. The plan explicitly leaves the affected layer, storage requirements, and testing strategy undecided.\\n\\n5. **The expected capability, proof of success, and stop condition are unknown.** The `New Capability` section says “Unknown,” while the validation plan only suggests running unspecified tests if any exist. A reviewer could not determine when the iteration was complete.\\n\\n## Non-blocking improvements\\n\\n1. After the product and technical decisions are resolved, map each acceptance criterion to a named acceptance scenario or automated test so coverage is easy to audit.\\n\\n2. Record assumptions and risks for any provider or delivery infrastructure involved in the eventual bounded slice.\\n\\n## Smallest viable iteration\\n\\nChoose one identified user role, one confusing message in one existing workflow, and one observable improvement. Limit the iteration to changing that message’s defined content or presentation and adding acceptance coverage. Exclude data-model changes, provider integration, permissions, analytics, retries, and broader template work unless one is demonstrably required for that single behaviour.\\n\\n## Required plan edits\\n\\n1. Rewrite the goal to name the actor, current messaging problem, desired observable behaviour, and user or business outcome.\\n2. Select one smallest useful messaging change and explicitly list its boundaries and non-goals.\\n3. Resolve the open product and policy decisions instead of leaving them for implementation.\\n4. Replace the current acceptance criteria with concrete Given/When/Then-style expectations covering the chosen happy path and all relevant edge, permission, error, and state-change cases.\\n5. Classify the iteration as behaviour-facing or technical/engineering. If behaviour-facing or domain-policy-related, add `## Acceptance Scenarios / Feature Files` naming the exact shared Cucumber feature file(s) and scenarios, or provide an explicit rationale for omitting Gherkin.\\n6. Add an ordered implementation plan naming the affected modules, UI or API surfaces, data changes, integrations, and tests where applicable; settle the open technical decisions first.\\n7. State the exact capability that will exist afterward and define an objective validation procedure and stop condition.\\n\\n## Validation plan\\n\\n1. Confirm the revised plan contains no material `TBD`, `Unknown`, or open business/technical decisions.\\n2. Execute the named shared acceptance scenarios for the selected actor and workflow, including the happy path and relevant exceptional paths.\\n3. Run focused automated tests for the affected component and integration boundaries, including permissions, errors, and persisted state where applicable.\\n4. Run the repository’s full `dev check` on the exact implementation state.\\n5. Verify the selected actor can demonstrate the promised observable improvement and that excluded messaging behaviours remain unchanged.\\n6. Stop only when every acceptance criterion and named scenario passes and no work outside the stated slice is required.\",\"context_updates\":{\"codex_review_decision\":\"NOT READY\",\"codex_review_confidence\":\"High\",\"codex_review_blocking_gap_count\":5,\"codex_review_blocking_gaps\":\"Goal lacks a concrete outcome and beneficiary; Scope and boundaries are unresolved; Acceptance criteria, business behaviour, iteration classification, and scenario decision are absent; Implementation approach and technical decisions are unresolved; New capability, validation evidence, and stop condition are undefined\",\"codex_review_required_edits\":\"Define the actor, problem, and measurable outcome; Select one bounded smallest useful slice with non-goals; Resolve product decisions and write objective acceptance criteria; Classify the iteration and add named acceptance feature scenarios or an explicit Gherkin rationale; Specify ordered implementation steps and settle technical choices; Define the new capability, validation procedure, and stop condition\"}}"}}] |


You are GPT-5.6 Sol acting as the repair coordinator for an iteration plan validation loop.

Use the three model reviews and their routing context fields. The reviewer agents read the plan file directly, so do not require plan text to be present in your own summarized context.

The reviewer stages fan out independently and then fan in before this stage. In the merged context, inspect `parallel.results`: each branch must expose its substantive response and the routing context fields under that branch's `context_updates`. A reviewer may supply its substantive report as Markdown or structured JSON. Do not assume those fields are promoted to top-level context.

Required fields:

- Gemini: `gemini_review_decision`, `gemini_review_confidence`, `gemini_review_blocking_gap_count`, `gemini_review_blocking_gaps`, `gemini_review_required_edits`
- Claude: `claude_review_decision`, `claude_review_confidence`, `claude_review_blocking_gap_count`, `claude_review_blocking_gaps`, `claude_review_required_edits`
- GPT-5.6 Sol: `codex_review_decision`, `codex_review_confidence`, `codex_review_blocking_gap_count`, `codex_review_blocking_gaps`, `codex_review_required_edits`

Fail closed if you cannot see all three reviewer decisions and blocking-gap summaries in `parallel.results`. Treat the required routing fields as sufficient reviewer evidence when a model returns structured JSON rather than Markdown. Missing reviewer evidence is a workflow/tooling failure for this validation pass, not proof that the plan is ready.

Your job in this stage is to decide whether the plan is ready, needs only obvious editorial/structural correction, or needs human product/technical decisions before it can be ready.

Readiness standard:

A plan is READY only if an engineer can begin implementation without first resolving material product/business decisions or material technical design decisions, and if a reviewer can objectively validate success at the end.

A plan is NOT READY if any of these are true:

- The goal is materially ambiguous.
- The scope is too broad or lacks a smallest useful slice.
- Acceptance criteria are not concrete/testable enough.
- The plan does not classify the iteration as behaviour-facing or technical/engineering.
- A behaviour-facing or domain-policy plan lacks an `## Acceptance Scenarios / Feature Files` section with either named shared Cucumber feature file(s)/scenarios or an explicit rationale for why Gherkin would not add useful stakeholder-readable examples.
- Important business decisions remain open.
- Implementation steps require major technical choices that are not made.
- The expected new capability or success validation is unclear.
- The plan expects shared acceptance `.feature` file edits but lacks a `## Allowed acceptance feature changes` section naming each exact file, the allowed kind of change, the reason, and how coverage is preserved or intentionally changed.

Correction policy:

GPT-5.6 Sol may only be asked to make obvious plan edits that do not require judgment calls, such as:

- tightening wording without changing meaning
- reorganizing existing content into clearer sections
- turning already-stated expectations into objective acceptance criteria
- making implicit boundaries explicit when the plan already clearly implies them
- removing duplication or contradiction when the intended meaning is obvious

Do not ask GPT-5.6 Sol to invent product policy, scope, UX, domain, data-model, integration, or technical-design decisions. If the plan needs those decisions, fail the validation and raise them for Matt.

Synthesis instructions:

1. First verify that all three reviewer decisions and blocking-gap summaries are visible in context. If any are missing, route to Matt/human input and explain that validation evidence was incomplete.
2. Compare the three reviews.
3. Include a reviewer decision table with each reviewer's decision, confidence, blocking gap count, and notes.
4. Identify consensus findings.
5. Correct reviewer findings that are wrong, too vague, duplicated, or not actually blocking.
6. Decide whether the plan is already ready, needs only obvious edits, or needs Matt's input.
7. If only obvious edits are needed, produce a concrete repair brief for GPT-5.6 Sol.
8. If Matt's input is needed, do not produce a repair brief as if GPT-5.6 Sol can solve it; list the decisions/questions clearly.

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
7. GPT-5.6 Sol repair brief: exact instructions for obvious edits only, or "None"
8. Questions for Matt: decisions that need human input, or "None"
9. Validation checklist: what to check after any GPT-5.6 Sol update

At the end of your response, include one final JSON object for workflow routing. It must be the last thing in the response.

If the plan is already READY:

{"preferred_next_label":"validated","context_updates":{"plan_ready":true,"plan_needs_fix":false,"plan_needs_human":false}}

If the plan is NOT READY but GPT-5.6 Sol should apply only obvious fixes:

{"preferred_next_label":"fix","context_updates":{"plan_ready":false,"plan_needs_fix":true,"plan_needs_human":false}}

If the plan is NOT READY because Matt needs to answer questions or make decisions:

{"preferred_next_label":"needs_human","context_updates":{"plan_ready":false,"plan_needs_fix":false,"plan_needs_human":true}}
