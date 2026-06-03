1. **Selected todo line**
   - `008 Add tests for Postmark inbound payload parsing and controller/dispatcher behaviour, including accepted primary-address sender, alternate-address sender where practical, rejection cases, attachments, HTML-only/missing plain text, and duplicate retry handling.`

2. **Changes made**
   - Updated Postmark inbound parsing to allow missing `TextBody` so HTML-only/missing-plain-text payloads reach the shared provider-neutral `plain_text_required` rejection path.
   - Added controller error text for malformed non-binary `TextBody`.
   - Expanded parser tests for:
     - Missing plain text with HTML body.
     - Malformed text body.
     - Existing required-field expectations adjusted so `TextBody` is no longer treated as a parser-required field.
   - Expanded Postmark inbound controller/dispatcher tests for:
     - Accepted primary-address sender.
     - Accepted alternate-address sender.
     - Unknown-sender rejection.
     - Attachment rejection.
     - HTML-only/missing plain-text rejection.
     - Quoted-only/no-usable-plain-text rejection.
     - Duplicate accepted retry handling.
     - Duplicate rejected retry handling without duplicate rejection emails.

3. **Focused validation**
   - Formatted touched files:
     ```sh
     PATH="$PWD/bin:$PATH" bin/mix format lib/memba_web/postmark_inbound_email_parser.ex lib/memba_web/controllers/postmark_inbound_webhook_controller.ex test/memba_web/postmark_inbound_email_parser_test.exs test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs
     ```
     Passed.
   - Initial focused test hit the known sandbox Postgres `PGHOST/PGPORT` mismatch.
   - Reran focused tests with sandbox Postgres override:
     ```sh
     env -u PGHOST -u PGPORT MEMBA_POSTGRES_PORT=15432 devenv shell -O services.postgres.port:int 15432 -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/postmark_inbound_email_parser_test.exs test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs'
     ```
     Passed: `15 tests, 0 failures`.
   - Broad per-task validation:
     ```sh
     PATH="$PWD/bin:$PATH" dev check --quick
     ```
     Passed: `486 tests, 0 failures`.
   - Formatting/whitespace check:
     ```sh
     PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/postmark_inbound_email_parser.ex lib/memba_web/controllers/postmark_inbound_webhook_controller.ex test/memba_web/postmark_inbound_email_parser_test.exs test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs && git diff --check
     ```
     Passed.

4. **Todo check-off made**
   - Changed exactly:
     ```md
     - [ ] 008 Add tests for Postmark inbound payload parsing and controller/dispatcher behaviour, including accepted primary-address sender, alternate-address sender where practical, rejection cases, attachments, HTML-only/missing plain text, and duplicate retry handling.
     ```
   - To:
     ```md
     - [x] 008 Add tests for Postmark inbound payload parsing and controller/dispatcher behaviour, including accepted primary-address sender, alternate-address sender where practical, rejection cases, attachments, HTML-only/missing plain text, and duplicate retry handling.
     ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0016 preserved: Postmark-specific code remains at the parser/controller boundary; accepted/rejected behaviour continues through the shared provider-neutral Messaging inbound API.
   - Resend fallback support was not changed.
   - No production hosting, release-state, routing, UI, acceptance feature, or devenv/process orchestration changes were made, preserving ADRs 0014, 0017, and 0018.