I'll now review the plan against the readiness criteria.

---

# Iteration Plan Review: Group Audience Foundation

## Decision: **READY**

## Confidence: **High**

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Process Manager Lifecycle Detail**: Step 5 mentions the process manager stops "only after `MemberRemoved` has removed Everyone and Admin memberships" but doesn't specify whether the policy explicitly issues those removal commands before stopping or relies on separate event handling. Minor—the implementation will clarify this.

2. **Backfill Error Handling Strategy**: The plan states the backfill "aborts the release on an unrecoverable error" but doesn't define what constitutes "unrecoverable" vs. transient. Given the restart safety emphasis, this is acceptable for implementation-time judgment.

3. **Index Detail for Query Performance**: Step 4 mentions "index current rows for group-to-members and person-to-groups access queries" but doesn't specify the exact indexes. Standard practice would add them during implementation; acceptable given focused scope.

## Smallest Viable Iteration

**This plan already represents the smallest viable iteration.**

The author explicitly deferred:
- Custom groups
- Group UI
- Additional email addresses
- Conversation read filtering
- Public visibility
- Shared multi-group access
- Roles within groups

The included scope establishes the minimal event-sourced foundation (two system groups, membership policy, conversation access model) required for the next slice (Admin group email). Removing any component would leave the foundation incomplete or unusable.

## Required Plan Edits

None. The plan is ready for implementation as written.

## Validation Plan

The plan includes a comprehensive validation strategy:

### Pre-implementation
- Strong consistency configuration ensures read-your-writes for group membership
- Replay parity test design using existing `EventSourcedCase` infrastructure

### During implementation
- Focused ExUnit tests for aggregate decisions, process policy idempotency, membership lifecycle
- Acceptance regression suite preserves existing behavior

### Post-implementation success criteria
1. Club creation produces deterministic Everyone/Admin groups
2. Member lifecycle triggers correct group membership through policy
3. Admin role assignment/removal reflected in Admin group
4. New root conversations emit Everyone write grant
5. Existing behavior unchanged: recipients, authorization, follower delivery, threading
6. Backfill idempotency proven through interrupt/retry tests
7. Replay from event store reproduces same read models
8. `dev check` passes

### Stop condition
All focused tests, acceptance regressions, replay parity, backfill idempotency coverage, and `dev check` pass on committed state.

---

## Detailed Assessment

### 1. Goal Clarity ✓

**Clear user/business outcome**: Replace hidden club-wide audience with explicit, event-sourced groups while preserving all current member capabilities.

**Beneficiaries identified**: Club members (unchanged posting/receiving), future iterations (explicit foundation for Admin email and custom groups), system maintainability (rebuildable projections vs. hidden special cases).

**Not just tasks**: The goal emphasizes the business invariant ("without changing what any member can currently see, post, or receive") alongside the technical transformation.

### 2. Scope Focus ✓

**One coherent outcome**: Establish event-sourced group foundation with two system groups.

**Minimal useful slice**: Yes. The author explicitly listed 8 categories of deferred work and explained why Everything/Admin system groups are the minimum foundation.

**Clear boundaries**: Detailed "Out of scope" section prevents feature creep. "In scope" section is precise about which events, projections, commands, and behavioral seams change.

### 3. Acceptance Criteria, BDD Decision, Business Decisions ✓

**Concrete & testable**: 13 numbered acceptance criteria cover:
- Happy path: club creation, member lifecycle, role assignment
- Edge cases: backfill idempotency, restart safety
- Permissions: Admin role preservation, reply authorization
- Data/state: projection rebuild parity, process manager consistency
- Error states: backfill failure handling

**BDD classification clear**: "Technical/engineering" with explicit rationale—no new member-visible rule.

**Gherkin decision justified**: Explains that existing `.feature` files already cover the behavior that must remain unchanged. New work (policy, event vocabulary, projection rebuild) needs focused ExUnit tests, not stakeholder-readable scenarios. This reasoning aligns with the framework: technical refactoring that preserves existing behavior doesn't need new Gherkin.

**Business decisions resolved**: "Open Business Decisions: None known" followed by 6 confirmed decisions about group/role separation, system group scope, and implementation approach.

### 4. Implementation Plan & Technical Decisions ✓

**Clear, ordered, specific**: 11 numbered steps with:
- Named files/modules: `Memba.Membership.Policies.SystemGroupMembership`, `membership_groups`, `membership_group_memberships`, `Memba.Membership.SystemGroups.Backfill`
- Integration points: Commanded router, projection barrier, release migrate
- Data model: typed Group ID, current-state membership projection with `active` toggle
- Workflow: process manager lifecycle from `:current`, backfill from release migration

**Technical decisions explicit**: Process policy consistency model, membership projection design, backfill execution strategy, replay proof approach all documented with rationale.

### 5. Expected Capability & Validation ✓

**New capability clear**: "Memba has explicit, rebuildable Group identities and memberships for its two existing conversation cohorts, plus a conversation-to-group write-access model."

**Proof of success**: Validation plan specifies focused tests, acceptance regression, backfill idempotency, and replay parity.

**Stop condition**: "Stop only when those focused tests, existing acceptance regressions, replay parity, idempotent automatic-backfill coverage, and `dev check` all pass on the committed implementation state."

---

## Summary

This is an exemplary iteration plan. It clearly separates the technical foundation work from future user-visible slices, provides concrete acceptance criteria that cover the critical consistency and idempotency concerns of event sourcing, explains the BDD decision with specific rationale, resolves all business decisions, and includes a detailed validation strategy with an explicit stop condition.

The plan demonstrates domain-driven design discipline: groups are conversation audiences, roles grant permissions, and the separation is preserved in both the event model and the code structure. The implementation steps are specific enough to guide work without over-specifying implementation details.

No blocking gaps. Ready for implementation.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}