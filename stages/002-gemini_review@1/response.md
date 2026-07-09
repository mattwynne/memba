## Decision: NOT READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/051-conversation-participant-avatar-stack/plan.md` through line 123. I did not edit files.

## Blocking gaps

1. **Missing required Acceptance Scenarios / Feature Files section.**  
   The plan correctly classifies the iteration as **Behaviour-facing**, but it does not include an `## Acceptance Scenarios / Feature Files` section naming the shared Cucumber feature file(s)/scenario(s) that will express the new stakeholder-visible rule. It only says to “Update the shared acceptance feature file(s)” and “acceptance coverage added,” which is not specific enough for the required workflow.

## Non-blocking improvements

1. The acceptance criteria are mostly clear, but they could explicitly call out the deduplication case: the same replier replying multiple times should appear once in the avatar stack.
2. The implementation plan could name the most likely acceptance feature file directly. Based on the existing suite, this appears likely to be `acceptance-tests/features/club_message_replies.feature`, under the existing club-home conversation rule.
3. The CSS scope says port `.conversation`, `.conversation__*`, and `.avatar-stack`; to avoid accidental broadening, the plan could clarify that only classes needed by the club-home conversation row should be ported in this iteration.

## Smallest viable iteration

Add the participant avatar stack to existing club-home conversation rows only: query distinct repliers excluding the originator, present the first three in first-reply order with a distinct-participant `+N` overflow, render them using the existing avatar component, port only the CSS classes needed for that row, and cover the behaviour in acceptance/unit tests.

## Required plan edits

1. Add an `## Acceptance Scenarios / Feature Files` section.
2. In that section, name the shared feature file and planned scenarios/rule updates, for example:
   - `acceptance-tests/features/club_message_replies.feature`
   - Existing rule: `Rule: On the club home, each conversation is one entry with its reply count`
   - Add scenarios for:
     - no replies shows no participant avatar stack;
     - 1–3 distinct repliers are shown in first-reply order;
     - the originator is excluded from the stack;
     - duplicate replies by the same participant are deduplicated;
     - 4+ distinct repliers show the first 3 plus a `+N` overflow badge.

## Validation plan

Success should be proven by:

1. Acceptance coverage for the club-home participant avatar stack in the named Cucumber feature file.
2. Automated tests for:
   - distinct participant query ordering;
   - deduplication;
   - originator exclusion;
   - cap of 3 visible avatars;
   - `+N` distinct-participant overflow count;
   - no-replies case.
3. Presentation/rendering tests confirming the club-home row emits the expected avatar stack and overflow badge.
4. Visual check with `./bin/dev gallery-walk` against `design-system/wireframes/club-home.html`.
5. Final `dev check` passing.

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":1,"gemini_review_blocking_gaps":"Missing required Acceptance Scenarios / Feature Files section naming the shared Cucumber feature file(s)/scenarios for this behaviour-facing change","gemini_review_required_edits":"Add an Acceptance Scenarios / Feature Files section naming acceptance-tests/features/club_message_replies.feature and scenarios for no replies, 1-3 repliers in first-reply order, originator exclusion, deduplication, and 4+ overflow"}}