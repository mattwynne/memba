# Iteration Plan Review: Browser Cucumber Automation

## Decision: READY

## Confidence: High

## Blocking Gaps

None.

## Non-Blocking Improvements

1. **Explicit non-goals section** - While the plan excludes `@todo-web` scenarios and notes dependencies, an explicit "What we are NOT doing" section would strengthen boundaries.

2. **Lifecycle wrapper naming** - Implementation step 3 says "Build or refine the browser test lifecycle wrapper" but doesn't specify where this code will live or what it will be called. However, step 1 includes inspection of existing setup, which addresses this during implementation.

3. **Step implementation detail** - Steps 4-6 reference implementing browser steps but rely on implementer inspection of feature files. This is acceptable given step 1, but more specificity about which Gherkin steps need new browser implementations versus reuse could reduce exploration time.

4. **UI selector strategy** - Step 5 mentions "accessible labels, roles, and stable identifiers supplied by the existing UI" but doesn't confirm these exist or specify the selector strategy (test-ids, aria-labels, etc.). The dependency on iteration 005 implies these exist, but explicit confirmation would help.

## Smallest Viable Iteration

The current scope is already well-focused. A smaller slice might be:

**Just homepage.feature browser automation** - This would validate the lifecycle wrapper, Phoenix readiness checks, and basic browser step implementation without the complexity of projection timing and webhook integration.

However, the current scope including `member_message_deliverability.feature` is justified because:
- It validates the critical projection-waiting infrastructure that differentiates this from simple browser testing
- The homepage alone wouldn't exercise the webhook or LiveView timing challenges that are core to the iteration's value
- It's already minimal (excludes operator features)

The current scope is appropriate and should not be reduced further.

## Required Plan Edits

None. The plan is implementable as written.

The implementation plan's first step explicitly includes inspection of existing code, which will surface necessary details (file locations, existing step definitions, UI selectors) before making changes. This discovery-before-modification approach is sound.

## Validation Plan

The plan's validation section is concrete and complete:

✅ **Validation is objective and testable:**
- Run `npm test` from `acceptance-tests/` with expected pass result
- Verify feature inclusion/exclusion by tag
- Run domain acceptance path via `dev check` 
- Confirm all scenarios pass regardless of `@todo-web`
- Run full `dev check` and fix failures

✅ **Stop condition is clear:** Both `npm test` and `dev check` pass with documented feature coverage.

✅ **Success proof:** The validation plan directly tests each acceptance criterion:
- Homepage and member message features pass browser tests
- Operator features excluded from browser, included in domain
- Diagnostic separation confirmed through test output inspection
- Overall quality gate passes via `dev check`

## Additional Validation Recommendations

1. **Projection timing validation** - Manually verify that status-change browser steps actually wait for UI updates rather than passing due to timing luck. Consider adding an intentional delay in projection to confirm waiting logic works.

2. **Diagnostic clarity validation** - Intentionally trigger each failure mode (database not ready, Phoenix not started, webhook failure, projection timeout, assertion mismatch) and confirm error messages clearly identify the cause.

3. **Documentation** - After implementation, update `acceptance-tests/README.md` (if it exists) or add inline comments documenting the lifecycle wrapper's startup/teardown sequence and waiting strategies for future maintainers.

## Summary

This plan is ready for implementation. It has:
- Clear, testable acceptance criteria covering happy paths and error diagnostics
- Ordered implementation steps with sufficient detail
- Resolved technical decisions (projection waiting strategy)
- Documented dependencies (iteration 005 routes)
- Concrete validation approach
- Appropriate scope

The plan correctly prioritizes infrastructure quality (clear diagnostics, bounded waiting, reliable teardown) over just "making tests pass," which will pay ongoing dividends.

The Gemini review concurred (READY, High confidence, 0 blocking gaps), and I agree with that assessment.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}