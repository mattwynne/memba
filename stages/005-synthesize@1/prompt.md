Goal: Validate that an iteration plan is ready for implementation
Run ID: 01KSV9DQ9P3JHP06CKHEA7XTBQ
Pipeline progress: 3 of 15 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/005-browser-acceptance-harness/plan.md'
if [ ! -f "$PLAN_PATH" ]; then
  echo "Plan file not found: $PLAN_PATH" >&2
  exit 1
fi
printf 'PLAN_PATH=%s\n\n' "$PLAN_PATH"
sed -n '1,260p' "$PLAN_PATH"`
- Output:
  ```
  (61 lines omitted)
  
  ## Acceptance Criteria
  
  - A developer can start the Phoenix app and use the browser to exercise the member-facing behaviours from the existing acceptance tests.
  - `npm test` in `acceptance-tests/` runs the Playwright/Cucumber browser acceptance suite against browser-ready scenarios and excludes `@todo-web` scenarios by default.
  - `homepage.feature` passes through the browser acceptance harness.
  - Every scenario in `member_message_deliverability.feature` passes through the browser acceptance harness.
  - `operator_email_deliverability.feature` remains in the shared acceptance suite, with its scenarios tagged `@todo-web` for browser acceptance.
  - The Elixir/domain Cucumber run still runs all shared scenarios, including scenarios tagged `@todo-web`.
  - PhoenixTest-based tests cover the new LiveView browser surface and important interactions.
  - `dev check` passes.
  
  ## Open Business Decisions
  
  None known.
  
  ## Implementation Plan
  
  1. Add minimal LiveView route(s) under the existing browser pipeline for the browser acceptance harness.
  2. Build simple LiveView forms/actions for club creation, person creation, membership, club message sending, receipt viewing, and status simulation.
  3. Give important forms, controls, rows, and status displays stable IDs or accessible labels suitable for Playwright and PhoenixTest.
  4. Update Playwright/Cucumber step definitions to drive the LiveView UI for `homepage.feature` and `member_message_deliverability.feature`.
  5. Add `@todo-web` tags to operator deliverability scenarios that are intentionally not browser-backed in this iteration.
  6. Configure `acceptance-tests` so the default browser Cucumber command excludes `@todo-web` scenarios.
  7. Add PhoenixTest-based LiveView tests for the new browser surface, using PhoenixTest as the preferred high-level web test API.
  8. Verify the Elixir/domain Cucumber path still runs every shared scenario regardless of `@todo-web` tags.
  9. Run the browser acceptance suite and `dev check`, fixing any issues.
  
  ## Open Technical Decisions
  
  None known.
  
  ## New Capability
  
  Developers/operators can use a browser to exercise and inspect the member-facing behaviours that are currently only implemented and validated at the domain/application layer. The shared acceptance feature files can now partition browser-ready scenarios from browser-deferred scenarios with `@todo-web` while continuing to validate the full domain behaviour separately.
  
  ## Validation Plan
  
  - Run `npm test` from `acceptance-tests/` and confirm it runs browser-ready scenarios only and passes.
  - Confirm `@todo-web` excludes operator deliverability scenarios from the browser acceptance run.
  - Run the Elixir/domain Cucumber suite and confirm it still runs all shared scenarios, including `@todo-web` scenarios.
  - Run PhoenixTest-based LiveView tests for the minimal browser surface.
  - Run `dev check` and fix any failures.
  - Manual demo: start the Phoenix app, create clubs/people/members, send a club message, inspect addressed recipients/delivery records, simulate each member-facing delivery status, and see the member receipt status update.
  
  ## Risks / Follow-ups
  
  - The minimal browser surface may reveal gaps in existing query APIs needed by LiveView. Keep any additions narrowly focused on exposing already-implemented behaviour.
  - The developer controls are intentionally temporary substrate; a later design iteration should replace or reshape them into a real product UX.
  - Operator deliverability browser UI remains deferred behind `@todo-web` and should be planned as a later slice.
  ```

## Stage: fork
- Status: succeeded
- Handler: parallel
- Notes: Parallel node dispatched 3 branches (3 succeeded, 0 failed)

## Stage: merge
- Status: succeeded
- Handler: parallel.fan_in
- Notes: Selected best candidate: claude_review

## Current context
| Key | Value |
|-----|-------|
| parallel.branch_count | 3 |
| parallel.fan_in.best_head_sha | 8818d9d853ff7b449282b35397f74d3ecf7ffb57 |
| parallel.fan_in.best_id | claude_review |
| parallel.fan_in.best_outcome | succeeded |
| parallel.results | [{"id":"gemini_review","status":"succeeded","head_sha":"a369ca387beb6eaabacb97d864c15cf515e140b1"},{"id":"claude_review","status":"succeeded","head_sha":"8818d9d853ff7b449282b35397f74d3ecf7ffb57"},{"id":"codex_review","status":"succeeded","head_sha":"b1516c6b31eea0f4ecca6e2a7dc94c3f015fabf9"}] |


You are Claude Opus acting as the repair coordinator for an iteration plan validation loop.

Use the plan text and the three independent model reviews in context:

- Gemini review
- Claude review
- Codex/GPT review

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

1. Compare the three reviews.
2. Identify consensus findings.
3. Correct reviewer findings that are wrong, too vague, duplicated, or not actually blocking.
4. Decide whether the plan is already ready, needs only obvious edits, or needs Matt's input.
5. If only obvious edits are needed, produce a concrete repair brief for Codex.
6. If Matt's input is needed, do not produce a repair brief as if Codex can solve it; list the decisions/questions clearly.

Return a Markdown report with:

1. Provisional decision: READY, OBVIOUS FIXES NEEDED, or NEEDS MATT
2. Consensus findings: 3-6 bullets
3. Corrected findings: reviewer findings you changed, downgraded, combined, or rejected
4. Blocking gaps: numbered list, each with why it blocks implementation
5. Codex repair brief: exact instructions for obvious edits only, or "None"
6. Questions for Matt: decisions that need human input, or "None"
7. Validation checklist: what to check after any Codex update

At the end of your response, include one final JSON object for workflow routing. It must be the last thing in the response.

If the plan is already READY:

{"context_updates":{"plan_ready":true,"plan_needs_fix":false,"plan_needs_human":false}}

If the plan is NOT READY but Codex should apply only obvious fixes:

{"context_updates":{"plan_ready":false,"plan_needs_fix":true,"plan_needs_human":false}}

If the plan is NOT READY because Matt needs to answer questions or make decisions:

{"context_updates":{"plan_ready":false,"plan_needs_fix":false,"plan_needs_human":true}}
