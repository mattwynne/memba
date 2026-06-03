1. **Selected todo line**
   - `011 Verify rejection-email delivery follows the configured mailer/provider path and works when Postmark is selected.`

2. **Changes made**
   - Updated `web/test/memba/messaging/email_delivery_provider_config_test.exs`:
     - Added runtime config coverage proving `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark` configures:
       - `:messaging_email_delivery_provider` to `Memba.Messaging.EmailDeliveryProviders.Postmark`
       - `Memba.Mailer` with `Swoosh.Adapters.Postmark`
       - `api_key` from `MEMBA_POSTMARK_SERVER_TOKEN`
       - Postmark provider `from` / `reply_to`
       - `Swoosh.ApiClient.Req`
     - Changed the module to `async: false` because the new test temporarily mutates process-wide environment variables.
   - Updated `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`:
     - Added an integration test selecting the Postmark messaging provider.
     - Verifies a rejected Postmark inbound email:
       - creates no club message
       - creates no outbound member-message deliveries
       - records the rejection source/projection
       - sends the rejection email through `Memba.Mailer`
       - uses configured Postmark sender/reply-to
       - includes Postmark-compatible rejection metadata and delivery reference.
   - Updated `docs/iterations/020-migrate-production-email-to-postmark/todo.md` to check off task 011 only.

3. **Focused validation commands run and results**
   - Formatting:
     ```sh
     PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/messaging/email_delivery_provider_config_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs
     ```
     Passed.
   - Initial focused test:
     ```sh
     PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/email_delivery_provider_config_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs
     ```
     Failed due the sandbox `PGHOST=/tmp/devenv/postgres PGPORT=5432` readiness mismatch while Postgres was listening on port `15432`.
   - Focused test rerun with sandbox Postgres override:
     ```sh
     env -u PGHOST -u PGPORT MEMBA_POSTGRES_PORT=15432 devenv shell -O services.postgres.port:int 15432 -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/email_delivery_provider_config_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs'
     ```
     Passed: `20 tests, 0 failures`.
   - Broad quick validation:
     ```sh
     PATH="$PWD/bin:$PATH" dev check --quick
     ```
     Passed: `491 tests, 0 failures`.
   - Whitespace:
     ```sh
     git diff --check
     ```
     Passed.

4. **Exact todo check-off made**
   - Changed:
     ```md
     - [ ] 011 Verify rejection-email delivery follows the configured mailer/provider path and works when Postmark is selected.
     ```
   - To:
     ```md
     - [x] 011 Verify rejection-email delivery follows the configured mailer/provider path and works when Postmark is selected.
     ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0016 preserved:
     - Postmark and Resend remain switchable providers.
     - Runtime provider selection remains at the configuration boundary.
     - Rejection email delivery uses Swoosh/Memba.Mailer rather than direct provider HTTP code.
     - Resend fallback support was not removed or weakened.
   - ADR 0017 respected:
     - Added explicit configuration-boundary coverage for production-style Postmark messaging mailer setup.
     - No migration or release-state changes were made.
   - No acceptance feature files, routing, UI, or provider-removal changes were made.