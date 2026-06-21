Implemented the next unchecked task: **003**.

1. **Selected todo line**
   - `003 Add the in-app follow/unfollow control + copy on the message-detail surface, reflecting the viewer's state and preventing non-current members from newly following.`

2. **Changes made**
   - Added current-member-only in-app follow/unfollow APIs:
     - `Memba.Messaging.follow_conversation_as_current_member/2`
     - `Memba.Messaging.unfollow_conversation_as_current_member/2`
   - Updated message-detail loading to assign:
     - `:following_conversation`
     - `:can_follow_conversation`
   - Added a message-detail follow/unfollow control below the original conversation message:
     - Shows “Follow conversation” when the viewer is not following.
     - Shows “Stop following” when the viewer is following.
     - Uses copy: “Follow this conversation to receive any new replies by email.”
     - Does not expose a follow action without current-member context.
   - Updated reply-composer copy from “current club members” to “current followers.”
   - Added LiveView event handlers for follow/unfollow and refresh on committed follow projection changes.
   - Added focused LiveView tests proving:
     - A non-engaged current member can follow/unfollow from message detail.
     - Reply auto-follow is reflected in the UI.
     - Former members cannot reach the in-app follow control.

3. **Validation run**
   - Initial TDD command:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/member_message_live/show_reply_test.exs`
     - Failed before tests due local Postgres readiness/PGHOST mismatch, so subsequent focused checks used `devenv shell --`.
   - Formatting:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix format --check-formatted ...`
     - Passed.
   - Focused LiveView tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/member_message_live/show_reply_test.exs`
     - Passed: `3 tests, 0 failures`.
   - Related member message detail tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/member_message_live/show_reply_test.exs test/memba_web/live/member_message_live/show_test.exs test/memba_web/member_message_detail_loader_test.exs`
     - Passed: `17 tests, 0 failures`.
   - Related messaging follow/reply tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/messaging/conversation_followers_test.exs test/memba/messaging/conversation_follow_projection_test.exs test/memba/messaging/post_message_reply_test.exs`
     - Passed: `12 tests, 0 failures`.
   - Full check, required because this task changes browser-facing UI:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Failed on the known pending acceptance update:
       - `features/club_message_replies.feature:31`
       - Scenario still expects every other member to receive Bob’s reply.
       - This is exactly the acceptance feature revision pending in todo **005**.

4. **Todo check-off made**
   - Changed only:
     - `- [ ] 003 Add the in-app follow/unfollow control + copy on the message-detail surface, reflecting the viewer's state and preventing non-current members from newly following.`
   - To:
     - `- [x] 003 Add the in-app follow/unfollow control + copy on the message-detail surface, reflecting the viewer's state and preventing non-current members from newly following.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Inspected relevant accepted ADRs: Commanded/CQRS, separate Membership/Messaging contexts, Ecto projections, LiveView member pages, committed read-model changes, and projection barriers.
   - Kept write behavior in Messaging commands/application service wrappers.
   - Used Membership’s public query API for current-member authorization.
   - Kept the member surface in LiveView and refreshed via committed read-model change notifications.
   - Did not edit acceptance feature files; those remain reserved for todo **005**.