1. **Selected todo line**
   - `008 Preserve the existing stable DOM/test attributes for recipient rows.`

2. **Changes made**
   - Added a focused LiveView regression test in:
     - `web/test/memba_web/live/member_message_live/show_test.exs`
   - The new test expands a receipt group and asserts the recipient row preserves the stable browser-test attributes:
     - `id="member-receipt-<recipient_id>"`
     - `data-testid="member-receipt"`
     - `data-recipient-id`
     - `data-recipient-name`
     - `data-receipt-status`
   - No production markup change was needed because the current row template already preserved these attributes.

3. **Validation run**
   - `cd web && mix format --check-formatted test/memba_web/live/member_message_live/show_test.exs`
     - Passed.
   - Focused LiveView test file inside devenv/Postgres:
     - `mix test test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `5 tests, 0 failures`.
   - Required full check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `228 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Preserve the existing stable DOM/test attributes for recipient rows.`
   - To:
     - `- [x] 008 Preserve the existing stable DOM/test attributes for recipient rows.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Checked relevant accepted ADRs:
     - `0001-use-phoenix-for-the-core-application.md`
     - `0006-simplify-member-facing-delivery-status.md`
     - `0015-use-liveview-for-member-application-pages.md`
   - The change is compatible: it keeps the member message page LiveView-tested, preserves simple member-facing receipt status attributes, and does not expose operator-only diagnostics.