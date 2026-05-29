Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 003 Add the application service that resolves recipients via Membership and`

2. **Changes made**
   - Added `web/lib/memba/messaging.ex` with `Memba.Messaging.send_club_message/2`.
   - The service:
     - Requires caller-supplied `message_id`, `club_id`, `sender_id`, `subject`, and `body`.
     - Resolves recipients via `Memba.Membership.list_active_members_of_club/1`.
     - Builds `Memba.Messaging.Recipient` structs with app-service-generated `delivery_id`s.
     - Dispatches `Memba.Messaging.Commands.SendMessage` through `Memba.Messaging.App`.
   - Added `web/test/memba/messaging/send_club_message_test.exs`.
     - Covers resolving exactly active members of the target club.
     - Proves members of other clubs are excluded.
     - Proves the service dispatches `SendMessage` and creates one delivery event per resolved recipient.

3. **Validation commands run**
   - `cd web && mix compile --warnings-as-errors` — passed.
   - Focused test inside devenv/Postgres:
     - `mix test test/memba/messaging/send_club_message_test.exs` — passed, `1 test, 0 failures`.
   - Required final check:
     - `PATH="$PWD/bin:$PATH" dev check` — passed, `69 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Add the application service that resolves recipients via Membership and`
   - To:
     - `- [x] 003 Add the application service that resolves recipients via Membership and`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0004: Service dispatches to the existing `Message` aggregate using the caller-supplied `message_id`.
   - ADR 0005: Recipients are resolved before `SendMessage` dispatch and included in the command.
   - ADR 0007: Messaging depends only on the public `Memba.Membership` query API, not Membership schemas/projections directly.
   - ADR 0011: `message_id` remains caller-supplied; delivery IDs are generated outside the aggregate by the application service.