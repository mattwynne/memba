## Decision: NOT READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md` lines 1–118.

The plan is strong and close to ready: the goal, user outcome, feature-file decision, and main behavioural rules are clear. However, two readiness gaps remain blocking because they affect security/workflow correctness for an in-scope email action and recipient authorization.

## Blocking gaps

1. **Reply-email stop-follow workflow/token behaviour is unresolved.**  
   The plan explicitly includes “stop following from a reply email,” but the unsubscribe token mechanism is still listed as an open technical decision. The acceptance criteria also do not specify whether the link is one-click, login-required, token-scoped, expiring, reusable, idempotent, or how invalid/expired/forged links behave. Because this is an email-originated state-changing action, this is a security/workflow decision that should be resolved before implementation.

2. **Reply-recipient eligibility is ambiguous around membership/authorization boundaries.**  
   The plan says replies go to “current followers,” but it does not explicitly state that recipients must also be current club members / authorized conversation participants. Iteration 039’s rule was “all current members”; replacing that with “followers” should preserve the current-member boundary unless intentionally changed. Acceptance criteria should cover or explicitly exclude cases like a former member who still has a follow record.

## Non-blocking improvements

1. Resolve or reframe the other open technical decisions. Follow storage and delivery-helper factoring can probably be left to implementation if the plan explicitly says they are implementer choices and gives constraints, but leaving them under “Open Technical Decisions” weakens readiness.

2. Add likely implementation touchpoints where useful: event/command modules, projections/read models, email template/module, message-detail LiveView/component, route/controller for email stop-follow, and relevant tests.

3. Add explicit idempotency expectations for follow/unfollow commands: following twice and unfollowing twice should not create inconsistent state or duplicate delivery.

4. Clarify whether auto-follow is derived from existing conversation/reply events, emitted as explicit follow events, or both. This matters for projections/backfills if iteration 039 conversations already exist.

## Smallest viable iteration

The smallest useful slice is:

- Per-conversation follow state.
- Auto-follow original sender and repliers.
- In-app follow/unfollow control.
- Reply fan-out only to current club members who are currently following, excluding the reply author.
- Tests/acceptance coverage for the follower delivery rule.

The email stop-follow link can remain in this iteration only if its token/workflow/security semantics are specified. Otherwise, it should be split into a follow-up slice.

## Required plan edits

1. Add a concrete “Reply email stop-follow behaviour” section specifying:
   - Whether the link is one-click or requires sign-in.
   - Token scope: member + conversation + club.
   - Expiry/reuse policy.
   - Idempotent behaviour when already unfollowed.
   - Invalid/expired/forged token behaviour.
   - Whether the response leaks conversation/member existence.
   - Required tests.

2. Clarify delivery eligibility as something like:  
   “A reply email is sent only to current club members who are currently following the conversation, excluding the reply author.”

3. Add acceptance criteria/scenarios for the membership boundary, for example:
   - A former/non-current member with a previous follow state does not receive reply emails.
   - An invalid stop-follow link does not change follow state.
   - A valid stop-follow link only unfollows the intended recipient from the intended conversation.

4. Update `Open Technical Decisions` so that blocking decisions are either resolved or explicitly delegated with safe constraints. At minimum, resolve the unsubscribe token/workflow decision before implementation starts.

## Validation plan

To prove the iteration succeeded:

1. Domain/integration tests cover:
   - Original sender auto-follows.
   - Replier auto-follows.
   - Non-engaged current member is not following by default.
   - Member can follow and unfollow.
   - Follow/unfollow is idempotent.
   - Replies are emailed only to current club-member followers.
   - Reply author is excluded.
   - Former/non-current members do not receive emails.
   - Unfollow stops future emails.

2. Email/security tests cover:
   - Reply email contains the correct follow status/footer and stop-follow link.
   - Valid stop-follow link changes only the intended member/conversation state.
   - Already-unfollowed link is safe/idempotent.
   - Invalid/expired/forged links do not change state.
   - Existing delivery tracking, layout/footer, and `<club name> via Memba` sender remain intact.

3. Acceptance:
   - Revised `acceptance-tests/features/club_message_replies.feature` scenarios tagged for iteration 040 pass with temporary todo tags removed or narrowed.
   - Preserved 039 conversation/reply/membership scenarios remain green, except for the superseded reply-audience rule.

4. Final stop condition:
   - All relevant tests pass.
   - `dev check` passes.

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":2,"codex_review_blocking_gaps":"Reply-email stop-follow workflow/token behaviour is unresolved; Reply-recipient eligibility around current club membership/authorization is ambiguous","codex_review_required_edits":"Specify stop-follow link token/workflow/security/idempotency/error behaviour and tests; Clarify delivery only to current club-member followers excluding author and add membership-boundary acceptance coverage"}}