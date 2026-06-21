Now I'll review this plan against the readiness questions:

---

# Iteration 042 Review: Club Email Subdomains

## Decision: READY

## Confidence: High

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Acceptance criteria could explicitly cover case-insensitive club slug matching** (e.g., `everyone@KMC.clubs.memba.io` vs `everyone@kmc.clubs.memba.io`). Open technical decision mentions case-insensitivity for address normalization but AC doesn't explicitly confirm club slug resolution is case-insensitive.

2. **The integration timing with iteration 041 could have a more explicit checkpoint** in the implementation plan. Step 8 says "After integrating with 041's result" but doesn't specify when/how to confirm 041 is complete enough to proceed with that step.

3. **Rejection copy updates** are mentioned in scope but not explicitly covered in validation plan. Minor gap since AC mentions rejection behaviour is preserved.

## Smallest Viable Iteration

The plan is already well-scoped to the smallest viable slice:
- Single route (`everyone`) only
- Hard cutover, no backward compatibility
- No channels, aliases, or custom domains
- Preserves existing 041 reply routing

This is appropriate for the goal. Could not be meaningfully smaller while delivering the stated outcome (club email subdomains).

## Required Plan Edits

None.

The plan is ready for implementation as written.

## Validation Plan

The plan's validation section (lines 175-188) is comprehensive and concrete:

**Success criteria:**
- Member sees `everyone@kmc.clubs.memba.io` on dashboard and compose surfaces
- Inbound mail to new address creates club messages
- Unsupported local parts and unknown club subdomains are rejected
- Old flat address is rejected
- Reply emails use new destination while preserving header-based routing
- Production smoke test passes after DNS/Postmark prerequisite

**Evidence to collect:**
1. Unit tests for address generation show `kmc` → `everyone@kmc.clubs.memba.io`
2. Unit tests for destination resolution show parsing and validation
3. Acceptance tests for primary/alternate sender, rejection paths, and reply routing pass
4. Member dashboard/compose tests assert new address display
5. Production smoke test passes against `everyone@test.clubs.memba.io` after Matt's DNS setup
6. `dev check` passes

**Stop condition:** All acceptance criteria met, production smoke test passes, `dev check` green.

---

## Detailed Assessment

### 1. Goal Clarity ✅

**Clear and outcome-focused:**
- Goal states user outcome: "members email a club-wide message to `everyone@<club-slug>.clubs.memba.io`"
- Beneficiary is clear: club members sending email
- Business outcome is clear: adopting Topicbox-style subdomain convention for better namespace management
- Concrete example provided (KMC: `everyone@kmc.clubs.memba.io`)

### 2. Scope Focus ✅

**Tightly scoped:**
- Single coherent outcome: change club email address convention from flat to subdomain
- Cannot be smaller while remaining useful: must handle address generation, parsing, rejection, UI updates, and docs together for the shape change to be complete
- Non-goals are explicit and reasonable (channels, aliases, custom domains, old address compatibility, staff UI for rejections)
- Hard cutover is appropriate given pre-launch state

### 3. Acceptance Criteria, BDD, and Business Decisions ✅

**Acceptance criteria (lines 111-128) are:**
- Concrete: specific addresses, specific behaviours
- Clear: no ambiguity about what happens
- Complete: covers happy path (primary/alternate sender), edge cases (unsupported local parts, unknown club subdomains, old address), rejection behaviour, reply routing, docs, smoke tests
- Testable: each criterion maps to observable behaviour or executable tests

**BDD decision (lines 78-92):**
- Iteration classified as behaviour-facing (line 74) ✅
- Includes `## Acceptance Scenarios / Feature Files` section ✅
- Names specific feature files: `member_message_deliverability.feature`, `club_message_replies.feature`
- Provides clear rationale: "address shape is the product behaviour" ✅
- Examples added during planning with `@todo-domain` / `@todo-ui` tags to preserve green mainline

**Business decisions (lines 130-140):**
- All resolved: namespace choice, hard cutover, `everyone`-only, channel deferral, Matt handles DNS
- No open decisions blocking implementation

### 4. Implementation Plan and Technical Decisions ✅

**Implementation plan (lines 143-157) is:**
- Clear and ordered: 14 sequential steps
- Specific about files/modules: address helper, destination resolver, parsers, dashboard/compose display, reply generation, smoke config, Postmark docs
- Names integration points: iteration 041 reply routing, Postmark/Resend parsers, acceptance step support
- Covers data/API/UI changes: address generation, parsing logic, UI copy, reply destination, rejection paths

**Technical decisions (lines 159-168):**
- Open decisions are implementation details, not product blockers
- Constraints are clear: environment-configurable namespace, case-insensitive normalization, adapt to 041's design, preserve diagnostics
- Appropriately delegates to implementer while preserving quality/compatibility requirements

### 5. Expected Capability and Validation ✅

**New capability (lines 170-172):**
- Clear: "club owns a subdomain under `clubs.memba.io`"
- Explains why this matters: "better foundation for future addresses... avoiding root `memba.io` subdomain reservation problems"

**Validation plan (lines 175-188):**
- Comprehensive test coverage: unit, acceptance, integration, smoke
- Clear success proof: updated tests pass, production smoke test passes after DNS setup
- Stop condition implicit but clear: all AC met, `dev check` green

**Risks documented (lines 191-196):**
- External prerequisite dependency on Matt's DNS/Postmark setup
- 041 integration timing risk
- Hard cutover implications
- Future channel scope boundary

---

## Summary

This plan is **exceptionally well-prepared**. It demonstrates:
- Clear understanding of the product outcome and business context
- Appropriate scope boundaries for a pre-launch hard cutover
- Concrete, testable acceptance criteria covering success and failure paths
- Thoughtful BDD decision with named feature files and rationale
- Detailed implementation steps naming specific modules and integration points
- Clear validation approach with unit, acceptance, and smoke tests
- Honest risk documentation with mitigation context

The plan is ready for implementation without blocking edits.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}