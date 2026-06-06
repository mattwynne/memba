1. **Selected todo line**
   - `007 Send a new-request notification email to hello@memba.io after successful request creation.`

2. **Changes made**
   - Added `Memba.Onboarding.NewRequestEmail`:
     - sends new onboarding request notifications to `hello@memba.io`;
     - includes request ID, requested club, requester name/email, and note;
     - sets `reply_to` to the requester;
     - uses `Memba.Mailer`/Swoosh, with Postmark-style message stream support and Resend tags.
   - Updated `/get-started` submission flow:
     - after `Onboarding.create_request/2` succeeds, delivers the staff notification;
     - logs delivery errors without rolling back or blocking the requester acknowledgement;
     - does not send notification email when validation fails.
   - Added config:
     - `Memba.Onboarding.NewRequestEmail` recipient and message stream.
   - Updated controller tests to prove:
     - invalid submissions send no email;
     - signed-out successful submissions notify `hello@memba.io`;
     - signed-in successful submissions notify using the known current-person identity, not forged submitted identity fields.

3. **Validation commands run**
   - Attempted focused format/test via `bin/mix`; direct `bin/mix` remains blocked in this sandbox by local permission/Postgres socket setup issues.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `546 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `546 tests, 0 failures`;
     - acceptance passed: `38 scenarios (38 passed), 252 steps (252 passed)`.
   - `git diff --check`
     - Passed.
   - Whitespace check for the new untracked email module
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Send a new-request notification email to hello@memba.io after successful request creation.`
   - To:
     - `- [x] 007 Send a new-request notification email to hello@memba.io after successful request creation.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: kept the flow in the Phoenix app using the existing PostgreSQL-backed request record and mailer boundary.
   - ADR 0002: did not add a new Commanded workflow; notification remains an external side effect after the existing Ecto request creation succeeds.
   - ADR 0013: added user-facing controller coverage for the `/get-started` submission side effect.
   - ADR 0015: kept `/get-started` as a controller-rendered marketing/onboarding surface.
   - ADR 0016: used `Memba.Mailer`/Swoosh and provider-neutral configuration; no direct HTTP client or new email provider dependency was introduced.