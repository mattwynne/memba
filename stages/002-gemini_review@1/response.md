## Decision: NOT READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md` lines 1–113.

## Blocking gaps

1. **Open technical decisions are still unresolved and affect implementation shape.**  
   The plan explicitly leaves follow storage/read-model shape, unsubscribe token mechanism, and reply-delivery factoring open. At least the first two affect schema/projections, security boundaries, routes/controllers, tests, and acceptance behaviour. This is not just refactoring latitude; implementers need a settled direction or explicit constraints before starting.

2. **Permission/member-lifecycle and error-state behaviour is not fully specified.**  
   The plan says replies go to “current followers,” but does not clearly state whether the actual recipient set is `followers ∩ current club members`, what happens if a follower later leaves the club, or whether non-current members may follow/unfollow. It also does not define invalid/expired/unauthorized email unsubscribe link behaviour. These are important privacy and permissions edge cases for notification email delivery.

## Non-blocking improvements

1. Name likely implementation files/modules more concretely, such as the messaging command/event modules, projection/read model, email template, mailer/delivery code, route/controller or LiveView handler, and tests.
2. Clarify idempotency expectations for repeated follow/unfollow commands.
3. Define exact user-facing copy for followed/unfollowed states and the email stop-following link.
4. Clarify whether “unfollow” removes the follow relationship or records an explicit unfollow state, especially after auto-follow events.

## Smallest viable iteration

The smallest useful slice is: per-conversation follow state for current club members; auto-follow original sender and repliers; in-app follow/unfollow; reply fan-out to current club-member followers excluding the reply author; an email stop-following link; and BDD/domain/email tests proving non-followers and former/non-current members do not receive replies.

Defer digesting, reply-by-email, advanced notification preferences, and any optional email redesign beyond what is needed for the reply notification and stop-following link.

## Required plan edits

1. Resolve the “Open Technical Decisions” section before implementation:
   - Choose the follow storage/projection approach.
   - Choose the unsubscribe token mechanism and security properties.
   - State whether delivery reuses the 039 path or is factored through a helper/boundary.
2. Add explicit acceptance criteria and scenarios for permissions/member lifecycle:
   - Only current club members can follow/unfollow.
   - Reply recipients are current club members who are following the conversation, excluding the author.
   - Former/non-current members who previously followed are not emailed.
   - Invalid, expired, or unauthorized stop-following links fail safely.
3. Add enough implementation pointers to identify expected modules, migrations/projections, routes/handlers, mailer/template changes, and tests.

## Validation plan

Prove success with:

1. BDD scenarios in `acceptance-tests/features/club_message_replies.feature` for:
   - Sender auto-follows.
   - Replier auto-follows.
   - Non-engaged member is not following by default.
   - Member can follow and then receives future replies.
   - Member can unfollow in app and receives no further replies.
   - Member can stop following from email and receives no further replies.
   - Former/non-current follower receives no reply email.
2. Domain/integration tests for follow/unfollow state, auto-follow events, idempotency, and recipient selection.
3. Email tests proving only eligible followers are delivered to, the author is excluded, delivery tracking and sender remain intact, and the stop-following link works/fails safely.
4. Existing 039 conversation/reply/membership tests remain green with the superseded reply-audience rule updated.
5. Full `dev check` passes.

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":2,"gemini_review_blocking_gaps":"Open technical decisions affect storage/security/delivery shape; Permission/member-lifecycle and unsubscribe error-state behaviour is underspecified","gemini_review_required_edits":"Resolve follow storage, unsubscribe token, and delivery-path decisions; Add acceptance criteria/scenarios for current-member-only delivery/following, former members, and invalid or unauthorized unsubscribe links; Name expected modules/migrations/routes/templates/tests"}}