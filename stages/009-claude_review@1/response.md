# Iteration 016 Plan Review: Person Email Addresses

## Decision: READY

## Confidence: High

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Add explicit Goal section**: While the goal is clear from "Background / Context" and "New Capability", adding a dedicated "## Goal" section with a single outcome-focused statement would improve readability. For example: "Goal: Enable persons to have multiple email addresses with one primary address for outbound delivery, while allowing authentication and membership checks against any known address."

2. **Test file path specificity**: Implementation step 19 says "Run targeted ... tests" but could optionally name specific test files (e.g., `test/memba/membership/person_email_addresses_test.exs`, `test/memba_web/live/admin/people_live_test.exs`). However, the current approach of naming test categories is sufficient given the project structure.

3. **Manual demo timing**: The manual demo in the Validation Plan could specify when it should be run (e.g., "after all tests pass and before marking iteration complete"), though the current placement implies this.

## Smallest Viable Iteration

The current scope represents the smallest useful increment. It cannot be meaningfully reduced because:

- **Data model alone** would leave staff unable to use the feature
- **UI alone** would be inconsistent with authentication/messaging behavior  
- **Skipping migration** would lose existing email data
- **Create-only** (no edit) would leave staff unable to fix mistakes
- **Single alternate** would require the same infrastructure as multiple

The iteration delivers a complete vertical slice: data model + commands/events + projections + queries + UI + auth integration + messaging integration + backward compatibility + tests. Each component depends on the others for coherent behavior.

## Required Plan Edits

**None.** The plan is implementation-ready as written.

## Validation Plan Assessment

The validation plan is thorough and specific:

### Automated Validation
- `dev check` (comprehensive)
- Targeted domain tests covering normalization, uniqueness, primary selection, and lookups
- Targeted Accounts tests for magic-link with alternates and delivery behavior
- Targeted Messaging tests for recipient resolution
- Migration/persistence tests for constraints
- LiveView/controller tests for forms and display
- Browser Cucumber with four named scenarios (after removing `@wip`)

### Manual Validation
Five-step demo that exercises the complete flow:
1. Staff creates Alice with primary + alternate
2. Alice requests sign-in link for alternate
3. Alice receives link at alternate and signs in
4. Bob sends message; Alice receives at primary
5. Staff changes primary; next message uses new primary

### Success Criteria
Clear stop condition: all acceptance criteria pass, Cucumber scenarios pass (without `@wip`), and `dev check` passes.

## Detailed Assessment

### 1. Goal Clarity ✓
The goal is clear from context: enable multiple email addresses per person to support future inbound email while maintaining single primary address for outbound delivery. Beneficiaries are explicit: members (sign in with any address), staff (manage addresses), future inbound capability. Minor improvement: could add explicit "## Goal" section.

### 2. Scope Focus ✓
Scope is well-defined with 16 in-scope items and 11 out-of-scope items. The iteration is appropriately sized—it delivers one coherent change (multi-email person model) with necessary UI, integration, and migration. Boundaries are crystal clear (no inbound webhook, no verification, no member self-service).

### 3. Acceptance Criteria & BDD ✓
- **BDD Decision**: Explicitly "Required" with four named Cucumber scenarios
- **Feature file**: `acceptance-tests/features/person_email_addresses.feature` with `@wip` tag during planning
- **Acceptance criteria**: 17 concrete, testable criteria covering:
  - Happy paths (create with multiple addresses)
  - Edge cases (blank, malformed, duplicates, no primary, multiple primary)
  - Permissions (staff-only create/edit)
  - Error states (validation failures)
  - Data changes (migration, address sets, primary selection)
  - Integration (auth, messaging, lookups)
- **Business decisions**: None unresolved; email verification explicitly deferred

### 4. Implementation Plan ✓
19 numbered steps with exceptional detail:
- Specific table name (`membership_person_email_addresses`)
- Schema module (`Memba.Membership.Projections.PersonEmailAddress`)
- Column definitions with types and constraints
- Command names (`ReplacePersonEmailAddresses`)
- Event names (`PersonEmailAddressesReplaced`)
- Route paths (`/admin/clubs/:club_id/people/new`, `/admin/clubs/:club_id/people/:person_id/edit`)
- Database constraints (unique indexes, partial unique, non-null)
- Migration strategy (backfill + denormalized primary)
- Query function names (`list_active_clubs_for_member_email/1`)
- Form behavior (radio buttons, defaults, validation)
- Test categories (domain, Accounts, Messaging, LiveView, migration, Cucumber)

All technical decisions are resolved and documented.

### 5. Expected Capability ✓
Clearly stated in "New Capability" section: "Memba can distinguish addresses that identify a person from the address Memba sends club messages to. Staff can manage that email-address set, members can sign in with any known address, and outbound club mail still goes once to the person's primary address."

Validation plan proves this through targeted tests and end-to-end manual demo.

## Risk Assessment

The plan explicitly documents risks and follow-ups:
- Shared household emails may require revisiting global uniqueness (intentionally deferred)
- Email verification needed before member self-service (out of scope)
- Member-facing display deferred to separate iteration
- Test helpers assume single email (noted for updating)
- Event replay must handle legacy `PersonCreated` events (solution provided)
- Future inbound email should use new query APIs (design guidance included)

Risk awareness is excellent. Mitigation strategies are provided where needed.

## Overall Assessment

This is an exemplary iteration plan. It demonstrates:
- Clear business value with concrete user outcomes
- Focused scope with explicit boundaries  
- Comprehensive acceptance criteria and BDD scenarios
- No unresolved decisions
- Exceptionally detailed implementation guidance
- Thorough validation approach
- Explicit risk acknowledgment

The plan is ready for implementation without modification.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}