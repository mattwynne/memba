1. **Selected todo line**
   - `007 Keep staff/admin diagnostics unchanged on /admin/messages/:message_id and /admin/deliveries.`

2. **Changes made**
   - Added `web/test/memba_web/live/admin_diagnostics_live_test.exs`.
   - Covered `/admin/messages/:message_id` to prove staff/admin message detail still exposes admin diagnostic structure and raw projection values:
     - addressed recipients section;
     - delivery records section;
     - member receipt statuses section;
     - delivery IDs, recipient emails, raw `"sent"` delivery status, raw lowercase `"delivery problem"` receipt value;
     - no member-facing `"Delivery problem"` label and no provider reason on message detail.
   - Covered `/admin/deliveries` to prove operator delivery diagnostics still show detailed provider/operator values:
     - raw `"spam complaint"` status;
     - provider reason text;
     - delivery ID, message ID, recipient email/name.
   - No production admin implementation was changed.

3. **Focused validation**
   - `devenv shell -- bash -lc 'mix test test/memba_web/live/admin_diagnostics_live_test.exs test/memba_web/live/deliveries_live_test.exs test/memba_web/live/browser_acceptance_harness_test.exs'`
     - Passed: `6 tests, 0 failures`.
   - `devenv shell -- bash -lc 'mix format --check-formatted && mix compile --warnings-as-errors'`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `213 tests, 0 failures`.
   - `git diff --check` plus whitespace check for the new untracked test file
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Keep staff/admin diagnostics unchanged on /admin/messages/:message_id and /admin/deliveries.`
   - To:
     - `- [x] 007 Keep staff/admin diagnostics unchanged on /admin/messages/:message_id and /admin/deliveries.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Kept the work inside Phoenix/Phoenix tests.
   - ADR 0006: Preserved the separation between simple member-facing receipt labels and detailed operator diagnostics.
   - ADR 0013: Added feature-style web coverage using existing Phoenix test support and stable selectors.