# Iteration Plan Review: 013-member-compose-liveview-flow

## Decision: NOT READY

## Confidence: High

The plan cannot be validated because critical sections are missing from the provided text, and the plan explicitly lists unresolved technical decisions that are blocking implementation.

---

## Blocking Gaps

1. **Missing plan sections**: The provided output starts at line 163, omitting the first 162 lines which should contain Goal, Scope, and Acceptance Criteria sections. These are fundamental to validating plan readiness.

2. **Unresolved technical decision**: Exact LiveView module name and route helper naming. The plan states this is an "Open Technical Decision" but naming is a prerequisite for implementation steps 2, 3, and 4.

3. **Unresolved technical decision**: Best way to simulate message-send unavailability in acceptance tests. This directly affects step 1 (adding the browser scenario) and step 10 (updating step support). The plan correctly notes this needs resolution to avoid coupling Gherkin to infrastructure.

4. **Unresolved technical decision**: Whether the old `POST /?club_id=<club_id>` route should be removed immediately or kept temporarily. This affects step 5 (controller updates) and overall cleanup scope.

---

## Non-blocking Improvements

1. **Make "no sender dropdown" rule explicit in acceptance criteria**: This is a significant product change (removing an affordance that "existed accidentally"). Consider adding specific acceptance criteria like "WHEN Alice composes a message THEN she cannot select a different sender AND the system shows her as the sender."

2. **Document rationale for dedicated LiveView**: The plan describes what will be built but could be clearer about what problem the inline form had that the new flow solves (e.g., was it confusing? did success/failure states not fit? was navigation unclear?).

3. **Specify failure simulation mechanism**: The manual demo says "simulate send failure" but doesn't specify how. Consider documenting the mechanism even if the exact test implementation is still being decided.

4. **Add test for unauthorized access**: Consider acceptance criteria or test case for attempting to access compose screen without authentication or without a selected club.

---

## Smallest Viable Iteration

The current iteration scope appears appropriate and focused:
- Move compose to dedicated LiveView
- Remove sender dropdown (use logged-in member)
- Add success/failure states with clear next actions
- Update acceptance tests

If you needed to reduce scope, you could defer the failure scenario to a follow-up iteration and focus only on the happy path (steps 1-7, 9-10, 12), but this would leave an incomplete feature. The current scope is already coherent and appropriately sized.

---

## Required Plan Edits

1. **Provide the complete plan text** including Goal, Scope, and Acceptance Criteria sections (currently omitted from lines 1-162).

2. **Decide and document the LiveView module name**, for example:
   - Module: `MembaWeb.MemberComposeLive` or `MembaWeb.ComposeMessageLive`
   - Route helper: `compose_messages_path` (already specified in step 4, but module name needed)

3. **Decide and document the test simulation strategy** for send unavailability:
   - Option A: Test configuration flag in MessageDeliverer behavior
   - Option B: Test-only failure condition in fake provider
   - Option C: Background Given step that configures failure mode
   - Document the chosen approach and rationale

4. **Decide and document the old POST route handling**:
   - Option A: Remove immediately (clean break, simplest)
   - Option B: Keep temporarily, remove in follow-up (safer, but more cleanup)
   - Specify which and update step 5 accordingly

5. **Add explicit acceptance criteria** for the sender dropdown removal since this is a notable product change that the plan identifies as having "existed accidentally."

---

## Validation Plan

The existing validation plan is comprehensive and appropriate:

- ✅ Run `dev check`
- ✅ Run targeted LiveView/Phoenix tests
- ✅ Run browser acceptance feature
- ✅ Manual demo with detailed steps

**Suggested additions:**
- Verify the old inline compose form is no longer accessible via any route
- Verify attempting to access compose without authentication redirects appropriately
- Verify attempting to access compose without a selected club shows appropriate error
- Document exactly how to "simulate send failure" in the manual demo step
- Verify failure state does NOT send any message (not just that error UI appears)

---

## Summary

The implementation steps (6-12 visible, presumably 1-12 complete in full plan) are detailed and actionable. The validation approach is solid. The business decisions appear resolved (sender logic, failure handling, success actions).

However, the plan cannot proceed to implementation because:
1. Core sections (Goal, Scope, Acceptance Criteria) are not visible for validation
2. Three technical decisions are explicitly unresolved and documented as "Open Technical Decisions"

Once the full plan is provided and the three technical decisions are made and documented, this plan should be ready for implementation.

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":4,"claude_review_blocking_gaps":"Missing Goal, Scope, and Acceptance Criteria sections (lines 1-162 omitted);Unresolved LiveView module and route naming;Unresolved test simulation strategy for send unavailability;Unresolved decision on old POST route removal","claude_review_required_edits":"Provide complete plan text with Goal, Scope, and Acceptance Criteria;Decide and document LiveView module name and route helper;Decide and document test simulation strategy for send failures;Decide and document old POST route handling (remove or keep temporarily)"}}