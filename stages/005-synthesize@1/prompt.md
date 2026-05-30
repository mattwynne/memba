Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KSVY6YF7GXPQT6BZV1B2JPPH
Pipeline progress: 3 of 15 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='.fabro/workflows/plan-validation/test/fixtures/unanimous-pass/plan.md'
if [ ! -f "$PLAN_PATH" ]; then
  echo "Plan file not found: $PLAN_PATH" >&2
  exit 1
fi
printf 'PLAN_PATH=%s\n\n' "$PLAN_PATH"
sed -n '1,260p' "$PLAN_PATH"`
- Output:
  ```
  (35 lines omitted)
  - Use RFC 4180-style CSV escaping: wrap fields containing commas, quotes, or newlines in double quotes and escape internal double quotes as two double quotes.
  
  ### Out of scope
  
  - New authentication, authorization, or permissions machinery. This fixture deliberately relies on the existing browser pipeline access model: any user who can access the message detail page may download the same message's CSV receipts.
  - Exports across multiple messages or clubs.
  - Background jobs, email attachments, scheduled reports, or admin dashboards.
  - Changing delivery status domain behaviour.
  - Styling beyond a plain download link.
  
  ## Acceptance Criteria
  
  - Given a message addressed to Alice, Bob, and Carol, when an operator downloads the CSV, then it contains one header row and exactly one data row per addressed recipient.
  - The CSV columns are exactly `message_id,message_subject,recipient_name,recipient_email,receipt_status,delivery_status,delivery_reason`.
  - Rows are sorted by recipient name ascending, then recipient email ascending.
  - A delivered recipient has `receipt_status` of `delivered`, `delivery_status` of `delivered`, and an empty `delivery_reason`.
  - A delayed, bounced, or spam-complaint recipient has `receipt_status` of `delivery problem`, the corresponding provider `delivery_status`, and the recorded provider reason.
  - An opened recipient has `receipt_status` of `opened`, `delivery_status` of `opened`, and an empty `delivery_reason`.
  - A recipient with no provider confirmation has `receipt_status` of `sent`, `delivery_status` of `sent`, and an empty `delivery_reason`.
  - Non-addressed club members do not appear in the CSV.
  - Requesting `/messages/:message_id/delivery_receipts.csv` for an unknown message returns 404.
  - `dev check` passes.
  
  ## Open Business Decisions
  
  None.
  
  ## Implementation Plan
  
  1. Add Phoenix controller coverage for `GET /messages/:message_id/delivery_receipts.csv` before implementation.
  2. Add a focused CSV export module or context function that reads existing message delivery receipt data and returns rows in the specified order.
  3. Add the CSV route under the browser pipeline.
  4. Add a download link from the message detail LiveView to the CSV route.
  5. Ensure the export uses existing receipt/delivery read models only; do not add new domain events or commands.
  6. Add tests for delivered, delivery problem, opened, sent, non-addressed exclusion, ordering, blank reasons, and unknown message 404.
  7. Run `dev check`.
  
  ## Open Technical Decisions
  
  None. Implement RFC 4180-style CSV escaping locally for this small fixed-column export; do not add a dependency.
  
  ## New Capability
  
  An operator can download a deterministic CSV delivery receipt report for one already-sent club message.
  
  ## Validation Plan
  
  - Run the focused controller/export tests.
  - Manually create a message with delivered, problem, opened, and sent recipients, download the CSV, and verify the columns, row count, ordering, statuses, and reasons.
  - Run `dev check`.
  ```

## Stage: review_fork
- Status: succeeded
- Handler: parallel
- Notes: Parallel node dispatched 3 branches (3 succeeded, 0 failed)

## Stage: review_merge
- Status: succeeded
- Handler: parallel.fan_in
- Notes: Selected best candidate: claude_review

## Current context
| Key | Value |
|-----|-------|
| parallel.branch_count | 3 |
| parallel.fan_in.best_head_sha | 89b4d9d7fb1daca929dfb40702754efdfc86b16f |
| parallel.fan_in.best_id | claude_review |
| parallel.fan_in.best_outcome | succeeded |
| parallel.results | [{"id":"gemini_review","status":"succeeded","head_sha":"f955534ce401bcbb84129acaae731e043774e2c9"},{"id":"claude_review","status":"succeeded","head_sha":"89b4d9d7fb1daca929dfb40702754efdfc86b16f"},{"id":"codex_review","status":"succeeded","head_sha":"74c6337a0ddebf3353b6a929a2db8fad6f2b7e23"}] |


You are Claude Opus acting as the repair coordinator for an iteration plan validation loop.

Use the plan text and the three model reviews in context.

The reviewer stages run in parallel and merge before this synthesis stage. Read the merged branch evidence from the stage preamble and, when available, `parallel_results.json`. Treat each branch's Markdown report and its routing context fields as reviewer evidence.

The reviewer stages must have exposed both their Markdown reports and these routing context fields:

- Gemini: `gemini_review_decision`, `gemini_review_confidence`, `gemini_review_blocking_gap_count`, `gemini_review_blocking_gaps`, `gemini_review_required_edits`
- Claude: `claude_review_decision`, `claude_review_confidence`, `claude_review_blocking_gap_count`, `claude_review_blocking_gaps`, `claude_review_required_edits`
- Codex/GPT: `codex_review_decision`, `codex_review_confidence`, `codex_review_blocking_gap_count`, `codex_review_blocking_gaps`, `codex_review_required_edits`

Fail closed if you cannot see all three reviewer decisions and blocking-gap summaries in the merged branch evidence. Missing reviewer evidence is a workflow/tooling failure for this validation pass, not proof that the plan is ready.

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

1. First verify that all three reviewer decisions and blocking-gap summaries are visible in the merged context, stage preamble, or `parallel_results.json`. If any are missing, route to Matt/human input and explain that validation evidence was incomplete.
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
