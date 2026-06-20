## Decision: READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md`.

## Blocking gaps

None.

## Non-blocking improvements

1. The implementation plan could optionally name likely concrete Phoenix/EventStore modules, projections, mailer templates, routes, and LiveView/controller surfaces once implementation context is known.
2. The stop-follow token section intentionally leaves expiry mechanics to implementation. That is acceptable, but the implementer should document the actual chosen token helper/expiry behavior in tests or code comments.
3. The acceptance feature update plan is clear; implementation may benefit from explicitly splitting `@todo-domain` and `@todo-ui` removal into staged commits/tasks.

## Smallest viable iteration

The smallest useful slice is essentially the planned slice:

- Add conversation follow state.
- Auto-follow the original sender and repliers.
- Let current members follow/unfollow in-app.
- Change reply email fan-out from all current members to current club-member followers, excluding the author.
- Include a signed stop-follow link in reply emails.
- Validate with updated acceptance scenarios and `dev check`.

Removing any of those would either preserve the noisy reply-all behavior, omit the opt-in outcome, or leave recipients unable to stop notifications from email.

## Required plan edits

None. The plan is ready for implementation as written.

## Validation plan

Success should be proven by:

1. Updated `acceptance-tests/features/club_message_replies.feature` scenarios covering:
   - Sender auto-follow.
   - Replier auto-follow.
   - Non-engaged members not following by default.
   - Current members following/unfollowing.
   - Replies emailed only to current club-member followers.
   - Reply author excluded from delivery.
   - Former/non-current members excluded from delivery.
   - In-app unfollow stops later reply emails.
   - Email stop-follow link unfollows the intended recipient/conversation.
   - Invalid/tampered/wrong-scope/expired stop-follow links change nothing.

2. Domain/integration tests for:
   - Idempotent follow/unfollow.
   - Follow read model/projection correctness.
   - Auto-follow from conversation creation and reply events.
   - Recipient selection from current club-member followers only.

3. Email tests for:
   - Existing delivery tracking preserved.
   - Shared layout/footer preserved.
   - `<club name> via Memba` sender preserved.
   - Stop-follow footer link present and scoped correctly.

4. UI/browser tests for:
   - Follow/unfollow control visible with correct copy and state.
   - Current members can follow/unfollow.
   - Non-current/former members cannot newly follow.

5. Final stop condition:
   - Revised `@iteration-040` scenarios pass with temporary tags removed or narrowed appropriately.
   - Relevant 039 conversation/reply/membership scenarios remain green with the reply-audience rule superseded.
   - `dev check` passes.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}