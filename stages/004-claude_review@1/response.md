# Iteration Plan Review: 014-member-dashboard-liveview-polish

## Decision: NOT READY

## Confidence: High

## Blocking Gaps

1. **Missing Gherkin decision for behaviour-facing iteration**: This iteration changes member-facing behaviour (dashboard UI, navigation, what members see, routing, empty states). Per project guidelines, behaviour-facing iterations require either:
   - An `## Acceptance Scenarios / Feature Files` section naming the Gherkin feature file(s)/scenarios that express acceptance criteria in stakeholder language, OR
   - Explicit rationale for why Gherkin wouldn't add value
   
   Simply running the existing `member_message_deliverability.feature` validates message delivery, not the dashboard polish/UI/navigation changes introduced here. The 10 detailed acceptance criteria (dashboard visibility, CTA navigation, receipt glances, empty states, active-member card, forbidden states) would benefit from stakeholder-readable Gherkin examples or require justification for their omission.

## Non-Blocking Improvements

1. **Explicit non-goals section**: Would clarify boundaries (e.g., "Not changing message compose flow beyond CTA routing", "Not modifying message detail view", "Not adding new messaging features")

2. **Clearer dependency handling**: Step 9 references iteration 013 status conditionally ("if iteration 013 has not already done so"). Either confirm 013 will merge first and remove this hedge, or explicitly handle both scenarios in the implementation steps.

3. **Auth integration as technical decision**: The risk about routing and auth preservation could become a technical decision: "Reuse iteration 010's `EnsureActiveMember` plug pattern at the controller dispatcher layer before LiveView mount"

4. **Explicit stop condition**: Add: "Iteration complete when all acceptance criteria pass, validation succeeds, and no regressions in public/logged-out/inactive-member flows"

## Smallest Viable Iteration

The current scope could theoretically split into:
- **Part A**: LiveView migration with existing content (routing, auth, basic message list)
- **Part B**: UI polish (receipt glances, active-member card, empty states)

However, given this is positioned as the final polish iteration completing wireframe alignment (after iterations 010 and 013), the current scope may be appropriate as a finishing slice. The main issue is the missing Gherkin decision, not scope bloat.

## Required Plan Edits

1. **Add `## Acceptance Scenarios / Feature Files` section** that either:
   - Names specific Gherkin feature file(s) and scenario titles (e.g., `member_dashboard_navigation.feature` with scenarios for "Active member views polished dashboard", "CTA routes to compose", "Empty club shows empty states", "Inactive member sees forbidden"), OR
   - Provides explicit rationale such as: "This iteration polishes internal UI details already validated by LiveView tests and existing message deliverability scenarios. Gherkin would duplicate lower-level test coverage without adding stakeholder-readable value because [specific reasoning about why the UI changes don't need behaviour examples]"

## Validation Plan

The current validation plan is solid **once the Gherkin gap is addressed**:
- `dev check` for quality gates
- LiveView/Phoenix tests for component behaviour
- Existing or new Cucumber scenarios for member workflows
- Manual demo with specific verification steps

**After the required edit**, validation should confirm:
- Dashboard routes correctly for all user states (active member, inactive, logged-out)
- CTA navigation to compose route
- Receipt glances render with correct vocabulary
- Timestamp handling (present/omitted appropriately)
- Empty states appear in new clubs
- Active-member card and avatar stack display
- No operator data leaks
- Existing message deliverability preserved

---

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":1,"claude_review_blocking_gaps":"Missing Gherkin decision for behaviour-facing iteration (requires either named feature files/scenarios or explicit rationale)","claude_review_required_edits":"Add Acceptance Scenarios section with either Gherkin feature file names/scenarios or explicit rationale for omission"}}