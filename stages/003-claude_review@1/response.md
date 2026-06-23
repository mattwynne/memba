Now I'll review the plan against the five readiness questions and provide my assessment.

---

# Iteration Plan Review — 043: Conversations Overview Grouping

**Decision:** READY  
**Confidence:** High

---

## Blocking Gaps

None.

---

## Non-Blocking Improvements

1. **Originator name source clarification** — The plan says rows will show "Started by \<originator\>" and that the presentation will build "originator name + initials" from the new query, but doesn't explicitly state whether `list_conversations_for_club/1` will return originator name/initials or if the presentation layer will join/look them up. This is a minor technical detail likely obvious in context, but stating "originator name and initials come from the root message's originator" would remove ambiguity.

2. **Design sync timing** — The plan says "Fast-follow design tweaks required" for making the row origin-led and removing the delivery glance. It's slightly unclear whether these design updates happen before or during implementation. Since the iteration is marked behaviour-facing and the wireframe exists, this is not blocking, but the plan could say "update wireframe before implementation" or "update wireframe in step 0."

3. **Reply count zero-case wording** — Acceptance criteria state "No replies yet" but don't confirm whether the count itself shows "0 replies" or is omitted entirely when zero. The scenarios and criteria imply complete omission (since "\<N\> replies..." is distinct from "No replies yet"), but stating "when zero, display only 'No replies yet' without a count" would be clearer.

---

## Readiness Assessment by Question

### 1. Goal Clarity ✅

**Is the goal clearly articulated?**  
Yes. The goal is concise and outcome-focused: "each conversation appears as **one row** with a **reply count**."

**Does it state the user/business outcome, not just tasks?**  
Yes. It states what members will see ("replies stop masquerading as new club-wide messages") rather than describing technical tasks.

**Is the intended beneficiary or actor clear?**  
Yes. The beneficiary is members viewing the club home. The scope explicitly names the surface (`PageHTML.club` via `MemberDashboardPresentation`).

---

### 2. Scope Focus ✅

**Is the scope focused on one coherent outcome?**  
Yes. The iteration focuses solely on changing how the member club-home list displays conversations.

**Could the iteration be any smaller while still useful?**  
Not without losing coherence. Grouping replies without showing a reply count would be incomplete; showing a count without grouping would be incoherent. The ordering decision (original send time) is necessary to prevent confusing reordering.

**Are non-goals and boundaries clear?**  
Exceptionally clear. The plan explicitly excludes:
- Staff/admin lists
- Conversation detail page
- Email surfaces
- Stop-following page
- Read state / unread emphasis
- The delivery glance is explicitly **removed** from the home

The "Out of scope" section directly references the related problems note to clarify what remains unresolved.

---

### 3. Acceptance Criteria, BDD Scenario Decision, and Business Decisions ✅

**Are acceptance criteria concrete, clear, complete, and objectively testable?**  
Yes. The six acceptance criteria cover:
- Happy path: one row per conversation, reply count shown
- Zero-reply case: "No replies yet"
- Ordering rule: original send time, newest first; replies don't reorder
- Avatar and date source: originator and original date
- Removal: delivery glance removed
- Reply count scope: includes both in-app and email replies

**Do they cover happy paths, important edge cases, permissions, error states, and data/state changes?**  
Yes for this scope. Happy path and zero-reply edge case are covered. No permissions changes (viewing is unchanged). No error states are introduced (the read model is query-only). Data/state changes (grouping and counting) are specified.

**Does the plan classify the iteration as behaviour-facing or technical/engineering?**  
Yes. Section "Iteration Type" states: "Behaviour-facing."

**For behaviour-facing, does the plan include an `## Acceptance Scenarios / Feature Files` section?**  
Yes. The section names the exact feature file (`acceptance-tests/features/club_message_replies.feature`), states the scope (add a Rule, stays `@not-ui`), and describes three domain-language scenarios that map directly to acceptance criteria. It includes appropriate tagging (`@iteration-043 @todo-domain`) and explicitly limits the scope of allowed feature changes.

**Are any business, product, policy, copy, workflow, or domain decisions still unresolved?**  
No. The "Open Business Decisions" section states "None known." All key decisions are resolved:
- Ordering (original send time, no bump-on-reply)
- Row identity (originator, original date)
- Reply count includes both in-app and email
- Delivery glance is removed from home
- Wireframe adjustments are specified

---

### 4. Implementation Plan and Technical Decisions ✅

**Are implementation steps clear, ordered, and specific?**  
Yes. Four numbered steps follow a natural dependency order:
1. Create the new read-model query
2. Update the presentation layer to consume it
3. Update the template markup
4. Keep the link target unchanged

**Are likely files, modules, migrations, tests, interfaces, and integration points named?**  
Yes:
- Modules: `Messaging.list_conversations_for_club/1`, `MemberDashboardPresentation`, `PageHTML.club`
- Files: `club.html.heex`, `acceptance-tests/features/club_message_replies.feature`
- Tables/schema: `MessageProjection` (existing, no migration)
- Template selector: `#member-message-list`
- Integration points: "Keep the row link target unchanged (the conversation/message-detail route)"

**Are data model, API, UI, workflow, integration, and background-job changes clear?**  
Yes:
- Data model: read-model query over `MessageProjection`; grouping logic specified
- API: none (UI-only iteration)
- UI: markup changes specified (originator avatar, reply-activity line, remove delivery glance)
- Workflow: none (viewing only)
- Integration: no external systems
- Background jobs: none

**Are any technical decisions still unresolved?**  
One minor decision is open: "Exact shape of the latest-replier lookup in the group-by (window function vs. a second query keyed by conversation)." The plan explicitly states "Either is acceptable; prefer one query if clean," which is appropriate delegation to the implementer for a purely technical choice with no observable behavior impact.

---

### 5. Expected Capability and Validation ✅

**What should we be able to do after this iteration that we cannot do now?**  
Clear. Members will see the club home as a list of conversations with reply counts, instead of a flat list of all messages. Replies will no longer appear as separate rows.

**How will we prove success?**  
Three validation methods are specified:
1. Cucumber scenarios (`@todo-domain` scenarios go green)
2. ExUnit test for `MemberDashboardPresentation` covering grouping, counting, ordering, and field removal
3. Gallery-walk screenshot confirming the "Saturday ridge walk" conversation renders correctly

**Is there a clear stop condition?**  
Yes. The acceptance criteria and validation plan together define completion: the three types of tests pass and the home renders conversations with reply counts as specified.

---

## Smallest Viable Iteration

The plan is already at the smallest useful increment. Any reduction would make it incomplete:

- Without grouping, the reply count is meaningless
- Without the reply count, grouping alone doesn't show conversation activity
- Without the ordering decision, users would see confusing reordering on every reply
- Without removing the delivery glance, the home would have incoherent mixed signals about what a "row" represents

**Recommendation:** Implement as planned. The scope is minimal and coherent.

---

## Required Plan Edits

None.

---

## Validation Plan

**How to prove the iteration succeeded:**

1. **Domain scenarios green:** The new `@todo-domain` tagged scenarios in `acceptance-tests/features/club_message_replies.feature` must pass, and the `@todo-domain` tag must be removed.

2. **Presentation unit tests:** `MemberDashboardPresentation` ExUnit tests confirm:
   - One entry per conversation (not per message)
   - Reply count matches the number of replies
   - Latest replier is named correctly
   - Ordering is by original send time descending
   - Delivery glance fields are absent

3. **Visual verification:** `bin/dev gallery-walk` produces a screenshot showing the "Saturday ridge walk" conversation as a single row with its reply count and "latest from \<name\>".

4. **`dev check` passes:** All tests, quality checks, and Cucumber scenarios pass.

**Stop condition:** All four validation steps pass.

---

## Summary

This is a well-scoped, clearly specified iteration plan. The goal is outcome-focused, the scope is minimal and coherent, acceptance criteria are testable and complete, the implementation plan is concrete and ordered, and the validation plan is explicit. Business and technical decisions are resolved except for one minor technical choice appropriately delegated to the implementer. The plan is ready for implementation.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}