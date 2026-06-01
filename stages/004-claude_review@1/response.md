# Iteration Plan Review: Member-Facing Message Behaviour

## Decision: NOT READY

## Confidence: High

The plan explicitly lists unresolved technical decisions that would block implementation, and critical sections (Goal, Scope, Acceptance Criteria) are missing from the provided text.

---

## Blocking Gaps

1. **Goal, Scope, and Acceptance Criteria sections missing from provided plan text** (lines 1-134 omitted)
   - Cannot verify goal clarity, scope focus, or acceptance criteria completeness
   - Cannot verify BDD scenario decision or business policy completeness
   - Cannot assess if the iteration is properly scoped as behaviour-facing or technical

2. **Four unresolved technical decisions explicitly listed in "Open Technical Decisions"**:
   - **Route shape**: No concrete route pattern chosen for member message detail
   - **Compose placement**: Separate page vs modal/section undecided
   - **Receipt status display**: Grouped sections vs simple list undecided  
   - **Icon source**: Specific icon approach not chosen

3. **Implementation steps depend on unresolved decisions**
   - Cannot write routes without route pattern
   - Cannot build UI without knowing compose placement and receipt display structure
   - Cannot import icons without knowing source/approach

---

## Non-Blocking Improvements

1. **Validation plan could specify exact Cucumber scenarios/tags**
   - Plan mentions `member_message_deliverability.feature` but doesn't list specific scenario names or show scenario outlines

2. **Manual demo could specify provider event simulation details**
   - Step 5 says "Simulate provider events for Bob, Carol, and Dana" - could specify which webhook payloads or which helper to use

3. **Design Constraints could clarify icon inventory**
   - Point 10 mentions "existing icon mappings" - could list the specific status→icon pairings expected

---

## Smallest Viable Iteration

Strip the iteration to absolute minimum member-facing message capability:

**Core slice:**
- Member views list of their sent messages (subject, date, recipient count)
- Member views one sent message detail with simple recipient list showing status labels (no icons, no grouping, no summary bar)
- Member cannot access `/admin/messages/*` routes
- Uses simplest route pattern: `/clubs/:club_id/messages/:id` with active membership authorization

**Deferred to follow-up:**
- Compose UI (can use existing admin compose for test setup)
- Grouped receipt displays with summary bars
- Status icons (just text labels first)
- Receipt status filtering/sorting

**Why this is still useful:**
- Proves member authorization works
- Proves member can see shared receipt states  
- Proves staff diagnostics remain separate
- Unblocks Cucumber scenarios for member message visibility

---

## Required Plan Edits

### 1. Provide Full Plan Text
Include Goal, Scope, and Acceptance Criteria sections (lines 1-134) so reviewers can verify:
- Goal articulates user/business outcome
- Scope is focused and complete
- Acceptance criteria are concrete and testable
- BDD scenario decision is documented

### 2. Resolve Route Decision
Choose exact route pattern. **Recommend:**
```
GET /clubs/:club_id/messages          # member message list
GET /clubs/:club_id/messages/:id      # member message detail
```
State authorization rule: requires active membership for `club_id`.

### 3. Resolve Compose Placement
The plan notes "design reference includes a separate compose screen." Either:
- **Commit to separate compose page**: Add route `GET/POST /clubs/:club_id/messages/new`
- **OR defer compose entirely**: Use existing admin compose for test setup; member compose is follow-up iteration

**Recommend:** Defer compose to separate iteration. This iteration proves member *viewing* behaviour.

### 4. Resolve Receipt Display Layout
Choose grouped sections with summary bar OR simple list. **Recommend:**
- Start with **simple list/table**: one row per recipient, status label column
- Defer grouping/summary bar to follow-up iteration when visual design is clearer

### 5. Resolve Icon Approach
State specific icon strategy. **Recommend:**
```
Use existing `<.icon>` component with Heroicons:
- Sending: hero-clock (outline)
- Delivered: hero-check-circle (outline)  
- Opened: hero-envelope-open (outline)
- Delivery problem: hero-exclamation-triangle (outline)
```
OR explicitly defer icons and use text-only labels first.

### 6. Reference Acceptance Scenarios
The plan mentions `member_message_deliverability.feature` and removing `@wip`. Either:
- Show the Gherkin scenarios in an `## Acceptance Scenarios` section
- OR state "Acceptance criteria are expressed in `member_message_deliverability.feature` scenarios: [list scenario names]"

This makes BDD decision visible and links criteria to executable tests.

### 7. Move Resolved Decisions Out of "Open Technical Decisions"
Once decisions are made, remove the "Open Technical Decisions" section or state "All technical decisions resolved; see Implementation Plan."

---

## Validation Plan

The existing Validation Plan is solid **after technical decisions are resolved**:

**Must pass:**
- `dev check` clean
- `member_message_deliverability.feature` untagged and passing
- Automated Phoenix tests cover member route authorization, status label mapping, member detail rendering

**Manual demo proves:**
1. Member can send message (using whatever compose approach is chosen)
2. Member sees sent message in list
3. Member sees message detail with recipient statuses
4. Statuses update as provider events arrive
5. Other members with active membership see same receipt states
6. No member page exposes delivery IDs, provider terminology, or admin diagnostics

**Stop condition:**
Cucumber scenarios pass without `@wip` tag; manual demo completes; `dev check` clean.

---

## Summary

The plan has a clear validation strategy and good awareness of risks/follow-ups. However, it cannot proceed to implementation because:

1. Critical sections are missing from review (Goal/Scope/Criteria)
2. Four major technical decisions remain unresolved
3. Implementation steps are blocked by undecided routes, UI structure, and display choices

**Next step:** Resolve all technical decisions into concrete choices, provide full plan text, and re-submit for review.

---

```json
{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":3,"claude_review_blocking_gaps":"Goal, Scope, and Acceptance Criteria sections missing from provided text; Four unresolved technical decisions (routes, compose placement, receipt display, icons); Implementation steps depend on unresolved decisions","claude_review_required_edits":"Provide full plan text including Goal/Scope/Criteria; Resolve route pattern; Resolve compose placement or defer; Resolve receipt display layout; Resolve icon approach; Reference acceptance scenarios explicitly"}}
```