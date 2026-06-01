Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KT2RMKK25ZDT43FHF949BDTR
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
  4. Update Membership person schemas/projections and public query APIs so callers can fetch a person's primary email, alternate emails, and lookup active memberships by any known address.
  5. Evolve person commands/events deliberately:
     - support creating a person with one or more email addresses and exactly one primary;
     - support editing a person's email addresses and primary selection from staff UI;
     - handle legacy `PersonCreated` events containing only `email` during replay/backfill.
  6. Enforce global duplicate normalized-email rejection before unsafe sign-in or sender matching can occur, using both application validation and database constraints where practical.
  7. Update Accounts sign-in eligibility to search all known addresses for active members, while preserving staff `@memba.io` sign-in behaviour.
  8. Ensure magic-link tokens and delivery use the normalized known address requested by the user, not necessarily the person's primary address.
  9. Update active-club lookup and active-member-by-email checks to match any known address attached to the person.
  10. Update Messaging recipient resolution to return one recipient per active member using the person's primary email address only.
  11. Add dedicated staff LiveViews/routes for person create and edit. Link to them from the existing admin club/person list. Keep the common one-email case easy by defaulting the first entered address as primary while still making the primary choice explicit and validated.
  12. Update staff/operator person displays to show primary and alternate addresses distinctly.
  13. Update seeds, fixtures, browser acceptance support, and tests that create people to supply or derive the new email-address shape.
  14. Add/enable the planned Cucumber scenarios in `acceptance-tests/features/person_email_addresses.feature`; remove or narrow `@wip` once implemented.
  15. Run targeted Membership, Accounts, Messaging, LiveView, migration, and Cucumber checks, then `dev check`.
  
  ## Open Technical Decisions
  
  - Exact table/schema names for projected person email addresses.
  - Whether to keep `membership_people.email` as a denormalized primary-email field for compatibility/performance or replace reads with joins to the email-address projection.
  - Exact database constraint strategy for “exactly one primary per person”.
  - Exact command/event names for adding/removing/changing person email addresses.
  - Whether person email editing is implemented as one replace-all command or as separate add/remove/change-primary commands.
  - Legacy event replay strategy for old `PersonCreated` events that contain only `email`.
  - How much of the existing inline person creation form remains on the admin club show page versus becoming a link to the dedicated create LiveView.
  
  ## New Capability
  
  Memba can distinguish addresses that identify a person from the address Memba sends club messages to. Staff can manage that email-address set, members can sign in with any known address, and outbound club mail still goes once to the person's primary address.
  
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
  ```

## Stage: read_plan_181_240
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/016-person-email-addresses/plan.md' 181 240 360 'original plan chunk 181-240'`
- Output:
  ```
  PLAN_PATH=docs/iterations/016-person-email-addresses/plan.md
  PLAN_TOTAL_LINES=193
  PLAN_CHUNK=original plan chunk 181-240
  PLAN_CHUNK_LINES=181-240
  
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
  PLAN_TOTAL_LINES=193
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
  PLAN_TOTAL_LINES=193
  PLAN_CHUNK=original plan chunk 301-360
  PLAN_CHUNK_LINES=301-360
  
  (no plan lines in this chunk)
  ```

## Stage: gemini_review
- Status: succeeded
- Handler: prompt
- Model: gemini-3.1-pro-preview
- Tokens: 5.0k in / 2.3k out
- Response:
  > {"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":2,"gemini_review_blocking_gaps":"Required lines omitted from context (1-15, 61-75, 121-135); 7 open technical decisions remain unresolved (schema, events, constraints, replay strategy)","gemini_review_required_edits":"Ensure full plan text is visible to reviewer; Resolve and document all 7 open technical decisions"}}

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 5.5k in / 3.5k out
- Response:
  > # Iteration Plan Review
  > 
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > ## Blocking Gaps
  > 
  > 1. **Incomplete reviewer context**: Required plan sections are omitted from the review context (lines 1-15 likely contain goal/title; lines 121-135 contain implementation steps 1-3). Cannot fully validate a plan when critical sections are not visible to the reviewer.
  > 
  > 2. **Unresolved technical decisions**: The plan explicitly documents 7 open technical decisions that must be resolved before implementation:
  >    - Table/schema names for person email addresses
  >    - Whether to keep `membership_people.email` denormalized field
  >    - Database constraint strategy for "exactly one primary per person"
  >    - Command/event names for email address operations
  >    - Email editing approach (replace-all vs separate add/remove/change commands)
  >    - Legacy `PersonCreated` event replay strategy
  >    - Staff UI split between inline form and dedicated LiveViews
  > 
  > ## Non-blocking Improvements
  > 
  > 1. **Implementation step numbering**: Steps 1-3 are not visible in context (lines 121-135), but step 4 begins with "Update Membership person schemas." Consider ensuring steps 1-3 establish foundation work like migrations and schema definitions.
  > 
  > 2. **Acceptance scenario detail**: The four named scenarios are descriptive but could benefit from Given/When/Then outlines in the plan to preview the test shape before writing the feature file.
  > 
  > 3. **Migration rollback**: The validation plan covers migration/backfill but doesn't explicitly address rollback strategy if the migration fails partway through.
  > 
  > 4. **Error message examples**: Acceptance criteria mention rejection of blank/malformed emails and duplicate addresses, but don't specify user-visible error messages. Consider documenting expected validation messages.
  > 
  > ## Smallest Viable Iteration
  > 
  > The current scope is already reasonably focused. If forced to reduce:
  > 
  > **Defer staff UI changes**: Keep the inline person creation form on the admin club page rather than adding dedicated create/edit LiveViews. Focus iteration on:
  > - Backend email address support (schema, commands, events, projections)
  > - Authentication updates (multi-email sign-in, magic link delivery)
  > - Messaging updates (primary email resolution)
  > - Migration/backfill
  > - Backend tests and Cucumber scenarios
  > 
  > Add dedicated staff LiveViews in a follow-up iteration once the data model is stable.
  > 
  > However, I don't strongly recommend this split. The real blocker is resolving technical decisions, not scope size.
  > 
  > ## Required Plan Edits
  > 
  > 1. **Workflow fix**: Ensure the complete plan text is available to reviewers without omitted sections. The current chunking strategy hides lines 1-15 (likely goal/title), lines 61-75 (out-of-scope section), and lines 121-135 (implementation steps 1-3).
  > 
  > 2. **Resolve technical decision 1**: Choose and document specific table/schema names (e.g., `membership_person_email_addresses` with columns `person_id`, `email_address`, `is_primary`, `inserted_at`).
  > 
  > 3. **Resolve technical decision 2**: Decide whether to keep `membership_people.email` as a denormalized primary-email field or remove it. Document the choice and rationale.
  > 
  > 4. **Resolve technical decision 3**: Choose the database constraint strategy for "exactly one primary per person" (e.g., partial unique index, check constraint, application validation). Document the approach.
  > 
  > 5. **Resolve technical decision 4**: Define specific command/event names (e.g., `AddPersonEmailAddress`, `RemovePersonEmailAddress`, `ChangePersonPrimaryEmail`, or a single `UpdatePersonEmailAddresses` command).
  > 
  > 6. **Resolve technical decision 5**: Choose whether email editing is one replace-all command or separate add/remove/change-primary commands. Document the choice.
  > 
  > 7. **Resolve technical decision 6**: Define the legacy event replay strategy for old `PersonCreated` events containing only `email` (e.g., treat as primary email during backfill, add migration step to create email address records).
  > 
  > 8. **Resolve technical decision 7**: Specify how much of the inline person creation form remains on the admin club page versus moving to dedicated LiveViews. Provide UI flow clarity.
  > 
  > 9. **Update "Open Technical Decisions" section**: After resolving items 2-8, change this section to state "None" or move resolved items into a "Technical Decisions" section documenting the chosen approaches.
  > 
  > ## Validation Plan
  > 
  > The plan's existing validation strategy is comprehensive and appropriate:
  > 
  > **Backend validation**:
  > - Migration/backfill tests proving existing emails become primary
  > - Membership domain tests for normalization, uniqueness, primary selection
  > - Accounts tests for multi-email sign-in and magic link delivery
  > - Messaging tests proving primary email resolution
  > - Database constraint tests
  > 
  > **Frontend validation**:
  > - LiveView tests for person create/edit forms, primary defaults, validation errors
  > - Staff UI tests for displaying primary/alternate addresses
  > 
  > **Integration validation**:
  > - Browser Cucumber scenarios in `person_email_addresses.feature` (remove `@wip` tag after implementation)
  > - Manual demo covering create, sign-in, message delivery, and primary-email change
  > - `dev check` green
  > 
  > **Success criteria**: When all acceptance criteria pass, Cucumber scenarios pass without `@wip`, manual demo works as described, and `dev check` is green, the iteration is complete.
  > 
  > **Missing validation**: Consider adding a rollback test to prove the migration can safely reverse if deployment issues occur.
  > 
  > ---
  > 
  > {"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":2,"claude_review_blocking_gaps":"Required plan sections omitted from reviewer context (lines 1-15, 121-135); 7 open technical decisions remain unresolved and must be documented before implementation","claude_review_required_edits":"Ensure complete plan visible to reviewer; Resolve and document all 7 technical decisions (schema names, denormalization strategy, constraints, command/event names, editing approach, replay strategy, UI split); Update Open Technical Decisions section to None after resolution"}}

## Stage: codex_review
- Status: partially_succeeded
- Handler: prompt
- Model: gpt-5.3-codex
- Tokens: 13.8k in / 1.2k out
- Response:
  > {"outcome":"partially_succeeded","preferred_next_label":"revise_plan","context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":2,"codex_review_blocking_gaps":"Workflow evidence gap: plan chunks contain omitted lines so full text was not visible; Open Technical Decisions section leaves 7 implementation-defining decisions unresolved","codex_review_required_edits":"Provide complete plan text with no omitted lines for review; Resolve and document all 7 technical decisions (schema/table shape, denormalized primary email strategy, one-primary constraint approach, command/event design, edit semantics, legacy replay strategy, UI split); Update Open Technical Decisions to None (or replace with finalized Technical Decisions) and align implementation steps accordingly"}}

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 2 |
| claude_review_blocking_gaps | Required plan sections omitted from reviewer context (lines 1-15, 121-135); 7 open technical decisions remain unresolved and must be documented before implementation |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Ensure complete plan visible to reviewer; Resolve and document all 7 technical decisions (schema names, denormalization strategy, constraints, command/event names, editing approach, replay strategy, UI split); Update Open Technical Decisions section to None after resolution |
| codex_review_blocking_gap_count | 2 |
| codex_review_blocking_gaps | Workflow evidence gap: plan chunks contain omitted lines so full text was not visible; Open Technical Decisions section leaves 7 implementation-defining decisions unresolved |
| codex_review_confidence | High |
| codex_review_decision | NOT READY |
| codex_review_required_edits | Provide complete plan text with no omitted lines for review; Resolve and document all 7 technical decisions (schema/table shape, denormalized primary email strategy, one-primary constraint approach, command/event design, edit semantics, legacy replay strategy, UI split); Update Open Technical Decisions to None (or replace with finalized Technical Decisions) and align implementation steps accordingly |
| gemini_review_blocking_gap_count | 2 |
| gemini_review_blocking_gaps | Required lines omitted from context (1-15, 61-75, 121-135); 7 open technical decisions remain unresolved (schema, events, constraints, replay strategy) |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Ensure full plan text is visible to reviewer; Resolve and document all 7 open technical decisions |


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
