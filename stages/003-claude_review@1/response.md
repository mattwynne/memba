I've read the complete plan. Let me review it against the readiness criteria.

---

# Iteration Plan Review: 022 Request-to-Club Onboarding

**Decision: READY**  
**Confidence: High**

## Blocking gaps

None.

## Non-blocking improvements

1. The implementation plan could name the specific auth email helper/module that generates magic links (e.g., `Auth.Token`, `Accounts.deliver_user_confirmation_instructions`), but the plan is clear enough to proceed and implementation can discover the exact helper.

2. The plan mentions "open technical decisions" about transaction boundaries around emails—this is appropriate to defer to implementation, but noting the current pattern in the codebase (e.g., if similar flows like password reset already handle this) would accelerate implementation slightly.

3. Acceptance scenarios mention "Robin receives a welcome sign-in link" but the criteria don't specify the email sender name or reply-to address for the welcome email. This is minor because `hello@memba.io` is already established for notifications and the same pattern likely applies.

## Smallest viable iteration

The plan already represents a minimal useful slice. The only smaller version would exclude rejection (keeping only conversion), but:
- Staff explicitly need both accept and reject actions to manage real vs. spam/unsuitable requests.
- Without rejection, unconvertible requests would clutter the inbox indefinitely.
- The rejection implementation is straightforward (status update + notes, skip emails).

Therefore, the current scope is already minimal and appropriately focused.

## Required plan edits

None. The plan is ready for implementation as written.

## Validation plan

The plan includes comprehensive validation across multiple dimensions:

**Acceptance coverage:**
- Six BDD scenarios explicitly cover the anti-abuse boundary, signed-in prepopulation, conversion, person reuse, rejection, and welcome links.
- Feature file is tagged `@wip` during planning to keep checks green.
- Matt reviews domain language before `@wip` removal.

**Test coverage:**
- LiveView/controller/context tests for request creation, validation, inbox, rejection, conversion, slug reuse, welcome email, authorization.
- Regression tests for existing staff club creation and authentication flows.
- Configuration test recognises the new `@wip` feature.

**Manual validation:**
- Nine-step demo covers signed-out request, staff triage, rejection without notification, conversion with slug editing, welcome email, and magic-link sign-in.

**Process validation:**
- `dev check` required before completion.
- Existing staff club/slug behaviour must remain working (explicit regression testing).

## Detailed assessment

### 1. Goal clarity ✅

**Clear:** The goal articulates a business/user outcome—letting club organisers request access through Memba while preventing public self-serve email abuse, with staff mediating the onboarding lifecycle.

**Beneficiary clear:** Interested club organisers can request access; Memba staff control who gains sending capability; public visitors cannot exploit open signups.

**Not just tasks:** The goal states the protection outcome ("Public visitors still cannot self-serve into email-sending capability") and the business model (staff-approved onboarding), not merely implementation tasks.

### 2. Scope focus ✅

**Coherent outcome:** The scope delivers a complete staff-mediated onboarding loop—request capture, triage, rejection, conversion, and welcome—without fragmenting into partial flows that would leave staff or requesters unable to complete the cycle.

**Could not be smaller:** Removing any major piece (request form, staff inbox, rejection, conversion, or welcome email) would break the onboarding loop or leave staff unable to manage spam/unsuitable requests.

**Boundaries clear:** The 15-item "out of scope" list explicitly excludes public self-serve, CAPTCHA, bulk actions, multi-person onboarding, billing, branding setup, and history UI that would expand the iteration without completing the core loop.

### 3. Acceptance criteria, BDD scenarios, and business decisions ✅

**Criteria concrete and testable:** All 39 acceptance criteria use objective, verifiable language:
- "Submitting a request does not create a club" (falsifiable).
- "Conversion suggests a default club slug from the requested club name" (observable).
- "Rejection does not send an email to the requester" (testable via mailbox inspection).
- "Invalid requester email addresses are not accepted" (validation testable).

**Coverage complete:** The criteria address:
- Happy paths: signed-out request, signed-in request, conversion with slug editing, existing-person reuse.
- Edge cases: invalid email, duplicate person, already-taken slug, signed-in vs. signed-out identity handling.
- Permissions: staff authorization for `/admin/requests`, non-staff blocked from conversion/rejection.
- Error states: required field validation, slug validation/availability.
- Data/state changes: request status transitions (active → converted/rejected), club creation, membership creation, email delivery.

**Iteration type explicit:** "Behaviour-facing" with clear rationale—the plan changes public onboarding, staff triage, and anti-abuse boundaries.

**BDD decision clear:** "Required" with strong justification—stakeholder-readable examples keep the anti-abuse boundary explicit ("a public request must not itself create email-sending access").

**Cucumber feature planned:** `acceptance-tests/features/request_account.feature` with six scenario summaries covering request without immediate access, signed-in prepopulation, conversion with slug editing, person reuse, rejection without notification, and welcome sign-in link. The `@wip` tag prevents breaking planning-time checks. Matt reviews before implementation removes `@wip`.

**Business decisions resolved:** The "Open Business Decisions: None known" section explicitly lists all planning-time decisions made:
- Notification address: `hello@memba.io`.
- Staff need both conversion and rejection.
- Rejection captures internal notes, no requester notification.
- Converted/rejected requests leave inbox, history out of scope.
- Staff approval sufficient for active membership.
- Existing-person email reuse policy.
- Signed-in users don't re-enter identity.
- Conversion sends direct magic-link welcome.

### 4. Implementation plan and technical decisions ✅

**Steps clear and ordered:** The 17-step plan sequences:
1. Inspection of current behaviour (club creation, slug helpers, auth emails).
2. Extraction/reuse of slug logic (avoid duplication).
3. Data model design (request schema with status, notes, audit fields).
4. Context functions for create/list/reject/convert.
5. Public request form (signed-out validation, signed-in prepopulation).
6. Notification email to `hello@memba.io`.
7. Staff routes, navigation, and authorization.
8. Active inbox with reject/convert actions.
9. Rejection implementation (notes, no email).
10. Conversion preparation (slug generation/editing).
11. Transactional conversion (club/person/membership/email).
12. Welcome email with magic link to club member home.
13. Test additions (validation, authorization, regression, acceptance).
14. Remove `@wip` when scenarios pass.
15. `dev check`.

**Specific enough:** The plan names:
- **Files/modules:** Staff club creation LiveView, slug helper modules, membership/person creation APIs, auth email/token APIs.
- **Data model fields:** Requester name/email, club name, note, status, rejection notes, converted club/person IDs, timestamps.
- **Routes/UI:** `/get-started`, `/admin/requests`, staff navigation.
- **Tests:** Form validation, authorization, slug validation, email delivery, existing-person reuse, regression for club creation/auth.
- **Integration points:** Existing staff authentication, current person identity assigns, magic-link auth flow.

**Changes clear:** Data model (request persistence), API (context functions for create/list/reject/convert), UI (public form, staff inbox), workflow (request → triage → reject/convert), email (notification, welcome with magic link).

**Technical decisions appropriate:** The "Open Technical Decisions" section defers five implementation-time choices to implementation:
- Request context placement (existing vs. new).
- Slug reuse mechanism (extracted helpers vs. shared component vs. routing).
- Post-auth return URL for club subdomains.
- Email module configuration (reuse auth email vs. new onboarding module).
- Transaction boundaries around external email delivery.

These are genuine implementation details that cannot be resolved without reading the existing codebase. The plan provides enough context ("reuse staff club creation slug behaviour", "magic sign-in token with post-auth destination", "keep conversion transactional where practical") for implementation to proceed.

### 5. Expected capability and validation ✅

**Capability clear:** "Memba has a staff-approved onboarding path: people can ask to try Memba, staff can reject unsuitable requests, and staff can convert genuine requests into clubs with active first members and direct sign-in links, without exposing public self-serve email-sending access."

**Before/after contrast:** Before: mailto-only contact. After: Memba-hosted request form, staff triage inbox, conversion creates real club/member/access, welcome magic link, anti-abuse boundary enforced.

**Proof of success:**
- BDD scenarios pass after `@wip` removal.
- `dev check` passes.
- Nine-step manual demo confirms request → inbox → rejection (no email) → conversion → club exists → requester is active member → request removed from inbox → welcome email → magic link works.
- Regression tests confirm existing staff club creation and authentication still work.

**Stop condition clear:** `dev check` passes, acceptance scenarios pass without `@wip`, manual demo succeeds.

---

## Summary

This plan is **READY** with **high confidence**. It meets all readiness criteria:

- **Goal:** Clear beneficiary (club organisers + staff + anti-abuse protection), business outcome stated.
- **Scope:** Minimal complete onboarding loop, explicit boundaries, cannot be smaller without breaking the cycle.
- **Acceptance:** 39 concrete testable criteria covering happy/edge/error/permission/state, BDD scenarios planned with rationale, business decisions resolved.
- **Implementation:** 17 ordered steps naming files/modules/tests/integration points, data model specified, technical decisions appropriately deferred.
- **Capability:** Clear before/after, proof via automated + manual validation, explicit stop condition.

The plan balances detail with flexibility—specific enough to guide implementation, open enough to let implementation discover optimal reuse patterns in the existing codebase.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}