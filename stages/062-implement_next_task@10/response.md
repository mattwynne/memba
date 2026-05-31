Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 010 Update documentation for enabling Postmark, configuring environment variables, configuring the Postmark webhook URL, and choosing a monitored Memba-controlled sending subdomain.`

2. **Changes made**
   - Added `docs/postmark-email.md` with operational/developer documentation for:
     - enabling real Postmark sending explicitly;
     - required/optional environment variables:
       - `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark`
       - `MEMBA_POSTMARK_SERVER_TOKEN`
       - `MEMBA_POSTMARK_FROM_ADDRESS`
       - `MEMBA_POSTMARK_REPLY_TO_ADDRESS`
     - local controlled real-send example;
     - choosing a monitored Memba-controlled sender on a dedicated sending subdomain such as `mail.memba.io`;
     - configuring the Postmark webhook URL at `https://<memba-host>/webhooks/postmark`;
     - supported webhook event types;
     - outbound metadata keys:
       - `memba_message_id`
       - `memba_delivery_id`
       - `memba_club_id`
     - multipart/open-tracking/send-failure behaviour;
     - manual smoke-test steps.
   - Updated `README.md` to link to the new Postmark email delivery documentation.
   - Updated `docs/human-todo.md` to link to the new documentation and list the exact runtime environment variables.

3. **Validation commands run**
   - `git diff --check`
     - Passed.
   - Focused documentation smoke checks with `grep`/shell assertions for key env vars, webhook URL, sending address example, README/human-todo links, and todo state.
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed after final changes.
     - Result: `129 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 010 Update documentation for enabling Postmark, configuring environment variables, configuring the Postmark webhook URL, and choosing a monitored Memba-controlled sending subdomain.`
   - To:
     - `- [x] 010 Update documentation for enabling Postmark, configuring environment variables, configuring the Postmark webhook URL, and choosing a monitored Memba-controlled sending subdomain.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0003: Documentation preserves fake/test delivery as the default for automated acceptance/domain tests and frames real Postmark use as explicit/manual configuration.
   - ADR 0004: Documentation describes webhook correlation through existing Memba message/delivery identifiers.
   - ADR 0005: No recipient-resolution or domain command changes.
   - ADR 0006: Documentation keeps provider-specific outcomes behind existing delivery-status handling.
   - ADR 0007: No Membership/Messaging coupling changes.
   - ADR 0012: Documentation describes open tracking as supporting the existing opened-at-least-once model, without adding counts or telemetry.