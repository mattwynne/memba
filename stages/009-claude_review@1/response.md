# Iteration Plan Review: Member Club Subdomains

## Decision: READY

## Confidence: High

## Blocking Gaps

None. The plan is complete and ready for implementation.

## Non-blocking Improvements

None significant. The plan is at an appropriate level of detail. Minor details like specific controller/LiveView module names and helper module naming can be determined during implementation as indicated by the "inspect" and "add" steps.

## Smallest Viable Iteration

The current scope is already the smallest viable iteration. While you could theoretically split this into:
1. Root subdomain routing + "My clubs" links only
2. Compose and message detail subdomain support

This would leave members with a partially-working subdomain they can navigate to but cannot use for their primary workflows (sending and reading messages). The current scope keeps all essential member subdomain navigation together, making it the smallest useful slice.

## Required Plan Edits

None. The plan is ready for implementation as written.

## Review by Criteria

### 1. Goal Clarity ✅
- **Goal**: Enable members to navigate their club sites using stable, human-readable subdomain URLs instead of UUID query strings
- **User/business outcome**: Clear - members get stable, human-readable club addresses
- **Beneficiary**: Active members navigating their clubs
- **Assessment**: Well articulated and outcome-focused

### 2. Scope Focus ✅
- **Coherence**: Focused on member subdomain navigation across all essential workflows
- **Size**: Appropriate - includes root routing, member pages (compose, detail), auth flows, and authorization boundaries
- **Boundaries**: Clear in-scope and out-of-scope lists; explicitly excludes custom domains, club-branded auth, slug history, complete UUID removal, and production DNS changes
- **Assessment**: Tightly scoped to one coherent outcome

### 3. Acceptance Criteria, BDD Decision, Business Decisions ✅

**BDD Decision**: Explicit and justified
- States "BDD decision: Required"
- Rationale: Changes member-visible URLs, club selection, authentication continuation, and authorization rules; stakeholder-readable scenarios are useful
- Names feature file: `acceptance-tests/features/member_club_subdomains.feature`
- Lists 6 scenarios covering key behaviors (subdomain navigation, host-selected club, auth return-to, authorization boundaries, public access)
- Properly tagged `@wip` for planning

**Acceptance Criteria**: Comprehensive (22 criteria)
- **Happy paths**: Member dashboard, compose, message detail, "My clubs" links
- **Edge cases**: Unknown subdomain (404), non-member at root (public page)
- **Permissions**: Active membership required, non-member forbidden from private URLs
- **Error states**: 404 for unknown subdomains, forbidden for non-members
- **Authentication flows**: Redirect to sign-in, preserve return URL, magic-link continuation
- **Data/state**: Messages address correct club members based on subdomain
- **Backward compatibility**: Fallback `?club_id=<uuid>` routes continue working and remain protected
- **Existing functionality**: Public routes, staff/admin routes unaffected
- **Documentation**: ADR 0019 recorded
- **Quality gate**: `dev check` passes

**Business Decisions**: None unresolved

**Assessment**: Complete, concrete, and testable

### 4. Implementation Plan and Technical Decisions ✅

**Implementation Steps**: 14 clear, ordered steps covering:
1. Inspection of current routing, controllers, LiveViews
2. Configuration for club-site base domain
3. URL/host helper for club URLs and slug extraction
4. "My clubs" link generation updates
5. Root subdomain routing (public/member/non-member cases)
6. Host-selected member routes (compose, detail)
7. Private route auth and membership enforcement
8. Auth redirect/return-to preservation
9. Legacy fallback route preservation
10. Template updates to stop generating `club_id` parameters
11. Acceptance test support for `lvh.me` URLs
12. Comprehensive test additions/updates
13. `@wip` tag management
14. `dev check` execution

**Specificity**: Names key integration points (controllers, LiveViews, routes, templates, auth handling, acceptance support)

**Technical Decisions**: None unresolved
- Documents decisions already made: ADR 0019 `lvh.me` strategy, fallback approach, auth flows, non-member handling

**Assessment**: Clear path forward with sufficient technical guidance

### 5. Expected Capability and Validation ✅

**New Capability**: "Members can use a stable, human-readable club subdomain as their normal club-site address. The app can select the active club from the host for member dashboard, compose, and message detail pages, while still preserving public club pages and authentication/authorization boundaries."

**Validation Plan**: Comprehensive
- `dev check` execution
- Targeted web tests for host detection, URL generation, routing, auth, authorization
- Acceptance-test configuration checks (`@wip` exclusion)
- Browser acceptance support tests (verify `lvh.me` usage)
- 10-step manual demo covering all key scenarios

**Stop Condition**: Clear - acceptance criteria met, validation steps pass

**Risks/Follow-ups**: Documents 5 known considerations (URL generation subtleties, auth safety, fallback retirement, browser test handling, production deployment prerequisites)

**Assessment**: Clear success criteria and comprehensive validation approach

## Validation Plan Summary

The iteration will be proven successful when:
1. All 22 acceptance criteria are met
2. `dev check` passes
3. Targeted web tests pass for subdomain routing, URL generation, auth flows, and authorization
4. Acceptance test support correctly uses `lvh.me` for local club URLs
5. Manual demo successfully exercises all key member subdomain workflows
6. `@wip` tag is managed appropriately

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}