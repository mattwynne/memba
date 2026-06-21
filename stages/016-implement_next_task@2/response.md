Implemented the next unchecked iteration task: **002**.

1. **Selected todo line**
   - `002 Rewire the reply delivery introduced in 039 from "all current members" to "current club-member followers of the conversation," excluding the author and excluding former/non-current members even when a historical follow record exists.`

2. **Changes made**
   - Updated reply recipient resolution in `Memba.Messaging`:
     - Replies now email only people who are both:
       - current active members of the root message’s club, and
       - currently following the conversation.
     - Reply author is excluded even if they follow.
     - Former/non-current followers are excluded.
     - Unfollowed members are excluded.
   - Updated `PostMessageReplyTest` to prove:
     - root sender auto-follow receives replies,
     - manually-following current members receive replies,
     - reply author is excluded,
     - unfollowed members are excluded,
     - former members with historical follow state are excluded,
     - followers from another club are excluded.
   - Added aggregate replay tolerance needed by follow events sharing the root conversation/message stream:
     - `ConversationFollowers` now applies `MessageSent` and ignores unrelated stream events.
     - `Message` now ignores `ConversationFollowed` / `ConversationUnfollowed`.

3. **Focused validation**
   - Formatting check:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/messaging.ex lib/memba/messaging/conversation_followers.ex lib/memba/messaging/message.ex test/memba/messaging/post_message_reply_test.exs`
     - **Passed**
   - Focused tests:
     - `devenv shell -- bin/mix test test/memba/messaging/post_message_reply_test.exs test/memba/messaging/conversation_follow_projection_test.exs test/memba/messaging/conversation_followers_test.exs test/memba/messaging/message_test.exs`
     - **Passed: 34 tests, 0 failures**
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - **Failed on the existing iteration-039 acceptance scenario** expecting every other member to receive replies. The new task-002 behavior correctly sends only to followers; revising that feature is explicitly pending as todo **005**.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Rewire the reply delivery introduced in 039 ...`
   - To:
     - `- [x] 002 Rewire the reply delivery introduced in 039 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No `docs/adr/*.md` files are present.
   - The implementation keeps the existing CQRS/event-sourced design: command-side behavior remains in aggregates, reply recipient selection uses projected read models, and delivery events remain generated through the existing Messaging command flow.