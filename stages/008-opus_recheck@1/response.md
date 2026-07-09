## Decision: READY

## Confidence: High

## What Codex fixed successfully

- Verified the plan file was actually updated.
- Added the required `## Acceptance Scenarios / Feature Files` section.
- Named the relevant shared Cucumber feature files:
  - `acceptance-tests/features/club_message_replies.feature`
  - `acceptance-tests/features/list_members.feature`
- Specified scenario coverage for:
  - Club-home conversation preview text.
  - Removed “Recent club messages” heading.
  - Removed “Current members” heading.
  - Exactly one visible “Invite member” action.
  - Removed conversation-entry badges.
  - Removed duplicate “From {sender}” line.
- Added an explicit rationale for validating heading scale via targeted Phoenix/LiveView tests and gallery-walk instead of Gherkin CSS assertions.
- Tightened the heading acceptance criterion to reference `.page-title` scale.
- Clarified the observable capability while keeping the iteration correctly scoped as fidelity/polish work.

## Remaining blocking gaps

None.

The updated plan is implementation-ready: goal, scope, acceptance criteria, iteration type, acceptance feature coverage, implementation steps, technical decisions, expected outcome, and validation plan are all clear enough for an engineer to start without resolving additional material product or technical decisions.

## Follow-up repair instructions for Codex

None.

## Questions for Matt

None.

## Final validation plan

The iteration succeeds when:

1. Named acceptance scenarios in:
   - `acceptance-tests/features/club_message_replies.feature`
   - `acceptance-tests/features/list_members.feature`

   are updated or added and pass.

2. Automated Phoenix/LiveView/component tests confirm:
   - Club-home conversation rows render preview text from `message_row.body`.
   - Conversation-entry badges are absent.
   - The duplicate “From {sender}” meta line is absent.
   - “Recent club messages” and “Current members” headings are absent.
   - The Members tab renders exactly one visible “Invite member” action for a member who can manage members.
   - The conversation subject uses normal `.page-title` scale rather than hero-scale styling.

3. Visual validation via `./bin/dev gallery-walk` confirms the scoped UI matches the design of record for:
   - Club-home Conversations panel.
   - Club-home Members panel.
   - Member conversation page.

4. Manual spot-check confirms long message previews clamp to one line visually.

5. `dev check` passes.

{"context_updates":{"plan_ready":true,"plan_needs_fix":false,"plan_needs_human":false}}