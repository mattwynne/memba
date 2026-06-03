1. **Selected todo line**
   - `007 Add Postmark inbound idempotency support using the stable provider message id or equivalent payload field.`

2. **Changes made**
   - Updated `web/lib/memba_web/postmark_inbound_email_parser.ex`
     - Made the Postmark provider-message-id key list explicit.
     - Added a comment documenting that Postmark’s top-level `MessageID` is the stable inbound retry/idempotency identity, not the RFC `Message-ID` header in `Headers`.
   - Updated `web/test/memba_web/postmark_inbound_email_parser_test.exs`
     - Added a parser test proving the top-level Postmark `MessageID` is used as `provider_message_id` even when the original sender `Message-ID` header is present.
   - Updated `web/test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs`
     - Added a controller/dispatch test proving repeated Postmark inbound webhooks with the same `MessageID` return accepted without creating duplicate club messages or duplicate outbound deliveries.

3. **Focused validation**
   - Formatting:
     ```sh
     PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/postmark_inbound_email_parser.ex test/memba_web/postmark_inbound_email_parser_test.exs test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs
     ```
     - Passed.
   - Initial focused test:
     ```sh
     PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/postmark_inbound_email_parser_test.exs test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs
     ```
     - Failed due the known sandbox `PGHOST=/tmp/devenv/postgres` / `PGPORT=5432` mismatch.
   - Rerun with sandbox Postgres override:
     ```sh
     env -u PGHOST -u PGPORT MEMBA_POSTGRES_PORT=15432 devenv shell -O services.postgres.port:int 15432 -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/postmark_inbound_email_parser_test.exs test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs'
     ```
     - Passed: `10 tests, 0 failures`.
   - Broad per-task validation:
     ```sh
     PATH="$PWD/bin:$PATH" dev check --quick
     ```
     - Passed: `481 tests, 0 failures`.
   - Whitespace:
     ```sh
     git diff --check
     ```
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     ```md
     - [ ] 007 Add Postmark inbound idempotency support using the stable provider message id or equivalent payload field.
     ```
   - To:
     ```md
     - [x] 007 Add Postmark inbound idempotency support using the stable provider message id or equivalent payload field.
     ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0016 preserved: Postmark-specific code only parses/translates provider payloads at the boundary; idempotency remains in the shared provider-neutral Messaging inbound aggregate keyed by `{provider, provider_message_id}`.
   - Resend remains untouched and selectable.
   - No production hosting, release-state, routing, UI, acceptance feature, or devenv/process orchestration changes, preserving ADRs 0014, 0017, and 0018.