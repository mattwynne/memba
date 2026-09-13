Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01M2CRH90MWVQ08YF38XYDNVC9
Pipeline progress: 2 of 10 stages completed

## Stage: review_fork
- Status: partially_succeeded
- Handler: parallel
- Notes: Parallel node dispatched 3 branches (1 succeeded, 2 failed)

## Stage: review_merge
- Status: succeeded
- Handler: parallel.fan_in
- Notes: Joined 3 parallel branches

## Current context
| Key | Value |
|-----|-------|
| parallel.branch_count | 3 |
| parallel.results | [{"id":"gemini_review","index":0,"status":"failed","context_updates":{}},{"id":"claude_review","index":1,"status":"failed","context_updates":{}},{"id":"codex_review","index":2,"status":"succeeded","context_updates":{"codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_confidence":"High","codex_review_decision":"READY","codex_review_required_edits":"None","last_response":"{\n  \"preferred_next_label\": \"implementation\",\n  \"outcome\": \"succeeded\",\n  \"failure_reason\": \"\",\n  \"suggested_next_ids\": [],\n  \"review_report\": \"## Decision: READY\\n\\n## Confidence: High\\n\\nThe complet","last_stage":"codex_review","response.codex_review":"{\n  \"preferred_next_label\": \"implementation\",\n  \"outcome\": \"succeeded\",\n  \"failure_reason\": \"\",\n  \"suggested_next_ids\": [],\n  \"review_report\": \"## Decision: READY\\n\\n## Confidence: High\\n\\nThe complete 104-line iteration plan was reviewed directly. It defines a clear user outcome for active club members, keeps discovery separate from participation, establishes role-specific privacy boundaries, identifies the shared acceptance feature, closes business and technical decisions, and provides an ordered implementation and validation strategy.\\n\\n## Blocking gaps\\n\\n1. None.\\n\\n## Non-blocking improvements\\n\\n1. Add an explicit acceptance scenario for an already-open LiveView when membership or administrator status changes. The scope, implementation plan, and validation plan require reactive permission updates, but a named example would make the expected transition and resulting selected surface easier to trace.\\n2. State the group-rail ordering rule explicitly, even if the decision is simply to preserve the existing system-group and custom-group ordering.\\n3. For stronger traceability, list the exact new scenario titles from `group_conversations.feature` in the Acceptance Scenarios section instead of describing them only by category.\\n\\n## Smallest viable iteration\\n\\nKeep the proposed slice intact: active club members can discover every same-club group name; participating members retain their existing conversation and membership capabilities; ordinary non-members receive only access guidance and the Admin contact; outside club administrators receive read-only membership inspection without conversation or email access; direct and stale actions remain server-authorized. The remembered-selection and live-permission-refresh work belongs in this slice because otherwise the new discoverable links could expose stale content or behave inconsistently with existing navigation.\\n\\nAfter this iteration, members will be able to find groups they have not joined and learn how to seek access, while club administrators will be able to inspect custom-group membership without joining or receiving conversations.\\n\\n## Required plan edits\\n\\n1. None before implementation.\\n\\n## Validation plan\\n\\n1. Parse the shared Gherkin and verify the `@iteration-061`, runner-debt, and inherited `@iteration-058` scenario inventory.\\n2. Test the Membership APIs independently: active members discover every same-club group, foreign-club and signed-out actors discover nothing, and `list_active_groups_for_member/2` continues to return actual memberships only.\\n3. Run the new domain and browser scenarios covering ordinary non-members, outside administrators, direct action refusal, club isolation, and remembered non-member selection.\\n4. Add focused presentation and routed LiveView tests for participating-member, ordinary-placeholder, and administrator-members-only surfaces. Assert that unauthorized conversations and member rows are neither loaded nor emitted in initial HTML or LiveView diffs.\\n5. Exercise guessed URLs and direct read, compose, reply, follow, and delivery-detail actions, including stale actions after access loss, and prove that no message, reply, follow, membership, or email subscription is created.\\n6. Verify already-open LiveViews recompute discovery and access after relevant read-model changes without requiring refresh or sign-out.\\n7. Verify same-club remembered selections reopen their currently permitted surface, while missing and foreign selections fall back to Everyone without granting access from browser state.\\n8. Manually review the ordinary access-guidance and outside-admin members-only surfaces on desktop and mobile against the approved local designs.\\n9. Run `dev check` against the exact delivered state. The stop condition is that all iteration-061 scenarios and focused regressions pass, existing iteration-058 and system-group behavior remains green, privacy checks show no unauthorized disclosure or mutation, the manual design review passes, and `dev check` succeeds.\",\n  \"context_updates\": {\n    \"codex_review_decision\": \"READY\",\n    \"codex_review_confidence\": \"High\",\n    \"codex_review_blocking_gap_count\": 0,\n    \"codex_review_blocking_gaps\": \"None\",\n    \"codex_review_required_edits\": \"None\"\n  }\n}"}}] |


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
