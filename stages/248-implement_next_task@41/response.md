Implemented the next unchecked task.

1. **Selected todo line**
   - `012 Add idempotency behaviour: if the same provider/provider message id is received again, return an accepted webhook response and do not emit another MessageSent, create another club message, or send duplicate outbound/rejection emails.`

2. **Changes made**
   - Updated `Memba.Messaging.receive_inbound_club_email/2` to dispatch `ReceiveInboundEmail` with `returning: :execution_result`.
   - Detects duplicate provider message IDs from the event-sourced inbound email aggregate result (`events: []`) before resolving/sending.
   - Duplicate receives now return `{:ok, %{duplicate?: true, status: ..., message_id: ...}}` without creating another club message or sending provider deliveries.
   - Added focused test coverage proving:
     - duplicate provider message IDs return accepted/ok,
     - only one projected club message exists,
     - fake outbound deliveries are not duplicated,
     - only one `MessageSent` event exists,
     - only one `InboundClubEmailAccepted` event exists,
     - the original inbound source projection remains tied to the first accepted event.

3. **Validation run**
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/messaging/inbound_club_message_acceptance_test.exs test/memba/messaging/inbound_email_dispatch_test.exs test/memba/messaging/inbound_email_receipt_test.exs test/memba/messaging/inbound_email_source_projection_test.exs test/memba/messaging/send_club_message_test.exs`
     - Result: `16 tests, 0 failures`
   - Formatting:
     - `PATH="$PWD/bin:$PATH" devenv shell -- mix format --check-formatted`
     - Result: passed
   - Full required check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `433 tests, 0 failures`; `31 scenarios (31 passed)`

4. **Todo check-off made**
   - Changed exactly task 012 from `- [ ]` to `- [x]` in `docs/iterations/019-inbound-club-messages-by-email/todo.md`.

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: keeps idempotency in the event-sourced Commanded aggregate flow.
   - ADR 0005: accepted inbound messages still reuse the existing resolved-recipient `SendMessage` path.
   - ADR 0007: Messaging continues to use Membership public APIs for club/member/person lookup.
   - ADR 0011: message aggregate IDs remain caller-generated UUIDs; duplicate handling uses the deterministic inbound email aggregate identity from `{provider, provider_message_id}`.