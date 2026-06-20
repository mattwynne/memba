## Decision: NOT READY

## Confidence: High

## Blocking gaps

1. **The plan explicitly leaves implementation-shaping technical decisions unresolved.**  
   The `## Open Technical Decisions` section leaves follow storage, unsubscribe token mechanism, and reply-delivery factoring undecided. These affect data modeling, migrations/projections, URL/security behavior, tests, and integration boundaries, so the implementation plan is not fully ready.

2. **Follower permissions and membership edge cases are not defined/tested clearly enough.**  
   The plan says replies go to “current followers,” but does not explicitly state whether delivery is limited to current club members who follow the conversation, what happens when a follower leaves the club, or who is allowed to follow/unfollow. This is important for privacy and notification correctness.

3. **Email unsubscribe behavior is under-specified.**  
   The plan requires “stop following from a reply email,” but does not decide whether this is one-click tokenized, login-required, token-expiring, idempotent, or what happens for invalid/expired links. That is both a technical and user-workflow decision that should be settled before implementation.

## Non-blocking improvements

1. Name likely modules/files for the follow projection, command/event handling, reply fan-out, email template, controller/LiveView route, and acceptance step definitions.
2. Add explicit UI acceptance expectations for the follow/unfollow control: visible labels, state after action, and behavior for already-following/already-unfollowed users.
3. Clarify whether the quoted-thread email body is part of the required minimum for iteration 040 or a design refinement that can be validated separately.
4. Add a brief migration/backfill note if iteration 039 conversations already exist when this ships.

## Smallest viable iteration

The smallest useful slice is:

- Add per-conversation follow state.
- Auto-follow the original sender and any replier.
- Allow current members to follow/unfollow in-app.
- Send reply notification emails only to current club members who are current followers, excluding the reply author.
- Include a working stop-following link in reply emails.
- Validate with domain/email/acceptance tests and `dev check`.

Email thread-history polish and internal delivery refactoring can remain secondary if they are not needed to prove the follower-only delivery outcome.

## Required plan edits

1. Replace the `## Open Technical Decisions` section with concrete decisions, or decision rules precise enough for implementation:
   - chosen follow storage/projection approach;
   - chosen unsubscribe token/auth mechanism and route behavior;
   - chosen reply-delivery integration path.
2. Add acceptance criteria and scenarios covering membership/permission edges:
   - only eligible/current club members can follow;
   - former/non-current members are not emailed even if follow state exists;
   - unauthorized users cannot alter another member’s follow state.
3. Define email unsubscribe behavior:
   - whether it is one-click/tokenized or login-required;
   - idempotent behavior for already-unfollowed;
   - expected behavior for invalid/expired links.
4. Add the likely implementation touchpoints: event/command modules, projection/read model, email template, route/controller or LiveView action, and tests.

## Validation plan

To prove the iteration succeeded:

1. Domain tests verify:
   - original sender auto-follows;
   - replier auto-follows;
   - non-engaged member is not following by default;
   - follow/unfollow changes persisted state;
   - former/non-current members are not eligible recipients.
2. Email/integration tests verify:
   - replies are emailed only to eligible current followers;
   - reply author is excluded;
   - non-followers receive no email;
   - unfollowed members receive no future reply emails;
   - stop-following link works and is idempotent;
   - invalid/unauthorized unsubscribe links behave as specified.
3. UI tests verify:
   - message detail shows correct follow/unfollow state;
   - current member can follow and unfollow;
   - state updates correctly after action.
4. Acceptance tests:
   - revised `club_message_replies.feature` scenarios tagged for iteration 040 pass with temporary todo tags removed/narrowed.
   - preserved iteration 039 conversation/reply/membership scenarios remain green.
5. Full `dev check` passes.

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":3,"codex_review_blocking_gaps":"Open technical decisions remain for follow storage, unsubscribe token mechanism, and delivery factoring; Follower permissions and current-membership delivery edge cases are not defined/tested; Email unsubscribe workflow/security behavior is under-specified","codex_review_required_edits":"Resolve open technical decisions; Add acceptance criteria/scenarios for current-member eligibility and permission edges; Specify unsubscribe token/auth/idempotency/invalid-link behavior and likely implementation touchpoints"}}