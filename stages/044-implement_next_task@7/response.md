Implemented the next unchecked task.

1. **Selected todo line**
   - `- [ ] 007 Ensure transport/auth/configuration/API failures from Postmark fail the send command hard and visibly, while preserving webhook-driven delivery outcomes for recipient-specific status changes.`

2. **Changes made**
   - Updated `web/lib/memba/messaging/delivery_providers/postmark.ex`
     - Postmark/Swoosh `{:error, reason}` results are now returned as:
       - `{:error, {:postmark_delivery_error, reason}}`
     - Swoosh delivery/config exceptions are now converted into visible error tuples:
       - `{:error, {:postmark_delivery_exception, ExceptionModule, message}}`
     - Unexpected delivery return values are tagged as Postmark delivery errors.
   - Added `web/test/support/failing_swoosh_adapter.ex`
     - Test-only Swoosh adapter for simulating API/auth/transport/configuration failures without sending real email.
   - Updated `web/test/memba/messaging/delivery_providers/postmark_test.exs`
     - Covers visible Postmark API/auth failure propagation.
     - Covers visible Swoosh configuration exception propagation.
   - Updated `web/test/memba/messaging/send_club_message_test.exs`
     - Proves `send_club_message/2` surfaces Postmark handoff failures.
     - Proves such failures do not get treated as recipient-specific delivery outcomes; projected receipt/operator status remains `sent`.
     - Ensures fake provider is not used when Postmark is explicitly configured.

3. **Validation commands run**
   - `cd web && mix format --check-formatted` — passed.
   - `cd web && MIX_ENV=test mix compile --warnings-as-errors` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `127 tests, 0 failures`.
   - `git diff --check` — passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 007 Ensure transport/auth/configuration/API failures from Postmark fail the send command hard and visibly, while preserving webhook-driven delivery outcomes for recipient-specific status changes.`
   - To:
     - `- [x] 007 Ensure transport/auth/configuration/API failures from Postmark fail the send command hard and visibly, while preserving webhook-driven delivery outcomes for recipient-specific status changes.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0004: Delivery state remains owned by the message aggregate; provider failures only affect send result/error propagation.
   - ADR 0005: Provider still consumes resolved `DeliveryRequest`s; no recipient-resolution changes.
   - ADR 0006: No delivery status vocabulary changes; provider handoff failures do not become recipient statuses.
   - ADR 0007: Messaging remains decoupled from Membership storage; no new Membership coupling.
   - ADR 0012: Open tracking/opened semantics unchanged; no counts/timestamps/client telemetry added.
   - No acceptance feature files were modified.