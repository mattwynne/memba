# Independent Plan Review: Staff Area Redesign

## Decision: READY

## Confidence: High

This plan is exceptionally well-structured and thorough. It demonstrates clear goal articulation, appropriate scope boundaries, comprehensive acceptance criteria with explicit BDD decisions, detailed implementation guidance, and a robust validation approach.

---

## Blocking gaps

**None identified.**

The plan addresses all readiness criteria:
- Goal and beneficiary are clear (Memba staff operations clarity)
- Domain rule (person vs membership distinction) is explicitly stated and drives scope decisions
- Acceptance criteria are concrete, testable, and comprehensive
- BDD decision is explicit with feature file named: `acceptance-tests/features/memba_staff_operations.feature`
- Business decisions are resolved; open decisions from planning are documented as closed
- Implementation steps are numbered, sequenced, and name specific files/modules/patterns
- Technical decisions are appropriately deferred to implementation with clear guidance and fallback positions
- Expected capability is clear and testable
- Validation plan includes multiple approaches (tests, acceptance scenarios, dev check, manual demo)
- Risks and follow-ups are identified

Gemini's assessment of READY/High confidence/0 blocking gaps is correct.

---

## Non-blocking improvements

1. **Composer removal timing**: The plan could defer removing the staff message composer to a follow-up, making this iteration purely additive (no breaking changes). This would reduce risk and complexity while still delivering the core goal of "clearer operations area showing the domain model." The removal could be a quick subsequent iteration.

2. **Effort sizing**: The plan could include a rough effort estimate or t-shirt sizing. The iteration touches 6 existing pages, adds 2 new pages, updates layout/navigation, and requires feature file scenarios—this is medium-large in scope. An explicit acknowledgment of expected effort would help with implementation planning.

3. **Acceptance scenario update specificity**: Line 157 states "Existing acceptance scenarios... keep passing unless intentionally updated for route/nav copy." The plan could be more specific about which scenarios are likely to need updates (e.g., any that reference `/admin/clubs/:club_id` navigation or staff composer affordances).

4. **Mockup reference completeness**: The plan lists 5 mockup files but doesn't clarify if all 5 are relevant or if some are examples of what NOT to copy. The "Deliveries _ full diagnostics.html" mockup is mentioned but the plan keeps existing diagnostics—clarifying which mockups inform which pages would be helpful.

None of these improvements are required for implementation to proceed safely.

---

## Smallest viable iteration

The current scope is coherent and represents a reasonable minimum to deliver the stated goal: "Memba staff have a clearer operations area that shows the real domain model."

**If the iteration must be smaller**, the most viable reduction would be:

### Option A: Defer message composer removal
- Keep: Layout shell, navigation, restyle 6 pages, add 2 new read-only pages
- Defer: Removing staff message composer
- Benefit: Makes the iteration purely additive with no breaking changes
- Tradeoff: Staff area temporarily shows an action that doesn't align with the "read-only diagnostics" direction, requiring a quick follow-up

This reduction would still deliver:
- Clearer navigation structure
- New People page demonstrating person/membership distinction
- New Messages page for cross-club diagnostics
- Consistent restyling

The composer removal would become a small follow-up iteration focused solely on cleaning up that affordance and updating related acceptance helpers.

**Current scope assessment**: While medium-large, the current scope is defensible. The plan argues that layout, navigation, new views, and existing page updates need to be done together for coherence. Splitting would create inconsistent intermediate states where some pages follow the new design system and others don't, or where navigation points to pages that don't exist yet.

---

## Required plan edits

**None.**

The plan is ready for implementation as written. The non-blocking improvements above are suggestions for consideration, not requirements.

---

## Validation plan

The plan includes a comprehensive validation approach that should prove iteration success:

### Automated validation
1. **LiveView tests** for:
   - Staff navigation links (4 working pages only)
   - `/admin/people` read-only list with multi-club membership summary
   - `/admin/messages` read-only list and diagnostics links
   - Absence of staff-side send-message affordance
   - Preservation of existing club/person/membership workflows

2. **Acceptance scenarios** (after removing `@wip` tag):
   - Staff navigation offers only working pages
   - One person with memberships in multiple clubs appears correctly
   - Messages across clubs are visible with diagnostics access
   - Staff cannot send club messages from staff pages

3. **Existing regression protection**:
   - Existing acceptance scenarios for staff sign-in, club visibility, slug management, person email addresses, and deliverability
   - Acceptance configuration checks (can run while scenarios are `@wip`)

4. **`dev check`**: Must pass before delivery complete

### Manual validation
8-step demo checklist (lines 221-230):
1. Sign in as Memba staff
2. Verify nav shows only Clubs, People, Messages, Deliveries
3. Open Clubs, create/inspect club
4. Open club, verify distinction of facts/people/memberships
5. Confirm no staff-side message composer
6. Open People, verify person with multiple memberships shown correctly
7. Open Messages, open message diagnostics
8. Open Deliveries, verify existing diagnostics

### Review validation
- Compare implemented pages to mockups for operations feel
- Verify domain language remains honest (people ≠ memberships)

### Stop condition
Clear: When acceptance scenarios pass without `@wip` tag and `dev check` passes.

---

## Summary

This plan demonstrates excellent planning discipline:
- Clear domain modeling decisions documented
- Explicit BDD approach with feature file named
- Comprehensive acceptance criteria covering happy paths, edge cases, and removals
- Detailed implementation guidance with appropriate technical decision deferrals
- Robust validation combining automated tests, acceptance scenarios, and manual verification
- Risk awareness with follow-up planning

The iteration is medium-large in scope but makes a coherent argument for why everything needs to be done together. If timeline is a concern, the message composer removal could be deferred, but the current scope is defensible and ready for implementation.

**Recommendation**: Proceed with validation and mark plan as validated.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}