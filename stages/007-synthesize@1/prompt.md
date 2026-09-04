Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01M1PGGCXRZV1MSEFMGK7ZWY5W
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
| parallel.results | [{"id":"gemini_review","index":0,"status":"succeeded","context_updates":{"gemini_review_blocking_gap_count":6,"gemini_review_blocking_gaps":"Goal lacks specific outcome; Scope is unfocused and TBD; Acceptance criteria are subjective; Missing Acceptance Scenarios section; Unresolved business and technical decisions; Implementation plan provides no steps or details","gemini_review_confidence":"High","gemini_review_decision":"NOT READY","gemini_review_required_edits":"Define a specific goal; Constrain scope; Write objective acceptance criteria; Add Acceptance Scenarios section; Resolve all open decisions; Detail step-by-step implementation plan","last_response":"- Decision: NOT READY\n- Confidence: High\n- Blocking gaps:\n  1. **Goal clarity**: The goal (\"Make messaging better for everyone\") is vague, lacks a specific business or user outcome, and does not clear","last_stage":"gemini_review","response.gemini_review":"- Decision: NOT READY\n- Confidence: High\n- Blocking gaps:\n  1. **Goal clarity**: The goal (\"Make messaging better for everyone\") is vague, lacks a specific business or user outcome, and does not clearly identify the beneficiary.\n  2. **Scope focus**: The scope is explicitly \"TBD\" and completely open-ended, meaning the iteration has no clear boundaries or non-goals.\n  3. **Acceptance criteria**: Criteria are subjective (\"better\", \"happier\", \"works correctly\") and impossible to objectively test or automate.\n  4. **Acceptance Scenarios**: The plan lacks an `## Acceptance Scenarios / Feature Files` section to outline behavior-facing changes or state why Gherkin would not be useful.\n  5. **Unresolved decisions**: Fundamental business and technical decisions (who the users are, what problem is being solved, what the technical approach is) are explicitly left unresolved.\n  6. **Implementation plan**: The plan (\"Start coding and figure it out\") provides zero specific steps, files, or technical details, making it impossible to evaluate the approach.\n- Non-blocking improvements:\n  1. Add detailed background context with examples of the confusing messaging aspects to justify the priority of the work once the problem is defined.\n- Smallest viable iteration: Identify a single, specific point of confusion in a single messaging workflow for a specific user persona (e.g., \"Add 'message sent' confirmation toast for users sending direct messages\") and implement only that.\n- Required plan edits:\n  - Define a specific, measurable goal and clearly state the target user.\n  - Constrain the scope to a single, coherent outcome and explicitly list non-goals.\n  - Write concrete, objective, and testable acceptance criteria that cover both happy paths and edge cases.\n  - Add an `## Acceptance Scenarios / Feature Files` section naming the intended Gherkin feature files, or provide an explicit rationale for omitting them.\n  - Provide a step-by-step implementation plan detailing the intended technical changes, including specific files, modules, and data model changes.\n  - Resolve all open business and technical decisions prior to starting implementation.\n  - Define a concrete validation plan explaining how to prove the specific capability was successfully added.\n- Validation plan: Success will be proven when all defined (and currently missing) objective acceptance criteria are met, automated tests verify the new capability, and manual testing confirms the specific user outcome was achieved.\n\n{\n  \"context_updates\": {\n    \"gemini_review_decision\": \"NOT READY\",\n    \"gemini_review_confidence\": \"High\",\n    \"gemini_review_blocking_gap_count\": 6,\n    \"gemini_review_blocking_gaps\": \"Goal lacks specific outcome; Scope is unfocused and TBD; Acceptance criteria are subjective; Missing Acceptance Scenarios section; Unresolved business and technical decisions; Implementation plan provides no steps or details\",\n    \"gemini_review_required_edits\": \"Define a specific goal; Constrain scope; Write objective acceptance criteria; Add Acceptance Scenarios section; Resolve all open decisions; Detail step-by-step implementation plan\"\n  }\n}"}},{"id":"claude_review","index":1,"status":"succeeded","context_updates":{"claude_review_blocking_gap_count":9,"claude_review_blocking_gaps":"Goal not articulated; Scope undefined/unbounded (TBD grab-bag); Acceptance criteria not testable (subjective statements); No behaviour-vs-technical classification or Acceptance Scenarios/Feature Files section; Core business decisions explicitly unresolved; Implementation plan absent ('start coding and figure it out'); Core technical decisions explicitly unresolved; Expected capability stated as Unknown; Validation plan not actionable ('run some tests if there are any')","claude_review_confidence":"High","claude_review_decision":"NOT READY","claude_review_required_edits":"State concrete goal with actor/beneficiary; Resolve and remove Open Business Decisions; Rewrite Scope with one coherent outcome and explicit non-goals; Rewrite Acceptance Criteria as testable statements covering happy path/edge cases/permissions/errors/data changes; Add behaviour-vs-technical classification and Acceptance Scenarios/Feature Files section or rationale; Resolve and remove Open Technical Decisions; Replace Implementation Plan with ordered specific steps naming files/modules/tests; Replace New Capability Unknown with concrete before/after statement; Replace Validation Plan with specific tests and stop condition","last_response":"{\"outcome\": \"succeeded\", \"preferred_next_label\": \"NOT READY\", \"failure_reason\": \"Plan fails readiness review: goal, scope, acceptance criteria, implementation plan, technical decisions, expected capab","last_stage":"claude_review","response.claude_review":"{\"outcome\": \"succeeded\", \"preferred_next_label\": \"NOT READY\", \"failure_reason\": \"Plan fails readiness review: goal, scope, acceptance criteria, implementation plan, technical decisions, expected capability, and validation plan are all unresolved or placeholder content ('TBD', 'Unknown', explicit Open Business/Technical Decisions lists).\", \"context_updates\": {\"claude_review_decision\": \"NOT READY\", \"claude_review_confidence\": \"High\", \"claude_review_blocking_gap_count\": 9, \"claude_review_blocking_gaps\": \"Goal not articulated; Scope undefined/unbounded (TBD grab-bag); Acceptance criteria not testable (subjective statements); No behaviour-vs-technical classification or Acceptance Scenarios/Feature Files section; Core business decisions explicitly unresolved; Implementation plan absent ('start coding and figure it out'); Core technical decisions explicitly unresolved; Expected capability stated as Unknown; Validation plan not actionable ('run some tests if there are any')\", \"claude_review_required_edits\": \"State concrete goal with actor/beneficiary; Resolve and remove Open Business Decisions; Rewrite Scope with one coherent outcome and explicit non-goals; Rewrite Acceptance Criteria as testable statements covering happy path/edge cases/permissions/errors/data changes; Add behaviour-vs-technical classification and Acceptance Scenarios/Feature Files section or rationale; Resolve and remove Open Technical Decisions; Replace Implementation Plan with ordered specific steps naming files/modules/tests; Replace New Capability Unknown with concrete before/after statement; Replace Validation Plan with specific tests and stop condition\"}}"}},{"id":"codex_review","index":2,"status":"succeeded","context_updates":{"codex_review_blocking_gap_count":7,"codex_review_blocking_gaps":"Goal lacks a specific problem, beneficiary, and outcome; Scope is TBD and unbounded; Behaviour/technical classification and acceptance-scenario decision are absent; Acceptance criteria are subjective and incomplete; Core business decisions are unresolved; Implementation details and technical decisions are unresolved; Capability, success proof, and stop condition are undefined","codex_review_confidence":"High","codex_review_decision":"NOT READY","codex_review_required_edits":"Define actor, problem, behaviour, and outcome; Bound scope and add non-goals; Resolve business decisions; Classify the iteration and add feature files/scenarios or a Gherkin rationale; Write objective acceptance criteria covering relevant paths and states; Add an ordered implementation plan and resolve technical decisions; Define the delivered capability, validation checks, and stop condition","last_response":"{\"report_markdown\":\"## Decision\\n\\nNOT READY\\n\\n## Confidence\\n\\nHigh\\n\\n## Blocking gaps\\n\\n1. The goal does not identify a specific messaging problem, intended beneficiary, or measurable user/busine","last_stage":"codex_review","response.codex_review":"{\"report_markdown\":\"## Decision\\n\\nNOT READY\\n\\n## Confidence\\n\\nHigh\\n\\n## Blocking gaps\\n\\n1. The goal does not identify a specific messaging problem, intended beneficiary, or measurable user/business outcome.\\n2. Scope is explicitly TBD and potentially spans UI, data model, providers, permissions, analytics, retries, and templates. No boundaries or non-goals define a coherent iteration.\\n3. The plan does not classify the iteration as behaviour-facing or technical/engineering. It also lacks an `## Acceptance Scenarios / Feature Files` section or a rationale for omitting Gherkin.\\n4. The acceptance criteria—“Messaging is better,” “Users are happier,” and “It works correctly”—are subjective and not objectively testable. They do not define happy paths, edge cases, permissions, errors, or expected state changes.\\n5. Core business and product decisions remain open: the users, problem, intended behaviour change, and meaning of success are all undecided.\\n6. The implementation plan contains no ordered implementation steps, affected files/modules, interfaces, tests, or integration points. Fundamental technical decisions, including the type of work, storage requirements, and testing approach, remain unresolved.\\n7. The new capability is unknown, and the validation plan provides neither specific proof of success nor a clear stop condition.\\n\\n## Non-blocking improvements\\n\\n1. After choosing the outcome, document relevant baseline evidence or metrics so the reason for prioritizing the iteration is clear.\\n2. Add dependencies, rollout considerations, and observability requirements if the selected slice affects providers, persisted messages, or production delivery.\\n\\n## Smallest viable iteration\\n\\nChoose one identified actor, one concrete messaging problem in one workflow, and one observable behaviour change. Limit the iteration to the minimum UI/domain/provider changes needed for that single flow, explicitly excluding unrelated analytics, templates, retries, schema changes, and provider work unless one is essential to the chosen outcome. The exact slice cannot be selected responsibly until the open product decisions are resolved.\\n\\n## Required plan edits\\n\\n1. Rewrite the goal to name the actor, current problem, desired behaviour, and user/business outcome.\\n2. Replace the TBD scope with one bounded workflow and add explicit non-goals.\\n3. Resolve and remove every open business decision, including what measurable or observable result constitutes success.\\n4. Classify the iteration as behaviour-facing or technical/engineering. If behaviour-facing or policy-related, add `## Acceptance Scenarios / Feature Files` naming the shared feature file and scenarios; otherwise explain why Gherkin adds no useful stakeholder-readable examples.\\n5. Replace the acceptance criteria with concrete Given/When/Then-style outcomes covering the main path and relevant edge cases, permissions, errors, and state changes.\\n6. Add an ordered implementation plan naming likely modules/files, interfaces, persistence changes, integrations, and tests, and resolve the listed technical decisions.\\n7. State the exact capability delivered and define an executable validation plan with a clear completion threshold.\\n\\n## Validation plan\\n\\nAfter the plan is revised, prove the selected flow with stakeholder-readable acceptance scenarios when behaviour-facing, focused automated tests for the affected domain/UI/integration boundaries, and explicit checks for the relevant error, permission, and state-transition cases. Run the repository-required `dev check` on the final implementation state. Stop only when every objective acceptance criterion and named scenario passes, the promised capability is demonstrable for the identified actor, and no in-scope business or technical decision remains open.\\n\\nThe plan was fully read from the requested file. It was not edited or marked validated, and implementation was not started.\",\"context_updates\":{\"codex_review_decision\":\"NOT READY\",\"codex_review_confidence\":\"High\",\"codex_review_blocking_gap_count\":7,\"codex_review_blocking_gaps\":\"Goal lacks a specific problem, beneficiary, and outcome; Scope is TBD and unbounded; Behaviour/technical classification and acceptance-scenario decision are absent; Acceptance criteria are subjective and incomplete; Core business decisions are unresolved; Implementation details and technical decisions are unresolved; Capability, success proof, and stop condition are undefined\",\"codex_review_required_edits\":\"Define actor, problem, behaviour, and outcome; Bound scope and add non-goals; Resolve business decisions; Classify the iteration and add feature files/scenarios or a Gherkin rationale; Write objective acceptance criteria covering relevant paths and states; Add an ordered implementation plan and resolve technical decisions; Define the delivered capability, validation checks, and stop condition\"}}"}}] |


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
