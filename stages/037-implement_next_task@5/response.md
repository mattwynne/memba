Implemented the next unchecked task.

1. **Selected todo line**

   `- [ ] 005 Update the member message-detail LiveView/template: render the conversation and an inline reply composer (body only, inheriting the subject); keep delivery receipts available (demoting them per the sketch is acceptable but optional).`

2. **Changes made for task 005 only**

   - Updated member message detail loading to include:
     - ordered conversation entries from `Messaging.list_conversation_messages/1`;
     - sender display names for each conversation entry;
     - the signed-in current member for reply posting.
   - Updated `MemberMessageLive.Show` to:
     - initialize reply form state;
     - handle `post_reply`;
     - reject blank reply bodies;
     - post replies through `Messaging.post_message_reply/2` with `consistency: :strong`;
     - refresh the detail view after successful posting;
     - subscribe/refresh on projected message changes in the same conversation.
   - Updated `message.html.heex` to:
     - render the original message, then inline reply composer, then replies;
     - keep the legacy `#member-message-body` selector for existing browser tests;
     - keep delivery summary/receipt groups available below the conversation;
     - render a body-only reply form (no subject field).
   - Added/updated tests for:
     - conversation entries and current-member loading;
     - rendering conversation entries and reply composer;
     - blank reply validation;
     - successful reply posting as the signed-in member, including inherited subject and delivery receipt creation excluding the author.
   - Did **not** edit acceptance feature files; task 006 remains unchecked.

3. **Validation commands/results**

   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format ... --check-formatted`
     - Passed.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/member_message_detail_loader_test.exs test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_message_live/show_reply_test.exs test/memba_web/controllers/page_controller_test.exs`
     - Passed: `55 tests, 0 failures`.
   - Full final check on the exact final worktree:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `844 tests, 0 failures`
       - Acceptance: `82 scenarios (82 passed), 493 steps (493 passed)`

   Note: direct `bin/mix test ...` hit a sandbox Postgres socket readiness mismatch, so focused tests were run inside `devenv shell -- ...`.

4. **Exact todo check-off made**

   Changed only task 005 from:

   `- [ ] 005 Update the member message-detail LiveView/template: render the conversation and an inline reply composer (body only, inheriting the subject); keep delivery receipts available (demoting them per the sketch is acceptable but optional).`

   to:

   `- [x] 005 Update the member message-detail LiveView/template: render the conversation and an inline reply composer (body only, inheriting the subject); keep delivery receipts available (demoting them per the sketch is acceptable but optional).`

5. **Todo splits/additions/reordering**

   None.

6. **ADR conformance evidence**

   - ADR 0015 / ADR 0001: kept the member application surface in Phoenix LiveView and enhanced the existing member message LiveView rather than introducing a controller-only interaction.
   - ADR 0002 / ADR 0009: reply posting still goes through `Memba.Messaging.post_message_reply/2`; conversation display reads from projected read models via the Messaging query API.
   - ADR 0022: reply submission uses strong consistency before refreshing the projected conversation, preserving read-your-writes behaviour for the member flow.
   - Delivery receipts remain unchanged and visible; the task only reframed the member-facing message detail UI around the conversation.