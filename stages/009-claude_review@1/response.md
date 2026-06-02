# Iteration Plan Review: Person Email Addresses

## Decision: READY

## Confidence: High

This is a thorough, well-structured iteration plan that addresses a foundational data model change with appropriate scope and detail.

## Blocking Gaps

None.

## Non-Blocking Improvements

1. **Magic-link token mechanism**: While step 10 states "Ensure magic-link tokens and delivery use the normalized known address requested by the user," and the acceptance criteria clearly require delivery to the requested alternate address, the plan could be more explicit about the mechanism. Specifically, clarify whether the token payload will embed the requested email or whether a database record will track which email address was requested alongside the token. This is solvable during implementation since the requirement is clear, but making the approach explicit would reduce implementation ambiguity.

## Smallest Viable Iteration

The current scope is already the smallest viable iteration. While you could theoretically split the data model from the staff UI, that would leave the new capability unusable by staff. Similarly, deferring magic-link-to-alternate-address would undermine a key value proposition (members signing in with any known address). The combination of:
- Data model + migration
- Staff create/edit UI  
- Auth lookup changes
- Messaging integration

represents the minimal set of changes needed to make multiple email addresses useful.

## Required Plan Edits

None. The plan is ready for implementation as written.

## Validation Plan

Execute the comprehensive validation plan detailed in the document:

1. **Automated testing:**
   - Run `dev check`
   - Run targeted Membership domain/projection/query tests for email address CRUD, normalization, uniqueness, primary selection, and lookup by alternate address
   - Run targeted Accounts tests for magic-link requests with alternate emails and delivery to the requested address
   - Run targeted Messaging tests proving recipient resolution uses primary email once per person
   - Run migration/persistence tests for email-address table, constraints, and one-primary enforcement
   - Run staff LiveView/controller tests for create/edit forms, validation errors, and display

2. **Acceptance testing:**
   - Run browser Cucumber with `person_email_addresses.feature` once `@wip` is removed during implementation
   - Verify the four planned scenarios: Alice signs in with alternate email, Alice receives messages at primary email, staff creates person with multiple addresses, staff changes primary address

3. **Manual demonstration:**
   - Staff creates Alice with primary `alice@example.com` and alternate `alice@work.example`
   - Alice requests sign-in link for `alice@work.example` and receives it there
   - Alice signs in and sees Kootenay Mountaineering Club  
   - Bob sends club message; Alice receives at `alice@example.com`
   - Staff changes Alice's primary to `alice@work.example`; next message goes there

**Stop condition:** All tests pass, dev check is green, Cucumber scenarios pass without `@wip`, and manual demo succeeds.

---

## Strengths of This Plan

1. **Clear goal and beneficiaries**: Distinguishes identity-matching emails from delivery-target email, serving members (alternate sign-in), staff (address management), and messaging (single primary delivery)

2. **Focused scope**: Addresses data model, staff UI, and auth integration without taking on inbound email, member self-service, or email verification

3. **Comprehensive acceptance criteria**: Covers migration/backfill, normalization, uniqueness, primary selection, alternate-email sign-in, message delivery, form validation, and UI display

4. **Proper BDD handling**: Declares "Required," names specific Cucumber scenarios, marks them `@wip` during planning, and updates `cucumber_config.test.js` expectations

5. **No unresolved decisions**: All business and technical decisions are resolved, with deferred questions (email verification, shared addresses) explicitly documented in Risks

6. **Detailed implementation steps**: 19 numbered steps with specific files (`PersonEmailAddress` schema, `ReplacePersonEmailAddresses` command, `/admin/clubs/:club_id/people/new` route), database constraints (global unique index on `normalized_email`, partial unique index for one primary), and integration points

7. **Migration safety**: Handles legacy `PersonCreated` event replay, keeps denormalized `membership_people.email` for compatibility, and tests that primary-email reads agree

8. **Clear new capability**: "Memba can distinguish addresses that identify a person from the address Memba sends club messages to."

This plan is implementation-ready.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}