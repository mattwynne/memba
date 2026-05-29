Implemented the next unchecked task.

1. **Selected todo line**
   - `- [ ] 004 Define the fake delivery provider port and wire it into the message`

2. **Changes made**
   - Added a channel-neutral provider boundary:
     - `web/lib/memba/messaging/delivery_request.ex`
     - `web/lib/memba/messaging/delivery_provider.ex`
   - Added supervised fake provider:
     - `web/lib/memba/messaging/delivery_providers/fake.ex`
     - Stores delivery requests in call order for ExUnit/Cucumber assertions.
   - Wired fake provider into application supervision/config:
     - `web/lib/memba/application.ex`
     - `web/config/config.exs`
   - Updated `Memba.Messaging.send_club_message/2` to:
     - Dispatch `SendMessage`.
     - Only call the provider after successful dispatch.
     - Call the provider once per resolved recipient delivery.
   - Added/updated tests:
     - `web/test/memba/messaging/delivery_providers/fake_test.exs`
     - `web/test/memba/messaging/send_club_message_test.exs`

3. **Focused validation commands run**
   - `cd web && mix format` — passed.
   - `cd web && mix compile --warnings-as-errors` — passed.
   - Focused tests inside devenv/Postgres:
     - `mix test test/memba/messaging/delivery_providers/fake_test.exs test/memba/messaging/send_club_message_test.exs`
     - Result: `3 tests, 0 failures`.
   - Required project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `71 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Define the fake delivery provider port and wire it into the message`
   - To:
     - `- [x] 004 Define the fake delivery provider port and wire it into the message`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0004: Kept one `Message` aggregate per message; provider wiring is outside aggregate state.
   - ADR 0005: Provider requests are built from the application-service-resolved recipients carried by `SendMessage`; request shape remains channel-neutral with `channel` and `recipient_address`.
   - ADR 0007: Messaging still depends on Membership only through `Memba.Membership.list_active_members_of_club/1`.
   - ADR 0011: Aggregate/message IDs remain caller-supplied; delivery IDs continue to be generated before aggregate dispatch, not by the aggregate.