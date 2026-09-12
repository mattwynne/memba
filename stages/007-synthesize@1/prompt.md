Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01M2ABMDSFVYTXQPEE78D18HVF
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
| parallel.results | [{"id":"gemini_review","index":0,"status":"succeeded","context_updates":{"gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_confidence":"High","gemini_review_decision":"READY","gemini_review_required_edits":"None","last_response":"{\n  \"context_updates\": {\n    \"gemini_review_decision\": \"READY\",\n    \"gemini_review_confidence\": \"High\",\n    \"gemini_review_blocking_gap_count\": 0,\n    \"gemini_review_blocking_gaps\": \"None\",\n    \"gemin","last_stage":"gemini_review","response.gemini_review":"{\n  \"context_updates\": {\n    \"gemini_review_decision\": \"READY\",\n    \"gemini_review_confidence\": \"High\",\n    \"gemini_review_blocking_gap_count\": 0,\n    \"gemini_review_blocking_gaps\": \"None\",\n    \"gemini_review_required_edits\": \"None\"\n  }\n}"}},{"id":"claude_review","index":1,"status":"succeeded","context_updates":{"claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_confidence":"High","claude_review_decision":"READY","claude_review_required_edits":"None","last_response":"{\"claude_review_decision\":\"READY\",\"claude_review_confidence\":\"High\",\"claude_review_blocking_gap_count\":0,\"claude_review_blocking_gaps\":\"None\",\"claude_review_required_edits\":\"None\",\"preferred_next_labe","last_stage":"claude_review","response.claude_review":"{\"claude_review_decision\":\"READY\",\"claude_review_confidence\":\"High\",\"claude_review_blocking_gap_count\":0,\"claude_review_blocking_gaps\":\"None\",\"claude_review_required_edits\":\"None\",\"preferred_next_label\":\"mark_validated\",\"outcome\":\"succeeded\",\"context_updates\":{\"claude_review_decision\":\"READY\",\"claude_review_confidence\":\"High\",\"claude_review_blocking_gap_count\":0,\"claude_review_blocking_gaps\":\"None\",\"claude_review_required_edits\":\"None\"}}"}},{"id":"codex_review","index":2,"status":"succeeded","context_updates":{"codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_confidence":"High","codex_review_decision":"READY","codex_review_required_edits":"None","last_response":"{\n  \"preferred_next_label\": \"validated\",\n  \"outcome\": \"succeeded\",\n  \"failure_reason\": \"\",\n  \"suggested_next_ids\": [],\n  \"decision\": \"READY\",\n  \"confidence\": \"High\",\n  \"blocking_gaps\": [],\n  \"non_bloc","last_stage":"codex_review","response.codex_review":"{\n  \"preferred_next_label\": \"validated\",\n  \"outcome\": \"succeeded\",\n  \"failure_reason\": \"\",\n  \"suggested_next_ids\": [],\n  \"decision\": \"READY\",\n  \"confidence\": \"High\",\n  \"blocking_gaps\": [],\n  \"non_blocking_improvements\": [\n    \"Document a repeatable browser procedure for independently triggering the client/network and server interruption classes so manual validation is less dependent on implementer knowledge.\",\n    \"Name the expected stylesheet location if implementation reveals that Tailwind utilities alone cannot clearly express safe-area or reduced-motion behavior.\",\n    \"State the stop condition explicitly: every acceptance criterion has automated or recorded manual evidence and dev check passes on the delivery candidate.\"\n  ],\n  \"smallest_viable_iteration\": \"Set disconnectedTimeout to 1500 milliseconds, replace only the two generated reconnect error toasts in the shared flash group with the approved non-dismissible status pill, preserve ordinary flash behavior, and verify brief, client, server, reconnect, accessibility, responsive, and reduced-motion states.\",\n  \"required_plan_edits\": [],\n  \"validation_plan\": [\n    \"Assert the shared rendered markup has stable client/server IDs, exact copy, initially hidden states, role=status and polite announcement semantics, matching LiveView selectors, automatic phx-connected hiding, shared visual treatment, and no close controls.\",\n    \"Assert the effective LiveSocket configuration uses disconnectedTimeout: 1500 while retaining existing options.\",\n    \"Run existing flash and layout coverage to prove ordinary informational and error flashes remain unchanged.\",\n    \"In a real browser, verify an interruption shorter than 1.5 seconds stays silent.\",\n    \"Verify longer client/network and server interruptions show only their corresponding copy while leaving the current page visible and unobstructed, then disappear on reconnection.\",\n    \"Check narrow and desktop viewport placement, safe-area handling, keyboard focus, pointer interaction, and reduced-motion behavior.\",\n    \"Run dev check on the exact delivery candidate.\"\n  ],\n  \"context_updates\": {\n    \"codex_review_decision\": \"READY\",\n    \"codex_review_confidence\": \"High\",\n    \"codex_review_blocking_gap_count\": 0,\n    \"codex_review_blocking_gaps\": \"None\",\n    \"codex_review_required_edits\": \"None\"\n  }\n}"}}] |


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
