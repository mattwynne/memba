## Iteration Plan Review: Request-to-Club Onboarding

**Decision**: READY

**Confidence**: High

**Blocking gaps**: None

**Non-blocking improvements**:

1. Consider adding an explicit `## Goal` section at the very top with a one-sentence outcome statement before the Background section. While the "New Capability" section effectively articulates the goal and the Background explains context well, a top-level goal statement would improve scanability.

2. The iteration bundles seven major features (public form, validation/persistence, notification email, staff inbox, rejection flow, conversion flow, welcome email). While Matt explicitly decided to group these to cover the full lifecycle, implementers should consider organizing work into logical commits or stacked PRs (e.g., 1. Public Request Form & Notification, 2. Staff Inbox & Rejection, 3. Conversion & Welcome Links) to aid review and enable incremental validation.

3. Email validation rules could be more specific (regex pattern? RFC compliance check? presence of @ symbol?), though this is appropriately a detail for implementation to decide.

**Smallest viable iteration**:

The current scope is the smallest viable iteration given the business requirement. Breaking it smaller would create incomplete states:
- Public form alone → requests accumulate with no processing mechanism
- Public form + rejection only → no path to create clubs
- Public form + conversion only → no way to filter unsuitable requests

The plan explicitly notes Matt decided to cover the full staff-mediated lifecycle, and that decision is sound: all three pieces (request → reject/convert → welcome) are needed for the anti-abuse onboarding feature to function.

**Required plan edits**: None

**Validation plan**:

The plan's validation strategy is comprehensive and should be followed exactly:

1. **Pre-implementation**: Review `acceptance-tests/features/request_account.feature` with Matt to validate domain language and scenario coverage before removing the `@wip` tag.

2. **During implementation**:
   - Add LiveView tests for public request form (signed-out and signed-in variants) with validation coverage
   - Add controller/context tests for request creation, persistence, and email notification
   - Add LiveView tests for staff inbox, rejection flow, and conversion flow
   - Add tests for slug suggestion/editing/validation reuse
   - Add tests for person reuse logic (existing email → reuse person vs. new email → create person)
   - Add tests for welcome email generation with magic link
   - Run existing staff club creation tests to prove slug behavior preservation
   - Run existing authentication tests to prove magic-link sign-in preservation

3. **Acceptance validation**: Remove `@wip` tag from feature file once step definitions are implemented and all scenarios pass.

4. **Final validation**: Run `dev check` to ensure all tests, linters, formatters, and type checks pass.

5. **Manual demonstration** (execute all 9 steps from the plan):
   - Submit signed-out request → verify acknowledgement, no access
   - Sign in as staff → verify active request appears in inbox
   - Reject a request with internal note → verify no email sent, request removed from inbox, no access created
   - Convert a request → edit suggested slug → verify club created, requester is active member, request removed from inbox
   - Open welcome email → follow magic link → verify arrival at new club member home

**Stop condition**: All acceptance scenarios pass, `dev check` passes, and manual demo completes successfully.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}