Now I'll review this plan against the five readiness questions and prepare my assessment.

---

# Iteration 028 Plan Validation Report

## Decision: READY

## Confidence: High

## Blocking Gaps

None.

## Non-Blocking Improvements

1. **Test classification**: The Implementation Plan doesn't explicitly specify which tests should be unit/integration vs acceptance. Consider mentioning expected test levels (e.g., "Add domain tests for Membership.InviteEmail context", "Add web tests for live view behaviors").

2. **Error state coverage**: Acceptance criteria cover happy paths and duplicate handling well, but edge cases like malformed invitation tokens or concurrent invitation acceptance attempts could be mentioned (though these may be implicit in standard security/error handling).

3. **Migration planning**: No explicit mention of migrations. If invitation tables/events are needed, step 3 could note "Add migration for invitation_tokens table" or similar, though this may be implied by "Add a minimal club invitation model."

4. **Email delivery failure**: No mention of email delivery failure handling (e.g., bounce handling, send confirmation). This is likely acceptable as out-of-scope infrastructure, but could be noted if important.

## Smallest Viable Iteration

The plan already represents a well-scoped minimal slice:
- Single actor (Staff only)
- Single entry point (email-only invitation form)
- Single profile field (name only)
- Core safety rules (duplicates, one-use tokens)
- Deferred: expiry, pending management UI, role selection, additional profile fields, Admin self-service

It would be difficult to make this iteration smaller without losing coherence. The only potential sub-slice would be "Staff invitation without existing-person reuse," but that would create technical debt and incomplete behavior.

## Required Plan Edits

None.

## Validation Plan

The plan includes a comprehensive validation approach:

1. **Stakeholder review**: Matt reviews the Cucumber feature file for domain language before finalization
2. **Domain coverage**: Domain/application tests for invitation lifecycle, duplicate rules, profile completion states
3. **UI coverage**: Web tests for Staff UI, email links, callbacks, profile completion flows
4. **Acceptance proof**: `club_member_invitations.feature` scenarios pass with `@todo` tags removed/narrowed
5. **Regression protection**: Existing auth/person/membership tests confirm no breaking changes
6. **Quality gate**: `dev check` passes

**Success criteria**: A Staff user can invite an email address, the invitee receives an email, follows the link, enters their name (if new) or accepts immediately (if existing), and lands in the club as an active ordinary member. Duplicate invitations are handled safely. The Cucumber scenarios document and verify this behavior.

---

## Detailed Readiness Assessment

### 1. Goal Clarity ✓

**Is the goal clearly articulated?** Yes. The goal is stated in concrete user/business terms: Staff add members by invitation, invitees control email verification, and membership only activates after profile completion.

**Does it state outcome, not tasks?** Yes. The goal describes what Staff and invitees will be able to do, not just "build an invitation system."

**Is the beneficiary clear?** Yes. Staff (inviters), invitees (profile owners), and the system (verified identity) are all clear.

### 2. Scope Focus ✓

**Is the scope focused?** Yes. Single coherent outcome: email-based invitation with profile completion for club membership.

**Could it be smaller while still useful?** No. The plan already defers Admin self-service, pending management UI, role selection, expiry, bulk operations, and extended profile fields. Removing existing-person handling or duplicate safety would create incomplete or unsafe behavior.

**Are boundaries clear?** Yes. Eight explicit out-of-scope items and seven related problems tagged as "intentionally left unresolved" provide strong boundary clarity.

### 3. Acceptance Criteria, BDD, and Business Decisions ✓

**Are acceptance criteria concrete and testable?** Yes. Fourteen specific, observable criteria covering:
- Happy paths (unknown invitee, existing person)
- Edge cases (abandoned profile, link reuse)
- Permissions (Staff-only creation)
- Error states (duplicate active member, duplicate pending invitation)
- Data/state changes (person creation, membership creation, token consumption)

**BDD classification?** Yes. Clearly tagged as "Behaviour-facing" with rationale.

**Acceptance scenarios section?** Yes. Complete `## Acceptance Scenarios / Feature Files` section with:
- BDD decision: Required
- Rationale for Gherkin
- Named feature file: `club_member_invitations.feature`
- Seven scenarios across five rules
- Tag strategy for in-progress implementation
- Allowed changes to existing features

**Business decisions resolved?** Yes. `## Open Business Decisions` states "None known" and lists nine confirmed decisions covering actor scope, required fields, duplicate handling, expiry, and roles.

### 4. Implementation Plan and Technical Decisions ✓

**Are steps clear and ordered?** Yes. Sixteen sequential steps from inspection through delivery, with logical dependencies.

**Are artifacts named?** Yes. Steps reference:
- Files/routes: `/admin/clubs/:club_id/...`, person edit routes
- Modules: invitation model in Membership boundary, invitation email module
- APIs: invite, resend, accept, complete-profile commands
- Tests: domain/application, browser/LiveView/controller, Cucumber step definitions
- Feature file: `club_member_invitations.feature`

**Are changes clear?** Yes. Data model (invitation/token storage), UI (Staff invite form), workflow (callback→profile→activation), integration points (email, auth/sign-in token reuse), and boundaries (Membership aggregate) are all described.

**Technical decisions resolved?** Yes. `## Open Technical Decisions` acknowledges two implementation details (aggregate shape, exact URLs) remain open, but lists six resolved architectural decisions covering token separation, person creation timing, state management, and token consumption timing.

### 5. Expected Capability and Validation ✓

**What will be possible afterward?** Clearly stated in `## New Capability`: Memba invites people by email with email-control proof and self-supplied identity before membership activation.

**How to prove success?** Comprehensive validation plan (Matt review, tests at three levels, Cucumber scenarios passing, regression tests, `dev check`).

**Clear stop condition?** Yes. The iteration is complete when:
- Staff invite by email, not direct creation
- Invitees complete profile and become members
- Duplicate/reuse safety works
- Cucumber scenarios pass with `@todo` tags removed
- `dev check` passes

---

## Summary

This plan is ready for implementation. It demonstrates exceptional clarity across all readiness dimensions:

- **Goal**: User-outcome focused with clear beneficiaries
- **Scope**: Minimal useful slice with explicit boundaries
- **Acceptance**: Concrete, complete, testable criteria with required Gherkin scenarios
- **Decisions**: All business/product decisions resolved; technical implementation details appropriately deferred
- **Implementation**: Clear, ordered, specific steps with named artifacts
- **Validation**: Multi-level proof with stakeholder review and automated verification

The plan successfully balances detail (enough to guide implementation) with flexibility (open technical decisions on exact names/URLs). The BDD coverage is appropriate for a behaviour-facing change affecting identity, membership, and staff workflow.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}