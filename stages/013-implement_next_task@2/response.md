Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 002 Add the member-facing receipt projection and query applying the ADR 0006`

2. **Changes made**
   - Added a new member-facing receipt projection table:
     - `messaging_member_receipts`
   - Added:
     - `Memba.Messaging.Projections.MemberReceipt`
     - `Memba.Messaging.Projectors.MemberReceipt`
   - Projector applies ADR 0006 mapping:
     - `sent` → `"sent"`
     - `delivered` → `"delivered"`
     - `delayed` / `bounced` / `spam_complaint` → `"delivery problem"`
     - `opened` → `"opened"`
   - Added public Messaging query APIs:
     - `Messaging.get_member_receipt(delivery_id)`
     - `Messaging.get_member_receipt(message_id, recipient_id)`
     - `Messaging.list_member_receipts(message_id)`
   - Wired the projector into supervision and event-sourced test reset config.
   - Added focused ExUnit coverage in:
     - `web/test/memba/messaging/member_receipt_projection_test.exs`
   - Did not edit acceptance feature files.

3. **Validation commands run**
   - `cd web && mix format --check-formatted` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `83 tests, 0 failures`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Add the member-facing receipt projection and query applying the ADR 0006`
   - To:
     - `- [x] 002 Add the member-facing receipt projection and query applying the ADR 0006`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0004: receipt projection is driven by delivery events from the single Message aggregate stream.
   - ADR 0006: member-facing query exposes only the simplified receipt vocabulary and maps delivery problems appropriately.
   - ADR 0009: implemented as a Commanded Ecto projection, not hand-rolled event handler plumbing.
   - ADR 0012: opened remains boolean-like; no open counts, timestamps, devices, or analytics were added.