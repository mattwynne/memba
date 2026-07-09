Now let me review the plan systematically against each readiness criterion.

---

# Iteration 051 Plan Review

## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. **Acceptance Scenarios section is missing.** The plan correctly identifies this as a behaviour-facing iteration and states "Update the shared acceptance feature file(s) used for the club-home conversation rows" (line 47), but does not include an `## Acceptance Scenarios / Feature Files` section naming the specific feature file(s) that will be updated or the scenarios that will be added/modified. While this follows the letter of the requirement (stating acceptance tests will be updated), the recommended practice is to name the files explicitly for clarity.

2. **Integration point naming could be more specific.** Step 1 mentions "likely alongside `reply_counts_query`/`latest_replies_query`" but doesn't confirm the exact location or function signature of the new query. This is likely fine given the small scope, but naming the exact function (`participants_query/1` or similar) would reduce implementation ambiguity.

## Smallest viable iteration

The plan already represents the smallest viable slice:
- Single focused capability: show who else is in a conversation via avatar-stack
- Natural CSS-porting boundary: `.conversation*`/`.avatar-stack` only, leaving `.message*`/`.composer*` for later
- Excludes member-since dates (separate problem), About tab (separate problem), and conversation-page CSS classes (tracked follow-up)
- Cannot be made smaller without losing user value (showing 0 participants or not capping the display would be incomplete)

The iteration appropriately bundles the CSS porting work with the avatar-stack feature because they touch the same templates and the design classes provide the natural markup structure for rendering the stack.

## Required plan edits

None blocking. The plan is implementation-ready.

**Optional enhancement:** Add an `## Acceptance Scenarios / Feature Files` section after line 88 naming the specific feature file(s) (likely a club-home or messaging feature file) and describing what scenarios will be added (e.g., "Scenario: Conversation with multiple participants shows avatar stack", "Scenario: Conversation with 4+ participants shows overflow badge").

## Validation plan

The iteration includes a clear, complete validation plan (lines 112-117):

**Automated testing:**
- Query tests for participant ordering, deduplication, and capping
- Presentation/LiveView tests for rendered avatar-stack and overflow badge
- Coverage for the no-replies-yet edge case

**Visual verification:**
- Gallery walk comparison against canonical design (`design-system/wireframes/club-home.html`)

**Manual verification:**
- Test with 0, 1–3, and 4+ distinct repliers to confirm correct rendering at each count

**Success criteria:**
- Clear stop condition: avatar-stack renders correctly with proper ordering, capping, and overflow count
- `dev check` passes
- Visual match to design confirmed via gallery walk

---

## Detailed assessment against readiness questions

### 1. Goal clarity ✓

**Is the goal clearly articulated?** Yes. Lines 9-12 state the outcome: conversation rows show participant avatar-stacks matching the design, closing a specific design gap.

**Does it state the user/business outcome, not just tasks?** Yes. The "New Capability" section (lines 106-109) explicitly states the user outcome: "Members can see at a glance who else is participating in a conversation from the club home, without opening it."

**Is the intended beneficiary or actor clear?** Yes. Club members viewing the club home.

### 2. Scope focus ✓

**Is the scope focused on one coherent outcome?** Yes. The iteration focuses on adding the participant avatar-stack to club-home conversation rows. The CSS porting work is appropriately bundled because it provides the structural foundation for rendering the stack.

**Could the iteration be any smaller while still useful?** No. The avatar-stack without the CSS classes would require ad hoc markup; the CSS classes without the avatar-stack data would render nothing. The three-participant cap and overflow badge are part of the design spec and essential for usability (preventing unbounded UI growth).

**Are non-goals and boundaries clear?** Yes. Lines 49-55 explicitly exclude:
- Conversation-page CSS classes (separate follow-up)
- Reply counts/latest-replier label changes
- Member-since dates (separate problem)
- About tab (separate problem)

### 3. Acceptance criteria, BDD scenario decision, and business decisions ✓

**Are acceptance criteria concrete, clear, complete, and objectively testable?** Yes (lines 80-87):
- Avatar-stack shows distinct repliers excluding originator, ordered by first reply, capped at 3, with "+N" overflow
- No stack when no replies exist
- CSS classes ported and used in template
- `dev check` passes and acceptance coverage added

**Do they cover happy paths, important edge cases, permissions, error states, and data/state changes where relevant?** Yes:
- Happy path: conversation with multiple participants
- Edge case: no replies (empty state)
- Edge case: exactly 3 vs. 4+ participants (overflow boundary)
- No permissions changes in scope (viewing existing conversation data)
- No error states beyond standard data-loading

**Does the plan classify the iteration as behaviour-facing or technical/engineering?** Yes. Lines 57-60 explicitly state "Behaviour-facing."

**For behaviour-facing changes, does the plan include an Acceptance Scenarios / Feature Files section or rationale for omitting Gherkin?** Partially. The plan states acceptance coverage will be added (line 87, line 102) but does not name the specific feature file(s) or scenarios. This is a **non-blocking improvement** area, not a blocking gap—the commitment to add acceptance tests is clear, just not the exact file location.

**Are any business, product, policy, copy, workflow, or domain decisions still unresolved?** No. The "Decisions" section (lines 62-72) documents that all three open questions from the draft were resolved by Matt on 2026-07-09:
1. Participant definition and ordering: distinct repliers excluding sender, ordered by first reply
2. "+N" meaning: counts participants, not replies
3. Cap: 3 visible avatars before overflow

### 4. Implementation plan and technical decisions ✓

**Are implementation steps clear, ordered, and specific?** Yes. Lines 89-104 provide a clear 7-step plan:
1. Add participants query (location specified)
2. Thread data through presentation layer with capping logic
3. Port CSS classes
4. Rewrite template
5. Add tests
6. Gallery walk
7. Run `dev check`

**Are likely files, modules, migrations, tests, interfaces, and integration points named where useful?** Yes:
- Modules: `Messaging.conversations_for_club_query/1`, `MemberDashboardPresentation.present_message_rows/2`
- Files: `app.css`, `club.html.heex`, `memba.css` (design-system reference)
- Components: `<.avatar>`
- Integration points: existing `reply_counts_query`/`latest_replies_query` pattern
- Design reference: `design-system/wireframes/club-home.html`

**Are data model, API, UI, workflow, integration, and background-job changes clear enough?** Yes:
- Data model: new query joining replies to get distinct sender_ids per conversation, ordered by first reply time
- UI: avatar-stack rendering via existing component, overflow badge for 4+ participants
- No API, background-job, or workflow changes in scope

**Are any technical decisions still unresolved?** No. The query approach, presentation-layer capping, component reuse, and CSS-porting strategy are all specified.

### 5. Expected capability and validation ✓

**What should we be able to do after this iteration that we cannot do now?** Clearly stated (lines 106-109): see at a glance who else is participating in a conversation from the club home without opening it.

**How will we prove success?** Three verification layers specified (lines 112-117):
- Automated tests (query, presentation, LiveView)
- Gallery walk against canonical design
- Manual testing with different participant counts

**Is there a clear stop condition?** Yes. The iteration is complete when:
- Avatar-stack renders with correct participants, ordering, cap, and overflow badge
- CSS classes ported and templates updated
- Acceptance tests pass
- `dev check` passes
- Visual comparison to design confirms match

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}