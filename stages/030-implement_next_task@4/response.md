Implemented the next unchecked task: **004**.

1. **Selected todo line**
   - `004 Add a one-click signed stop-following (unsubscribe) link to the reply email, consistent with in-app unfollow; ensure unfollow halts future reply emails.`

2. **Changes made**
   - Added encrypted/signed long-lived stop-follow tokens:
     - `Memba.Messaging.ConversationStopFollowToken`
     - Token scope: `club_id`, `conversation_id`, `member_id`
     - Uses `Phoenix.Token.encrypt/4` with `max_age: :infinity`.
   - Added a Messaging API:
     - `Memba.Messaging.stop_following_conversation_from_email_token/2`
     - Verifies token scope against the conversation root.
     - Does not require sign-in/current membership.
     - Idempotently succeeds when already unfollowed.
     - Handles auto-follow projection state so stop-follow actually clears future reply delivery.
   - Added per-recipient `stop_follow_url` to reply email delivery requests.
   - Added reply email footer/text copy:
     - “You’re following this conversation.”
     - “Stop following this conversation”
   - Added no-login browser endpoint:
     - `GET /messages/conversations/stop-following/:token`
     - Success page with link back to the conversation.
     - Generic invalid-link failure page that reveals no club/conversation/member existence.
   - Extended shared email footer support for trusted extra footer detail HTML.
   - Added tests for:
     - Token opacity/tamper rejection.
     - Valid/reused/wrong-scope/invalid stop-follow links.
     - Stop-follow halting future reply email.
     - Dispatcher-generated stop-follow URLs scoped to the recipient.
     - Reply email text/HTML footer rendering.

3. **Focused validation commands/results**
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...`
     - Passed.
   - Direct focused test attempt:
     - `PATH="$PWD/bin:$PATH" bin/mix test ...`
     - Failed before tests due sandbox PGHOST mismatch (`/tmp/devenv/postgres` vs running `/tmp/devenv-...` socket).
   - Focused tests via devenv shell:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/messaging/conversation_stop_follow_token_test.exs test/memba_web/controllers/conversation_follow_controller_test.exs test/memba/messaging/email_delivery_dispatcher_test.exs test/memba/messaging/email_delivery_providers/postmark_test.exs`
     - Passed: `30 tests, 0 failures`.
   - Related follow/reply/provider tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/messaging/conversation_followers_test.exs test/memba/messaging/conversation_follow_projection_test.exs test/memba/messaging/post_message_reply_test.exs test/memba/messaging/email_delivery_providers/local_test.exs test/memba/messaging/email_delivery_providers/resend_test.exs`
     - Passed: `22 tests, 0 failures`.
   - Controller rerun after template class adjustment:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/controllers/conversation_follow_controller_test.exs`
     - Passed: `3 tests, 0 failures`.
   - Full check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Failed in acceptance: `86 scenarios (1 failed, 85 passed)`.
     - The remaining failure corresponds to the stale `club_message_replies.feature` rule still expecting “every current member” reply delivery; updating that feature is the next unchecked task 005.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Add a one-click signed stop-following (unsubscribe) link to the reply email, consistent with in-app unfollow; ensure unfollow halts future reply emails.`
   - To:
     - `- [x] 004 Add a one-click signed stop-following (unsubscribe) link to the reply email, consistent with in-app unfollow; ensure unfollow halts future reply emails.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No `docs/adr/*.md` files are present.
   - Kept write behaviour in `Memba.Messaging` application-service APIs.
   - Kept follow/unfollow state changes event-sourced through the existing Messaging commands.
   - Added the browser endpoint as a thin controller over the Messaging API.
   - Did not edit acceptance feature files; those are explicitly reserved for todo 005.