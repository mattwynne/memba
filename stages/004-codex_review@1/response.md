## Decision: NOT READY

## Confidence: High

I read the complete plan file directly: `docs/iterations/051-conversation-participant-avatar-stack/plan.md` lines 1–123.

## Blocking gaps

1. The plan is explicitly **behaviour-facing**, but it does not include the required `## Acceptance Scenarios / Feature Files` section naming the shared Cucumber feature file(s)/scenario(s), nor does it provide an explicit rationale for why Gherkin would not add useful stakeholder-readable examples. The plan only says “Update the shared acceptance feature file(s)” without naming them.

## Non-blocking improvements

1. The likely shared feature file should be named directly, probably `acceptance-tests/features/club_message_replies.feature`, under the existing club-home conversation rule.
2. The plan could name likely test modules/files for the query, presentation, and LiveView/template coverage.
3. Acceptance criteria are good overall, but could explicitly call out de-duplication when the same member replies multiple times.
4. The implementation plan says to port `.conversation__*`; if only a subset is required for this row, the plan could clarify whether all conversation row classes or only the row-relevant classes are intended.

## Smallest viable iteration

The smallest useful slice is: add participant data for club-home conversation rows, render a capped avatar-stack of distinct repliers excluding the originator, include `+N` overflow for more than 3 distinct repliers, and port only the CSS classes needed for that row. Leave unrelated conversation-detail CSS reuse and other design-gap work out of scope.

## Required plan edits

1. Add a section named `## Acceptance Scenarios / Feature Files`.
2. In that section, name the shared Cucumber file, likely `acceptance-tests/features/club_message_replies.feature`.
3. List the intended stakeholder-readable scenarios, for example:
   - Under the club-home conversation rule, a conversation with no replies shows no participant avatar-stack.
   - Distinct repliers appear in first-reply order and exclude the original sender.
   - More than 3 distinct repliers shows the first 3 avatars and a `+N` badge for the remaining distinct participants.
4. Optionally tag the scenarios with `@iteration-051`.

## Validation plan

Success should be proven by:

1. Cucumber/acceptance coverage in the named feature file for the avatar-stack rules.
2. Query tests proving distinct replier selection, originator exclusion, de-duplication, and first-reply ordering.
3. Presentation/rendering tests proving 0, 1–3, and 4+ participant states, including `+N`.
4. Visual comparison via `./bin/dev gallery-walk` against `design-system/wireframes/club-home.html`.
5. Full `dev check` passing.

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":1,"codex_review_blocking_gaps":"Behaviour-facing plan lacks required Acceptance Scenarios / Feature Files section naming shared Cucumber feature file(s)/scenarios or providing rationale","codex_review_required_edits":"Add ## Acceptance Scenarios / Feature Files; name the relevant shared Cucumber feature file, likely acceptance-tests/features/club_message_replies.feature; list scenarios for no replies, distinct ordered repliers excluding originator, and 4+ repliers with +N overflow"}}