## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Move the “exact shape of latest-replier lookup” from **Open Technical Decisions** into the implementation plan if the author wants zero ambiguity, but it is not blocking because the plan explicitly says either approach is acceptable.
2. Add a validation note that the home row link still opens the root conversation/detail page, since the implementation plan says the target remains unchanged.
3. Consider adding an ExUnit assertion that reply rows are excluded from the dashboard presentation entirely, not only visually hidden.

## Smallest viable iteration

Implement exactly the described slice: on the member club home only, replace the raw message list with one row per root conversation, showing originator, original send date, reply count, latest replier when present, and no delivery glance. Leave conversation detail, email surfaces, stop-following pages, unread state, and staff/admin lists untouched.

## Required plan edits

None required.

## Validation plan

Success can be proven by:

1. Adding the planned Cucumber Rule/scenarios to `acceptance-tests/features/club_message_replies.feature`, initially tagged `@iteration-043 @todo-domain`, then making them pass and removing the todo tag during implementation.
2. Adding ExUnit coverage for `MemberDashboardPresentation` proving:
   - replies are grouped under the root conversation;
   - reply count includes all replies;
   - latest replier is shown for conversations with replies;
   - “No replies yet” is shown for conversations without replies;
   - ordering remains by original/root send time;
   - delivery-glance fields are absent from the home row model.
3. Verifying the HEEx output for the member club home renders the expected conversation row and no separate reply rows.
4. Running the gallery-walk screenshot check to confirm the “Saturday ridge walk” thread appears as a single row with its reply count.
5. Running the project’s required `dev check` after implementation.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}