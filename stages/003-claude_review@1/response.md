Now I'll review this plan against all five readiness criteria.

# Iteration 053 Plan Review

## Decision: **READY**

## Confidence: **High**

This plan is thorough, well-structured, and ready for implementation. It demonstrates careful domain modeling, clear boundaries, and comprehensive coverage of business rules, technical decisions, and validation.

## Blocking gaps

None.

## Non-blocking improvements

1. **Token expiry duration**: While the plan mentions "one-use/expiring" tokens, consider specifying a reasonable expiry window (e.g., 24 hours, 7 days) to help implementers make consistent decisions.

2. **Verification email "from" address**: Consider noting whether verification emails should use club-specific from addresses or a global Memba system address, for consistency with existing transactional email patterns.

3. **Rate limiting follow-up**: The plan explicitly scopes out rate limiting for this iteration. Consider logging or capturing a follow-up note about when anti-abuse controls become necessary (e.g., after user count threshold, observed abuse patterns).

4. **Migration backfill timing**: The plan states existing rows are backfilled as verified but doesn't specify whether this happens in the migration itself or as a post-migration data task. This is likely clear enough from implementation context, but could be made explicit.

## Smallest viable iteration

The plan is already well-scoped to a minimal useful slice. If forced to reduce scope further, you could defer:

- Resend verification (users could add the address again)
- Live PubSub refresh of open settings page (require manual refresh)

However, **I do not recommend reducing scope**. The current iteration is coherent, focused, and delivers a complete member-facing capability. Removing features would degrade UX without meaningful risk reduction.

## Required plan edits

None. The plan is ready for implementation as written.

## Validation plan

The plan includes a comprehensive validation strategy:

### Automated validation
- **Domain/context tests** covering all critical invariants: verification state, primary restrictions, duplicate handling, removal restrictions, sign-in-as-verification, and inbound rejection
- **LiveView/controller tests** covering navigation, rendering, all user flows, verification callbacks, and live updates
- **Acceptance tests** with 9 named scenarios in `person_email_addresses.feature` tagged `@iteration-053`
- **`dev check`** as the final gate

### Manual validation
10-step manual demo script covering the complete user journey from opening settings through adding, verifying, making primary, and removing addresses, plus confirming downstream message delivery.

### Success criteria
Clear stop condition: All acceptance criteria met, all tests passing, `dev check` green, manual demo successful.

---

## Detailed readiness assessment

### 1. Goal clarity ✅

**Goal is clear and outcome-focused.**

The plan states both user outcomes ("a signed-in member can...") and business/system outcomes ("members can manage their own verified email addresses"). The beneficiary is explicit: signed-in club members who are Membership Persons. The goal distinguishes between what users can do (9 bullet points) and what the system gains (verification enforcement, safe identity handling).

### 2. Scope focus ✅

**Scope is coherent and minimal.**

The iteration delivers one complete capability: member self-service email-address management with verification. Everything in scope serves this goal. The 9-point out-of-scope section demonstrates clear boundaries: no Account aggregate, no club settings, no get-started-only identities, no anti-abuse controls, no name changes.

The iteration could not be smaller while remaining useful. Removing verification would leave the security hole open. Removing self-service would fail to deliver member value. Removing primary management would leave members unable to control their outbound identity.

### 3. Acceptance criteria, BDD scenario decision, and business decisions ✅

**Acceptance criteria are concrete, complete, and testable.**

The plan includes 27 acceptance criteria covering:
- **Happy paths**: open settings, add address, verify, make primary, remove
- **Edge cases**: duplicate addresses, old verification links, removed addresses
- **Permissions/restrictions**: pending cannot be primary, primary cannot be removed, settings only for Person identities
- **Error states**: invalid verification links, duplicate address rejection
- **Data/state changes**: backfill verification, immediate primary update, session preservation, inbound rejection

**BDD scenario decision is explicit and justified.**

The plan classifies as "Behaviour-facing" (line 78), justifies why BDD is required (lines 90-92: "changes member-visible identity and email-address policy... business rules that benefit from stakeholder-readable examples"), and names 9 specific scenarios with personas in `person_email_addresses.feature` (lines 96-108).

**Business decisions are resolved.**

Line 165: "None known." The plan is explicit about verification policy (pending addresses cannot be primary/trusted), primary rules (exactly one, cannot remove), duplicate handling (reject with clear copy), and session preservation (removing session email doesn't break session).

### 4. Implementation plan and technical decisions ✅

**Implementation steps are clear, ordered, and specific.**

The 17-step plan follows a logical sequence:
1. Inspect current state
2. Add verification schema/migration
3. Model write-side commands/events
4. Preserve staff edit compatibility
5-9. Token infrastructure and email delivery
10-13. UI implementation
14-16. Testing at all levels
17. `dev check`

**Likely files and integration points are named:**
- `acceptance-tests/features/person_email_addresses.feature`
- `web/lib/memba_web/components/layouts.ex` (Layouts.club_site/1, avatar menu)
- `web/lib/memba_web/live/admin/people_live/edit.ex` (staff edit compatibility)
- Routes: `/my/settings`, verification callback route
- Design references: mobile-club-home, invite-a-member, profile-completion wireframes

**Data model changes are clear:**
- Add verification state to Person email-address projection
- Backfill existing rows as verified
- New addresses default to pending
- Token storage for verification links

**Technical decisions are appropriately open.**

Lines 188-194 list 4 open technical decisions that cannot be resolved without inspecting code:
- Token storage mechanism (reuse auth tokens vs. new store)
- Command/event shape (individual actions vs. set replacement)
- Verification state location (projection vs. aggregate value object)
- PubSub topic/message shape

These are legitimate implementation-time decisions. The plan constrains them with preferences ("Prefer aggregate enforcement for primary/removal rules") and safety requirements ("avoid exposing sensitive email details unnecessarily") without over-specifying.

### 5. Expected capability and validation ✅

**New capability is clear.**

Lines 196-197: "Members can manage their own verified email addresses from a global personal settings page. Memba can distinguish verified and pending Person email addresses and prevent pending addresses from being used for primary delivery or inbound identity until mailbox control is proven."

**Success proof is comprehensive.**

The validation plan (lines 199-233) includes:
- Automated tests at three layers (domain, LiveView/controller, acceptance)
- 10-step manual demo script
- `dev check` as final gate

**Stop condition is clear.**

Iteration succeeds when all acceptance criteria are met, all tests pass, `dev check` is green, and the manual demo completes successfully.

---

## Summary

This plan demonstrates excellent iteration planning:

- **Domain sophistication**: Carefully preserves existing aggregate semantics while adding new verification rules
- **Risk awareness**: Identifies 5 follow-up risks including staff edit compatibility, sign-in/verification interaction, and household email addresses
- **Problem linkage**: Explicitly resolves one documented problem and partially addresses another, with clear follow-up scope
- **Design grounding**: References existing design system components and acknowledges that DesignSync review may add dedicated previews
- **Testing rigor**: Three-layer test strategy with named acceptance scenarios
- **Boundary clarity**: 9-point out-of-scope section prevents scope creep

The plan is ready for implementation without modification.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}