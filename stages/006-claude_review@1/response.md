# Iteration Review Report

**Iteration:** 052-desktop-member-app-design-alignment  
**Commit Range:** `eebacadd114ae0325805a17da9744b0722f8e91e..HEAD`  
**Review Date:** 2026-07-11

---

## Decision: **ACCEPT**

## Confidence: **High**

## ADR Conformance: **PASS**

---

## ADR Violations

None identified.

**Analysis:**
- No ADRs explicitly cited in the plan
- Changes are UI/presentation layer focused (LiveView components, templates, styling)
- Implementation follows standard Phoenix LiveView patterns documented in project references
- No domain modeling, CQRS, event sourcing, or aggregate responsibility changes
- Component boundaries and LiveView structure align with project conventions in `docs/reference/liveview.md` and `docs/reference/phoenix-html.md`

---

## Blocking Issues

None.

---

## Bounded-Safe Fixes

1. **Test setup extraction**: Consider extracting repeated test setup patterns into shared helpers. Examples:
   - `create_active_member` + `create_message` + `signed_in_club_host` appears in multiple tests in `member_message_detail_live_test.exs`
   - Could introduce `setup_message_detail_test(conn, opts)` helper
   - **Why low-risk:** Pure test code refactoring; no behavior change; improves maintainability

2. **CSS selector test assertions**: Some tests use long CSS selector strings that could be extracted into named helper predicates. Example:
   ```elixir
   # Current:
   "#member-message-heading-row.detail-head > .detail-head__main h1#member-message-subject.page-title"
   
   # Could be:
   message_subject_in_detail_head(view, expected_text)
   ```
   **Why low-risk:** Test code only; improves readability; preserves exact assertions

---

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Cross-cutting UI behavior test coverage**  
   **Files:** `member_message_detail_live_test.exs`, `club_home_live_test.exs`, `member_conversations_live_test.exs`  
   **Smell:** Multiple test files test similar UI patterns (back links, footer visibility, compact layout) across different LiveView contexts  
   **Why judgement-worthy:** While appropriate for integration testing, this might indicate opportunity for:
   - Shared component tests if these UI elements become reusable components
   - Documented UI patterns/guidelines to ensure consistency
   - Trade-off: Current approach tests actual integration points; component tests would require more test infrastructure

2. **Follow control placement architecture**  
   **Files:** `member_message_detail_live.ex`, `member_message_detail_component.ex`  
   **Smell:** Follow toggle moved from one UI location to another (below composer → beside subject in detail head)  
   **Why judgement-worthy:** Implementation is clean, but broader question: "Where should contextual actions like follow/unfollow live in member app layouts?" might merit documentation for:
   - Future UI consistency across member app features
   - Design system pattern catalog
   - Not a code smell per se, but architectural decision worth capturing

3. **Design system coupling and maintenance**  
   **Files:** All changed HEEx templates, CSS classes, component render functions  
   **Smell:** Direct 1:1 implementation of design system wireframes (expected and correct), but no documented mapping between wireframe IDs and implementation files  
   **Why judgement-worthy:** Future design system changes will require code changes. Consider:
   - Adding comments linking code sections to design system wireframe IDs
   - Maintaining a design-to-code mapping document
   - Trade-off: Adds documentation overhead vs. easier maintenance when designs evolve

---

## Suggested Fixes

None required for acceptance.

**Optional bounded-safe improvements** (can be deferred to maintenance):
- Extract repeated test setup into `test/support/member_message_test_helpers.ex`
- Add inline comments linking major UI sections to design system wireframe references
- Consider shared test predicates for common UI assertions (footer presence, back link structure)

---

## Validation Notes

**Automated Test Coverage:**
- ✅ Dev check passed: 109 scenarios (109 passed), 783 steps (783 passed)
- ✅ New tests for back link behavior (text, href, no club_id param)
- ✅ New tests for follow control placement in detail head
- ✅ Tests verify removal of "Prefer email?" card
- ✅ Tests verify compact footer-only presence
- ✅ Tests verify composer "Replying as" inline placement
- ✅ Tests verify page-title scale (not hero scale) for message subject
- ✅ Tests verify removal of helper sentence and green alert from posted state

**Implementation Evidence:**
- ✅ `member_message_detail_live.ex`: Clean component structure
- ✅ Tests use semantic selectors (`#back-to-club-home-link`, `.detail-head__main`)
- ✅ CSS changes use Tailwind utilities consistently
- ✅ No behavioral regressions (all existing tests pass)
- ✅ Mobile explicitly out of scope (correctly)

**Plan Conformance:**
- ✅ All 8 plan requirements addressed (back link, follow control, subject scale, composer inline, helper/alert removal, email card removal, compact footer, coordination with iteration 051)
- ✅ No out-of-scope work detected
- ✅ Acceptance criteria met via automated tests

**Code Quality:**
- ✅ Phoenix LiveView conventions followed
- ✅ HEEx templates well-structured
- ✅ Test organization clear and focused
- ✅ Proper use of PhoenixTest helpers (`has_element?`, `refute has_element?`)
- ✅ Clean component boundaries

**Manual Smoke Validation Required:**
Per plan, human should verify:
- Desktop gallery screenshots match wireframes
- App card width, top-bar alignment, compact footer
- Back link wording and placement
- Message card styling (borders, shadows, spacing)
- Composer panel background/border/height
- Absence of removed elements (helper sentence, green alert, email card, public footer)

---

## Summary

This is a **clean, well-executed UI alignment iteration** with excellent test coverage and no architectural concerns. The implementation:

1. Addresses all plan requirements precisely
2. Maintains backward compatibility (no behavioral changes)
3. Follows project conventions for Phoenix/LiveView/HEEx/Tailwind
4. Has comprehensive automated test coverage
5. Includes appropriate integration tests for new UI layouts

The code is maintainable, the changes are minimal and focused, and the test suite provides strong confidence in correctness. Minor opportunities for test code refactoring exist but do not block merge.

**Recommendation:** Merge after human visual validation of desktop gallery screenshots against design system wireframes as outlined in plan acceptance criteria.