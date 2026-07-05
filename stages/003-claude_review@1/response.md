Now I'll conduct a thorough review of this plan against the readiness criteria.

---

# Iteration 044 Plan Review: Shared Member App-Shell

## Decision: **NOT READY**

## Confidence: **High**

---

## Blocking Gaps

1. **Open technical decision on identity name/initials plumbing** — The plan explicitly leaves unresolved how to supply member display name + initials to the shared layout (line 143-146). This is core to the acceptance criteria ("avatar initials + member name") and affects the implementation approach. The decision must be made before implementation can proceed.

2. **Open technical decision on CSS source strategy** — While the plan recommends porting DS component classes (line 140-141), it presents this as an open decision. Since this affects file structure, CSS architecture, and maintainability, it should be decided in the plan rather than during implementation.

3. **Fallback behavior for member name is underspecified** — Line 132-133 mentions "Fall back gracefully to the current `current_identity.email`" but doesn't specify what the **avatar initials** should be when falling back to email, or whether the dropdown should show email instead of member name in the fallback case. This is visible UI behavior that must be defined.

4. **Acceptance criteria missing concrete dropdown menu structure** — The criteria state the identity dropdown contains "Sign out" (line 101-102) but don't specify whether the member name appears in the dropdown menu itself, or only in the closed/trigger state. The design reference should clarify this, but the plan should state the expected structure explicitly.

---

## Non-Blocking Improvements

1. **CSS class list could be more specific** — Line 127-128 lists "the identity-dropdown pieces" without naming the specific classes. Naming them (e.g., `avatar-initials`, `member-name`, `dropdown-menu`, etc.) would make the CSS porting scope clearer.

2. **Test coverage could mention signed-out public page explicitly** — While line 167 mentions manual verification of the public club page, the test specification (line 155-157) doesn't explicitly call out testing the signed-out state rendering.

3. **"Six surfaces" could be enumerated more clearly** — The plan mentions "all six `club_site` surfaces" (line 107) and lists five plus "and the public club page" (line 108). Clearer: enumerate all six by name in one place.

---

## Smallest Viable Iteration

**Current scope is already minimal** for establishing the shared app-shell foundation. The plan correctly excludes tabs, conversation content alignment, and cross-site navigation. 

**Recommendation:** Keep the current scope, but resolve the technical decisions in the plan before starting implementation. The iteration cannot be made smaller without losing its coherent value (establishing the consistent shell foundation).

---

## Required Plan Edits

1. **Resolve CSS porting decision** — Replace "Open Technical Decisions" section with a clear decision: port DS component classes into `app.css` (1:1 with design), or re-express with Tailwind. Recommendation: port, as stated in the plan's own preference.

2. **Decide and document identity plumbing approach** — Replace the open decision with a concrete approach:
   - How will member name + initials reach the shared layout?
   - What are the avatar initials when falling back to email? (First letter of email? Initials "ME"? Email-derived?)
   - Should the fallback show email in the dropdown trigger, or member name still appears as email?

3. **Specify dropdown menu structure in acceptance criteria** — Add a criterion that states what appears inside the opened dropdown menu (e.g., "The opened dropdown menu contains only a Sign out button" or "contains member name + email + Sign out").

4. **Specify fallback UI behavior** — Add acceptance criterion covering the fallback case: "When member display name is not available, the identity dropdown shows [X] and avatar initials are [Y-derived]."

5. **Enumerate specific CSS classes to port** — In implementation plan, replace "the identity-dropdown pieces" with the specific class names from the design system (read from `design-system/memba.css` or `styles.css`).

---

## Validation Plan

The plan's validation approach is sound once the gaps are resolved:

- **Automated tests:** LiveView/layout tests covering app-bar rendering, identity gating, Sign out action, content framing, and all six surfaces
- **Visual:** `gallery-walk` comparison to design wireframes  
- **Manual:** Exercise signed-in/signed-out states, dropdown interaction, and sign-out function

**After gaps resolved:** validation plan is adequate to prove success. The stop condition is clear: app-bar + app-card on all `club_site` surfaces, matching the refreshed design, with existing behavior preserved.

---

## Summary

This is a **well-structured, appropriately-scoped plan** that correctly identifies the shared app-shell as the foundation for later slices. The goal is clear, scope is focused, and the iteration type / BDD decision are well-reasoned.

**Blocking issue:** The plan explicitly defers two technical decisions (CSS porting, identity plumbing) and underspecifies fallback behavior. These decisions affect implementation approach, file structure, and visible UI behavior. They must be resolved in the plan before implementation can begin.

**Recommendation:** Author should resolve the three technical decisions, add the missing acceptance criteria for fallback behavior and dropdown structure, then resubmit for validation. Once those gaps are closed, the plan will be ready for implementation.

---

```json
{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":4,"claude_review_blocking_gaps":"Open decision on identity name/initials plumbing; Open decision on CSS source strategy; Fallback behavior for member name underspecified (avatar initials when using email); Acceptance criteria missing concrete dropdown menu structure","claude_review_required_edits":"Decide identity plumbing approach and document how member name + initials reach layout; Decide CSS porting vs Tailwind and document choice; Specify avatar initials derivation for email fallback; Add acceptance criterion for dropdown menu contents; Enumerate specific CSS classes to port"}}
```