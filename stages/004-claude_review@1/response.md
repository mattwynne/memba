# Iteration Plan Review: Member Receipt Detail LiveView Polish

## Decision: NOT READY

## Confidence: High

## Blocking Gaps

1. **Zero-count status display decision is unresolved**: The plan lists "Whether zero-count statuses appear as collapsible group headers or only in the summary" as an open technical decision, but this is actually a UX/product decision that affects what members see. Must be resolved before implementation. The plan states "The summary must represent all four statuses" but doesn't decide whether zero-count groups also appear as expandable (but empty) sections in the recipient list.

2. **Browser test strategy for collapsed groups is undefined**: The plan notes as a risk that "Existing browser helpers expect recipient rows to be present; implementation may need to expand groups in helpers or expose rows only after interaction." This must be a decided approach, not a risk. Will step definitions automatically expand groups? Will scenarios be updated to include explicit expand steps? Will there be a hybrid approach? This affects both implementation (DOM structure, test attributes) and scenario maintenance.

3. **Missing formal acceptance criteria**: While the validation plan includes manual demo steps and references to existing Cucumber scenarios, there is no dedicated "## Acceptance Criteria" section with concrete, testable statements of what should and shouldn't happen. The manual demo steps are close but not formatted as acceptance criteria that define done.

## Non-blocking Improvements

1. **Add explicit non-goals section**: Non-goals are mentioned in passing ("This does not address dashboard polish or separate compose screens") but would benefit from a dedicated section for clarity.

2. **Clarify Gherkin scenario decision**: The plan references an existing Cucumber feature file (`member_message_deliverability.feature`) and expects it to "pass unchanged," but doesn't explicitly state whether new Gherkin scenarios are needed to cover the new collapse/expand behavior, summary bar, counts/percentages, etc., or provide a rationale for why the existing scenarios suffice for a behaviour-facing change.

3. **Module naming can be deferred**: "Exact LiveView module name" and helper function placement are listed as open decisions but are implementation details that can be resolved during development without blocking the start.

## Smallest Viable Iteration

The current scope is already quite focused - it's a single page conversion with closely coupled visual and interaction changes. You could theoretically split it into:

1. **Phase 1**: LiveView conversion with basic grouped receipt display (no collapse/expand, all groups always visible)
2. **Phase 2**: Add collapse/expand functionality and summary bar

However, this would deliver less value in phase 1 since the collapse/expand and summary are core to the "polish" goal and the design inspiration from `receipts.jsx`. The current scope is appropriate as a single iteration if the blocking gaps are resolved.

## Required Plan Edits

1. **Resolve zero-count status behavior**: In the "## Open Technical Decisions" section, decide and document whether zero-count statuses appear as:
   - Summary bar only (e.g., "0 bounced" in the summary, no "Bounced" group header in recipient list)
   - Summary bar + collapsed group header (e.g., "0 bounced" in summary, "Bounced (0)" header with no rows when expanded)
   - Document the rationale for UI clarity and implementation consistency

2. **Specify browser test approach**: In the implementation steps or a new "## Browser Test Strategy" section, decide and document:
   - Will existing step definitions be updated to expand groups before asserting on rows?
   - Will scenarios be updated to include explicit "When I expand the X group" steps?
   - Will there be test-only attributes or methods to bypass collapse state for setup?
   - State the chosen approach and confirm it preserves scenario readability

3. **Add formal acceptance criteria section**: Add "## Acceptance Criteria" before or after "## Implementation Steps" with concrete, testable statements like:
   - Members see a summary bar showing counts and percentages for all four receipt statuses (delivered, opened, bounced, pending)
   - All receipt groups are collapsed by default
   - Clicking a group header expands/collapses that group
   - Expanded groups show recipient rows with name, email, status icon, and timestamp
   - Collapsed groups show no recipient rows
   - Only member-facing fields appear (no operator-only diagnostics)
   - Unauthorized access returns 403/404 as appropriate
   - Cover zero-count status rendering based on decision from #1

4. **Clarify Gherkin coverage**: In or near the "## Acceptance Scenarios / Feature Files" section (add if missing), state whether:
   - Existing `member_message_deliverability.feature` scenarios cover the new behavior sufficiently, or
   - New scenarios will be added to cover collapse/expand, summary bar, and mixed-status presentation, or
   - Provide explicit rationale if no Gherkin is needed for this behaviour-facing change

## Validation Plan

After the required edits are made, the plan will be ready when:

1. The zero-count status behavior is documented with a specific UI approach
2. The browser test strategy is specified with concrete steps for handling collapsed groups
3. Formal acceptance criteria are listed in a dedicated section
4. Gherkin scenario coverage is explicitly addressed

Then validation proceeds as stated in the plan:
- Run `dev check`
- Run targeted LiveView/Phoenix tests
- Confirm Cucumber scenarios pass (with the decided test strategy applied)
- Manual demo confirms all acceptance criteria and visual/interaction polish
- Staff can confirm operator diagnostics remain accessible at `/admin/*` routes

---

```json
{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":3,"claude_review_blocking_gaps":"Zero-count status display behavior must be decided; Browser test strategy for collapsed groups must be specified; Missing formal acceptance criteria section","claude_review_required_edits":"Decide and document zero-count status behavior; Specify exact browser test approach for collapsed groups; Add formal acceptance criteria section; Clarify Gherkin scenario coverage"}}
```