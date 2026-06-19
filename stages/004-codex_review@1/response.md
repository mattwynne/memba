## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. The plan intentionally leaves a few implementation-level choices open, especially aggregate shape, follow storage, and reuse of the strong-consistency path. That is acceptable for readiness, but the implementer should decide these early before broad UI work.
2. Acceptance criteria could explicitly mention that non-current members cannot follow/unfollow either, since scope says follow authorization is limited to current club members.
3. Acceptance criteria could explicitly state the ordering basis for replies, e.g. posted-at/event order, to avoid ambiguity if multiple replies are close together.
4. The plan could clarify whether former members/non-members can read the thread or whether existing message-detail authorization already covers that.

## Smallest viable iteration

The planned slice is already a small, coherent iteration: in-app thread replies, ordered thread reading, member-only reply authorization, and stored follow/unfollow state, while excluding reply notification emails, reply-by-email, attachments, editing/deleting, reactions, and notification badges.

If it had to be reduced further, the smallest useful fallback would be: domain + read model + LiveView support for current members to post and read ordered in-app replies, with sender/replier auto-follow stored, deferring manual follow/unfollow UI. However, because iteration 040 depends on follow state, the current plan’s inclusion of follow/unfollow is reasonable and implementation-ready.

## Required plan edits

None required.

## Validation plan

Success should be proven by:

1. Domain tests for:
   - Current member can reply.
   - Non-current member cannot reply.
   - Blank reply body is rejected.
   - Reply is associated with the original club message thread.
   - Sender auto-follows.
   - Replier auto-follows.
   - Follow/unfollow state changes persist.

2. Projection/read-model tests for:
   - Loading original message plus replies.
   - Replies appearing in deterministic posted order.
   - Viewer follow state being returned correctly.

3. LiveView tests for:
   - Rendering original message and replies.
   - Showing inline body-only reply composer.
   - Posting a valid reply.
   - Showing validation for blank replies.
   - Showing and toggling follow/unfollow control.
   - Preserving delivery receipts behavior.

4. Acceptance validation:
   - `acceptance-tests/features/club_message_replies.feature` scenarios for iteration 039 pass with relevant temporary tags removed or narrowed.
   - Existing messaging acceptance scenarios remain green.

5. Final project validation:
   - `dev check` passes before implementation delivery.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}