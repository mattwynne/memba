Now I'll analyze this plan against the five readiness questions and prepare a comprehensive review.

---

# Iteration 030 Plan Review: Verified Public Onboarding Requests

## Decision: READY

## Confidence: High

## Blocking Gaps

None.

## Non-Blocking Improvements

1. **Implementation step 4** could be more specific about where `current_identity` is expected to be set (router plug, controller assign, LiveView mount) to guide implementers toward the existing auth pattern.

2. **Risk section** mentions low-friction UX preservation—consider if acceptance criteria should include a maximum step count or page-transition constraint to make "low-friction" objectively testable, though current AC are sufficient for functional correctness.

3. The plan does not explicitly state whether existing unverified onboarding requests (if any) should be handled, archived, or left in place. If the database could contain pre-verification requests when this ships, consider whether they should be migrated, marked obsolete, or left for Staff to clear manually.

## Smallest Viable Iteration

The plan already represents the smallest viable iteration for verified onboarding. Any smaller slice would leave either:
- Public requesters able to submit unverified requests (no improvement over current state), or
- Staff unable to convert verified requests (breaking the onboarding flow entirely).

The current scope tightly couples email verification with Staff notification/triage and excludes all unrelated concerns (CAPTCHA, rejection emails, alternate emails). No further reduction is recommended.

## Required Plan Edits

None. The plan is ready for implementation as written.

## Validation Plan

The plan includes a clear, complete validation plan:

1. **Pre-delivery review**: Review Cucumber scenario language before implementation starts.
2. **Unit/integration tests**: Add web tests for signed-out email step, magic-link return, verified request form, existing-person signed-in form.
3. **Negative tests**: Prove Staff do not see abandoned email-only verifications and that verified submission creates no membership-domain records.
4. **BDD scenarios**: Four new scenarios in `request_account.feature` with appropriate `@iteration-030 @todo-domain @todo-ui` tags, removing or narrowing todo tags as functionality passes.
5. **Regression guard**: `dev check` passes.

Success is proven when:
- A signed-out visitor must follow a magic link before Staff see the request
- Verification creates an identity session but no Person/club/membership
- Staff conversion still works for verified requests
- All Cucumber scenarios pass with todo tags appropriately removed

---

## Detailed Assessment

### 1. Goal Clarity ✓

**Is the goal clearly articulated?**  
Yes. The goal explicitly states the outcome: "Require a signed-out public requester to verify control of their email address with Memba's existing magic-link auth before they can submit a club onboarding request that Memba Staff can see or act on."

**Does it state the user/business outcome, not just tasks?**  
Yes. The beneficiary is Memba Staff (reduced triage of spoofed/mistyped emails) and the business (protected sender reputation). The goal focuses on verified email control, not on implementation details.

**Is the intended beneficiary or actor clear?**  
Yes. Public requesters must verify, Staff gain confidence in email validity, and the verification creates an identity/account session without creating membership-domain records until Staff conversion.

### 2. Scope Focus ✓

**Is the scope focused on one coherent outcome?**  
Yes. Every in-scope item serves the single outcome: verified email control before Staff-visible onboarding requests. The plan explicitly excludes CAPTCHA, rejection emails, alternate email verification, invitation flows, and Person creation during verification.

**Could the iteration be any smaller while still useful?**  
No. The verification step and Staff notification deferral must ship together, or Staff would see unverified requests (no improvement) or verified requests would never reach Staff (broken flow). The plan already defers CAPTCHA, rate limiting, rejection emails, and other concerns.

**Are non-goals and boundaries clear?**  
Yes. The "Out of scope" section lists 8 explicit exclusions, including Person creation at verification time, self-serve club creation, CAPTCHA, spam scoring, rate limiting, requester rejection emails, notification content changes beyond verified triggers, invitation flows, and alternate email verification.

### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✓

**Are acceptance criteria concrete, clear, complete, and objectively testable?**  
Yes. The 20 acceptance criteria cover:
- Happy path: email-only step → magic link → verified form → submission → Staff inbox/notification/conversion
- Edge cases: existing Person vs. no Person, abandoned email-only verification
- Permissions: Staff can reject/convert
- Error states: implicitly covered by preserving existing rejection/conversion/validation behaviors
- Data/state changes: explicit criteria state what is NOT created (Person, club, membership, access) and what IS created (onboarding request after verification)

**Does the plan classify the iteration type?**  
Yes. "Iteration Type: Behaviour-facing" with clear rationale: changed rules observable to public requesters and Staff.

**For behaviour-facing work, does the plan include Acceptance Scenarios / Feature Files?**  
Yes. The plan names the specific feature file (`acceptance-tests/features/request_account.feature`), identifies 4 new scenarios under 2 rule headings, specifies `@iteration-030 @todo-domain @todo-ui` tags, and explains when to remove or narrow todo tags during delivery.

**Are business/product/policy/copy/workflow/domain decisions still unresolved?**  
No. "Open Business Decisions: None known." The plan lists 5 confirmed decisions including email-first verification, magic-link reuse, identity-not-Person semantics, post-verification name collection, and verified-only Staff notifications.

### 4. Implementation Plan and Technical Decisions ✓

**Are implementation steps clear, ordered, and specific?**  
Yes. The 15 steps proceed logically: inspect → split flow → reuse magic-link → return-to handling → form rendering → submission verification → Staff visibility preservation → tests → Cucumber steps → dev check.

**Are likely files/modules/migrations/tests/interfaces/integration points named where useful?**  
Yes where deterministic:
- Feature file: `acceptance-tests/features/request_account.feature`
- Modules: "controller/templates or LiveView", "auth sign-in token creation", "return-to handling", "Staff request inbox", "onboarding request creation/notification code"
- Tests: "controller/LiveView tests", "domain/context tests", "Cucumber step definitions"

The plan appropriately defers exact function/module names to "Open Technical Decisions" since the codebase inspection (step 1) will reveal whether the current Get Started flow is a controller+template or LiveView.

**Are data model/API/UI/workflow/integration/background-job changes clear enough?**  
Yes:
- Data model: onboarding request creation deferred until after verification; no Person/club/membership created at submission
- UI: two-state flow (email-only signed-out, verified form signed-in)
- Workflow: magic-link return-to Get Started
- Integration: reuse existing magic-link sign-in flow
- Background jobs: Staff notification timing changes (sent only after verified submission)

**Are technical decisions still unresolved?**  
Yes, 3 open technical decisions listed:
1. Exact function/module names for email-only verification step
2. Whether auth sign-in UI/service can be reused directly or needs a thin wrapper
3. Whether to persist pre-verification UI state (plan prefers no)

These are appropriate to defer until code inspection (implementation step 1). None block starting work.

### 5. Expected Capability and Validation ✓

**What should we be able to do after this iteration that we cannot do now?**  
The "New Capability" section states: "Memba Staff only triage onboarding requests from people who have proved control of the requester email address. Public visitors can create a verified identity/account session before requesting a club, without creating a Membership Person or gaining club access until Staff approve the request."

**How will we prove success?**  
The "Validation Plan" section lists 6 concrete proof points: pre-delivery scenario language review, web tests for each flow variant, negative tests for abandoned verification and non-creation of membership records, Cucumber scenarios passing with todo tags removed, and `dev check` passing.

**Is there a clear stop condition?**  
Yes. The iteration is done when:
- Email-only verification precedes Staff-visible requests
- Magic-link return-to works
- Verification creates identity/account but not Person/club/membership
- Staff can still reject/convert verified requests
- All 20 acceptance criteria pass
- Cucumber scenarios pass with appropriate todo tag removal
- `dev check` passes

---

## Summary

This plan is **ready for implementation**. It exhibits strong goal clarity, tight scope focus, complete and testable acceptance criteria, a named BDD feature file with planned scenarios, no open business decisions, a clear implementation plan with appropriately deferred technical details, and a comprehensive validation plan. The iteration is already at minimum viable size and includes explicit boundaries excluding unrelated concerns.

The plan demonstrates mature iteration design: it builds on existing patterns (magic-link auth from iterations 028/029), explicitly references resolved and related problems, names the beneficiaries (Staff, requester, sender reputation), and makes the identity-vs-Person boundary concrete through multiple acceptance criteria and Cucumber scenario commentary.

No blocking gaps or required edits. Proceed to implementation.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}