Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KT0ZAT9MTMB77247W73SNY5W
Pipeline progress: 2 of 13 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/012-member-receipt-detail-liveview-polish/plan.md'
if [ ! -f "$PLAN_PATH" ]; then
  echo "Plan file not found: $PLAN_PATH" >&2
  exit 1
fi
printf 'PLAN_PATH=%s\n\n' "$PLAN_PATH"
sed -n '1,260p' "$PLAN_PATH"`
- Output:
  ```
  (122 lines omitted)
     - load the message;
     - ensure `message.club_id == club_id`;
     - render existing forbidden/not-found semantics where applicable.
  5. Build a receipt presentation model for the LiveView:
     - reuse `MembaWeb.MemberReceiptPresentation` for labels and icons;
     - add descriptions, display order, counts, and percentages;
     - create deterministic summary/group data for all four statuses, including zero-count statuses where useful for the summary.
  6. Render the polished message detail page with `<Layouts.club_site>` and Phoenix/Tailwind styling inspired by `receipts.jsx`.
  7. Add LiveView state for collapsed groups:
     - all groups collapsed initially;
     - `handle_event("toggle_receipt_group", ...)` toggles a status key;
     - avoid custom JavaScript unless needed.
  8. Preserve the existing stable DOM/test attributes for recipient rows so browser acceptance helpers do not need to change.
  9. Add focused LiveView/ConnCase tests covering:
     - route and authorization behaviours preserved;
     - summary counts and percentages for mixed statuses;
     - all groups collapsed by default;
     - expand/collapse reveals and hides rows;
     - no operator-only fields appear on the member page.
  10. Run the existing member-message browser Cucumber scenarios and `dev check`.
  
  ## Open Technical Decisions
  
  - Exact LiveView module name and whether small helper functions live in the LiveView or a presentation module. Prefer simple module boundaries that keep receipt calculations testable without over-engineering.
  - Whether zero-count statuses appear as collapsible group headers or only in the summary. The summary must represent all four statuses; recipient rows are required only for statuses with receipts.
  
  ## New Capability
  
  Members can scan a message's reach using a summary bar with counts and percentages, then expand specific receipt groups to see which members are in each status without leaving the page.
  
  ## Validation Plan
  
  - Run `dev check`.
  - Run targeted LiveView/Phoenix tests for the new member message detail LiveView.
  - Confirm existing `acceptance-tests/features/member_message_deliverability.feature` passes unchanged through the browser runner.
  - Manual demo:
    - sign in as Alice;
    - open a message with mixed receipt statuses;
    - confirm the summary bar, counts, percentages, descriptions, and collapsed groups;
    - expand and collapse each group;
    - confirm recipient rows appear only when expanded;
    - confirm no operator-only details are visible;
    - confirm `/admin/*` diagnostics still show operator detail for staff.
  
  ## Risks / Follow-ups
  
  - LiveView conversion may require carefully preserving controller-era auth and error semantics.
  - Existing browser helpers expect recipient rows to be present; implementation may need to expand groups in helpers or expose rows only after interaction while keeping scenarios meaningful.
  - Percent rounding can produce totals that do not add exactly to 100%; choose a user-friendly deterministic approach and test it.
  - This does not address dashboard polish or separate compose screens; those remain good future iterations.
  ```

## Stage: gemini_review
- Status: succeeded
- Handler: prompt
- Model: gemini-3.1-pro-preview
- Tokens: 4.2k in / 2.8k out
- Response:
  > {
  >   "context_updates": {
  >     "gemini_review_decision": "NOT READY",
  >     "gemini_review_confidence": "High",
  >     "gemini_review_blocking_gap_count": 2,
  >     "gemini_review_blocking_gaps": "Open technical decisions must be resolved before implementation (zero-count behavior); Test strategy for hidden rows in existing Cucumber scenarios must be finalized",
  >     "gemini_review_required_edits": "Resolve open technical decisions in the plan; Specify exact approach for expanding rows in browser tests"
  >   }
  > }

## Current context
| Key | Value |
|-----|-------|
| gemini_review_blocking_gap_count | 2 |
| gemini_review_blocking_gaps | Open technical decisions must be resolved before implementation (zero-count behavior); Test strategy for hidden rows in existing Cucumber scenarios must be finalized |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Resolve open technical decisions in the plan; Specify exact approach for expanding rows in browser tests |


You are independently reviewing an iteration plan before implementation.

Use the plan text from the preceding `Read Iteration Plan` stage. Do not assume any missing details. Be strict, practical, and specific.

Review the plan against these readiness questions:

1. Goal clarity
   - Is the goal clearly articulated?
   - Does it state the user/business outcome, not just tasks?
   - Is the intended beneficiary or actor clear?

2. Scope focus
   - Is the scope focused on one coherent outcome?
   - Could the iteration be any smaller while still useful?
   - Are non-goals and boundaries clear?

3. Acceptance criteria, BDD scenario decision, and business decisions
   - Are acceptance criteria concrete, clear, complete, and objectively testable?
   - Do they cover happy paths, important edge cases, permissions, error states, and data/state changes where relevant?
   - Does the plan classify the iteration as behaviour-facing or technical/engineering?
   - For behaviour-facing or domain-policy changes, does the plan include an `## Acceptance Scenarios / Feature Files` section naming the shared Cucumber feature file(s)/scenarios that will express the rules, or an explicit rationale for why Gherkin would not add useful stakeholder-readable examples?
   - Are any business, product, policy, copy, workflow, or domain decisions still unresolved?

4. Implementation plan and technical decisions
   - Are implementation steps clear, ordered, and specific?
   - Are likely files, modules, migrations, tests, interfaces, and integration points named where useful?
   - Are data model, API, UI, workflow, integration, and background-job changes clear enough?
   - Are any technical decisions still unresolved?

5. Expected capability and validation
   - What should we be able to do after this iteration that we cannot do now?
   - How will we prove success?
   - Is there a clear stop condition?

Return a Markdown report with:

- Decision: READY or NOT READY
- Confidence: High, Medium, or Low
- Blocking gaps: numbered list
- Non-blocking improvements: numbered list
- Smallest viable iteration: your recommended smallest useful slice
- Required plan edits: concrete edits the author should make
- Validation plan: how to prove the iteration succeeded

At the end of your response, include one final JSON object for workflow routing. It must be the last thing in the response and must not be wrapped in a Markdown code fence.

Use these keys exactly so the synthesis stage can fail closed if reviewer findings are not visible in context:

- `claude_review_decision`: `READY` or `NOT READY`
- `claude_review_confidence`: `High`, `Medium`, or `Low`
- `claude_review_blocking_gap_count`: integer count of blocking gaps
- `claude_review_blocking_gaps`: concise semicolon-separated blocking gaps, or `None`
- `claude_review_required_edits`: concise semicolon-separated required edits, or `None`

Examples:

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":2,"claude_review_blocking_gaps":"Ordering is not decided; Acceptance criteria omit visible table columns","claude_review_required_edits":"State ordering; Define table columns and row identity"}}
