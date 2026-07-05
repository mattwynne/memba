Now I'll evaluate this plan against the readiness criteria and provide a comprehensive review.

---

# Iteration 046 Plan Review

**Decision:** READY  
**Confidence:** High  
**Date:** 2026-07-05

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Timestamp format example could be more precise** — Step 1 specifies `"3 Jun, 7:02am"` format, but could clarify timezone handling (appears to be UTC from the schema, but display timezone isn't stated). Not blocking because the design file is the source of truth and the helper can be adjusted during implementation.

2. **Card CSS class names could reference line numbers** — Step 9 mentions `message` / `message--original` classes from the design but doesn't specify where in `app.css` to place them. Not blocking because step 3 already establishes the pattern of porting from design-system 1:1.

3. **Gallery-walk comparison method could be more specific** — Step 11 says "compare the conversation screenshot" but doesn't state whether this is a visual diff, side-by-side review, or overlay. Not blocking because the validation plan clarifies manual testing follows automated tests.

## Smallest Viable Iteration

**This is already the smallest viable iteration.** The plan explicitly:
- Excludes delivery relocation (deferred to 047)
- Changes only presentation (no new business rules)
- Bundles three tightly-coupled UI changes that must ship together for coherence (follow toggle + replies-first ordering + timestamps + card treatment)

Attempting to split further (e.g., "just timestamps" or "just reorder composer") would leave the page in an inconsistent half-migrated state that doesn't match either the old or new design.

## Required Plan Edits

None. The plan is ready for implementation as written.

## Validation Against Readiness Questions

### 1. Goal Clarity ✅

**Pass.** The goal clearly states:
- **User/business outcome:** "Align the member conversation page to the refreshed interaction model"
- **Beneficiary:** Members viewing conversations
- **What changes:** Compact follow toggle, replies-first reading order, timestamps, card treatment
- **What doesn't change:** Delivery (explicitly excluded), follow/reply behavior

The goal is outcome-focused, not task-focused.

### 2. Scope Focus ✅

**Pass.** The scope is:
- **Coherent:** All changes align the conversation page to the refreshed design's interaction model
- **Minimal:** Explicitly excludes delivery relocation (047), any behavior changes, and unrelated features
- **Useful while small:** Delivers a complete visual alignment step without half-states
- **Boundaries clear:** In-scope and out-of-scope sections are explicit and comprehensive

Could not be smaller without leaving the page inconsistent.

### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✅

**Pass.**

**Acceptance criteria:**
- Concrete: "toggle beside the subject," "composer renders below replies," "show a timestamp," "boxed cards"
- Complete: Cover follow control (toggle), composer position, timestamps (original + replies), card treatment, delivery preservation
- Testable: Each criterion maps to observable UI state or behavior
- Appropriate scope: Cover presentation changes and behavior preservation (no new edge cases because no new behavior)

**BDD classification:**
- Correctly classified as "Technical / UI restructure (presentation)"
- Explicit rationale: "No new business rule, permission, or lifecycle state... follow and reply behaviour unchanged"

**Acceptance Scenarios / Feature Files:**
- Clear decision: "Not useful for this slice"
- Justified: No new business rules, existing scenarios cover behavior, presentation verified by LiveView tests
- Appropriate: Technical presentation changes don't need stakeholder-readable Gherkin

**Business decisions:**
- Explicitly states: "None known"
- Context provided: Delivery relocation confirmed as intentional split to 047

### 4. Implementation Plan and Technical Decisions ✅

**Pass.**

**Implementation steps:**
- Clear and ordered: 12 sequential steps from helper function → CSS → markup → tests → validation
- Specific files named: `page_html.ex`, `message.html.heex`, `app.css`, `conversation_entry_card`, `MemberMessageDetailLive` tests
- Integration points clear: Existing `follow_conversation`/`unfollow_conversation` events, `@following_conversation` assign, `@can_follow_conversation` gating
- Data model: Confirms `@entry.message.inserted_at` available (no projection change needed)
- Tests: Step 10 specifies what to test (toggle state, composer position, timestamps)
- Validation: Steps 11-12 specify gallery-walk and `dev check`

**Technical decisions:**
- Explicitly resolved: Timestamp source (`inserted_at` from existing projection), follow control (compact toggle wired to existing events)
- States: "None open"

### 5. Expected Capability and Validation ✅

**Pass.**

**New capability clearly stated:**
- "The conversation page reads replies-first with a lightweight follow toggle and message timestamps — matching the refreshed app-like design"

**Success proof:**
- **Automated:** LiveView tests green, `dev check` green
- **Visual:** Gallery-walk screenshot comparison to design
- **Manual:** Follow/unfollow, post reply, confirm order and timestamps

**Stop condition:** Clear — all acceptance criteria met, tests green, visual match confirmed.

## Summary

This plan is **production-ready**. It demonstrates:

- **Excellent scope discipline:** Tight focus on presentation alignment, explicit exclusion of delivery (047)
- **Thorough grounding:** References current implementation files, design source of record, existing events
- **Clear decisions:** BDD rationale explicit, timestamp source decided, follow control approach decided
- **Implementable steps:** 12 concrete steps with file names, integration points, and test expectations
- **Complete validation:** Automated + visual + manual verification specified

The plan correctly identifies this as a technical/presentation change requiring LiveView tests but not new Gherkin scenarios. The delivery relocation split (047) is well-justified and prevents this iteration from growing too large.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}