Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01M1PG6GRCBC62C9D3JN593E1X
Pipeline progress: 2 of 10 stages completed

## Stage: review_fork
- Status: succeeded
- Handler: parallel
- Notes: Parallel node dispatched 3 branches (3 succeeded, 0 failed)

## Stage: review_merge
- Status: succeeded
- Handler: parallel.fan_in
- Notes: Joined 3 parallel branches

## Current context
| Key | Value |
|-----|-------|
| parallel.branch_count | 3 |
| parallel.results | [{"id":"gemini_review","index":0,"status":"succeeded","context_updates":{"gemini_review_blocking_gap_count":8,"gemini_review_blocking_gaps":"Goal is too vague; Scope is unbounded; Acceptance criteria are untestable; Missing BDD scenario decisions; Fundamental business decisions are unresolved; Implementation plan is missing; Core technical decisions are open; Validation plan and capabilities are undefined","gemini_review_confidence":"High","gemini_review_decision":"NOT READY","gemini_review_required_edits":"Define a specific goal; Define concrete scope boundaries; Write testable acceptance criteria; Add Acceptance Scenarios section; Resolve open business decisions; Write step-by-step implementation plan; Resolve open technical decisions; Define clear validation plan","last_response":"# Plan Validation Report\n\n- Decision: NOT READY\n- Confidence: High\n\n## Blocking gaps\n\n1. **Unclear Goal:** \"Make messaging better for everyone\" is too vague; it does not define a specific user or busi","last_stage":"gemini_review","response.gemini_review":"# Plan Validation Report\n\n- Decision: NOT READY\n- Confidence: High\n\n## Blocking gaps\n\n1. **Unclear Goal:** \"Make messaging better for everyone\" is too vague; it does not define a specific user or business outcome.\n2. **Unbounded Scope:** The scope is explicitly \"TBD\" and unbounded, offering no focus or boundaries for the iteration.\n3. **Untestable Acceptance Criteria:** The criteria (\"Messaging is better\", \"Users are happier\", \"It works correctly\") are highly subjective and cannot be objectively tested or verified.\n4. **Missing BDD/Scenario Considerations:** The plan lacks an `## Acceptance Scenarios / Feature Files` section and gives no indication of how behaviour-facing changes will be documented and verified.\n5. **Unresolved Business Decisions:** Fundamental product questions (who the users are, which problem is being solved, what success means) are left completely open.\n6. **Missing Implementation Plan:** \"Start coding and figure it out\" provides no direction, sequence, or technical strategy.\n7. **Unresolved Technical Decisions:** Core engineering questions regarding UI, domain, storage, and testing are undefined.\n8. **Undefined Validation and Capabilities:** There is no defined new capability, and the validation plan (\"Run some tests if there are any\") provides no way to prove success or establish a stop condition.\n\n## Non-blocking improvements\n\n1. **Provide Concrete Context:** The background section could include specific examples of what users currently find confusing to ground the problem.\n\n## Smallest viable iteration\n\nIdentify **one** specific, isolated messaging problem (e.g., \"Users cannot see when a message failed to send\" or \"Add a character counter to the message input form\") and solve only that single problem.\n\n## Required plan edits\n\n- **Goal:** Replace the current goal with a specific, achievable objective naming the intended beneficiary.\n- **Scope:** Define concrete boundaries, including explicit non-goals.\n- **Acceptance Criteria:** Write specific, objectively testable criteria that cover happy paths, edge cases, and error states.\n- **Acceptance Scenarios:** Add an `## Acceptance Scenarios / Feature Files` section naming the Gherkin files/scenarios that will cover the rules, or explain why they are unnecessary.\n- **Business Decisions:** Resolve all items in the \"Open Business Decisions\" section.\n- **Implementation Plan:** Write a step-by-step technical plan naming likely files, modules, or architectural components.\n- **Technical Decisions:** Resolve all items in the \"Open Technical Decisions\" section.\n- **Validation Plan:** Define a clear stop condition and specify exactly how the team will prove the iteration succeeded.\n\n{\"context_updates\":{\"gemini_review_decision\":\"NOT READY\",\"gemini_review_confidence\":\"High\",\"gemini_review_blocking_gap_count\":8,\"gemini_review_blocking_gaps\":\"Goal is too vague; Scope is unbounded; Acceptance criteria are untestable; Missing BDD scenario decisions; Fundamental business decisions are unresolved; Implementation plan is missing; Core technical decisions are open; Validation plan and capabilities are undefined\",\"gemini_review_required_edits\":\"Define a specific goal; Define concrete scope boundaries; Write testable acceptance criteria; Add Acceptance Scenarios section; Resolve open business decisions; Write step-by-step implementation plan; Resolve open technical decisions; Define clear validation plan\"}}"}},{"id":"claude_review","index":1,"status":"succeeded","context_updates":{"claude_review_blocking_gap_count":9,"claude_review_blocking_gaps":"No clear goal/outcome/actor; scope explicitly unbounded with no non-goals; acceptance criteria untestable; missing behaviour-vs-technical classification and Acceptance Scenarios/Feature Files section or rationale; core business decisions unresolved (users, problem, behaviour change, success definition); no implementation plan; core technical decisions unresolved (layer, storage, testing approach); new capability undefined; no real validation plan or stop condition","claude_review_confidence":"High","claude_review_decision":"NOT READY","claude_review_required_edits":"Rewrite goal naming actor and outcome; bound scope and list non-goals; resolve open business decisions before acceptance criteria; rewrite acceptance criteria as concrete testable statements; add classification plus Acceptance Scenarios/Feature Files section or rationale; resolve open technical decisions; write concrete ordered implementation plan naming files/tests; state the new capability explicitly; write concrete validation plan with stop condition","last_response":"{\"outcome\":\"succeeded\",\"preferred_next_label\":\"NOT READY\",\"context_updates\":{\"claude_review_decision\":\"NOT READY\",\"claude_review_confidence\":\"High\",\"claude_review_blocking_gap_count\":9,\"claude_review_","last_stage":"claude_review","response.claude_review":"{\"outcome\":\"succeeded\",\"preferred_next_label\":\"NOT READY\",\"context_updates\":{\"claude_review_decision\":\"NOT READY\",\"claude_review_confidence\":\"High\",\"claude_review_blocking_gap_count\":9,\"claude_review_blocking_gaps\":\"No clear goal/outcome/actor; scope explicitly unbounded with no non-goals; acceptance criteria untestable; missing behaviour-vs-technical classification and Acceptance Scenarios/Feature Files section or rationale; core business decisions unresolved (users, problem, behaviour change, success definition); no implementation plan; core technical decisions unresolved (layer, storage, testing approach); new capability undefined; no real validation plan or stop condition\",\"claude_review_required_edits\":\"Rewrite goal naming actor and outcome; bound scope and list non-goals; resolve open business decisions before acceptance criteria; rewrite acceptance criteria as concrete testable statements; add classification plus Acceptance Scenarios/Feature Files section or rationale; resolve open technical decisions; write concrete ordered implementation plan naming files/tests; state the new capability explicitly; write concrete validation plan with stop condition\"}}"}},{"id":"codex_review","index":2,"status":"succeeded","context_updates":{"codex_review_blocking_gap_count":6,"codex_review_blocking_gaps":"Goal lacks a specific actor, problem, and outcome; Scope is TBD and unbounded; Acceptance criteria are subjective and omit required paths and state details; Behaviour classification and feature scenarios or rationale are absent; Business and technical decisions plus actionable implementation steps remain unresolved; New capability, proof of success, and stop condition are undefined","codex_review_confidence":"High","codex_review_decision":"NOT READY","codex_review_required_edits":"Define the actor, problem, changed behaviour, and outcome; Bound scope and state non-goals; Add objective acceptance criteria for success and relevant edge, permission, error, and state cases; Classify the iteration and add named feature scenarios or an explicit rationale; Resolve business and technical decisions and provide ordered file/module-specific implementation steps; Define the new capability, validation procedure, and stop condition","last_response":"{\n  \"outcome\": \"succeeded\",\n  \"failure_reason\": \"\",\n  \"review\": {\n    \"decision\": \"NOT READY\",\n    \"confidence\": \"High\",\n    \"blocking_gaps\": [\n      \"The goal does not identify the intended actor, th","last_stage":"codex_review","response.codex_review":"{\n  \"outcome\": \"succeeded\",\n  \"failure_reason\": \"\",\n  \"review\": {\n    \"decision\": \"NOT READY\",\n    \"confidence\": \"High\",\n    \"blocking_gaps\": [\n      \"The goal does not identify the intended actor, the messaging problem to solve, or a concrete user or business outcome.\",\n      \"The scope is explicitly TBD and potentially includes unrelated UI, data-model, provider, permissions, analytics, retry, and template work; no boundaries or non-goals are established.\",\n      \"The acceptance criteria are subjective and not objectively testable. They do not define expected behaviour, happy paths, edge cases, permissions, error states, or data and state changes.\",\n      \"The plan does not classify the iteration as behaviour-facing or technical. Given the apparent behaviour-facing scope, it also lacks an Acceptance Scenarios / Feature Files section and provides no rationale for omitting stakeholder-readable Gherkin scenarios.\",\n      \"Core business and technical decisions remain unresolved, and the implementation plan does not identify ordered steps, affected files or modules, interfaces, integrations, migrations, or tests.\",\n      \"The expected new capability is unknown, and the validation plan supplies neither concrete proof of success nor a clear stop condition.\"\n    ],\n    \"non_blocking_improvements\": [\n      \"After choosing a concrete outcome, document relevant dependencies, risks, and an explicit baseline if success will be measured quantitatively.\",\n      \"Record major scope tradeoffs so later iterations can distinguish intentionally deferred messaging improvements from omissions.\"\n    ],\n    \"smallest_viable_iteration\": \"Choose one clearly identified user group and one observable messaging problem on one product surface. Deliver one end-to-end behaviour change for that problem, including its primary success path and the most important permission or failure case. Exclude provider, storage, analytics, retry, template, and broader UI work unless directly required by that single behaviour.\",\n    \"required_plan_edits\": [\n      \"Rewrite the goal to name the actor, current problem, desired behaviour, and user or business outcome.\",\n      \"Replace the TBD scope with one bounded behaviour and add explicit non-goals.\",\n      \"Resolve who the users are, which messaging problem is being addressed, what behaviour changes, and what constitutes success.\",\n      \"Replace subjective acceptance criteria with concrete Given/When/Then-style observable outcomes covering the success path and relevant edge, permission, error, and state-change cases.\",\n      \"Classify the iteration as behaviour-facing or technical. If behaviour-facing, add an Acceptance Scenarios / Feature Files section naming the shared feature file and scenarios; otherwise explain why Gherkin adds no useful stakeholder-readable examples.\",\n      \"Resolve the open technical decisions and provide ordered implementation steps naming expected modules, files, interfaces, persistence changes, integrations, and test layers where applicable.\",\n      \"State the exact capability available after completion and define specific validation commands, automated tests, acceptance scenarios, and the pass/fail stop condition.\"\n    ],\n    \"validation_plan\": \"Run the named shared Cucumber scenarios for the selected user-visible behaviour, targeted automated tests for the affected domain and interface layers, and the repository's required dev check. Verify the primary success path and the identified permission or failure case, including any expected persisted state or external interaction. The iteration succeeds only when every acceptance criterion and named scenario passes and no unresolved business or technical decisions remain.\"\n  },\n  \"context_updates\": {\n    \"codex_review_decision\": \"NOT READY\",\n    \"codex_review_confidence\": \"High\",\n    \"codex_review_blocking_gap_count\": 6,\n    \"codex_review_blocking_gaps\": \"Goal lacks a specific actor, problem, and outcome; Scope is TBD and unbounded; Acceptance criteria are subjective and omit required paths and state details; Behaviour classification and feature scenarios or rationale are absent; Business and technical decisions plus actionable implementation steps remain unresolved; New capability, proof of success, and stop condition are undefined\",\n    \"codex_review_required_edits\": \"Define the actor, problem, changed behaviour, and outcome; Bound scope and state non-goals; Add objective acceptance criteria for success and relevant edge, permission, error, and state cases; Classify the iteration and add named feature scenarios or an explicit rationale; Resolve business and technical decisions and provide ordered file/module-specific implementation steps; Define the new capability, validation procedure, and stop condition\"\n  }\n}"}}] |


You are GPT-5.6 Sol acting as the repair coordinator for an iteration plan validation loop.

Use the three model reviews and their routing context fields. The reviewer agents read the plan file directly, so do not require plan text to be present in your own summarized context.

The reviewer stages fan out independently and then fan in before this stage. In the merged context, inspect `parallel.results`: each branch must expose both its Markdown response and the routing context fields under that branch's `context_updates`. Do not assume those fields are promoted to top-level context.

Required fields:

- Gemini: `gemini_review_decision`, `gemini_review_confidence`, `gemini_review_blocking_gap_count`, `gemini_review_blocking_gaps`, `gemini_review_required_edits`
- Claude: `claude_review_decision`, `claude_review_confidence`, `claude_review_blocking_gap_count`, `claude_review_blocking_gaps`, `claude_review_required_edits`
- GPT-5.6 Sol: `codex_review_decision`, `codex_review_confidence`, `codex_review_blocking_gap_count`, `codex_review_blocking_gaps`, `codex_review_required_edits`

Fail closed if you cannot see all three reviewer Markdown reports, decisions, and blocking-gap summaries in `parallel.results`. Missing reviewer evidence is a workflow/tooling failure for this validation pass, not proof that the plan is ready.

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
