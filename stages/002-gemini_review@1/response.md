## Decision: NOT READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md` lines 1–118.

## Blocking gaps

1. **Core technical decisions are explicitly unresolved.**  
   The plan’s `## Open Technical Decisions` section leaves follow storage, unsubscribe token mechanism, and reply-delivery factoring undecided. These are not merely incidental details: they affect data modeling, migrations/projections, security, email links, tests, and integration boundaries.

2. **Email stop-follow/unsubscribe behavior is not specified enough to implement safely.**  
   The plan requires members to stop following from a reply email, but does not define the authorization/token behavior, invalid/expired token handling, idempotency, whether login is required, success/failure UX, or behavior for former/non-current members.

3. **Follow/unfollow permissions and edge/error states are incomplete.**  
   Acceptance criteria cover happy paths and delivery outcomes, but do not objectively specify who may follow/unfollow a conversation, what happens if a non-member or removed member attempts it, or how repeated follow/unfollow commands behave.

## Non-blocking improvements

1. Name likely implementation files/modules/tests where possible, especially the messaging command/event modules, follow projection/read model, reply delivery path, email template, LiveView/controller surface, and acceptance/browser tests.
2. Add explicit UI state expectations for the message-detail follow control: initial state, followed state, unfollowed state, loading/error behavior if relevant.
3. Clarify whether the no-reply `Reply-To` guidance from the business decision should be asserted in tests for this iteration.
4. Add a brief migration/projection backfill note if existing conversations from iteration 039 may exist when this lands.

## Smallest viable iteration

The smallest useful slice is:

- Persist per-member/per-conversation follow state.
- Auto-follow the original sender and anyone who replies.
- Let a current member follow/unfollow from the conversation screen.
- Deliver new reply emails only to current followers, excluding the reply author.
- Provide one defined, secure email stop-follow mechanism.
- Prove the rule through domain/integration tests and the revised `club_message_replies.feature`.

Do not include digesting, batching, inbound reply-by-email, custom thread folding, or broader delivery-path refactoring unless required by the chosen implementation.

## Required plan edits

1. Resolve the `Open Technical Decisions` section by choosing:
   - the follow storage/projection approach,
   - the unsubscribe token/authentication approach,
   - whether reply delivery reuses the 039 path or introduces a shared delivery helper.
2. Add concrete acceptance criteria for email stop-follow behavior:
   - valid link,
   - invalid/expired/tampered link,
   - already-unfollowed link,
   - whether login is required,
   - success/failure user-visible outcome.
3. Add follow/unfollow permission criteria:
   - only current members can follow/unfollow,
   - behavior for former/non-members,
   - idempotent repeated follow/unfollow behavior.
4. Update the validation plan to include tests for those permission and token/error cases.

## Validation plan

Success should be proven by:

- Domain tests for auto-following sender/repliers, default non-follow state, manual follow/unfollow, idempotency, and permission rejection.
- Delivery tests showing replies go only to current followers and exclude the reply author.
- Email tests for footer copy, stop-follow link generation, valid stop-follow behavior, invalid/tampered token behavior, and no further emails after unfollowing.
- UI/browser tests for the conversation follow/unfollow control state transitions.
- Acceptance scenarios in `club_message_replies.feature` covering follower-only delivery, auto-follow, opt-in default, follow/unfollow, and unfollow-stops-email.
- Existing 039 conversation/reply/membership scenarios remaining green, with the old reply-all audience rule superseded.
- `dev check` passing.

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":3,"gemini_review_blocking_gaps":"Core technical decisions are explicitly unresolved; Email stop-follow/unsubscribe behavior is not specified enough to implement safely; Follow/unfollow permissions and edge/error states are incomplete","gemini_review_required_edits":"Resolve follow storage, unsubscribe token/authentication, and reply delivery implementation choices; Add concrete acceptance criteria for valid, invalid, expired/tampered, and repeated email stop-follow links; Add current-member permissions and idempotency criteria for follow/unfollow; Update validation plan with tests for permission and token/error cases"}}