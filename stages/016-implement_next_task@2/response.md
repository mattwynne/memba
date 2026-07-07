1. **Selected todo line**
   - `002 Create MemberMessageDeliveryLive.Show that loads the target message and its receipt model via Messaging.list_member_email_deliverys/1 |> MemberEmailDeliveryPresentation.present_receipts/1, scoped to the member's active clubs (reuse the member_message_detail load pattern and authz).`

2. **Changes made for this task only**
   - Added `web/lib/memba_web/live/member_message_delivery_live/show.ex`
     - Defines `MembaWeb.MemberMessageDeliveryLive.Show`.
     - Reuses `MembaWeb.MemberMessageDetail.load/3`, preserving the selected active-club authorization and existing receipt loading/presentation path.
     - Handles host-selected `club_id` session params the same way as the conversation LiveView.
     - Provides a minimal render scaffold exposing the loaded message and receipt presentation model via stable IDs/data attributes. Full design/template work remains for later todos.
   - Added `web/test/memba_web/live/member_message_delivery_live/show_test.exs`
     - Proves the route loads the selected club message and presented receipt model.
     - Proves messages outside the selected active club are rejected with the same not-found behavior as the conversation authz pattern.

3. **Validation commands run and results**
   - TDD failing check before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
     - Failed as expected because `MembaWeb.MemberMessageDeliveryLive.Show` was undefined.
   - Focused passing check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
     - Passed: `2 tests, 0 failures`.
   - Required broad UI/LiveView validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance suite: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed exactly task `002` from:
     - `- [ ] 002 Create MemberMessageDeliveryLive.Show ...`
   - To:
     - `- [x] 002 Create MemberMessageDeliveryLive.Show ...`
   - No other ordinary todo lines were checked off.

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: Uses the Phoenix/Phoenix LiveView stack for the core app surface.
   - ADR 0006: Reuses the existing member-facing delivery presentation model instead of introducing new delivery status vocabulary.
   - ADR 0015: Implements the member-facing page as a LiveView.
   - ADR 0023: Keeps the delivery detail state URL-addressable at `/messages/:message_id/delivery`.