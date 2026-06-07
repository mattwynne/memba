Now I'll review this plan against all the readiness criteria.

---

# Iteration Plan Review: Membership Administrator Role Foundation

## Decision: READY

## Confidence: High

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Projection strategy clarification**: The plan lists "exact projection storage shape" as an open technical decision (line 148), but provides enough guidance ("preserve role/permission decoupling for future role assembly") that implementation can proceed. Consider adding an explicit preference (e.g., "start with normalized projections for roles, permissions, assignments, plus a flattened permission query optimization") if there's a strongly preferred approach.

2. **Staff authorization boundary example**: Line 149 mentions keeping staff authorization separate from club permissions. A brief example like "staff convert requests via platform authorization; club admins grant roles via `club.manage_members`" would reinforce the boundary, though the current guidance is sufficient.

3. **Scenario naming precision**: The Cucumber scenarios use clear Given/When/Then names but could specify exact permission checks in the scenario outline. However, the current scenario structure is concrete enough to implement.

## Smallest Viable Iteration

The plan is already at or near the smallest viable slice. Any reduction would create incomplete capability:

- Removing role assignment to another member would leave the foundation unvalidatable.
- Removing the last-administrator invariant would create a dangerous state gap.
- Removing authorization checks would make permissions unused scaffolding.

The current scope is appropriately minimal: one permission, one default role, role creation + assignment + authorization + invariant enforcement.

## Required Plan Edits

None.

The plan is ready for implementation without edits.

## Validation Plan

The plan includes a comprehensive validation strategy (lines 156-164):

**Pre-implementation:**
- Domain language review with Matt for the Cucumber feature

**During implementation:**
- ExUnit tests for role creation, permission grants, projection, authorization, and invariants
- Tests for requester becoming Membership Administrator during conversion
- Tests for granting/denying role assignment based on permission
- Tests for last-administrator protection

**Post-implementation:**
- New Cucumber scenarios pass with `@todo-domain`/`@todo-ui` removed
- Existing request-account scenarios still pass (regression protection)
- `dev check` passes (full suite)

This multi-layer validation covers unit, integration, acceptance, and regression concerns.

---

## Detailed Review Against Readiness Questions

### 1. Goal Clarity ✓

**Is the goal clearly articulated?**
Yes. Lines 6-10 state the goal: create the role/permission foundation, establish the default Membership Administrator role for new clubs, assign it to the approved requester/first member, and authorize behaviour through permissions rather than role-name checks.

**Does it state the user/business outcome, not just tasks?**
Yes. The goal emphasizes that "the approved requester/first member receives it" and that "implementation should authorize member-management behaviour through permissions," making clear the business outcome: club requesters gain membership-administration authority.

**Is the intended beneficiary or actor clear?**
Yes. The approved club requester/first member is the beneficiary who gains the new capability.

### 2. Scope Focus ✓

**Is the scope focused on one coherent outcome?**
Yes. The entire iteration delivers one outcome: club-scoped role/permission foundation with default Membership Administrator assignment.

**Could the iteration be any smaller while still useful?**
Barely. Removing any major component (role assignment to others, authorization checks, or last-administrator invariant) would make the foundation incomplete or unsafe. The plan explicitly excludes member-facing UI, custom role assembly, fine-grained permissions, and invite flows.

**Are non-goals and boundaries clear?**
Yes. Lines 50-59 explicitly list eight out-of-scope items, and lines 27-29 name three related problems that remain unresolved or only partially addressed.

### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✓

**Are acceptance criteria concrete, clear, complete, and objectively testable?**
Yes. Lines 93-106 provide 12 testable criteria covering:
- Permission existence and semantics
- Default role creation on club creation
- Role assignment during requester conversion
- Authorization for granting/revoking roles
- Last-administrator invariant
- Backward compatibility
- Scenario completion and `dev check` success

**Do they cover happy paths, important edge cases, permissions, error states, and data/state changes?**
Yes:
- Happy path: requester becomes administrator, administrator grants role to another
- Edge case: last administrator cannot be removed
- Permission denial: ordinary member cannot grant roles
- State change: role created, permission granted, assignment recorded
- Backward compatibility: existing onboarding continues working

**Does the plan classify the iteration as behaviour-facing or technical/engineering?**
Yes. Lines 61-65 classify it as "Behaviour-facing foundation iteration" and explain the reasoning: user-observable domain rules change (who can do what in a club).

**For behaviour-facing changes, does the plan include an Acceptance Scenarios section?**
Yes. Lines 67-85 provide:
- BDD decision rationale (stakeholder-readable role/permission examples)
- Feature file name
- Three Rules with four specific Scenarios
- Tag strategy (`@todo-domain`/`@todo-ui` during planning, removed after implementation)

**Are business/product/policy/copy/workflow decisions unresolved?**
No. Line 109 states "None known for this slice." Lines 112-118 list five confirmed decisions including role name, permission identifier, permission scope, who receives the role, and what's deferred to the next slice.

### 4. Implementation Plan and Technical Decisions ✓

**Are implementation steps clear, ordered, and specific?**
Yes. Lines 120-142 provide 16 numbered steps from inspection → design → commands/events → projection → authorization → tests → scenario completion → `dev check`.

**Are likely files, modules, migrations, tests, interfaces, and integration points named?**
Partially explicit, appropriately general:
- File: `acceptance-tests/features/club_membership_administration.feature` (line 75)
- Concepts: Membership event-sourced aggregate (line 122), projection tables/read models (line 132), ExUnit tests (line 140)
- The plan does not prescribe exact module names, which is appropriate for an event-sourced domain where exact aggregate and event shapes are open technical decisions

**Are data model, API, UI, workflow, integration, and background-job changes clear?**
- Data model: role definition, permission identifiers, role-permission grants, role assignments, permission projections (lines 124-128)
- API: permission check query/API (line 133)
- UI: explicitly out of scope (line 52); step definitions exercise domain/application behaviour without polished UI (line 139)
- Workflow: onboarding conversion enhanced with role assignment (line 131)
- Integration: authorization added to membership-management operations (line 134)
- Background jobs: not mentioned (none needed)

**Are technical decisions unresolved?**
Yes, four open decisions listed (lines 144-150):
- Event/command names
- Timing of default role assignment relative to onboarding conversion
- Projection storage shape
- Staff vs. club-member authorization boundary implementation

However, all four have sufficient guidance to proceed:
- Event/command names: open as "implementation details" but bounded by the stated events (role creation, permission grant, assignment)
- Timing: "prefer the simplest consistent event-sourced shape"
- Projection: "preserve role/permission decoupling for future role assembly"
- Staff authorization: "keep staff authorization separate"

These are appropriately deferred implementation details, not blocking unknowns.

### 5. Expected Capability and Validation ✓

**What should we be able to do after this iteration that we cannot do now?**
Clear. Lines 151-153: "Memba can represent and enforce a club-scoped Membership Administrator role built from a permission primitive. Newly approved club requesters become Membership Administrators of their clubs, and the system can distinguish ordinary members from members who can manage membership-administration authority."

**How will we prove success?**
Clear. Lines 156-164 specify:
- Pre-implementation domain language review
- Domain/application ExUnit tests during implementation
- Cucumber scenarios passing with tags removed
- Existing scenarios still passing
- `dev check` passing

**Is there a clear stop condition?**
Yes. Implicit from acceptance criteria + validation plan: all Cucumber scenarios pass, `dev check` passes, and the requester/first member has Membership Administrator authority.

---

## Summary

This plan meets all readiness criteria:

1. **Goal clarity**: User outcome is explicit (approved requester gains membership-administration authority).
2. **Scope focus**: Minimal viable foundation; non-goals are explicit.
3. **Acceptance criteria and BDD**: Concrete, testable, complete; behaviour-facing classification with required Cucumber scenarios and confirmed business decisions.
4. **Implementation plan**: Clear, ordered, specific steps; open technical decisions have sufficient guidance.
5. **Expected capability and validation**: New capability stated; multi-layer validation plan defined.

The iteration is appropriately scoped, well-reasoned, and ready for implementation.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}