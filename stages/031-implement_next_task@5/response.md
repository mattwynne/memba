Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Move sending behaviour into the LiveView submit event or a small shared service function:`

2. **Changes made**
   - Updated `web/lib/memba_web/live/member_message_live/new.ex`:
     - Added `phx-submit="send_message"` to `#member-message-compose-form`.
     - Added `handle_event/3` for `"send_message"`.
     - Generates a `message_id` before dispatch.
     - Sends via existing `Messaging.send_club_message/2` with `consistency: :strong`.
     - Derives `sender_id` from `socket.assigns.current_member.id`, ignoring any submitted sender params.
     - Tracks internal submit result assigns for later success/failure rendering:
       - `:compose_state`
       - `:sent_message_id`
       - `:send_error`
   - Added `web/test/memba_web/live/member_message_live/new_send_test.exs`:
     - Exercises the routed LiveView submit flow.
     - Proves a message is created with a generated UUID.
     - Proves sender is the signed-in member, even if submitted params include another sender.
     - Proves active members receive member receipts and fake delivery requests.

3. **Focused validation**
   - First ran the new focused test before implementation; it failed as expected because the form had no `phx-submit`.
   - Ran focused compose LiveView tests:
     - `MIX_ENV=test mix test test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_message_live/new_send_test.exs`
     - Result: `5 tests, 0 failures`
   - Ran required project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `236 tests, 0 failures`

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 005 Move sending behaviour into the LiveView submit event or a small shared service function:`
   - To:
     - `- [x] 005 Move sending behaviour into the LiveView submit event or a small shared service function:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No `docs/adr/*.md` files are present.
   - Followed local Phoenix/LiveView guidance:
     - Used `to_form`-backed form state.
     - Added a stable form ID and LiveView submit event.
     - Used LiveView test selectors and `render_submit`.
   - Kept scope limited to moving send behavior into the compose LiveView; success/failure UI rendering remains for later todo items.