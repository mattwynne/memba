## Decision: READY

## Confidence: High

## Blocking gaps

1. None.

## Non-blocking improvements

1. Add an explicit accessibility note for the toggle and delivery disclosure, e.g. label text, `aria-expanded`, and keyboard-operable disclosure behavior.
2. Add one acceptance/test note that existing permission/access behavior is unchanged, especially for users who can see the page but may not be able to follow/unfollow.
3. Clarify the exact date/timestamp format if the team wants pixel-level design consistency, though the plan’s “existing formatting helpers” is sufficient for implementation.
4. Consider naming the exact LiveView test file(s) if known, but the current module/template references are already specific enough.

## Smallest viable iteration

The smallest useful slice is the planned member conversation/message-detail presentation alignment only: update the follow control presentation, collapse delivery detail, move the composer below replies, add reply count/timestamps/sent date, keep card treatment, and validate with LiveView/component tests. Do not include conversations overview, staff/admin views, email surfaces, stop-following page changes, or behavior/domain-rule changes.

## Required plan edits

None required. The plan is ready for implementation.

## Validation plan

Prove success with:

1. LiveView/component tests for `MemberMessageLive.Show` / `PageHTML.message` covering:
   - Follow toggle renders, reflects current state, and still triggers existing follow/unfollow behavior.
   - Delivery detail is collapsed by default.
   - Delivery detail expands and collapses through the server-driven toggle.
   - Composer renders after replies and includes “Replying as <name>”.
   - “Replies · N” appears with the correct count when replies exist.
   - Reply header/list are omitted when there are zero replies.
   - Each reply shows a timestamp.
   - Original message meta shows the sent date.
   - Original message and replies remain boxed cards.
2. Existing `club_message_replies.feature` scenarios continue to pass, confirming behavior did not change.
3. `bin/dev gallery-walk` screenshot confirms the member message-detail layout matches the intended wireframe/design alignment.
4. Final project validation with the repo’s required `dev check` after implementation, because this will be a code/app-behavior surface change.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}