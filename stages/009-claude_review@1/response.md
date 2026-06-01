# Iteration Plan Review

## Decision: NOT READY

## Confidence: High

## Blocking Gaps

1. **Incomplete reviewer context**: Required plan sections are omitted from the review context (lines 1-15 likely contain goal/title; lines 121-135 contain implementation steps 1-3). Cannot fully validate a plan when critical sections are not visible to the reviewer.

2. **Unresolved technical decisions**: The plan explicitly documents 7 open technical decisions that must be resolved before implementation:
   - Table/schema names for person email addresses
   - Whether to keep `membership_people.email` denormalized field
   - Database constraint strategy for "exactly one primary per person"
   - Command/event names for email address operations
   - Email editing approach (replace-all vs separate add/remove/change commands)
   - Legacy `PersonCreated` event replay strategy
   - Staff UI split between inline form and dedicated LiveViews

## Non-blocking Improvements

1. **Implementation step numbering**: Steps 1-3 are not visible in context (lines 121-135), but step 4 begins with "Update Membership person schemas." Consider ensuring steps 1-3 establish foundation work like migrations and schema definitions.

2. **Acceptance scenario detail**: The four named scenarios are descriptive but could benefit from Given/When/Then outlines in the plan to preview the test shape before writing the feature file.

3. **Migration rollback**: The validation plan covers migration/backfill but doesn't explicitly address rollback strategy if the migration fails partway through.

4. **Error message examples**: Acceptance criteria mention rejection of blank/malformed emails and duplicate addresses, but don't specify user-visible error messages. Consider documenting expected validation messages.

## Smallest Viable Iteration

The current scope is already reasonably focused. If forced to reduce:

**Defer staff UI changes**: Keep the inline person creation form on the admin club page rather than adding dedicated create/edit LiveViews. Focus iteration on:
- Backend email address support (schema, commands, events, projections)
- Authentication updates (multi-email sign-in, magic link delivery)
- Messaging updates (primary email resolution)
- Migration/backfill
- Backend tests and Cucumber scenarios

Add dedicated staff LiveViews in a follow-up iteration once the data model is stable.

However, I don't strongly recommend this split. The real blocker is resolving technical decisions, not scope size.

## Required Plan Edits

1. **Workflow fix**: Ensure the complete plan text is available to reviewers without omitted sections. The current chunking strategy hides lines 1-15 (likely goal/title), lines 61-75 (out-of-scope section), and lines 121-135 (implementation steps 1-3).

2. **Resolve technical decision 1**: Choose and document specific table/schema names (e.g., `membership_person_email_addresses` with columns `person_id`, `email_address`, `is_primary`, `inserted_at`).

3. **Resolve technical decision 2**: Decide whether to keep `membership_people.email` as a denormalized primary-email field or remove it. Document the choice and rationale.

4. **Resolve technical decision 3**: Choose the database constraint strategy for "exactly one primary per person" (e.g., partial unique index, check constraint, application validation). Document the approach.

5. **Resolve technical decision 4**: Define specific command/event names (e.g., `AddPersonEmailAddress`, `RemovePersonEmailAddress`, `ChangePersonPrimaryEmail`, or a single `UpdatePersonEmailAddresses` command).

6. **Resolve technical decision 5**: Choose whether email editing is one replace-all command or separate add/remove/change-primary commands. Document the choice.

7. **Resolve technical decision 6**: Define the legacy event replay strategy for old `PersonCreated` events containing only `email` (e.g., treat as primary email during backfill, add migration step to create email address records).

8. **Resolve technical decision 7**: Specify how much of the inline person creation form remains on the admin club page versus moving to dedicated LiveViews. Provide UI flow clarity.

9. **Update "Open Technical Decisions" section**: After resolving items 2-8, change this section to state "None" or move resolved items into a "Technical Decisions" section documenting the chosen approaches.

## Validation Plan

The plan's existing validation strategy is comprehensive and appropriate:

**Backend validation**:
- Migration/backfill tests proving existing emails become primary
- Membership domain tests for normalization, uniqueness, primary selection
- Accounts tests for multi-email sign-in and magic link delivery
- Messaging tests proving primary email resolution
- Database constraint tests

**Frontend validation**:
- LiveView tests for person create/edit forms, primary defaults, validation errors
- Staff UI tests for displaying primary/alternate addresses

**Integration validation**:
- Browser Cucumber scenarios in `person_email_addresses.feature` (remove `@wip` tag after implementation)
- Manual demo covering create, sign-in, message delivery, and primary-email change
- `dev check` green

**Success criteria**: When all acceptance criteria pass, Cucumber scenarios pass without `@wip`, manual demo works as described, and `dev check` is green, the iteration is complete.

**Missing validation**: Consider adding a rollback test to prove the migration can safely reverse if deployment issues occur.

---

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":2,"claude_review_blocking_gaps":"Required plan sections omitted from reviewer context (lines 1-15, 121-135); 7 open technical decisions remain unresolved and must be documented before implementation","claude_review_required_edits":"Ensure complete plan visible to reviewer; Resolve and document all 7 technical decisions (schema names, denormalization strategy, constraints, command/event names, editing approach, replay strategy, UI split); Update Open Technical Decisions section to None after resolution"}}