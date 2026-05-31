# Iteration Plan Review: Shared Magic Link Authentication

## Decision: READY

## Confidence: Medium

## Blocking gaps

None.

## Non-blocking improvements

1. **Move security requirement to acceptance criteria**: The validation plan tests that "/auth does not reveal whether an email is known," but this security requirement should be an explicit acceptance criterion, not just a test assertion.

2. **Add acceptance criterion for unauthenticated access**: Currently listed as an open decision, but the user-facing behavior for unauthenticated access to protected routes should be in acceptance criteria. The plan states a preference ("Prefer preserving the originally requested path"), which provides implementation guidance, but this should be formalized.

3. **Add acceptance criteria for token error states**: The validation plan tests expired tokens, single-use tokens, and invalid tokens, but acceptance criteria don't specify what users see when encountering these states.

4. **Specify token expiration duration**: Mentioned in implementation ("appropriate expiration") but not decided. A concrete duration (e.g., 15 minutes, 1 hour) would remove ambiguity.

5. **Clarify sign-out behavior**: Not mentioned in acceptance criteria. Even if it's just "clear session," this should be explicit.

6. **Decide staff identity persistence before implementation**: Currently an open decision, but choosing upfront (even if the choice is "decide during implementation based on code clarity") would be cleaner.

## Smallest viable iteration

The current iteration is already quite focused. A smaller slice would be:

**Magic link authentication only**, deferring:
- Multiple club support (show only first club or require query param)
- Staff/admin distinction (all authenticated users see same view)

However, this would deliver limited value. The current scope is reasonable because:
- Multiple clubs is core to the member experience
- Staff/admin distinction is minimal code but important for operational access
- The whole iteration is bounded by a single authentication pattern

I recommend keeping the current scope.

## Required plan edits

None. The plan is implementable as written. The validation plan is comprehensive and covers the user-facing behaviors not fully enumerated in acceptance criteria. Open technical decisions are appropriately deferred to implementation.

## Validation plan

The plan includes excellent validation:

**Automated tests** cover:
- Token security (hashing, expiration, single-use)
- Session creation
- Privacy (no email enumeration)
- Email construction
- Authorization (staff vs member, admin access, club access)
- Webhook preservation

**Manual demo** covers:
- End-to-end magic link flow
- Multiple club display
- Staff admin access
- Authorization enforcement

**Stop condition**: Clear - when `bin/dev check` passes and all automated tests prove the documented behaviors.

## Recommendations

1. The iteration is well-structured and ready for implementation.

2. Consider promoting the security, error-state, and redirect behaviors from validation plan to acceptance criteria for future iterations—this makes the contract clearer upfront.

3. The implementer should use the stated preferences in "Open Technical Decisions" as guidance rather than blockers. For example, "prefer preserving the originally requested path" is sufficient direction.

4. The validation plan is strong enough to catch any ambiguities during implementation, making this safe to proceed despite minor acceptance criteria gaps.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"Medium","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}