Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KV3DSATBGM3JJBHY8T4TZBZ4
Pipeline progress: 3 of 10 stages completed

## Stage: gemini_review
- Status: succeeded
- Handler: agent
- Model: gemini-3.1-pro-preview
- Tokens: 36.5k in / 1.9k out
- Response:
  > - Decision: NOT READY
  > - Confidence: High
  > - Blocking gaps:
  >   1. **Workflow-evidence gap**: The iteration plan file `docs/iterations/033-homepage-staff-bar/plan.md` does not exist in the workspace and could not be read.
  > - Non-blocking improvements:
  >   1. N/A
  > - Smallest viable iteration: Unknown (the plan file is missing).
  > - Required plan edits: Create the plan file at `docs/iterations/033-homepage-staff-bar/plan.md` containing the goal, scope, acceptance criteria, implementation steps, and expected capability/validation.
  > - Validation plan: Re-run the review validation once the plan file has been successfully created in the project repository.
  > 
  > {"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":1,"gemini_review_blocking_gaps":"The iteration plan file docs/iterations/033-homepage-staff-bar/plan.md does not exist","gemini_review_required_edits":"Create the iteration plan file at the specified path with all required sections"}}

## Stage: claude_review
- Status: succeeded
- Handler: agent
- Model: claude-sonnet-4-5
- Tokens: 16.5k in / 4.7k out
- Response:
  > Iteration 033 is not listed in the README. The plan file truly doesn't exist. This is a workflow-evidence gap - I cannot review a plan that doesn't exist.
  > 
  > ---
  > 
  > # Iteration Plan Review Report
  > 
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > ## Blocking gaps
  > 
  > 1. **Plan file does not exist**: The file `docs/iterations/033-homepage-staff-bar/plan.md` cannot be found in the repository. The directory `docs/iterations/033-homepage-staff-bar/` does not exist.
  > 2. **Workflow-evidence gap**: Cannot review plan content when the complete plan file is not available through file-reading tools, as instructed.
  > 
  > ## Non-blocking improvements
  > 
  > None - cannot assess improvements without access to the plan content.
  > 
  > ## Smallest viable iteration
  > 
  > Cannot recommend a smallest viable iteration without access to the plan content.
  > 
  > ## Required plan edits
  > 
  > 1. **Create the plan file**: The plan must exist at `docs/iterations/033-homepage-staff-bar/plan.md` before validation can proceed.
  > 2. **Register in iteration index**: Once created, add iteration 033 to the table in `docs/iterations/README.md` with appropriate status, date, and title.
  > 
  > ## Validation plan
  > 
  > Cannot determine validation criteria without access to the plan content. Once the plan exists and is readable:
  > 
  > 1. Read the complete plan file using file-reading tools
  > 2. Validate against all five readiness questions (goal clarity, scope focus, acceptance criteria/BDD decisions, implementation plan, expected capability)
  > 3. Verify all business and technical decisions are resolved
  > 4. Confirm acceptance scenarios are properly specified for behaviour-facing work
  > 5. Check that implementation steps name relevant files, modules, and integration points
  > 
  > ---
  > 
  > {"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":1,"claude_review_blocking_gaps":"Plan file docs/iterations/033-homepage-staff-bar/plan.md does not exist","claude_review_required_edits":"Create plan file at docs/iterations/033-homepage-staff-bar/plan.md; Register iteration 033 in docs/iterations/README.md"}}

## Stage: codex_review
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 28.1k in / 1.3k out
- Response:
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > I could not read the required plan file completely because the requested file does not exist at:
  > 
  > `/workspace/memba/docs/iterations/033-homepage-staff-bar/plan.md`
  > 
  > I also verified the checked-out repository’s `docs/iterations/` directory only contains iterations through `032-auth-email-delivery-progress`; there is no `033-homepage-staff-bar` directory or matching plan file visible in the workspace.
  > 
  > Because the review instructions explicitly require reading the complete plan file directly, this is a blocking workflow-evidence gap.
  > 
  > ## Blocking gaps
  > 
  > 1. The required iteration plan file is unavailable, so the plan cannot be reviewed for readiness against goal clarity, scope, acceptance criteria, implementation plan, technical decisions, or validation.
  > 
  > ## Non-blocking improvements
  > 
  > 1. None identified; no plan text was available to assess.
  > 
  > ## Smallest viable iteration
  > 
  > Unavailable to assess. The smallest viable slice should be determined only after the complete plan is available and reviewed.
  > 
  > ## Required plan edits
  > 
  > 1. Make the complete iteration plan available at `docs/iterations/033-homepage-staff-bar/plan.md`.
  > 2. Re-run this readiness review after the file is present and readable.
  > 3. Do not mark the iteration validated until the complete plan has passed review.
  > 
  > ## Validation plan
  > 
  > Once the plan file is available, validate readiness by reviewing it directly against the required questions:
  > 
  > 1. Confirm the goal states a clear user/business outcome and actor.
  > 2. Confirm scope, non-goals, and boundaries are explicit.
  > 3. Confirm acceptance criteria are concrete and testable, including relevant edge cases and permissions.
  > 4. Confirm the plan classifies the iteration as behaviour-facing or technical/engineering and includes appropriate Cucumber/Gherkin guidance.
  > 5. Confirm implementation steps name likely files, modules, tests, and integration points.
  > 6. Confirm unresolved business or technical decisions are either absent or explicitly called out.
  > 7. Confirm there is a clear stop condition and proof of success.
  > 
  > {"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":1,"codex_review_blocking_gaps":"Required plan file docs/iterations/033-homepage-staff-bar/plan.md is unavailable/read failed, so complete plan cannot be reviewed","codex_review_required_edits":"Make the complete plan file available at docs/iterations/033-homepage-staff-bar/plan.md and rerun readiness review before marking validated"}}

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 1 |
| claude_review_blocking_gaps | Plan file docs/iterations/033-homepage-staff-bar/plan.md does not exist |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Create plan file at docs/iterations/033-homepage-staff-bar/plan.md; Register iteration 033 in docs/iterations/README.md |
| codex_review_blocking_gap_count | 1 |
| codex_review_blocking_gaps | Required plan file docs/iterations/033-homepage-staff-bar/plan.md is unavailable/read failed, so complete plan cannot be reviewed |
| codex_review_confidence | High |
| codex_review_decision | NOT READY |
| codex_review_required_edits | Make the complete plan file available at docs/iterations/033-homepage-staff-bar/plan.md and rerun readiness review before marking validated |
| gemini_review_blocking_gap_count | 1 |
| gemini_review_blocking_gaps | The iteration plan file docs/iterations/033-homepage-staff-bar/plan.md does not exist |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Create the iteration plan file at the specified path with all required sections |


You are Claude Opus acting as the repair coordinator for an iteration plan validation loop.

Use the three model reviews and their routing context fields. The reviewer agents read the plan file directly, so do not require plan text to be present in your own summarized context.

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
- The plan does not classify the iteration as behaviour-facing or technical/engineering.
- A behaviour-facing or domain-policy plan lacks an `## Acceptance Scenarios / Feature Files` section with either named shared Cucumber feature file(s)/scenarios or an explicit rationale for why Gherkin would not add useful stakeholder-readable examples.
- Important business decisions remain open.
- Implementation steps require major technical choices that are not made.
- The expected new capability or success validation is unclear.
- The plan expects shared acceptance `.feature` file edits but lacks a `## Allowed acceptance feature changes` section naming each exact file, the allowed kind of change, the reason, and how coverage is preserved or intentionally changed.

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
