Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `016 Add a Resend inbound webhook route/controller/parser for email.received-style inbound payloads...`

2. **Changes made**
   - Added `MembaWeb.ResendInboundEmailParser`
     - Parses Resend `email.received` payloads under `data`.
     - Supports `email_id` or `id`, `from`, `to`, optional `cc`/`bcc`, `subject`, `text`, optional `html`, optional `attachments`, and optional `headers`.
     - Normalizes email addresses from strings, display-name strings, lists, and `%{"email" => ...}` maps.
     - Returns provider-neutral inbound email attrs for the later Messaging API handoff.
     - Treats missing required fields as parser errors.
   - Added `MembaWeb.ResendInboundWebhookController`
     - Accepts parseable inbound payloads with `202`.
     - Returns `422` JSON errors for malformed/unprocessable inbound payloads.
   - Added route:
     - `POST /webhooks/resend/inbound`
   - Added parser tests and controller tests for realistic payloads, fallback provider message id, unsupported event type, missing required fields, invalid recipients, and controller `202`/`422` responses.
   - Installed acceptance test dependencies locally with `npm ci` so `dev check` could run; no tracked dependency files changed.

3. **Validation run**
   - Focused new tests:
     - `mix test test/memba_web/resend_inbound_email_parser_test.exs test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
     - Result: `7 tests, 0 failures`
   - Existing Resend webhook regression plus new tests:
     - `mix test test/memba_web/controllers/resend_webhook_controller_test.exs test/memba_web/resend_inbound_email_parser_test.exs test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
     - Result: `15 tests, 0 failures`
   - Full required check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `454 tests, 0 failures`; `31 scenarios (31 passed)`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 016 ...`
     - to
     - `- [x] 016 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Kept the implementation in Phoenix routing/controller structure.
   - ADR 0016: Added Resend-specific webhook parsing while preserving provider-neutral domain-facing attrs and leaving existing `/webhooks/resend` delivery webhook behavior intact.
   - ADR 0007: Did not couple Messaging/Membership internals into the web parser/controller; this task only prepares provider-neutral attrs for the later Messaging API handoff.