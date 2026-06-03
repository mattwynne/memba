Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/resend_inbound_webhook_controller.ex`
     - After signature verification and Resend payload parsing, the controller now calls:
       - `Memba.Messaging.receive_inbound_club_email(attrs, consistency: :strong)`
     - Parse/signature errors still return appropriate error responses.
     - Successfully received/handled webhook payloads return `202` with `%{status: "accepted"}`.
   - Updated `web/test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
     - Added event-sourced reset/setup for controller tests that now exercise domain side effects.
     - Configures/restores the fake messaging email provider.
     - Added coverage proving a realistic Resend inbound payload is translated through the provider-neutral Messaging API and creates:
       - inbound email source projection,
       - normal club message,
       - recipient delivery records,
       - fake outbound delivery requests.
     - Existing malformed/signature status tests remain covered.

3. **Validation**
   - Attempted focused controller test:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
     - Blocked by the known sandbox/devenv duplicate Postgres startup lock (`postmaster.pid already exists`), not by a test assertion failure.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `461 tests, 0 failures`.
   - Full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `461 tests, 0 failures`; `31 scenarios (31 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.`
   - To:
     - `- [x] 018 Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Kept the integration in the Phoenix controller layer.
   - ADR 0002: Continued using the Commanded/event-sourced Messaging API for domain behaviour.
   - ADR 0007: Preserved the Messaging/Membership bounded-context boundary; tests set up membership through Membership’s public API and inbound handling calls Messaging’s public API.
   - ADR 0016: Kept Resend-specific parsing in the web/provider adapter and translated into provider-neutral Messaging attrs rather than coupling the domain to Resend payload shape.