Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `013 Add plain-text body normalization:`

2. **Changes made**
   - Added `Memba.Messaging.InboundEmailBody` to normalize inbound `text/plain` bodies:
     - requires usable plain text,
     - ignores `html_body`,
     - does not convert HTML to text,
     - normalizes line endings,
     - strips common signature/reply markers and quoted lines,
     - rejects bodies that become blank after stripping.
   - Added event-sourced rejected outcome support with `RejectInboundClubEmail`, so plain-text-required rejections are recorded on the inbound email aggregate/read model without creating a club message.
   - Updated `receive_inbound_club_email/2` to:
     - normalize the body before posting,
     - post only the normalized body,
     - record `plain_text_required` rejection when no usable plain text remains.
   - Added/updated tests for:
     - body normalization rules,
     - rejection aggregate behavior,
     - rejected inbound source projection,
     - accepted inbound email using normalized plain text and ignoring HTML,
     - no message/outbound delivery on blank-after-stripping body.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" devenv shell -- mix format --check-formatted`
     - Passed.
   - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/messaging/inbound_email_body_test.exs test/memba/messaging/inbound_email_receipt_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs test/memba/messaging/inbound_email_dispatch_test.exs test/memba/messaging/inbound_email_source_projection_test.exs test/memba/messaging/app_test.exs`
     - `26 tests, 0 failures`.
   - Final required gate: `PATH="$PWD/bin:$PATH" dev check`
     - `444 tests, 0 failures`
     - `31 scenarios (31 passed)`.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 013 Add plain-text body normalization:`
     - to `- [x] 013 Add plain-text body normalization:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: rejection/acceptance outcomes remain event-sourced through Commanded.
   - ADR 0005: accepted messages still use the existing resolved-recipient `SendMessage` path.
   - ADR 0007: Messaging continues to use Membership public APIs for club/sender/member resolution.
   - ADR 0011: message aggregate IDs remain caller-generated UUIDs; inbound idempotency stays keyed by deterministic provider identity.