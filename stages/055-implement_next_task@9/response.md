1. **Selected todo line**
   - `009 Verify or add tests proving Postmark outbound member-message payloads still include sender/reply-to, text/HTML bodies, and correlation metadata expected by the Postmark delivery-status webhook handler.`

2. **Changes made**
   - Added a focused integration-style test in `web/test/memba_web/controllers/postmark_webhook_controller_test.exs` that:
     - Sends a Postmark outbound member-message email through `Memba.Messaging.EmailDeliveryProviders.Postmark`.
     - Asserts the generated email includes:
       - Verified sender/from address.
       - Member sender reply-to.
       - Recipient.
       - Subject.
       - Plain-text body.
       - Escaped HTML body.
       - Postmark metadata keys:
         - `memba_message_id`
         - `memba_delivery_id`
         - `memba_club_id`
     - Reuses that exact outbound metadata in a realistic Postmark delivery webhook payload.
     - Verifies the Postmark delivery-status webhook correlates the event and marks the recipient delivery as delivered.
   - Added small test helpers/setup in that test file for Postmark/Swoosh test delivery config and building the matching `EmailDeliveryRequest`.

3. **Focused validation**
   - Formatting check:
     ```sh
     PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/controllers/postmark_webhook_controller_test.exs
     ```
     Passed.
   - Whitespace check:
     ```sh
     git diff --check
     ```
     Passed.
   - Initial focused test commands hit the known sandbox Postgres `PGHOST/PGPORT` mismatch.
   - Reran focused tests with sandbox Postgres override:
     ```sh
     env -u PGHOST -u PGPORT MEMBA_POSTGRES_PORT=15432 devenv shell -O services.postgres.port:int 15432 -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/postmark_webhook_controller_test.exs'
     ```
     Passed: `5 tests, 0 failures`.
   - Postmark outbound provider tests:
     ```sh
     env -u PGHOST -u PGPORT MEMBA_POSTGRES_PORT=15432 devenv shell -O services.postgres.port:int 15432 -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/email_delivery_providers/postmark_test.exs'
     ```
     Passed: `6 tests, 0 failures`.
   - Broad per-task validation:
     ```sh
     PATH="$PWD/bin:$PATH" dev check --quick
     ```
     Passed: `487 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     ```md
     - [ ] 009 Verify or add tests proving Postmark outbound member-message payloads still include sender/reply-to, text/HTML bodies, and correlation metadata expected by the Postmark delivery-status webhook handler.
     ```
   - To:
     ```md
     - [x] 009 Verify or add tests proving Postmark outbound member-message payloads still include sender/reply-to, text/HTML bodies, and correlation metadata expected by the Postmark delivery-status webhook handler.
     ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0016 preserved: Postmark remains a switchable provider behind the existing provider boundary.
   - The test keeps provider-specific Postmark payload/metadata concerns at the provider/webhook boundary and verifies correlation through the shared Messaging status-reporting path.
   - Resend fallback support was not changed or weakened.
   - No acceptance feature files, UI, routing, or production configuration were changed.