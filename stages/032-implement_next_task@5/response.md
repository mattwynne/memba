Implemented task 020.

1. **Selected todo line**
   - `020 Add tests for provider-neutral inbound behaviour:`

2. **Changes made**
   - Updated `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`.
   - Added provider-neutral inbound behaviour coverage for:
     - Accepted inbound email from an alternate sender address, posted as the same person.
     - Blank plain-text body rejection.
     - HTML-only rejection without HTML-to-text conversion.
     - Known person who is not a member of the destination club rejection.
     - Known person with inactive destination-club membership rejection.
     - Unknown club slug rejection.
   - Existing tests in the same file already covered:
     - Accepted primary address.
     - Unknown sender rejection.
     - Attachment rejection.
     - Quote/signature stripping.
     - Duplicate/idempotent accepted and rejected inbound provider message IDs.
   - Extended the test helper `create_person!/1` to support optional `email_addresses`.
   - Added a local inactive-membership projection helper for the inactive-member rejection case.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/messaging/inbound_club_message_acceptance_test.exs`
     - Passed.
   - Attempted focused test:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/inbound_club_message_acceptance_test.exs`
     - Blocked before tests ran by the sandbox duplicate Postgres startup lock (`postmaster.pid already exists`), same environment issue seen in prior task output.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `467 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 020 Add tests for provider-neutral inbound behaviour:`
   - To:
     - `- [x] 020 Add tests for provider-neutral inbound behaviour:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: Kept tests within the Phoenix/Elixir application.
   - ADR 0002: Tests exercise Commanded/event-sourced inbound and messaging behaviour through public APIs.
   - ADR 0004/0005: Accepted inbound tests assert normal message aggregate/delivery-recipient behaviour.
   - ADR 0007: Messaging tests use Membership through public context/API setup and do not move membership rules into Messaging.
   - ADR 0009: Assertions cover projected inbound email source status from events.
   - ADR 0011: Test setup continues using caller-generated UUID identities.
   - ADR 0016: Tests stay provider-neutral at `Messaging.receive_inbound_club_email/2` rather than coupling to Resend payload parsing.