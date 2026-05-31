Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 009 Exercise realistic Postmark webhook payloads that contain the outbound metadata and confirm they update the existing delivery records.`

2. **Changes made**
   - Updated `web/test/memba_web/controllers/postmark_webhook_controller_test.exs`
     - Reworked Postmark webhook tests to use more realistic Postmark-shaped payloads for:
       - `Delivery`
       - `Open`
       - `Bounce` / transient delayed
       - `Bounce` / hard bounce
       - `SpamComplaint`
     - Payloads now include outbound provider metadata keys:
       - `memba_message_id`
       - `memba_delivery_id`
       - `memba_club_id`
     - Added realistic Postmark fields such as `MessageStream`, `MessageID`, `ServerID`, timestamps, bounce IDs, type/type codes, client/open details, recipient email, sender, and subject.
     - Added assertions that the webhook updates existing operator delivery records by `delivery_id`, in addition to existing member/operator status assertions.
   - Updated `docs/iterations/008-postmark-email-integration/todo.md`
     - Checked off task `009` only.

3. **Focused validation commands run**
   - `cd web && mix format --check-formatted test/memba_web/controllers/postmark_webhook_controller_test.exs`
     - Passed.
   - `devenv shell -- bash -lc 'cd /workspace/memba; DEVENV_TUI=false devenv processes up --no-strict-ports -d postgres; devenv processes wait --timeout 120; cd web && mix test test/memba_web/controllers/postmark_webhook_controller_test.exs; status=$?; cd /workspace/memba; devenv processes down || true; exit $status'`
     - Passed: `3 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `129 tests, 0 failures`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 009 Exercise realistic Postmark webhook payloads that contain the outbound metadata and confirm they update the existing delivery records.`
   - To:
     - `- [x] 009 Exercise realistic Postmark webhook payloads that contain the outbound metadata and confirm they update the existing delivery records.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0004: Delivery state remains owned and updated through the existing message aggregate/status-report flow.
   - ADR 0005: No recipient-resolution changes; tests use existing resolved recipient delivery IDs.
   - ADR 0006: Member-facing assertions still use the accepted simplified receipt vocabulary.
   - ADR 0007: No new Membership coupling introduced.
   - ADR 0012: Open events still transition through the existing delivered/opened semantics.
   - No acceptance feature files were modified.