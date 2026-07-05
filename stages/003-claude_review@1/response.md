Now I'll review the plan against the readiness criteria and provide my assessment.

---

# Iteration Plan 044 Review — Shared App-Shell

## Decision: **READY**

## Confidence: **High**

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Member name fallback test clarity:** The implementation plan specifies "When `member_name` is absent but `current_identity` is present, fall back to the email local-part for both the label and the initials." Consider explicitly mentioning this fallback scenario in the acceptance criteria or validation plan to ensure it's tested.

2. **"Powered by Memba" footer location:** The acceptance criteria mention the footer is preserved, but it's not crystal clear whether it lives inside or outside the `app-card` frame. The implementation plan should specify where exactly the footer renders in relation to `app-card` (though the design wireframes likely show this).

3. **Gallery-walk validation scope:** The validation plan mentions `./bin/dev gallery-walk` but doesn't specify which gallery screenshots should be reviewed. If this is a known command that captures all relevant surfaces, that's fine; otherwise, listing which surfaces should be visually checked would be helpful.

## Smallest Viable Iteration

**This IS the smallest viable iteration.** The plan correctly identifies the atomic unit: replacing the shared layout's header and content frame. You cannot ship part of the shell (e.g., app-bar without app-card) and have a coherent intermediate state. Splitting by surface (e.g., "club home only, then conversation") would duplicate the work instead of leveraging the shared layout. The out-of-scope items (tabs, conversation content, club switcher) are correctly deferred.

## Required Plan Edits

None. The plan is ready for implementation as written.

## Validation Plan

The specified validation approach is comprehensive and appropriate:

1. **Automated verification:**
   - LiveView/layout tests confirm app-bar structure (club name, identity dropdown gating, Sign out action)
   - Tests verify app-card frame wraps content
   - All six `club_site` surfaces render without error
   - `dev check` green (existing feature files pass unchanged)

2. **Visual verification:**
   - Gallery-walk screenshots compared to design wireframes
   - Pixel-fidelity check against `club-home.html` and `member-conversation.html`

3. **Manual spot-check:**
   - Signed-in surfaces show identity dropdown with working Sign out
   - Public (signed-out) page shows app-bar without identity dropdown

**Proof of success:** Every member-facing club surface renders inside the consistent app-shell (app-bar + app-card frame) matching the refreshed design wireframes, with all existing functionality (sign-out, identity gating, navigation) preserved.

---

## Review Analysis

### 1. Goal Clarity ✅

**Pass.** The goal is clear: "Replace the plain shared club-site header with the app-like app-bar inside an app-card frame... so every member-facing club surface reads as one consistent application shell." The beneficiary (members viewing club surfaces) is clear, and the user outcome (consistent app-like experience) is stated, not just tasks.

### 2. Scope Focus ✅

**Pass.** The scope is tightly focused on the shared layout shell transformation. The in-scope section is concrete (app-bar structure, app-card frame, CSS porting). The out-of-scope list is comprehensive (tabs, conversation content, club switcher, membership status, other layouts, behavior changes) and shows appropriate restraint. The iteration cannot be smaller—it's the atomic unit of replacing the shared layout chrome.

### 3. Acceptance Criteria, BDD Decision, Business Decisions ✅

**Pass.**

- **Acceptance criteria:** Six concrete, testable criteria covering:
  - Signed-in state (app-bar with club name, identity dropdown, Sign out action preservation)
  - Signed-out state (app-bar without identity dropdown, preserving existing gating)
  - Content frame (app-card wraps content, footer preserved)
  - Coverage (all six `club_site` surfaces render)
  - Explicit exclusion (no club dropdown/switcher/Memba mark)

- **BDD classification:** Clearly classified as "Technical / UI restructure (shared layout chrome)" with explicit rationale: "user-observable... but no new business rule."

- **Feature file decision:** Explicit and well-justified: "Not useful for this slice. No new business rule, permission, or lifecycle state... Sign-out and identity behaviour are unchanged and already covered... verified by LiveView/layout tests... No `.feature` files change; mainline stays green."

- **Business decisions:** "None known." The plan documents that the refreshed design resolved prior open questions (club dropdown removed, membership-status detail deferred).

### 4. Implementation Plan and Technical Decisions ✅

**Pass.** The implementation plan is concrete and ordered:

1. **Files named:** `web/lib/memba_web/components/layouts.ex` → `club_site/1` function
2. **Changes specified:** Replace header markup with app-bar, wrap `@inner_block` in app-card, preserve footer/flash, keep `@current_identity` gating
3. **CSS porting detailed:** Port specific classes (`app-frame`, `app-card`, `app-bar`, `app-menu`, `app-foot`, identity-dropdown pieces) from `design-system/` into `web/assets/css/app.css`, maintaining 1:1 names
4. **Data plumbing decided:** New optional `member_name` assign with email-local-part fallback, `initials/1` helper in `Layouts`
5. **Test updates:** LiveView/layout tests for new header structure, identity gating, Sign out action, content frame, surface rendering

**Technical decisions:** Both prior technical questions are explicitly documented as decided (CSS source approach, identity name/initials plumbing) with clear rationales.

### 5. Expected Capability and Validation ✅

**Pass.**

- **New capability clearly stated:** "A shared, app-like shell (app-bar + app-card) across every member surface — built once in the shared layout — so the club-home tabs and the aligned conversation page can be built inside a consistent frame."

- **Stop condition clear:** All six `club_site` surfaces render in the new shell, matching design wireframes, with preserved functionality.

- **Validation plan comprehensive:** Automated tests + visual gallery-walk comparison + manual spot-check (see detailed validation plan above).

---

## Summary

This plan is **ready for implementation**. It demonstrates:

- Clear goal focused on user-observable outcome (consistent app-shell across member surfaces)
- Tightly scoped, atomic unit of work leveraging shared layout
- Concrete, testable acceptance criteria covering happy paths and edge cases (signed-in/signed-out states)
- Appropriate BDD classification with explicit rationale for no feature-file changes
- Specific implementation steps naming files, modules, helpers, and integration points
- Resolved technical decisions with documented rationales
- Clear new capability and comprehensive validation approach

The three non-blocking improvements noted above are minor polish items that don't prevent implementation from proceeding.

---

```json
{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}
```