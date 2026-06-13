Now I'll analyze the plan against the five readiness questions.

---

# Iteration Plan Review: Auth Email Delivery Progress

## Decision: **READY**

## Confidence: **High**

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Fallback timing clarity**: Step 9 mentions "fallback timing" tests but the 60-second threshold for showing fallback guidance is stated in acceptance criteria and UX decisions but not explicitly named in the implementation plan steps. This is clear enough from context, but could be more explicit in implementation step 6.

2. **Backward-compatible handling detail**: Step 5 mentions "backward-compatible handling for any old route if needed" but doesn't clarify if the old route exists. This is appropriately cautious but could note whether there is an existing `/auth/check-email` route shape to preserve.

3. **LiveView mount argument**: The implementation mentions adding a request ID to the check-email route but doesn't explicitly state whether this will be a query parameter, path segment, or session data. This is a reasonable implementation detail to leave for coding time.

## Smallest Viable Iteration

The plan is already at its smallest viable slice. The author has clearly thought through the minimum:

- Cannot remove unknown-email handling without breaking the anti-enumeration requirement
- Cannot remove live updates without losing the core user benefit
- Cannot remove webhook handling without getting the delivery state
- Cannot remove the opaque request record without a correlation point

Any smaller and the iteration would fail to deliver the stated outcome: "showing neutral, live delivery progress ... including when the recipient mailbox provider has accepted the email, without revealing whether an email address is known to Memba."

## Required Plan Edits

None. The plan is ready for implementation as written.

## Validation Plan Assessment

The validation plan is comprehensive and concrete:

- **Unit/context testing**: Covers persistence, status transitions, metadata, webhook handling, and LiveView rendering
- **Integration testing**: Includes Cucumber scenarios with appropriate tags and waiting discipline
- **Quality gates**: Includes `dev check` requirement
- **Manual verification**: Provides a concrete 5-step smoke test covering both known and unknown addresses
- **Stop condition**: Clear success criteria tied to observable behaviour and existing sign-in functionality preservation

## Detailed Assessment

### 1. Goal Clarity ✅

**Is the goal clearly articulated?** Yes. "Make the sign-in-link waiting experience less frustrating by showing neutral, live delivery progress..."

**Does it state outcome, not just tasks?** Yes. It focuses on the user outcome (less frustrating waiting experience) and the mechanism (neutral, live progress).

**Is the beneficiary clear?** Yes. People waiting for sign-in links.

### 2. Scope Focus ✅

**Focused on one coherent outcome?** Yes. The iteration delivers live auth-email progress tracking with anti-enumeration protection.

**Could it be smaller while still useful?** No. All in-scope items support the core outcome and preserve required security properties.

**Are boundaries clear?** Excellent. The plan explicitly excludes inbox-placement guarantees, Postmark provider changes, staff dashboards, and the separate cross-browser update problem.

### 3. Acceptance Criteria, BDD, and Business Decisions ✅

**Acceptance criteria concrete and testable?** Yes. 11 acceptance criteria covering:
- Known and unknown email request creation and routing (anti-enumeration)
- Metadata correlation
- State transitions and timing (60-second fallback, 30-minute expiry, 7-day retention)
- Exact copy requirements
- Webhook edge cases
- Preservation of existing sign-in behavior

**Coverage complete?** Yes. Happy path (known email, provider acceptance), edge cases (unknown email, no webhook, delayed/bounced/spam), permissions (implicit: public auth flow), error states (malformed webhooks, missing correlation), and data/state changes (persistence, expiry, cleanup).

**BDD scenario decision made?** Yes. Explicitly classified as "Behaviour-facing" with BDD decision "Required."

**Feature files identified?** Yes. `acceptance-tests/features/authentication.feature` with two named scenarios under `@iteration-032 @todo-domain @todo-ui` tags.

**Gherkin rationale when not used?** N/A. BDD scenarios are planned.

**Business/product decisions resolved?** Yes. Section "Product / UX Decisions" provides binding copy states, unknown-email behavior rules, and expiry/retention policy. "Webhook Edge-Case Policy" provides binding rules for all webhook event types.

### 4. Implementation Plan and Technical Decisions ✅

**Steps clear and ordered?** Yes. 10 numbered steps from inspection through acceptance test completion.

**Likely files/modules/interfaces named?** Yes. References:
- Existing auth LiveView
- Auth email module
- Postmark webhook controller
- Read-model change publisher
- Delivery-status LiveViews
- `/auth/check-email` route
- `authentication.feature` file
- ADR 0021 (PubSub/read-model pattern)
- ADR 0022 (projection barriers)

**Technical changes clear?** Yes. Ecto table (not event-sourced), PubSub/committed-change pattern, LiveView subscription/refresh, Postmark metadata, webhook routing, expiry/cleanup.

**Technical decisions resolved?** Yes. Section "Technical Decisions" provides binding choices on:
- Ecto source-of-truth (not event-sourced)
- PubSub pattern (follows ADR 0021)
- No sensitive data in PubSub payloads
- 30-minute progress expiry
- 7-day retention
- Route fallback behavior

### 5. Expected Capability and Validation ✅

**What can we do after?** Clearly stated: "A person waiting for a sign-in link can see neutral live progress and, when Postmark reports success, know that their mailbox provider accepted the email. Memba gains an auditable correlation point for auth-email delivery latency without compromising account-enumeration protection."

**How to prove success?** Comprehensive validation plan with unit tests, integration tests, Cucumber scenarios, `dev check`, and 5-step manual smoke test.

**Clear stop condition?** Yes. All acceptance criteria met, tests pass, `dev check` passes, smoke test confirms both known and unknown address behavior.

---

## Summary

This iteration plan is exceptionally well-prepared for implementation. It demonstrates:

- Clear user outcome focus with security requirements preserved
- Comprehensive acceptance criteria covering happy paths and all relevant edge cases
- Explicit BDD scenario commitment with named feature file
- Resolved product copy and technical architecture decisions
- Detailed implementation steps referencing existing patterns (ADR 0021, ADR 0022)
- Strong validation plan including automated tests, BDD scenarios, quality gates, and manual verification

The plan is ready for implementation without edits.

---

```json
{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}
```