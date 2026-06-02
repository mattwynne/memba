# Independent Plan Review: Person Email Addresses

## Decision: READY

## Confidence: High

## Blocking Gaps

None. The plan is comprehensive and ready for implementation.

## Non-Blocking Improvements

1. **Add explicit Goal section**: While the Background/Context explains the need and New Capability states the outcome, adding a dedicated "Goal" section with a single clear statement of the user/business outcome would improve clarity. For example: "Goal: Enable persons to have multiple email addresses while ensuring each person has exactly one primary address for outbound club messages."

2. **Enhance manual demo with negative case**: The manual demo (validation plan) is excellent but could add one negative test, such as: "Staff attempts to create a person with no primary email selected and sees validation error" or "Staff tries to add a duplicate email and sees rejection."

3. **Consider documenting denormalization trade-off**: The plan keeps `membership_people.email` as a denormalized field "for compatibility and efficient recipient reads." It might be worth explicitly noting whether there's a future plan to remove this denormalization or keep it permanently.

## Smallest Viable Iteration

The current scope **is** the smallest viable iteration. The plan appropriately defers:
- Inbound email webhook and controller
- Email verification workflow
- Member self-service management
- Bounce-driven changes
- Shared household addresses

Any attempt to further reduce scope would leave the system in an inconsistent state:
- Can't defer database/projection changes (foundation required)
- Can't defer command/event changes (needed to create multi-email people)
- Can't defer authentication updates (sign-in would break with alternate addresses)
- Can't defer staff UI (no way to create/manage the data)
- Can't defer messaging updates (would deliver to wrong address or multiple addresses)

The scope is large but coherent and necessary.

## Required Plan Edits

**None.** The plan is ready for implementation as written.

While adding an explicit Goal section would improve clarity, it's not blocking because:
- Background/Context clearly explains the business need
- New Capability section states the outcome
- Scope section comprehensively defines boundaries
- All acceptance criteria, technical decisions, and validation steps are clear

## Validation Plan Assessment

The validation plan is **exemplary**:

### Automated Validation
- `dev check` enforcement ✓
- Targeted domain tests for normalization, uniqueness, primary selection ✓
- Targeted Accounts tests for authentication and magic-link delivery ✓
- Targeted Messaging tests for recipient resolution ✓
- Migration/persistence tests for constraints ✓
- Staff LiveView tests for forms and validation ✓
- Browser Cucumber with named feature file and scenarios ✓

### Manual Validation
Five-step demo covering:
1. Staff creating multi-email person ✓
2. Sign-in with alternate address ✓
3. Club membership visible ✓
4. Message delivery to primary ✓
5. Primary address change and re-delivery ✓

### Success Criteria
Clear stop condition: all tests green, `dev check` passes, manual demo succeeds.

## Detailed Assessment

### 1. Goal Clarity: ✓ Strong
- Business need clearly explained in Background/Context
- Beneficiaries identified: inbound email system, members, staff
- Outcome stated in New Capability section
- Only improvement: explicit Goal section at top

### 2. Scope Focus: ✓ Excellent
- In scope: 9 specific capabilities with clear boundaries
- Out of scope: 10 deferred items with rationale
- Scope is large but coherent and minimal for the feature
- Cannot be reduced without breaking coherence

### 3. Acceptance Criteria: ✓ Exemplary
- **BDD Decision**: Explicit "Required" with rationale
- **Feature File**: Named with 4 specific scenarios, `@wip` tagged appropriately
- **Allowed Changes**: Documented for Cucumber config updates
- **Criteria Coverage**: 19 testable criteria covering:
  - Happy paths (multi-email create, sign-in, message delivery)
  - Edge cases (normalization, default primary selection)
  - Error states (malformed, duplicate, no/multiple primary)
  - Permissions (staff-only UI)
  - Data changes (migration, projections)
  - Backward compatibility (existing flows)
- **Business Decisions**: None open, deferred items explicitly noted

### 4. Implementation Plan: ✓ Excellent
- **Ordered**: 19 steps build from data layer → domain → consumers → UI
- **Specific**: Names exact modules, tables, commands, events, routes, LiveViews
- **Technical Decisions**: All resolved (table names, constraints, command model, routes)
- **Integration Points**: Clear updates to Membership, Accounts, Messaging, staff UI
- **Files Named**: Commands, Events, Schemas, LiveViews, queries, migrations
- **Data Model**: New table, constraints, denormalization strategy
- **APIs**: Query updates specified
- **UI**: Routes, LiveViews, form behavior, display changes
- **Migration**: Backfill strategy clear

### 5. Expected Capability: ✓ Clear
- **New Capability**: "Distinguish addresses that identify a person from the address Memba sends to"
- **Validation**: Multi-level automated and manual testing
- **Stop Condition**: Tests pass, `dev check` green, demo succeeds

## Risks and Follow-ups

The plan appropriately identifies and defers:
- Shared household addresses (policy revisit needed)
- Email verification (required before self-service)
- Member-facing display/editing (separate iteration)
- Test helper updates (handled in implementation)
- Event-sourced replay handling (deliberately addressed)
- Future inbound sender matching (uses new queries)

All risks acknowledged, none blocking.

## Conclusion

This is an **exemplary iteration plan** that meets or exceeds all readiness criteria:
- Clear business context and outcome
- Focused, minimal scope for coherent delivery
- Explicit BDD decision with named scenarios
- Comprehensive, testable acceptance criteria
- Detailed, ordered implementation steps
- All technical decisions resolved
- Thorough validation plan with multiple test levels
- Risks identified and appropriately deferred

The plan is ready for implementation without changes.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}