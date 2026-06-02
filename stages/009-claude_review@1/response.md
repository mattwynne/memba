# Iteration Plan Review: Person Email Addresses

## Decision: NOT READY

## Confidence: High

## Blocking Gaps

1. **Seven unresolved technical decisions block implementation**. The "Open Technical Decisions" section lists fundamental architectural and design choices that must be made before code can be written:
   - Table/schema names for email address projection
   - Whether to keep denormalized `membership_people.email` or use joins
   - Database constraint strategy for enforcing exactly one primary per person
   - Command/event naming for email operations
   - Command granularity (replace-all vs. separate add/remove/change-primary)
   - Legacy event replay strategy for old `PersonCreated` events
   - UI scope for inline vs. dedicated person creation

   These are not optional implementation details—they are core design decisions that affect what tables to create, what events to define, what queries to write, and what UI to build. Implementers cannot proceed without knowing the answers.

## Non-Blocking Improvements

1. **Email normalization rules could be more precise**. The plan mentions "trims whitespace and lowercases" but doesn't address plus-addressing (`alice+club@example.com`), subdomain handling, or whether normalization strips dots in Gmail addresses.

2. **Inactive member sign-in behavior is unspecified**. If someone requests a magic link with an email belonging to an inactive member, should they get a generic "no clubs found" message or explicit inactive-member feedback?

3. **Duplicate email error messages are not specified**. When staff tries to add an email already belonging to another person, what should the error message say?

## Smallest Viable Iteration

The current scope appears minimal for a useful outcome. You could theoretically split into:
- **Phase 1**: Database schema + staff create/edit UI only (no authentication changes)
- **Phase 2**: Authentication/lookup changes to use alternate emails

However, this would leave Phase 1 in a non-functional state where alternate emails exist but aren't used for sign-in. The current scope represents the right minimum viable change—all pieces are needed to deliver the core value.

## Required Plan Edits

The author must resolve all seven open technical decisions and document the chosen approaches in the plan before implementation:

### 1. Table/Schema Design
Decide and document:
- Table name (e.g., `membership_person_email_addresses`)
- Schema columns: `id`, `person_id`, `email`, `normalized_email`, `is_primary`, timestamps
- Whether `membership_people.email` remains as a denormalized primary email column or is replaced by joins to the email addresses table
- Projection module name (e.g., `Memba.Membership.Projections.PersonEmailAddress`)

### 2. Database Constraints
Decide and document:
- Unique index/constraint on `normalized_email` globally
- Constraint mechanism for "exactly one primary per person" (partial unique index on `(person_id) WHERE is_primary = true`? check constraint? trigger? application validation only?)
- Foreign key constraints and cascade behavior
- Whether null `normalized_email` is allowed (probably not)

### 3. Command/Event Design
Decide and document:
- Event names: 
  - Single `PersonEmailAddressesReplaced` with full email set?
  - Granular `PersonEmailAddressAdded`, `PersonEmailAddressRemoved`, `PersonPrimaryEmailChanged`?
  - Hybrid approach?
- Command names and parameter structures
- How staff edit operations map to events (one replace-all command or separate add/remove/change-primary commands?)
- Command validation rules

### 4. Legacy Event Replay Strategy
Decide and document:
- Exact approach for handling old `PersonCreated` events containing only `email` field during replay:
  - One-time migration that creates email address rows from existing `membership_people.email`?
  - Ongoing projection logic that handles both old and new event shapes?
  - Version-specific event upcasting?
- When/how the transition happens

### 5. UI Architecture
Decide and document:
- What remains on admin club show page: just a link to person edit? mini person card with primary email?
- Routes for new LiveViews: `/admin/people/new`, `/admin/people/:id/edit`?
- Form structure: dynamic form inputs for multiple emails? repeated email + primary checkbox pairs? email list with add/remove buttons?
- Where primary email selection appears: radio buttons? dropdown? implicit first-is-primary with reorder controls?

### 6. Update Implementation Plan
After resolving the above decisions, update the Implementation Plan section (currently steps 1-15) to reference the specific:
- Table names being created
- Migration file approaches
- Event/command names being defined
- Routes/LiveView modules being added
- Constraint mechanisms being used

Example revised step 3: "Add `membership_person_email_addresses` table via migration with unique index on `normalized_email` and partial unique index on `(person_id) WHERE is_primary` to enforce one primary per person. Add `Memba.Membership.Projections.PersonEmailAddress` schema."

## Validation Plan

The existing validation plan is comprehensive and does not need changes, assuming technical decisions are resolved. It appropriately covers:
- Unit tests for normalization, uniqueness, primary enforcement
- Integration tests for authentication, messaging, active member lookup
- Migration/persistence tests
- LiveView tests
- Browser Cucumber scenarios
- Manual demo with specific steps

The stop condition is clear: acceptance criteria met, `dev check` green, Cucumber scenarios passing with `@wip` removed.

---

## Summary

This plan demonstrates excellent practices in most areas:
- Clear goal and scope boundaries
- Comprehensive acceptance criteria covering happy paths, edge cases, validation, and integration
- Appropriate BDD decision with named Cucumber feature file and scenarios
- Detailed validation planning
- No unresolved business decisions

However, **seven fundamental technical decisions remain open** in a section explicitly labeled "Open Technical Decisions." These are not minor details—they are core architectural choices about data model, event design, constraints, and UI structure that determine what code to write. The plan cannot proceed to implementation until these are resolved and documented.

Once the author resolves these decisions and updates the implementation plan with specific table names, event names, constraint mechanisms, routes, and migration approaches, this plan will be ready.

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":1,"claude_review_blocking_gaps":"Seven unresolved technical decisions (table/schema names, email column strategy, constraint strategy, command/event design, command granularity, legacy event replay, UI scope)","claude_review_required_edits":"Resolve all open technical decisions and document chosen approaches for table schema, constraints, commands/events, legacy replay, and UI architecture; update implementation plan with specific names and mechanisms"}}