## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Consider naming the likely test file(s) to update, e.g. the existing `MemberMessageLive.Show` LiveView test or component/template test location, if known.
2. Consider making the stop condition explicit in one sentence: implementation stops when the listed UI assertions pass, existing reply acceptance feature remains green, and the gallery-walk screenshot matches the synced wireframe.
3. Consider clarifying the exact visual/copy text for the collapsed delivery summary if the current summary copy has variants, though the plan’s reuse of existing summary copy is acceptable.

## Smallest viable iteration

The current slice is already a small, coherent, useful iteration: align only the member conversation/message-detail page presentation with the conversation wireframe, without changing follow, reply, delivery, permission, command, projection, staff/admin, email, or stop-following behaviour.

If forced smaller, the smallest still-useful slice would be: update only the member conversation page layout to show the follow toggle, collapsed delivery disclosure, replies header/count, reply timestamps, original sent date, and composer-after-replies, while preserving existing behaviour and card treatment.

## Required plan edits

None required.

## Validation plan

Prove success with the plan’s stated validations:

1. LiveView/component tests assert:
   - Follow control renders as a toggle.
   - Toggle reflects current follow state and drives the existing follow/unfollow events.
   - Delivery detail is collapsed by default.
   - Delivery detail expands and collapses through the server-driven `toggle_delivery` event.
   - Composer renders after replies and includes “Replying as”.
   - “Replies · N” appears with the correct count when replies exist.
   - Replies header and reply list are omitted when there are zero replies.
   - Each reply shows a posted timestamp.
   - Original-message meta shows the sent date.
   - Original message and replies remain boxed cards.

2. Existing `acceptance-tests/features/club_message_replies.feature` scenarios stay green, confirming behaviour did not change.

3. A `bin/dev gallery-walk` screenshot confirms the member message-detail page visually matches the synced `wireframes/member-conversation.html` direction.

4. Stop condition: all above validations pass, no command/projection/follow/reply behaviour changes are introduced, and the delivery detail remains reachable through the disclosure.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}