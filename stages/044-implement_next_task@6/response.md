1. **Selected todo line**
   - `006 Add a **Back to conversation** link on the delivery page returning to the message's conversation.`

2. **Changes made for this task only**
   - Added `#member-delivery-back-to-conversation-link` to `MemberMessageDeliveryLive.Show`.
   - The link points to the containing conversation root message:
     - original message → its own `/messages/:message_id`
     - reply message → root `/messages/:conversation_id`
   - Preserved club-host behavior and absolute club-site URL behavior via `ClubSite.url/2`.
   - Added focused LiveView test coverage proving a reply delivery page links back to the root conversation, not the reply’s own delivery/message id.
   - Checked off only task `006` in `docs/iterations/047-conversation-delivery-details/todo.md`.

3. **Focused validation commands run and results**
   - TDD failing check after adding the test:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
     - Failed as expected on missing `#member-delivery-back-to-conversation-link`.
   - Focused test after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
     - Passed: `3 tests, 0 failures`.
   - Formatting check:
     - `cd web && mix format --check-formatted lib/memba_web/live/member_message_delivery_live/show.ex test/memba_web/live/member_message_delivery_live/show_test.exs`
     - Passed.
   - Full validation on final worktree:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance suite: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 006 Add a **Back to conversation** link on the delivery page returning to the message's conversation.`
   - To:
     - `- [x] 006 Add a **Back to conversation** link on the delivery page returning to the message's conversation.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR files were present under `docs/adr/`.
   - Followed local Phoenix/LiveView/HEEx guidance:
     - Used HEEx component syntax.
     - Added a stable DOM id and tested with `has_element?/3`.
     - Kept the change focused on the selected delivery-page navigation task.
   - No acceptance feature files were changed.