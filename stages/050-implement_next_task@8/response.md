Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 008 Add focused tests for the Postmark provider using Swoosh test facilities or a test adapter so no real email is sent.`

2. **Changes made**
   - Updated `web/test/memba/messaging/delivery_providers/postmark_test.exs`
     - Imported `Swoosh.TestAssertions`.
     - Added focused provider tests proving:
       - Missing required Postmark configuration returns a clear provider configuration error and does **not** hand an email to Swoosh.
       - Unsupported delivery channels return `{:unsupported_delivery_channel, channel}` and do **not** hand anything to Swoosh.
   - Updated `docs/iterations/008-postmark-email-integration/todo.md`
     - Checked off task `008` only.

3. **Focused validation commands run**
   - `cd web && mix format --check-formatted test/memba/messaging/delivery_providers/postmark_test.exs` — passed.
   - `devenv shell -- bash -lc 'cd /workspace/memba; DEVENV_TUI=false devenv processes up --no-strict-ports -d postgres; devenv processes wait --timeout 120; cd web && mix test test/memba/messaging/delivery_providers/postmark_test.exs; status=$?; cd /workspace/memba; devenv processes down || true; exit $status'` — passed, `6 tests, 0 failures`.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed, `129 tests, 0 failures`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 008 Add focused tests for the Postmark provider using Swoosh test facilities or a test adapter so no real email is sent.`
   - To:
     - `- [x] 008 Add focused tests for the Postmark provider using Swoosh test facilities or a test adapter so no real email is sent.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Tests only; no domain/application behaviour was changed.
   - ADR 0004: Delivery state remains owned by the message aggregate.
   - ADR 0005: No recipient-resolution changes.
   - ADR 0006: No delivery status vocabulary changes.
   - ADR 0007: No new Membership coupling.
   - ADR 0012: Open-tracking semantics unchanged.
   - No acceptance feature files were modified.