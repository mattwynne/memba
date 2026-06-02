Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KT2Z129Q0DEZ8YRC72N3Q9MD
Pipeline progress: 9 of 23 stages completed

## Stage: read_plan_001_060
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/016-person-email-addresses/plan.md' 1 60 360 'original plan chunk 001-060'`
- Output:
  ```
  (15 lines omitted)
  
  ## Background / Context
  
  Memba currently stores one `email` on each Membership person projection. That single value is used for several jobs: magic-link sign-in, finding active clubs for a signed-in email, checking active membership by email, and resolving outbound club-message recipients.
  
  Inbound email needs a more precise model. A person may have multiple legitimate sender addresses, but Memba should normally deliver each club message to one address per person. Separating known addresses from the primary sending address gives us that distinction.
  
  Relevant current implementation:
  
  - `Memba.Membership.Commands.CreatePerson`, `Memba.Membership.Events.PersonCreated`, `Memba.Membership.Person`, and `Memba.Membership.Projections.Person` currently carry one `email`.
  - `membership_people.email` is the existing projected email column.
  - `Membership.list_active_clubs_for_member_email/1` and `Membership.active_member_of_club_by_email?/2` match the single projected person email.
  - `Membership.list_active_members_of_club/1` returns one email per person for Messaging recipient resolution.
  - `Accounts.request_magic_link/1` uses Membership email lookup to decide whether a non-staff requester is known.
  - The existing admin club LiveView has an inline person creation form and people list; this iteration should move person create/edit into dedicated staff LiveViews linked from that staff/admin surface rather than expanding the inline form.
  
  ## Scope
  
  ### In scope
  
  - Add support for multiple normalized email addresses per person.
  - Ensure each person has exactly one primary email address.
  - Default the primary address to the first entered address for the common one-email case, while validating that exactly one primary address is selected on create/edit.
  - Treat the existing person `email` value as the initial primary email during migration/backfill.
  - Globally disallow duplicate normalized email addresses for now, so one email address cannot identify more than one person.
  - Use the primary email address for outbound club-message recipient resolution.
  - Let authentication/magic-link eligibility recognize any known email address attached to an active member.
  - Send a requested magic-link email to the known address the requester typed, including when that address is an alternate email address.
  - Let active-member-by-email checks recognize any known email address attached to an active member.
  - Add public Membership query APIs needed by Accounts and future inbound email sender matching.
  - Add database/projection support for person email addresses.
  - Add dedicated staff LiveViews for creating and editing people with primary and alternate email addresses, linked from the existing admin club/person surface.
  - Display a person's primary and alternate email addresses on staff/operator person surfaces.
  - Add tests for migration/backfill, normalization, uniqueness, primary selection, authentication lookup, active-member lookup, outbound recipient resolution, staff create/edit UI, and display.
  - Keep existing single-email flows working.
  - Keep `dev check` green.
  
  ### Out of scope
  
  - Postmark inbound email setup.
  - Inbound webhook controller.
  - Sending club messages by emailing a club address.
  - Email verification workflow for newly-added alternate addresses.
  - Member self-service email address management.
  - Member-facing display of primary or alternate email addresses; capture this as a follow-up iteration if needed.
  - Sending outbound club messages to more than one address per person.
  - Per-club email preferences.
  - Bounce-driven automatic primary-email changes.
  - Shared household email addresses or any policy that lets the same normalized email address belong to more than one person.
  - Ambiguous sign-in or inbound-sender disambiguation flows.
  ```

## Stage: read_plan_061_120
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/016-person-email-addresses/plan.md' 61 120 360 'original plan chunk 061-120'`
- Output:
  ```
  (15 lines omitted)
  - outbound club messages still go to one primary email address per active member.
  
  ## Acceptance Scenarios / Feature Files
  
  BDD decision: Required.
  
  This iteration changes identity, staff data-management, and message-delivery business rules. Add the following shared Cucumber feature file as stakeholder-readable acceptance criteria:
  
  - `acceptance-tests/features/person_email_addresses.feature` (`@wip` until this iteration is implemented)
    - `Alice signs in with her work email address`
    - `Alice receives a club message at her primary email address`
    - `Staff creates a person with primary and alternate email addresses`
    - `Staff changes a person's primary email address`
  
  The feature is tagged `@wip` during planning so default browser Cucumber excludes it until Fabro implements the behaviour and removes or narrows the tag.
  
  ## Allowed acceptance feature changes
  
  - `acceptance-tests/features/person_email_addresses.feature`: add the new `@wip` feature and scenarios listed above. Reason: these scenarios document the new identity, primary-email, and staff-management rules before implementation. Coverage is intentionally future-facing and excluded from default Cucumber while tagged `@wip`.
  - `acceptance-tests/test/cucumber_config.test.js`: update the configuration expectation so the new `@wip` feature is known to be skipped by the default browser Cucumber profile. Reason: planning-time `@wip` scenarios must not make the main check red before implementation.
  
  ## Acceptance Criteria
  
  - Existing people retain their current email address as their primary email after migration/backfill.
  - A person can have more than one normalized email address.
  - Email normalization trims whitespace and lowercases addresses consistently.
  - Blank or malformed email addresses are rejected.
  - A person has exactly one primary email address.
  - Primary email is one of the person's known email addresses.
  - The first entered email address is selected as primary by default for staff create/edit forms.
  - Staff create/edit validation rejects forms with no primary address or more than one primary address.
  - Duplicate normalized email addresses are globally rejected so an address cannot be attached to two people.
  - `Accounts.request_magic_link/1` accepts any known email address for an active member.
  - When a member requests a magic link using an alternate email address, the sign-in link is delivered to that alternate address.
  - A person who signs in with an alternate email still sees the clubs for their person record.
  - Membership email checks recognize any known email address for the person.
  - `Messaging.send_club_message/2` resolves each active member once and uses that member's primary email address for outbound delivery.
  - Existing member-message receipt and delivery projections still identify recipients by person, not by email address alone.
  - Dedicated staff create/edit LiveViews allow staff to create a person with primary and alternate email addresses and later edit the email set and primary selection.
  - Staff/operator UI displays a person's primary email and alternate email addresses.
  - Existing single-email authentication and member-message scenarios continue to pass.
  - `dev check` passes.
  
  ## Open Business Decisions
  
  None known.
  
  Deferred decisions:
  
  - Whether alternate email addresses must be verified before they can be used for sign-in or future inbound sending.
  ```

## Stage: read_plan_121_180
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/016-person-email-addresses/plan.md' 121 180 360 'original plan chunk 121-180'`
- Output:
  ```
  (15 lines omitted)
     - `person_id` foreign key to `membership_people.person_id` with `on_delete: :delete_all`;
     - `email` for the trimmed address used for display and delivery;
     - `normalized_email` for lowercase trimmed lookup;
     - `is_primary` boolean, default `false`, null `false`;
     - UTC timestamps.
  3. Add migration/backfill that creates one email-address row for every existing `membership_people.email`, sets it as primary, stores the lowercase trimmed value in `normalized_email`, and keeps `membership_people.email` as a denormalized primary-email field for compatibility and efficient recipient reads during this iteration.
  4. Add database constraints and matching changeset/command validation:
     - unique index on `membership_person_email_addresses.normalized_email` for global duplicate prevention;
     - partial unique index on `membership_person_email_addresses.person_id` where `is_primary = true` to enforce at most one primary address per person;
     - non-null constraints on `person_id`, `email`, `normalized_email`, and `is_primary`;
     - application/aggregate validation requiring at least one address and exactly one primary address before projection writes, because PostgreSQL cannot express “at least one primary child row” with a simple index.
  5. Evolve Membership commands/events using an atomic replace-all model:
     - keep `Memba.Membership.Commands.CreatePerson` accepting the existing `email` field for current callers and add optional `email_addresses` entries shaped as `%{email: binary, is_primary: boolean}` for new staff create forms;
     - keep `Memba.Membership.Events.PersonCreated` with `email` as the primary email for backward-compatible event replay;
     - add `Memba.Membership.Commands.ReplacePersonEmailAddresses` with `person_id` and `email_addresses`;
     - add `Memba.Membership.Events.PersonEmailAddressesReplaced` with `person_id`, normalized `email_addresses`, and `primary_email`;
     - have staff create with multiple addresses emit `PersonCreated` followed by `PersonEmailAddressesReplaced`; have staff edits emit `PersonEmailAddressesReplaced`.
  6. Add projector handling so:
     - legacy `PersonCreated` events create or upsert one primary `membership_person_email_addresses` row during replay;
     - `PersonEmailAddressesReplaced` replaces that person's projected email-address rows atomically;
     - `membership_people.email` is updated to the event's `primary_email` so old callers and outbound recipient reads continue to see the primary address.
  7. Update Membership public query APIs so callers can fetch a person's primary email, alternate emails, and lookup active memberships by any known address. `list_active_clubs_for_member_email/1` and `active_member_of_club_by_email?/2` must join `membership_person_email_addresses` on `normalized_email`; `list_active_members_of_club/1` must still return one row per active member with the primary email address.
  8. Enforce global duplicate normalized-email rejection before unsafe sign-in or sender matching can occur, using both application validation and the database unique index.
  9. Update Accounts sign-in eligibility to search all known addresses for active members, while preserving staff `@memba.io` sign-in behaviour.
  10. Ensure magic-link tokens and delivery use the normalized known address requested by the user, not necessarily the person's primary address.
  11. Update active-club lookup and active-member-by-email checks to match any known address attached to the person.
  12. Update Messaging recipient resolution to return one recipient per active member using the person's primary email address only.
  13. Add dedicated staff routes and LiveViews under the existing `/admin` staff LiveSession:
     - `live "/clubs/:club_id/people/new", PeopleLive.New` for creating a person and adding them to the club context shown by the route;
     - `live "/clubs/:club_id/people/:person_id/edit", PeopleLive.Edit` for editing the person's name, email-address set, and primary selection.
  14. Replace the existing inline person creation form on `MembaWeb.Admin.ClubsLive.Show` with a “New person” link to the create LiveView. Keep the people list on the club show page, show each person's primary email plus alternate-count or alternate-list summary, and add an “Edit” link for each person.
  15. Build the staff forms as repeated email rows with one primary radio button. Default the first entered address as primary for the common one-email case, reject blank/malformed addresses, reject no-primary and multiple-primary submissions, and show duplicate-email errors from validation/constraints.
  16. Update staff/operator person displays to show primary and alternate addresses distinctly.
  17. Update seeds, fixtures, browser acceptance support, and tests that create people to supply or derive the new email-address shape.
  18. Add/enable the planned Cucumber scenarios in `acceptance-tests/features/person_email_addresses.feature`; remove or narrow `@wip` once implemented.
  19. Run targeted Membership, Accounts, Messaging, LiveView, migration, and Cucumber checks, then `dev check`.
  
  ## Resolved Technical Decisions
  
  - Projected email-address table: `membership_person_email_addresses`.
  - Projection schema module: `Memba.Membership.Projections.PersonEmailAddress`.
  - `membership_people.email` remains as a denormalized primary-email field during this iteration. Known-address lookup reads from `membership_person_email_addresses`; primary-recipient reads may use either the primary email-address row or `membership_people.email`, but tests must prove they agree.
  - Database constraints: global unique index on `normalized_email`; partial unique index on `(person_id) WHERE is_primary = true`; non-null constraints on required columns. Aggregate/application validation enforces at least one address and exactly one primary address.
  - Command/event model: atomic replace-all, not separate add/remove/change-primary commands. Use `ReplacePersonEmailAddresses` and `PersonEmailAddressesReplaced`.
  - Legacy replay: `PersonCreated` with only `email` creates a single primary email-address row and keeps `membership_people.email` populated. New multi-address create emits `PersonCreated` plus `PersonEmailAddressesReplaced`.
  - Staff UI: the admin club show page keeps the people list but no longer owns inline person creation. It links to dedicated create/edit LiveViews at `/admin/clubs/:club_id/people/new` and `/admin/clubs/:club_id/people/:person_id/edit`.
  
  ## New Capability
  
  Memba can distinguish addresses that identify a person from the address Memba sends club messages to. Staff can manage that email-address set, members can sign in with any known address, and outbound club mail still goes once to the person's primary address.
  ```

## Stage: read_plan_181_240
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/016-person-email-addresses/plan.md' 181 240 360 'original plan chunk 181-240'`
- Output:
  ```
  PLAN_PATH=docs/iterations/016-person-email-addresses/plan.md
  PLAN_TOTAL_LINES=214
  PLAN_CHUNK=original plan chunk 181-240
  PLAN_CHUNK_LINES=181-240
  
  
  ## Validation Plan
  
  - Run `dev check`.
  - Run targeted Membership domain/projection/query tests for:
    - creating/backfilling person email addresses;
    - normalization and malformed-address rejection;
    - global duplicate normalized-email rejection;
    - exactly one primary address per person;
    - active-club and active-member lookup by alternate address.
  - Run targeted Accounts tests for:
    - magic-link request accepted for an alternate email address;
    - magic-link email delivered to the address requested;
    - staff `@memba.io` sign-in remains unchanged;
    - unknown email remains neutral and receives no link.
  - Run targeted Messaging tests proving club-message recipient resolution uses the primary address and sends once per person.
  - Run migration/persistence tests for email-address rows, uniqueness, and one-primary constraints.
  - Run staff LiveView/controller tests for person create/edit forms, primary selection defaults, validation errors, and display of primary/alternate addresses.
  - Run browser Cucumber with the new `person_email_addresses.feature` once the `@wip` tag is removed or narrowed during implementation.
  - Manual demo:
    1. Staff creates Alice with primary `alice@example.com` and alternate `alice@work.example`.
    2. Alice requests a sign-in link for `alice@work.example` and receives it there.
    3. Alice signs in and sees Kootenay Mountaineering Club.
    4. Bob sends a club message; Alice receives it at `alice@example.com`, not `alice@work.example`.
    5. Staff edits Alice to make `alice@work.example` primary; the next club message goes to `alice@work.example`.
  
  ## Risks / Follow-ups
  
  - Shared household email addresses are intentionally out of scope; global uniqueness may need revisiting when that policy is designed.
  - Email verification is out of scope here but will matter before members can self-add addresses.
  - Member-facing display or editing of known email addresses is deferred and captured in `docs/problems.md` as a separate account/profile problem to explore.
  - Existing test helpers and browser acceptance support assume a single `email` field on person projections.
  - Event-sourced history may contain old `PersonCreated` events without the new email-address shape. The implementation must handle replay deliberately.
  - Future inbound email should use the new sender-matching query rather than reimplementing email lookup in a controller.
  ```

## Stage: read_plan_241_300
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/016-person-email-addresses/plan.md' 241 300 360 'original plan chunk 241-300'`
- Output:
  ```
  PLAN_PATH=docs/iterations/016-person-email-addresses/plan.md
  PLAN_TOTAL_LINES=214
  PLAN_CHUNK=original plan chunk 241-300
  PLAN_CHUNK_LINES=241-300
  
  (no plan lines in this chunk)
  ```

## Stage: read_plan_301_360
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/016-person-email-addresses/plan.md' 301 360 360 'original plan chunk 301-360'`
- Output:
  ```
  PLAN_PATH=docs/iterations/016-person-email-addresses/plan.md
  PLAN_TOTAL_LINES=214
  PLAN_CHUNK=original plan chunk 301-360
  PLAN_CHUNK_LINES=301-360
  
  (no plan lines in this chunk)
  ```

## Stage: gemini_review
- Status: succeeded
- Handler: prompt
- Model: gemini-3.1-pro-preview
- Tokens: 12.0k in / 1.7k out
- Response:
  > {
  >   "context_updates": {
  >     "gemini_review_decision": "READY",
  >     "gemini_review_confidence": "High",
  >     "gemini_review_blocking_gap_count": 0,
  >     "gemini_review_blocking_gaps": "None",
  >     "gemini_review_required_edits": "None"
  >   }
  > }

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 6.4k in / 4.6k out
- Response:
  > # Iteration 016 Plan Review: Person Email Addresses
  > 
  > ## Decision: READY
  > 
  > ## Confidence: High
  > 
  > ## Blocking Gaps
  > 
  > None.
  > 
  > ## Non-blocking Improvements
  > 
  > 1. **Add explicit Goal section**: While the goal is clear from "Background / Context" and "New Capability", adding a dedicated "## Goal" section with a single outcome-focused statement would improve readability. For example: "Goal: Enable persons to have multiple email addresses with one primary address for outbound delivery, while allowing authentication and membership checks against any known address."
  > 
  > 2. **Test file path specificity**: Implementation step 19 says "Run targeted ... tests" but could optionally name specific test files (e.g., `test/memba/membership/person_email_addresses_test.exs`, `test/memba_web/live/admin/people_live_test.exs`). However, the current approach of naming test categories is sufficient given the project structure.
  > 
  > 3. **Manual demo timing**: The manual demo in the Validation Plan could specify when it should be run (e.g., "after all tests pass and before marking iteration complete"), though the current placement implies this.
  > 
  > ## Smallest Viable Iteration
  > 
  > The current scope represents the smallest useful increment. It cannot be meaningfully reduced because:
  > 
  > - **Data model alone** would leave staff unable to use the feature
  > - **UI alone** would be inconsistent with authentication/messaging behavior  
  > - **Skipping migration** would lose existing email data
  > - **Create-only** (no edit) would leave staff unable to fix mistakes
  > - **Single alternate** would require the same infrastructure as multiple
  > 
  > The iteration delivers a complete vertical slice: data model + commands/events + projections + queries + UI + auth integration + messaging integration + backward compatibility + tests. Each component depends on the others for coherent behavior.
  > 
  > ## Required Plan Edits
  > 
  > **None.** The plan is implementation-ready as written.
  > 
  > ## Validation Plan Assessment
  > 
  > The validation plan is thorough and specific:
  > 
  > ### Automated Validation
  > - `dev check` (comprehensive)
  > - Targeted domain tests covering normalization, uniqueness, primary selection, and lookups
  > - Targeted Accounts tests for magic-link with alternates and delivery behavior
  > - Targeted Messaging tests for recipient resolution
  > - Migration/persistence tests for constraints
  > - LiveView/controller tests for forms and display
  > - Browser Cucumber with four named scenarios (after removing `@wip`)
  > 
  > ### Manual Validation
  > Five-step demo that exercises the complete flow:
  > 1. Staff creates Alice with primary + alternate
  > 2. Alice requests sign-in link for alternate
  > 3. Alice receives link at alternate and signs in
  > 4. Bob sends message; Alice receives at primary
  > 5. Staff changes primary; next message uses new primary
  > 
  > ### Success Criteria
  > Clear stop condition: all acceptance criteria pass, Cucumber scenarios pass (without `@wip`), and `dev check` passes.
  > 
  > ## Detailed Assessment
  > 
  > ### 1. Goal Clarity ✓
  > The goal is clear from context: enable multiple email addresses per person to support future inbound email while maintaining single primary address for outbound delivery. Beneficiaries are explicit: members (sign in with any address), staff (manage addresses), future inbound capability. Minor improvement: could add explicit "## Goal" section.
  > 
  > ### 2. Scope Focus ✓
  > Scope is well-defined with 16 in-scope items and 11 out-of-scope items. The iteration is appropriately sized—it delivers one coherent change (multi-email person model) with necessary UI, integration, and migration. Boundaries are crystal clear (no inbound webhook, no verification, no member self-service).
  > 
  > ### 3. Acceptance Criteria & BDD ✓
  > - **BDD Decision**: Explicitly "Required" with four named Cucumber scenarios
  > - **Feature file**: `acceptance-tests/features/person_email_addresses.feature` with `@wip` tag during planning
  > - **Acceptance criteria**: 17 concrete, testable criteria covering:
  >   - Happy paths (create with multiple addresses)
  >   - Edge cases (blank, malformed, duplicates, no primary, multiple primary)
  >   - Permissions (staff-only create/edit)
  >   - Error states (validation failures)
  >   - Data changes (migration, address sets, primary selection)
  >   - Integration (auth, messaging, lookups)
  > - **Business decisions**: None unresolved; email verification explicitly deferred
  > 
  > ### 4. Implementation Plan ✓
  > 19 numbered steps with exceptional detail:
  > - Specific table name (`membership_person_email_addresses`)
  > - Schema module (`Memba.Membership.Projections.PersonEmailAddress`)
  > - Column definitions with types and constraints
  > - Command names (`ReplacePersonEmailAddresses`)
  > - Event names (`PersonEmailAddressesReplaced`)
  > - Route paths (`/admin/clubs/:club_id/people/new`, `/admin/clubs/:club_id/people/:person_id/edit`)
  > - Database constraints (unique indexes, partial unique, non-null)
  > - Migration strategy (backfill + denormalized primary)
  > - Query function names (`list_active_clubs_for_member_email/1`)
  > - Form behavior (radio buttons, defaults, validation)
  > - Test categories (domain, Accounts, Messaging, LiveView, migration, Cucumber)
  > 
  > All technical decisions are resolved and documented.
  > 
  > ### 5. Expected Capability ✓
  > Clearly stated in "New Capability" section: "Memba can distinguish addresses that identify a person from the address Memba sends club messages to. Staff can manage that email-address set, members can sign in with any known address, and outbound club mail still goes once to the person's primary address."
  > 
  > Validation plan proves this through targeted tests and end-to-end manual demo.
  > 
  > ## Risk Assessment
  > 
  > The plan explicitly documents risks and follow-ups:
  > - Shared household emails may require revisiting global uniqueness (intentionally deferred)
  > - Email verification needed before member self-service (out of scope)
  > - Member-facing display deferred to separate iteration
  > - Test helpers assume single email (noted for updating)
  > - Event replay must handle legacy `PersonCreated` events (solution provided)
  > - Future inbound email should use new query APIs (design guidance included)
  > 
  > Risk awareness is excellent. Mitigation strategies are provided where needed.
  > 
  > ## Overall Assessment
  > 
  > This is an exemplary iteration plan. It demonstrates:
  > - Clear business value with concrete user outcomes
  > - Focused scope with explicit boundaries  
  > - Comprehensive acceptance criteria and BDD scenarios
  > - No unresolved decisions
  > - Exceptionally detailed implementation guidance
  > - Thorough validation approach
  > - Explicit risk acknowledgment
  > 
  > The plan is ready for implementation without modification.
  > 
  > {"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}

## Stage: codex_review
- Status: failed
- Handler: prompt

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 0 |
| claude_review_blocking_gaps | None |
| claude_review_confidence | High |
| claude_review_decision | READY |
| claude_review_required_edits | None |
| failure_class | deterministic |
| failure_signature | codex_review|deterministic|api_deterministic|openai|invalid_request |
| gemini_review_blocking_gap_count | 0 |
| gemini_review_blocking_gaps | None |
| gemini_review_confidence | High |
| gemini_review_decision | READY |
| gemini_review_required_edits | None |


You are Claude Opus acting as the repair coordinator for an iteration plan validation loop.

Use the plan text and the three model reviews in context.

The reviewer stages must have exposed both their Markdown reports and these routing context fields. The reviewers run as separate model-review stages so these fields are visible to synthesis:

- Gemini: `gemini_review_decision`, `gemini_review_confidence`, `gemini_review_blocking_gap_count`, `gemini_review_blocking_gaps`, `gemini_review_required_edits`
- Claude: `claude_review_decision`, `claude_review_confidence`, `claude_review_blocking_gap_count`, `claude_review_blocking_gaps`, `claude_review_required_edits`
- Codex/GPT: `codex_review_decision`, `codex_review_confidence`, `codex_review_blocking_gap_count`, `codex_review_blocking_gaps`, `codex_review_required_edits`

Fail closed if you cannot see all three reviewer decisions and blocking-gap summaries. Missing reviewer evidence is a workflow/tooling failure for this validation pass, not proof that the plan is ready.

Your job in this stage is to decide whether the plan is ready, needs only obvious editorial/structural correction, or needs human product/technical decisions before it can be ready.

Readiness standard:

A plan is READY only if an engineer can begin implementation without first resolving material product/business decisions or material technical design decisions, and if a reviewer can objectively validate success at the end.

A plan is NOT READY if any of these are true:

- The goal is materially ambiguous.
- The scope is too broad or lacks a smallest useful slice.
- Acceptance criteria are not concrete/testable enough.
- The plan does not classify the iteration as behaviour-facing or technical/engineering.
- A behaviour-facing or domain-policy plan lacks an `## Acceptance Scenarios / Feature Files` section with either named shared Cucumber feature file(s)/scenarios or an explicit rationale for why Gherkin would not add useful stakeholder-readable examples.
- Important business decisions remain open.
- Implementation steps require major technical choices that are not made.
- The expected new capability or success validation is unclear.
- The plan expects shared acceptance `.feature` file edits but lacks a `## Allowed acceptance feature changes` section naming each exact file, the allowed kind of change, the reason, and how coverage is preserved or intentionally changed.

Correction policy:

Codex may only be asked to make obvious plan edits that do not require judgment calls, such as:

- tightening wording without changing meaning
- reorganizing existing content into clearer sections
- turning already-stated expectations into objective acceptance criteria
- making implicit boundaries explicit when the plan already clearly implies them
- removing duplication or contradiction when the intended meaning is obvious

Do not ask Codex to invent product policy, scope, UX, domain, data-model, integration, or technical-design decisions. If the plan needs those decisions, fail the validation and raise them for Matt.

Synthesis instructions:

1. First verify that all three reviewer decisions and blocking-gap summaries are visible in context. If any are missing, route to Matt/human input and explain that validation evidence was incomplete.
2. Compare the three reviews.
3. Include a reviewer decision table with each reviewer's decision, confidence, blocking gap count, and notes.
4. Identify consensus findings.
5. Correct reviewer findings that are wrong, too vague, duplicated, or not actually blocking.
6. Decide whether the plan is already ready, needs only obvious edits, or needs Matt's input.
7. If only obvious edits are needed, produce a concrete repair brief for Codex.
8. If Matt's input is needed, do not produce a repair brief as if Codex can solve it; list the decisions/questions clearly.

Voting/consensus guardrails:

- If two or more reviewers say NOT READY, you must not publish READY unless you explicitly quote or summarize each NOT READY blocker and explain why it is wrong or non-blocking.
- If any reviewer says NOT READY, include a `Reviewer objections addressed` section that accounts for every blocking gap from that reviewer.
- Do not treat successful reviewer node execution as readiness. Only the reviewer decision and findings content can support readiness.
- If your response cannot include a real synthesis report with the sections below, route to Matt/human input rather than READY.

Return a Markdown report with:

1. Provisional decision: READY, OBVIOUS FIXES NEEDED, or NEEDS MATT
2. Reviewer decision table: Reviewer, Decision, Confidence, Blocking gaps count, Notes
3. Consensus findings: 3-6 bullets
4. Reviewer objections addressed: account for every NOT READY blocking gap, or "No reviewer returned NOT READY"
5. Corrected findings: reviewer findings you changed, downgraded, combined, or rejected
6. Blocking gaps: numbered list, each with why it blocks implementation
7. Codex repair brief: exact instructions for obvious edits only, or "None"
8. Questions for Matt: decisions that need human input, or "None"
9. Validation checklist: what to check after any Codex update

At the end of your response, include one final JSON object for workflow routing. It must be the last thing in the response.

If the plan is already READY:

{"context_updates":{"plan_ready":true,"plan_needs_fix":false,"plan_needs_human":false}}

If the plan is NOT READY but Codex should apply only obvious fixes:

{"context_updates":{"plan_ready":false,"plan_needs_fix":true,"plan_needs_human":false}}

If the plan is NOT READY because Matt needs to answer questions or make decisions:

{"context_updates":{"plan_ready":false,"plan_needs_fix":false,"plan_needs_human":true}}
