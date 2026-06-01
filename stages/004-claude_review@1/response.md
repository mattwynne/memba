# Independent Plan Review

## Decision: NOT READY

## Confidence: High

## Blocking Gaps

1. **Three open technical decisions remain unresolved**:
   - Route organization for `GET /?club_id=<club_id>` (public marketing vs. member dashboard)
   - Receipt glance calculation location (per-row in LiveView vs. presentation helper)
   - Timestamp metadata source for message rows (if projections lack sent timestamps)
   
   These decisions directly impact implementation steps 1, 4, and 5. The plan notes preferences ("prefer a helper", "preserve user-visible behaviour") but doesn't commit to specific approaches.

2. **Missing explicit iteration classification**: The plan doesn't state whether this is behaviour-facing or technical/engineering. This matters for determining whether new Gherkin scenarios are needed.

3. **Missing BDD scenario decision section**: Per reference requirements, behaviour-facing iterations need an `## Acceptance Scenarios / Feature Files` section or explicit rationale for not using Gherkin. The plan mentions running existing `member_message_deliverability.feature` in validation but doesn't explain whether new scenarios are needed or why not.

## Non-blocking Improvements

1. **Implementation step 7** ("Design and render empty states") could specify which conditions trigger which empty states (e.g., "when club has no messages" vs. "when club has no active members").

2. **Acceptance criterion 5** mentions "timestamp (if available)" but doesn't clearly state fallback behavior when timestamps are unavailable. Should the row omit timestamp entirely, show a different field, or display "Unknown"?

3. **The "Risks / Follow-ups" section** mentions that routing needs care and receipt glances may need efficient queries, but doesn't propose mitigation strategies or acceptance criteria to validate these concerns are addressed.

## Smallest Viable Iteration

The current scope is already reasonably focused. However, if forced to slice smaller, you could:

**Option A**: Split into two iterations:
- Iteration 14a: Convert to LiveView, remove inline compose, preserve exact current functionality
- Iteration 14b: Add receipt glances, active-member card, empty states

**Option B**: Defer polish elements:
- Core iteration: LiveView conversion, compose CTA, basic message list
- Defer: Receipt glances, active-member card, empty states to iteration 15

However, the current scope seems appropriate if the technical decisions are resolved. The deliverable "polished dashboard matching wireframe" is coherent and useful.

## Required Plan Edits

1. **Resolve technical decisions** and integrate into implementation steps:
   - **Route organization**: Choose between (a) route-based split with pattern matching in router, (b) single LiveView with mount-time auth check and conditional rendering, or (c) separate public and member routes. State the choice and update step 1 accordingly.
   - **Receipt glances**: Choose between calculation in mount/handle_info vs. dedicated presentation helper. Update step 4 with the chosen module, function signature, and data source.
   - **Timestamp metadata**: Inspect current message projections, confirm whether `sent_at` or equivalent exists. If yes, use it. If no, state explicitly what field will be shown instead (or that timestamp will be omitted). Update step 5 and acceptance criterion 5.

2. **Add explicit iteration classification**: Insert a line near the top stating either:
   - "This is a technical/engineering iteration focused on presentation layer reorganization, not new business rules."
   - Or: "This is a behaviour-facing iteration that changes [specific user-visible behavior]."

3. **Add `## Acceptance Scenarios / Feature Files` section** (or explicit rationale):
   - If technical/engineering: "No new Gherkin scenarios needed. Existing `member_message_deliverability.feature` validates underlying message delivery behavior. This iteration only changes presentation layer; new LiveView tests in implementation step 10 validate UI rendering."
   - If behaviour-facing: List specific scenarios to add/modify in shared feature files.

4. **Minor: Specify empty state conditions** in implementation step 7:
   - "Render empty state when `Clubs.list_messages(club_id)` returns empty list"
   - "Render empty member state when `Clubs.count_active_members(club_id)` returns 0"

## Validation Plan

After required edits are made, the iteration will be ready when:

1. All three open technical decisions are resolved with specific chosen approaches
2. Implementation steps 1, 4, and 5 are updated to reference the chosen approaches
3. The plan explicitly classifies the iteration type and explains the BDD scenario decision
4. Acceptance criterion 5 clearly states fallback behavior for missing timestamps

The existing validation plan (dev check, LiveView tests, browser acceptance test, manual demo) is comprehensive and appropriate once the plan is implementation-ready.

---

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":3,"claude_review_blocking_gaps":"Three unresolved technical decisions (routing, receipt glance location, timestamp source); Missing iteration classification (behaviour-facing vs technical); Missing BDD scenario decision section or rationale","claude_review_required_edits":"Resolve technical decisions and integrate into implementation steps; Add iteration classification; Add Acceptance Scenarios section or explicit rationale for no new Gherkin"}}