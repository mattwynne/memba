## Decision: NOT READY

## Confidence: High

## Blocking gaps

1. **Missing required Acceptance Scenarios / Feature Files section.**  
   The plan explicitly classifies the iteration as “Behaviour-facing, presentation-only” and says it needs acceptance coverage, but it does not include an `## Acceptance Scenarios / Feature Files` section naming the shared Cucumber feature file(s)/scenario(s), nor does it give a rationale for why Gherkin would not add useful stakeholder-readable examples. The current generic reference to `acceptance-tests/features/*.feature` is not specific enough for readiness.

## Non-blocking improvements

1. **Clarify the exact visual target for “normal page heading.”**  
   The plan says the conversation subject should render as a normal page heading rather than a hero headline. It would be stronger if it named the intended class/scale, e.g. match `.page-title` or a specific Tailwind size.

2. **Reword “New Capability.”**  
   “None” is understandable for a polish/fidelity iteration, but the plan could better state the observable capability: members can now see conversation previews on club home, and the shipped UI matches the design of record for the listed elements.

3. **Name likely acceptance feature files directly.**  
   Even outside the required dedicated section, the implementation plan would be clearer if it named the likely feature files/scenarios rather than `acceptance-tests/features/*.feature`.

## Smallest viable iteration

The smallest useful slice is: **make the club-home Conversations panel match the design by showing one-line message previews and removing the “Recent club messages” heading**, with acceptance coverage and gallery-walk validation.  

That said, the currently proposed scope is still coherent and small enough because all items are low-risk presentation fidelity fixes from the same design-gap pass.

## Required plan edits

1. Add an `## Acceptance Scenarios / Feature Files` section.
2. In that section, name the specific shared Cucumber feature file(s) and scenario(s) that will cover:
   - Club-home conversation row previews.
   - Removed “Recent club messages” heading.
   - Removed “Current members” heading.
   - Exactly one visible “Invite member” action on the Members tab.
   - Removed conversation-entry badges.
   - Removed duplicate “From {sender}” meta line.
   - Conversation subject heading scale, if feasible via acceptance/visual coverage.
3. If any of the above are not suitable for Gherkin, explicitly state why and identify the alternate validation mechanism.

## Validation plan

Success should be proven by:

1. Updated acceptance scenarios in named feature file(s) for the member-visible presentation changes.
2. Targeted Phoenix/LiveView/component tests confirming:
   - Preview text renders from `message_row.body`.
   - Removed badges/meta/headings no longer render.
   - Members tab renders exactly one Invite-member action.
3. Visual validation via `./bin/dev gallery-walk`, comparing:
   - Club-home Conversations panel.
   - Club-home Members panel.
   - Member conversation page.
4. Full project validation with `dev check`.
5. Stop condition: all listed acceptance criteria pass, gallery screenshots match the design of record for the scoped elements, and `dev check` is green.

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":1,"gemini_review_blocking_gaps":"Missing required Acceptance Scenarios / Feature Files section naming shared Cucumber feature files/scenarios or giving rationale","gemini_review_required_edits":"Add Acceptance Scenarios / Feature Files section; Name specific feature files/scenarios for behaviour-facing UI changes or justify alternate validation"}}