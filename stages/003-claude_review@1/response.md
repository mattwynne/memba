Now I'll review this plan against the readiness criteria.

---

# Iteration Plan Review: 053 My Settings Email Addresses

## Decision: **READY**

## Confidence: **High**

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Tighten duplicate-detection scope**: The plan says "Prevent pending/unverified addresses from being used for sign-in identity" (line 61) and later "Signing in with a pending known address may itself verify that address" (line 61) which is resolved, but the phrase "pending known Person email address" (line 186) could be more explicit that this is distinct from duplicate detection, which already rejects addresses belonging to another Person.

2. **Clarify PubSub notification scope**: Line 54 and line 201 mention read-model/PubSub notifications but could be slightly more explicit about whether the notification is emitted only for verification or for all email-address changes (add, remove, make-primary). The validation plan (line 229) and criteria (line 167) imply verification-only, but implementation step 13 says "Person email-address changes" (line 192), which is broader.

3. **Verification email tone example**: The plan specifies `Verify this email address for your Memba account` (line 50) as suitable general copy but doesn't show the full email structure. This is fine — copy details are usually implementation-time decisions — but a follow-up iteration might want to refine copy if the tone lands awkwardly for staff-added addresses.

## Smallest Viable Iteration

The plan describes a **focused, coherent slice**: member self-service email-address management with verified/pending states. The scope cannot be usefully reduced without losing the core outcome. The plan already defers:
- club settings,
- profile editing beyond email addresses,
- rate limiting and anti-abuse,
- rich inbound-rejection recovery UX.

Attempting to defer verification itself or the settings UI would undermine the iteration's stated goal.

## Required Plan Edits

**None.** The plan is ready for implementation as-written.

## Validation Plan

The plan includes a complete validation strategy:

- **Domain/context tests** covering verification state, primary restrictions, duplicate handling, sign-in verification, and inbound rejection (lines 212–221).
- **LiveView/controller tests** for avatar menu, settings page rendering, tab URL addressability, add/resend/remove/make-primary flows, verification callback, and live refresh (lines 222–229).
- **Acceptance scenarios** listed with coverage for avatar menu, add/verify, pending restrictions, make primary, resend, removed address, sign-in verification, and inbound rejection (lines 96–107, 230–231).
- **Manual demo workflow** with 10 concrete steps proving end-to-end success (lines 232–242).
- **`dev check` gate** at completion (line 210).

The iteration has a clear stop condition: members can manage verified/pending email addresses from `/my/settings`, and pending addresses are rejected for primary/inbound use until verified.

---

## Detailed Readiness Assessment

### 1. Goal Clarity ✅

**Yes.** The goal is clearly articulated (lines 6–21):
- **Outcome**: Members can review profile basics and manage their own email addresses safely from a global settings page.
- **Beneficiary**: Signed-in club members (Membership Persons).
- **Observable capabilities after completion** are enumerated: open settings, see verification state, add/verify/remove/make-primary addresses, and keep sessions intact.

The goal states the user outcome, not just tasks.

### 2. Scope Focus ✅

**Yes.** The scope is tightly focused on member email-address self-service:
- **In scope** (lines 38–64): settings page, verification state, backfill, add/verify/resend/remove/make-primary flows, live updates, duplicate rejection.
- **Out of scope** (lines 66–74): club settings, Account aggregate, get-started identities, shared household addresses, rate limiting, rich rejection UX, profile editing beyond emails, design-system preview.
- **Non-goals and boundaries** are explicit and well-justified.

The iteration is as small as it can be while delivering the complete outcome: without verification, the feature is unsafe; without the settings UI, the feature is inaccessible; without make-primary/remove, the feature is incomplete.

### 3. Acceptance Criteria, BDD Decision, Business Decisions ✅

**Yes.**

- **Acceptance criteria** (lines 145–171): 27 concrete, testable criteria covering happy paths (add, verify, make-primary), edge cases (removed address cannot be re-verified, URL-addressable tabs, live updates), permissions (primary cannot be removed, pending cannot be primary), error states (duplicate address, invalid verification link), and state changes (backfill, verification, primary change).
- **Iteration type**: Classified as behaviour-facing (lines 76–86).
- **Acceptance Scenarios / Feature Files** (lines 88–110): Section present, BDD decision is "Required" with clear rationale (stakeholder-readable identity and email-address policy rules). Nine specific scenario summaries are listed. The feature file path is named (`person_email_addresses.feature`), tags are specified (`@iteration-053 @todo-domain @todo-ui`), and the temporary exclusion mechanism is explained (Cucumber profile).
- **Business decisions** (lines 173–175): None known / none open.

The criteria are clear, complete, and objectively testable.

### 4. Implementation Plan and Technical Decisions ✅

**Yes.**

- **Implementation steps** (lines 178–196): 17 ordered steps naming specific files/modules/routes where useful (`Layouts.club_site/1`, `replace_person_email_addresses/2`, `/my/settings`, `handle_params/3`, `design-system/templates/account-settings.html`, `app_shell_css_test.exs`).
- **Data model changes**: Verification state added to read model/projection, backfill as verified, token storage for verification (lines 180–182, 184–185).
- **API/UI changes**: `/my/settings` LiveView with URL-addressable tabs, avatar menu link with separator, verification callback route, email verification template (lines 185–186, 189–190).
- **Integration points**: PubSub notifications for live refresh, sign-in callback handling, inbound email sender resolution (lines 186–189, 192).
- **Open technical decisions** (lines 198–202): Four specific unresolved technical choices are listed (token storage reuse vs. dedicated store, command/event shape for compatibility, aggregate vs. projection verification enforcement, PubSub topic shape). These are implementation-time architecture decisions, not blocking unknowns.

The plan is sufficiently detailed to begin implementation.

### 5. Expected Capability and Validation ✅

**Yes.**

- **New capability** (lines 205–206): Members can manage verified email addresses; Memba distinguishes verified/pending and prevents pending use until verified.
- **Proof of success**: Validation plan (lines 209–242) includes domain tests, LiveView tests, acceptance scenarios, and a 10-step manual demo.
- **Stop condition**: Clear — the iteration ends when members can self-service email addresses and the system enforces verification-based safety rules.

---

## Summary

This iteration plan is **ready for implementation**. It demonstrates:

- **Clear goal and beneficiary** with observable post-iteration capabilities.
- **Focused scope** with explicit in/out boundaries and well-justified deferrals.
- **Complete, testable acceptance criteria** covering happy paths, edge cases, permissions, and error states.
- **Explicit BDD decision and feature file location** with rationale for Gherkin scenarios.
- **Ordered implementation plan** naming files, modules, routes, and integration points.
- **No blocking business or product decisions** remaining unresolved.
- **Comprehensive validation strategy** with domain tests, LiveView tests, acceptance scenarios, manual demo, and `dev check`.

The open technical decisions are appropriate implementation-time architecture choices that do not block starting work.

---

```json
{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}
```