Implemented the first unchecked iteration task.

1. **Selected todo line**
   - `001 Add follow/unfollow command(s)/event(s) and a per-(member, conversation) follow read model; auto-follow the sender on conversation creation and a replier on reply (from the 039 events).`

2. **Changes made**
   - Added `FollowConversation` / `UnfollowConversation` commands.
   - Added `ConversationFollowed` / `ConversationUnfollowed` events.
   - Added `Memba.Messaging.ConversationFollowers` aggregate with idempotent follow/unfollow behavior.
   - Added `messaging_conversation_follows` projection schema, migration, and strong projector.
   - Projector auto-follows `MessageSent.sender_id` for both root messages and replies.
   - Added public Messaging APIs:
     - `follow_conversation/2`
     - `unfollow_conversation/2`
     - `get_conversation_follow/2`
     - `following_conversation?/2`
     - `list_conversation_followers/1`
   - Registered new commands in the Messaging router.
   - Supervised the new projector and included it in event-sourced test/reset support.
   - Added `:conversation_follow` typed ID prefix.
   - Added/updated tests for aggregate behavior, projection behavior, auto-follow, public API contract, migration contract, and app wiring.

3. **Validation run**
   - `devenv shell -- bin/mix format --check-formatted ...` — passed.
   - `devenv shell -- bin/mix test test/memba/messaging/no_crud_spike_test.exs test/memba/messaging/conversation_followers_test.exs test/memba/messaging/conversation_follow_projection_test.exs test/memba/messaging/app_test.exs` — passed, 17 tests.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed on the final worktree state, 859 tests, 0 failures.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 ...`
   - To:
     - `- [x] 001 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference any ADRs, and no `docs/adr/*.md` files were present to inspect.
   - Implementation follows the existing Commanded/CQRS style in the Messaging bounded context: commands routed through `Memba.Messaging.Router`, domain events with `Jason.Encoder`, an aggregate for write behavior, and a Commanded Ecto projection for read state.