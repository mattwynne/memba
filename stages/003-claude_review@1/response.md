Now I'll evaluate the plan against the readiness criteria and provide a comprehensive review.

---

# Iteration 028 Plan Review: Staff Member Invitations

## Decision: **READY**

## Confidence: **High**

This plan is ready for implementation. It demonstrates exceptional clarity, comprehensive acceptance criteria, and thoughtful scope boundaries. The plan explicitly names Cucumber feature files, scenarios, and rules; resolves all business decisions; and provides a detailed, ordered implementation plan with named modules and concerns.

---

## Blocking Gaps

**None.**

---

## Non-Blocking Improvements

1. **Invitation aggregate shape decision could advance**: The "Open Technical Decisions" section lists "exact invitation aggregate/stream shape and event names" as unresolved. While this is a reasonable implementation-time decision, the plan could note whether invitations should be a new aggregate root or events on an existing stream (e.g., Membership). This would reduce early implementation uncertainty. However, the plan provides enough guidance that implementers can make this decision cleanly during step 3.

2. **Token storage decision could advance**: The choice between "reuse the auth token table with a distinct purpose or use a separate invitation-token table/projection" is left open. A slight preference or rationale would help, but the plan correctly identifies the key property: "invitation tokens are one-use and membership-granting." This is acceptable for technical decisions that are best made during implementation with full context.

3. **"Incomplete person" representation could be clearer**: The plan asks whether to create "pending invitation only, or an incomplete person-like identity record" before acceptance. The acceptance criteria strongly imply "no active person," but the plan could state a preference. However, step 10 ("generalize the current staff onboarding/profile completion") and the acceptance criteria ("unknown invited emails create a pending invitation, not an active person") together provide enough direction.

---

## Smallest Viable Iteration

The plan **is already the smallest viable slice**. The scope:

- Solves one coherent problem: Staff-driven invitation with profile completion before membership activation
- Explicitly defers Membership Admin self-service, pending-invitation management, expiry, roles, bulk flows, and additional profile fields
- Delivers user value: Staff can now invite members without trusting Staff-typed identity data, and invitees control their own email and name

The only possible reduction would be removing the "existing complete person can accept without re-entering name" case, but that would make the system regress for multi-club scenarios and feels less viable than the current scope.

---

## Required Plan Edits

**None.**

The plan already satisfies all readiness requirements.

---

## Validation Plan

The plan's validation section (lines 172-179) is clear and complete. To prove the iteration succeeded:

1. **Pre-delivery domain review**: Matt reviews `acceptance-tests/features/club_member_invitations.feature` for domain language correctness.

2. **Unit/integration coverage**: Domain/application tests cover:
   - Pending invitation creation
   - Duplicate active member block
   - Duplicate pending invitation resend
   - Existing-person acceptance without profile completion
   - Unknown-person profile completion requirement
   - Abandoned profile completion (no membership created)
   - Accepted-link reuse (no duplicate membership)

3. **Web/LiveView coverage**: Controller/LiveView tests cover:
   - Staff invitation form/page
   - Invitation email delivery
   - Invitation callback route
   - Profile completion flow
   - Redirects to club after acceptance

4. **BDD scenarios pass**: All scenarios in `club_member_invitations.feature` pass with `@todo-domain`/`@todo-ui` removed or narrowed.

5. **Regression protection**: Run existing authentication, request-account, person-email-address, and club membership administration tests.

6. **Full check**: `dev check` passes.

---

## Detailed Readiness Assessment

### 1. Goal Clarity ✅

**Clearly articulated.** The goal (lines 6-8) states:
- **Who**: Staff (the actor)
- **What**: Add club members by invitation instead of direct creation
- **Outcome**: Invited person controls email, completes profile, and only then becomes an active ordinary member
- **Benefit**: Avoids trusting Staff-entered identity details; creates a pattern for future required details

The goal describes a user/business outcome, not just tasks.

### 2. Scope Focus ✅

**Tightly focused and coherent.** The plan:
- Solves one problem: Staff invitation with profile completion before membership activation
- Explicitly lists 14 in-scope items and 8 out-of-scope items (lines 29-54)
- Clearly defers Membership Admin UI, pending-invitation management, expiry, roles, bulk flows, and additional profile fields
- Could not be smaller while remaining useful

### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✅

**Concrete, complete, and testable.** The acceptance criteria (lines 92-111):
- Cover happy paths: new person invitation, existing person invitation, profile completion, membership creation
- Cover edge cases: abandoning profile completion (line 99), reopening accepted link (line 104)
- Cover error states: inviting active member (line 102), duplicate pending invitation (line 103)
- Cover permissions: Staff-only access, no Admin role by default (line 107)
- Cover data/state changes: pending invitation creation (line 96), active membership creation (line 100), sign-in (line 100)
- Are objectively testable

**BDD decision is clear.** Lines 62-85:
- Iteration type: "Behaviour-facing" (line 58)
- BDD decision: "Required" (line 64)
- Feature file named: `acceptance-tests/features/club_member_invitations.feature`
- Rules and scenarios are enumerated with clear names
- Rationale: "identity, membership activation, invitation lifecycle, and Staff workflow" changes require stakeholder-readable examples

**Business decisions are resolved.** Lines 113-128:
- "None known for this slice" (line 115)
- Lists 8 confirmed decisions
- No unresolved product, policy, copy, workflow, or domain questions

### 4. Implementation Plan and Technical Decisions ✅

**Clear, ordered, and specific.** The 16-step plan (lines 129-159):
- Orders steps logically: inspect → model → APIs → UI → tests → validation
- Names modules: Membership boundary, invitation model, email module
- Names routes: `/admin/clubs/:club_id/...` (line 149)
- Names files/features: `club_member_invitations.feature`
- Specifies migrations: invitation aggregate/stream (line 133)
- Identifies integration points: auth sign-in token reuse (line 132), staff onboarding generalization (line 152)

**Technical decisions are explicitly listed.** Lines 160-167 enumerate 5 open technical decisions:
- Invitation aggregate shape and event names
- Token storage strategy (reuse auth table or separate table)
- Unknown email representation before person exists
- Exact URLs and LiveView/controller split
- Profile-completion gate representation

Each decision lists the key properties or constraints that guide implementation (e.g., "invitation tokens are one-use and membership-granting").

### 5. Expected Capability and Validation ✅

**Clear new capability** (lines 168-170): "Memba can invite a person to a club by email without trusting Staff-entered identity details. The invitee proves control of the email, supplies their own required name, and only then becomes an active ordinary club member."

**Clear validation plan** (lines 172-179): Domain review, domain/application tests, web tests, Cucumber scenarios, regression tests, `dev check`.

**Clear stop condition**: When all acceptance criteria pass, Cucumber scenarios pass with `@todo` tags removed, and `dev check` passes.

---

## Summary

This plan is **exemplary**. It demonstrates:
- Clear goal and beneficiary
- Tightly scoped, smallest-viable iteration
- Comprehensive, testable acceptance criteria covering happy paths, edge cases, permissions, and error states
- Explicit BDD decision with named feature file, rules, and scenarios
- All business decisions resolved
- Clear, ordered, specific implementation plan with named modules, routes, and integration points
- Open technical decisions explicitly listed with guiding constraints
- Clear new capability and validation plan

The plan is ready for implementation without edits.

---

```json
{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}
```