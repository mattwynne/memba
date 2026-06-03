Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `014 Add attachment rejection before message creation when inbound payload includes any attachments.`

2. **Changes made**
   - Updated `Memba.Messaging.receive_inbound_club_email/2` flow to reject inbound emails with any normalized attachments before body normalization/message creation.
   - Rejection is recorded through the existing event-sourced `RejectInboundClubEmail` path with reason:
     - `"attachments_not_supported"`
   - Added a focused acceptance-style messaging test proving:
     - an authorized member’s inbound email with an attachment is rejected,
     - no club message is created,
     - no outbound club-message deliveries are sent,
     - no `MessageSent` / `InboundClubEmailAccepted` events are emitted,
     - exactly one `InboundClubEmailRejected` event is emitted,
     - the inbound email source projection records rejected status and reason.

3. **Validation run**
   - TDD confirmation first:
     - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/messaging/inbound_club_message_acceptance_test.exs`
     - Failed as expected before implementation: attachment email was still accepted.
   - Focused validation:
     - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/messaging/inbound_club_message_acceptance_test.exs test/memba/messaging/inbound_email_receipt_test.exs test/memba/messaging/inbound_email_source_projection_test.exs`
     - `18 tests, 0 failures`
   - Formatting:
     - `PATH="$PWD/bin:$PATH" devenv shell -- mix format --check-formatted`
     - Passed after manual formatting fixes.
   - Full required gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - `445 tests, 0 failures`
     - `31 scenarios (31 passed)`

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 014 Add attachment rejection before message creation when inbound payload includes any attachments.`
     - to:
     - `- [x] 014 Add attachment rejection before message creation when inbound payload includes any attachments.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: rejection remains an event-sourced domain outcome.
   - ADR 0005: accepted-message flow remains unchanged; rejected attachment messages do not enter `SendMessage`.
   - ADR 0007: messaging still uses membership APIs for destination/sender/authorization and does not mutate membership state.
   - ADR 0009: inbound rejection audit state is projected from `InboundClubEmailRejected`.
   - ADR 0011: message IDs remain caller-generated only for accepted messages; rejected attachment emails create no message aggregate.