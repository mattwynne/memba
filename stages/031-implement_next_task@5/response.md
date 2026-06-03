1. **Selected todo line**
   - `005 Add a Postmark inbound parser/controller/dispatcher that maps realistic Postmark inbound payload fields to the provider-neutral inbound email structure: provider name, provider message id, sender, recipients, subject, plain text, HTML body if present, attachment metadata, and useful headers.`

2. **Changes made**
   - Added `MembaWeb.PostmarkInboundEmailParser`
     - Maps Postmark inbound fields to provider-neutral attrs:
       - `provider: "postmark"`
       - `provider_message_id` from `MessageID`
       - sender from `FromFull` / `From`
       - recipients from `OriginalRecipient`, `ToFull`, `To`, `CcFull`, `Cc`, `BccFull`, `Bcc`
       - subject, `TextBody`, optional `HtmlBody`
       - attachment metadata from `Attachments` (`Name`, `ContentType`, `ContentLength`, `ContentID`)
       - raw `Headers`
   - Added `MembaWeb.PostmarkInboundWebhookController`
     - Parses Postmark inbound payloads.
     - Dispatches parsed attrs through `Messaging.receive_inbound_club_email/2`.
     - Returns `202 {"status":"accepted"}` for accepted processing.
     - Returns `422` with operator-readable errors for malformed payloads.
   - Added route:
     - `POST /webhooks/postmark/inbound`
   - Added focused tests:
     - Parser mapping tests for realistic Postmark payloads.
     - OriginalRecipient forwarding-address coverage.
     - Parser malformed-field coverage.
     - Controller/dispatcher integration through provider-neutral inbound API.
     - Router coverage for the new inbound route.

3. **Focused validation**
   - Ran focused tests:
     ```sh
     env -u PGHOST -u PGPORT MEMBA_POSTGRES_PORT=15432 devenv shell -O services.postgres.port:int 15432 -- bash -lc 'echo PGHOST=$PGHOST PGPORT=$PGPORT; PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/postmark_inbound_email_parser_test.exs test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs test/memba_web/router_test.exs'
     ```
     Result: `17 tests, 0 failures`.
   - Ran full check because this task changes routing:
     ```sh
     PATH="$PWD/bin:$PATH" dev check
     ```
     Result: passed.
     - ExUnit: `478 tests, 0 failures`
     - Acceptance: `31 scenarios (31 passed), 205 steps (205 passed)`

4. **Todo check-off made**
   - Changed exactly task `005` from:
     - `- [ ] 005 Add a Postmark inbound parser/controller/dispatcher...`
   - To:
     - `- [x] 005 Add a Postmark inbound parser/controller/dispatcher...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0016 preserved: Postmark parsing stays provider-specific at the webhook boundary; Messaging remains provider-neutral.
   - Existing `/webhooks/postmark` delivery-status route/controller remains unchanged.
   - Resend inbound support remains untouched and available.
   - ADR 0014/0017 respected by keeping production webhook shape explicit for later docs/runbook tasks.
   - ADR 0018 respected: no devenv/process-compose/service orchestration changes.