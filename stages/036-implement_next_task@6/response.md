Implemented the next unchecked task.

1. **Selected todo line**
   - `006 Build the Postmark webhook controller/handler to parse Postmark-style event payloads and call the public Messaging status-reporting functions.`

2. **Changes made**
   - Implemented `MembaWeb.PostmarkWebhookController.create/2`.
   - Added Postmark-style event parsing for:
     - `Delivery` / `Delivered` → `Messaging.report_delivery_delivered/2`
     - `Open` / `Opened` → `Messaging.report_delivery_opened/2`
     - `Bounce` with transient/delayed type → `Messaging.report_delivery_delayed/2`
     - `Bounce` / `Bounced` → `Messaging.report_delivery_bounced/2`
     - `SpamComplaint` / `Spam` → `Messaging.report_delivery_spam_complaint/2`
   - Extracts `message_id` and `delivery_id` from Postmark `Metadata` first, with top-level fallbacks.
   - Extracts reasons from Postmark-like `Details`, `Description`, `Message`, `Name`, or `Type`.
   - Returns:
     - `202` JSON success for accepted events.
     - `422` JSON error for unsupported or invalid events.
   - Added `web/test/memba_web/controllers/postmark_webhook_controller_test.exs` covering delivery/open, delayed/bounced/spam complaint, and unsupported events.
   - Updated Messaging status-reporting API defaults to dispatch with `consistency: :strong`, making delivered-then-opened browser/status-report flows deterministic when callers use the public APIs without explicit dispatch options.

3. **Validation run**
   - `cd web && mix format --check-formatted lib/memba/messaging.ex lib/memba_web/controllers/postmark_webhook_controller.ex test/memba_web/controllers/postmark_webhook_controller_test.exs`
     - Passed.
   - `cd web && MIX_ENV=test mix compile --warnings-as-errors`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `107 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Build the Postmark webhook controller/handler to parse Postmark-style event payloads and call the public Messaging status-reporting functions.`
   - To:
     - `- [x] 006 Build the Postmark webhook controller/handler to parse Postmark-style event payloads and call the public Messaging status-reporting functions.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0010 respected: no shared `.feature` files were edited.
   - ADR 0013 respected: added Phoenix web/controller test coverage through the existing web test harness.
   - ADR 0007 respected: the controller calls public `Memba.Messaging` APIs, not private projection storage or direct Commanded dispatch.
   - ADR 0012 respected: Postmark open events map to the existing opened delivery status path.
   - ADR 0006 respected: delayed/bounced/spam complaint still project to member-facing `delivery problem`; opened projects to `opened`.