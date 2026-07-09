- Decision: NOT READY
- Confidence: High

## Blocking gaps

1. The plan is behaviour-facing but does not include the required `## Acceptance Scenarios / Feature Files` section naming the shared Cucumber feature file(s)/scenario(s) that will express the changed member-visible rules, nor does it provide an explicit rationale for why Gherkin would not add value.

## Non-blocking improvements

1. The “New Capability” section says “None,” which is understandable for a fidelity iteration, but it would be clearer to state the observable post-iteration capability: members see club-home conversation previews and a conversation/member-list UI that matches the design more closely.
2. The “normal page heading” acceptance criterion could be made slightly more objective by naming the expected scale/class or explicitly saying it should match the design-system `.page-title` scale.
3. The validation plan could name the exact screenshots/pages to compare during gallery walk, though the current wording is probably sufficient.

## Smallest viable iteration

The smallest useful slice is the current focused presentation-fidelity slice, but only after adding the missing acceptance-scenario decision. It should remain limited to:

- Club-home conversation preview rendering.
- Removal of duplicate/obsolete headings, badges, meta line, and duplicate invite button.
- Conversation subject heading size adjustment.

Do not add member join dates, participant avatar stacks, About tab, staff console IA, or CSS architecture refactors.

## Required plan edits

1. Add a `## Acceptance Scenarios / Feature Files` section.
2. In that section, name the relevant `acceptance-tests/features/*.feature` file(s) and scenario(s) that will be updated or added for:
   - club-home conversation preview text,
   - absence of removed conversation-page badges/meta line,
   - absence of “Recent club messages” and “Current members” headings,
   - exactly one visible “Invite member” action on the Members tab for a manager.
3. If the team intentionally does not want Cucumber coverage for this presentation-only change, add an explicit stakeholder-readable rationale for why Gherkin would not add useful examples. Given the plan already says acceptance coverage is needed, naming the feature files/scenarios is the better edit.

## Validation plan

To prove success after implementation:

1. Automated tests confirm:
   - club-home conversation rows render `message_row.body`,
   - removed badges/headings/meta line are absent,
   - Members tab renders exactly one invite action when `@current_member_can_manage_members?` allows it,
   - relevant acceptance feature scenarios pass.
2. Visual validation:
   - run `./bin/dev gallery-walk`,
   - compare club-home Conversations/Members panels and member conversation page against `design-system/wireframes/club-home.html` and `design-system/wireframes/member-conversation.html`.
3. Full project validation:
   - run `dev check` and require it to pass.
4. Stop condition:
   - all listed UI deltas are implemented,
   - named acceptance scenarios are updated/passing,
   - gallery walk confirms the design-fidelity fixes,
   - `dev check` is green.

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":1,"codex_review_blocking_gaps":"Behaviour-facing plan lacks required Acceptance Scenarios / Feature Files section naming feature files/scenarios or giving rationale","codex_review_required_edits":"Add Acceptance Scenarios / Feature Files section naming relevant acceptance-tests feature files/scenarios for preview text, removed elements, and single Invite member action, or explicitly justify no Gherkin coverage"}}