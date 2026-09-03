Now I'll review the plan against the readiness criteria.

---

## Iteration Plan Review: Group Audience Foundation

### Decision: **READY**

### Confidence: **High**

This plan is implementation-ready. It defines a focused technical foundation for explicit conversation groups, maintains clear scope boundaries, and includes comprehensive acceptance criteria with appropriate technical validation.

---

### Blocking Gaps

None.

---

### Non-blocking Improvements

1. **Consider explicit query API signatures in Implementation Plan**: While step 6 mentions "public Membership queries such as active group members and whether a person is an active member of a group," naming the proposed function signatures (e.g., `Membership.active_group_members(group_id)`, `Membership.member_of_group?(person_id, group_id)`) would help implementation stay aligned with the public API boundary from ADR 0007.

2. **Clarify backfill ordering dependencies**: Step 9 mentions "dependency order (groups, memberships/Admin assignments, root conversations)" but could briefly state why—for example, "groups must exist before memberships can be added; memberships must be seeded before conversation access grants reference them."

3. **Make conversation-access query API explicit**: Step 7 adds `messaging_conversation_group_access` and mentions "the Messaging query API" validating access levels, but doesn't name the proposed query function (e.g., `Messaging.has_conversation_access?(person_id, conversation_id, :write)`). Including this would mirror the Membership API guidance.

These are minor and do not block implementation—they would refine the developer experience during execution but the plan clearly identifies what needs building.

---

### Smallest Viable Iteration

This iteration is already at its smallest viable slice. It:
- Introduces only the two system groups (Everyone, Admin) without custom groups
- Makes no member-visible behaviour changes
- Preserves all existing workflows intact
- Defers all UI, email routes, read filtering, and public visibility

Any smaller scope would leave the foundation incomplete for the next slice (Admin group email route). The iteration cannot be reduced further while remaining useful.

---

### Required Plan Edits

None. The plan is ready as-written.

---

### Validation Plan

The plan's validation section (lines 297-316) is comprehensive and correctly sequenced:

1. **Aggregate & policy unit tests** confirm group creation, membership lifecycle, idempotency
2. **Lifecycle integration tests** prove member/role changes produce correct group memberships
3. **Acceptance regression** confirms existing behaviour unchanged (deliverability, replies, admin authority)
4. **Backfill tests** validate idempotency and restart safety with interruption scenarios
5. **Replay parity test** rebuilds projections from events and compares read-model state
6. **Final gate**: `dev check` passes on committed state

Success criteria are observable, testable, and sufficient. The iteration is complete when existing acceptance tests pass unchanged, new domain/policy tests pass, replay produces identical read models, backfill is restartable, and `dev check` succeeds.

---

### Detailed Assessment by Criterion

#### 1. Goal Clarity ✓

**Goal (lines 6-20)**: Replace hidden club-wide audience with explicit event-sourced conversation groups for Everyone and Admin, preserving all current member visibility, posting, and delivery behaviour.

- Outcome-focused: transitions from implicit to explicit audience model
- Beneficiary clear: foundation for future group features; preserves current member experience
- Business value stated: makes conversation cohorts explicit domain facts rather than hardcoded special cases

#### 2. Scope Focus ✓

**In scope (49-111)** precisely defines:
- Group/membership events and commands
- System groups (Everyone, Admin only)
- Membership policy for automatic group alignment
- Conversation access grants and projection
- Message routing through new group APIs
- Backfill strategy for existing data

**Out of scope (113-128)** explicitly defers:
- Custom groups, group UI, Admin email routes
- Read filtering, visibility rules, shared conversations
- Role changes, follower delivery changes

The scope is tightly focused on establishing the group foundation without changing observable behaviour. Cannot be smaller while useful (see above).

#### 3. Acceptance Criteria, BDD Decision, Business Decisions ✓

**Acceptance criteria (162-192)**: Concrete, testable, complete
- Group creation during club creation
- Membership additions/removals trigger correct group events
- Policy implementation outside projectors (architectural constraint)
- Existing permissions unchanged
- Access grants recorded for conversations
- Backfill idempotency and replay parity
- Strong consistency (read-your-writes)
- `dev check` gate

Criteria cover happy paths (club creation, member addition), edge cases (reply vs root message), permissions (Admin role unchanged), error states (backfill restart), and state changes (membership toggles).

**BDD decision (138-156)**: Explicit and justified
- Classification: Technical/engineering (line 130-136)
- Rationale: No new stakeholder-visible workflow; existing `.feature` files already express preserved behaviour
- Named existing features that provide regression coverage
- Appropriate: this is an internal refactoring with no observable rule changes

**Business decisions (194-207)**: All resolved
- Groups vs roles distinction confirmed
- System-group membership rules confirmed
- Event-sourcing approach confirmed
- No open decisions listed

#### 4. Implementation Plan and Technical Decisions ✓

**Implementation plan (209-265)**: Ordered, specific, actionable
- Step-by-step from aggregate inspection through backfill to replay tests
- Names modules: `Memba.Membership.Policies.SystemGroupMembership`, `Memba.Release.migrate/0`, `Memba.EventSourcedCase`
- Names tables: `membership_groups`, `membership_group_memberships`, `messaging_conversation_group_access`
- Names events: `GroupCreated`, `GroupMemberAdded`, `GroupMemberRemoved`, `ConversationAccessGrantedToGroup`
- Integration points clear: Club aggregate, Commanded router, projection barrier, release migration flow

**Technical decisions (267-287)**: All resolved
- System-group policy architecture (stateless handler, strong consistency, `:current` start)
- Membership projection design (current-state rows, active toggle)
- Backfill execution (automatic from release, idempotent, restartable)
- Replay proof strategy (EventSourcedCase helpers, ProjectionBarrier)

Data model changes clear, workflow integration points named, background-job/policy design explicit.

#### 5. Expected Capability and Validation ✓

**New capability (289-295)**: Clear stop condition
- Explicit rebuildable Group identities and memberships exist
- Everyone conversations no longer a special case
- Foundation ready for Admin-group email route

**Validation (297-316)**: Comprehensive and concrete
- ExUnit tests for aggregates, policies, projections
- Lifecycle tests for membership/role changes
- Acceptance regression for unchanged behaviour
- Backfill idempotency and interruption tests
- Replay parity test
- `dev check` as final gate

Success proof is objective: tests pass, existing behaviour unchanged, projections rebuildable, backfill restartable.

---

### Summary

This iteration plan is **implementation-ready** with **high confidence**. It defines a focused technical foundation, maintains clear boundaries between groups and roles, preserves all existing behaviour, and includes comprehensive validation through unit tests, acceptance regression, replay parity, and backfill safety checks. The three non-blocking improvements would enhance developer experience but do not prevent successful implementation.

The plan demonstrates strong alignment with the project's event-sourcing and bounded-context principles, explicitly addresses the relevant existing problems and product vision documents, and sets a solid foundation for the stated next iteration (Admin group email route).

---

```json
{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}
```