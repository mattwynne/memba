Now I'll review the plan against all readiness criteria.

---

# Iteration 057 Plan Review: Admin Group Email Conversations

## Decision: READY

## Confidence: High

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Acceptance scenario language review**: Line 102 states "Matt must review the scenario language as domain language before the plan is treated as final." This is acknowledged as a pending step but doesn't block implementation start since the scenarios are well-defined and tagged for progressive enablement.

2. **Vision document update timing**: The plan notes (lines 27-28, 236-237) that the Groups vision document must be updated to reflect the `club_members_only` posting rule. This is a documentation debt that should be tracked but doesn't block the technical work.

## Smallest Viable Iteration

The plan already describes the smallest viable slice: enable Admin-group email routing and delivery while deferring all UI, configuration, sender-copy suppression, and custom groups. This is appropriately minimal.

The only conceivable reduction would be to defer the generic group-ID queries (step 8) and keep web queries hard-coded to Everyone, but that would likely require throwaway work since the queries are needed immediately after for the group-display iteration.

## Required Plan Edits

None. The plan is implementation-ready as written.

## Validation Plan

The plan includes a comprehensive validation approach (lines 217-231):

- **Pre-implementation**: Verify acceptance test configuration excludes new scenarios from default runners
- **During implementation**: Focused unit/integration tests for each component (slugs, routing, authorization, delivery, queries)
- **Realistic payload testing**: Multiple sender scenarios (non-Admin, Admin, inactive, other-club, duplicates)
- **Query boundary verification**: Group-scoped queries return correct conversations; web still uses Everyone
- **Progressive BDD enablement**: Remove runner-debt tags as step support completes
- **Final gate**: `dev check` passes on committed state

Success criteria:
- `admin@<club-slug>.clubs.memba.io` routes to Admin group
- Active club members can send to Admin regardless of membership
- Only active Admin members receive and can reply
- Non-Admin senders get no copy, access, or follower status
- Web UI shows no Admin conversations (Everyone-only constraint preserved)
- All existing Everyone behavior unchanged
- All acceptance scenarios executable with tags removed
- `dev check` passes

---

## Detailed Assessment

### 1. Goal Clarity ✅

**Clear and outcome-focused** (lines 6-13). The goal states:
- What: Make Admin a private, email-only conversation audience
- Who: Active club members (senders) and active Admin members (recipients/replyers)
- Benefit: Private Admin communication channel via `admin@<club-slug>.clubs.memba.io`
- User experience: Clear sender/recipient/reply rules with web UI deliberately excluded

### 2. Scope Focus ✅

**Tightly scoped and coherent** (lines 35-73).

In scope:
- Group email slugs and routing (`everyone`, `admin`)
- Fixed posting policy (active club member can start conversation)
- Admin-only delivery and reply rights
- Generic group-ID queries for future UI (without exposing Admin in current UI)
- Backfill for existing system groups

Out of scope is comprehensive and well-justified:
- No web UI changes
- No policy configuration
- No custom groups
- No sender-copy suppression (deferred as documented problem)
- No rejected-email inbox

The iteration cannot be meaningfully smaller while remaining useful. The email-slug infrastructure, routing, and access model are all necessary for the Admin email address to function.

### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✅

**Acceptance criteria** (lines 123-144) are concrete, complete, and testable:
- Technical facts: email slugs, routing resolution, access grants
- Authorization rules: who can send (active club member), who receives (active Admin), who can reply (active Admin)
- Edge cases: sender outside Admin gets no copy/access, rejection rules preserved
- State changes: write-access grant creation, follower non-creation for non-Admin sender
- Regression coverage: Everyone behavior unchanged, `dev check` passes

**BDD classification** (lines 75-79): Explicitly classified as behaviour-facing with clear rationale (inbound authorization, recipient privacy, conversation access, email replies all change).

**Acceptance scenarios** (lines 81-114):
- Required scenarios clearly enumerated for `member_message_deliverability.feature` and `club_message_replies.feature`
- Scenarios cover: non-Admin sender (receives nothing), Admin sender (receives copy), other-club sender (rejected), Admin reply
- Runner-debt tags documented (`@todo-domain`, `@todo-ui`) with progressive enablement plan
- Caveat noted that Matt must review scenario language (line 102)—this is acknowledged as a gate but scenarios are well-specified

**Business decisions** (lines 146-158):
- No open decisions
- All confirmed decisions documented: `club_members_only` policy, deferred future policies, deferred sender-copy problem
- Vision document update identified as separate follow-up (not blocking)

### 4. Implementation Plan and Technical Decisions ✅

**Implementation steps** (lines 160-197) are clear, ordered, and specific:
1. Verify iteration 056 foundation
2. Add email-slug to Membership model/events/projections
3. System-group creation and backfill with consistent slugs
4. Generalize inbound routing from hard-coded `everyone` to slug lookup
5. Introduce named posting-policy boundary in Messaging
6. Extend inbound command for group-based delivery and access grants
7. Reuse iteration-056 group-write reply authorization
8. Add group-ID-based queries; refactor web to explicit Everyone
9. Comprehensive tests (aggregate, policy, backfill, routing, authorization, delivery, reply)
10. Implement BDD step support and run `dev check`

**Named components and files**:
- Membership context (groups, events, projections, slug lookup)
- Messaging context (inbound routing, posting policy, commands, queries)
- Release backfill
- Acceptance features: `member_message_deliverability.feature`, `club_message_replies.feature`

**Technical decisions** (lines 199-207):
- All resolved
- Email slug as immutable routing key (distinct from display name)
- Fixed policy boundary (not persisted)
- Email idempotency keyed by provider/message identity

### 5. Expected Capability and Validation ✅

**New capability** (lines 209-214): Clear statement of what becomes possible:
- Admin email address for private conversations
- Active members can contact Admin
- Only Admin members receive/reply
- APIs ready for future group UI

**Stop condition**: All acceptance scenarios executable, existing behavior preserved, `dev check` passes (lines 217-231).

**Validation plan**: Comprehensive as detailed above.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}