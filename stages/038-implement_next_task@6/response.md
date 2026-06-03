Implemented the next unchecked task.

1. **Selected todo line**
   - `021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.`

2. **Changes made**
   - Updated `web/test/memba_web/resend_inbound_email_parser_test.exs`
     - Added malformed-field parser coverage for:
       - invalid provider message id shape
       - invalid from address
       - invalid HTML body shape
       - invalid attachment size
   - Updated `web/test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
     - Added controller retry/idempotency coverage for accepted inbound emails:
       - retry returns `202`
       - no duplicate message
       - no duplicate outbound deliveries
       - original inbound source projection remains unchanged
     - Added controller rejection-path coverage for attachment rejection:
       - webhook still returns accepted receipt (`202`)
       - no club message created
       - no outbound club-message deliveries
       - inbound source projected as rejected
       - rejection email sent once
       - provider retry does not send a duplicate rejection email
   - Updated `docs/iterations/019-inbound-club-messages-by-email/todo.md` to check off task 021 only.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/resend_inbound_email_parser_test.exs test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
     - Initially failed on formatting; fixed with a small patch.
     - Reran and passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/resend_inbound_email_parser_test.exs test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
     - Attempted twice.
     - Blocked both times by sandbox duplicate Postgres startup lock: `postmaster.pid already exists`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `470 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.`
   - To:
     - `- [x] 021 Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, signature-required behaviour, duplicate provider message id behaviour, and rejection paths.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: Kept changes in the Phoenix app test suite.
   - ADR 0002: Tests exercise Commanded/event-sourced inbound behaviour via the public webhook/API flow.
   - ADR 0007: Test setup uses Membership public commands/queries; Messaging remains separate.
   - ADR 0009: Assertions verify inbound source projection state from events.
   - ADR 0011: Test fixture setup continues using caller-generated UUIDs.
   - ADR 0016: Resend-specific parser/controller behaviour remains isolated while the domain-facing inbound API stays provider-neutral.