# Iteration 039 Implementation Review

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation is consistent with the plan and with the project’s DDD/CQRS/event-sourcing direction. Conversation/reply behavior is modeled in `Memba.Messaging`, uses command/event/projection flow, preserves delivery receipts through the existing messaging delivery path, and keeps member UI work scoped to the message-detail/conversation surface.

## ADR violations

None identified.

Relevant conformance notes:

1. **ADR-0004 / bounded contexts**
   - Reply/conversation behavior belongs to `Memba.Messaging`.
   - Club membership authorization is enforced before replies are accepted.
   - No evidence of controller/LiveView-local domain state replacing bounded-context behavior.

2. **ADR-0005 / CQRS**
   - Replies are posted through commands/events.
   - Conversation display uses projected/read-model state.
   - Delivery observability continues through existing receipt machinery.

3. **ADR-0006 / event sourcing**
   - Reply posting is represented as domain events.
   - Conversation aggregate state is event-derived rather than persisted directly as write-side mutable state.

4. **Multi-tenancy / club isolation**
   - Message/conversation loading is scoped to club membership.
   - Non-members and mismatched club/message combinations are rejected or hidden as not found.

## Blocking issues

None.

The implementation appears plan-conforming, and the successful `dev ci` run gives adequate behavioral confidence for the intended iteration scope.

## Bounded-safe fixes

1. **Centralize conversation ID / stream derivation**
   - **File:** `lib/memba/messaging/router.ex`
   - **Issue:** Conversation identity appears to be derived inline with a literal prefix such as `"conversation-" <> command.root_message_id`.
   - **Fix:** Move this into a named function or module attribute, e.g. `Memba.Messaging.Conversation.conversation_id_for_root_message/1` or a private `conversation_id_for/1`.
   - **Why safe:** No behavior change; reduces future risk when iterations 040/041 build more on conversation identity.

2. **Consider extracting duplicated current-member validation**
   - **Files:** `lib/memba/messaging/aggregates/message.ex`, `lib/memba/messaging/aggregates/conversation.ex`
   - **Issue:** Current-member authorization logic appears duplicated between sending a root club message and posting a reply.
   - **Fix:** If the code remains identical, extract a small shared helper with tests preserving the existing authorization behavior.
   - **Why safe:** Low-risk deduplication if kept narrow. Avoid broad architectural changes in this iteration.

3. **Name reply email context construction explicitly if currently inline**
   - **Files:** reply delivery/email builder modules under the messaging/mailer path
   - **Issue:** Reply emails now need stable conversation context for 039 and will likely evolve in 040/041.
   - **Fix:** Keep subject/context formatting in a clearly named function rather than embedding it directly in fan-out/delivery orchestration.
   - **Why safe:** Maintains current behavior while making future follow/inbound-threading work easier.

## Judgement-worthy non-blocking code-health findings

1. **Aggregate authorization reaches across bounded contexts**
   - **Files:** `lib/memba/messaging/aggregates/conversation.ex`; existing analogue in `lib/memba/messaging/aggregates/message.ex`
   - **Smell:** Aggregate command execution appears to call `Memba.Memberships.current_member?/2` or equivalent.
   - **Why it may need human judgement:** From a strict event-sourcing/RDD perspective, aggregates are healthiest when decisions are made from aggregate state plus command data, not live reads into another context. However, this follows the existing message aggregate pattern and keeps the business rule close to the write model. Refactoring would affect both message sending and reply posting, so it should be a deliberate architecture decision, not a review-time cleanup.

2. **Conversation read path loads all replies**
   - **Files:** conversation projection/read API, `lib/memba_web/live/member_message_detail_live.ex`
   - **Smell:** The conversation screen appears to load and render the full reply history.
   - **Why it may need human judgement:** This is reasonable for the initial reply feature, but long-running conversations may eventually need pagination, windowing, or “load more” behavior. Not blocking because 039 is the first conversation iteration and expected initial volumes are likely small.

3. **Interim reply-all delivery is intentionally noisy**
   - **Files:** reply delivery/fan-out path
   - **Smell:** Replies are emailed to every current club member except the author.
   - **Why it may need human judgement:** This exactly matches the 039 plan, but the plan also calls out that it is an interim model before 040 narrows delivery to followers. Release sequencing matters; avoid leaving this behavior in production long-term unless the team consciously accepts reply-all noise.

4. **Conversation identity derived from root message identity**
   - **Files:** `lib/memba/messaging/router.ex`, conversation aggregate/projection modules
   - **Smell:** Conversation identity appears to be derived from the root message rather than modeled as an independently generated public/thread ID.
   - **Why it may need human judgement:** This is simple and appropriate for 039, but 040 follow state and 041 reply-by-email threading will build on it. Before adding more conventions around inbound email headers or followers, confirm this derived identity remains the intended long-term model.

## Suggested fixes

No required fixes before merge.

If applying polish now, prioritize:

1. Extract the conversation ID derivation into one named function.
2. Keep any reply email subject/context formatting behind named helper functions.
3. Defer aggregate authorization refactoring unless the team explicitly chooses to revisit the existing cross-context aggregate-query pattern.

Any code changes should be followed by a fresh `dev check` / `dev ci`.

## Validation notes

- Preflight sandbox check passed.
- Full project check passed via `dev ci`.
- Acceptance suite passed:
  - **86 scenarios passed**
  - **531 steps passed**
- Evidence indicates coverage for:
  - Current member posting a reply.
  - Non-member reply rejection.
  - Blank reply-body rejection.
  - Conversation loading with original message plus ordered replies.
  - Reply email delivery to current club members excluding the author.
  - Delivery receipt observability.
  - Member LiveView rendering of conversation and inline reply composer.
- No files were edited during this review.