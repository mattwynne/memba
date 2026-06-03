Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.`

2. **Changes made**
   - Added provider-neutral inbound email data structures:
     - `web/lib/memba/messaging/inbound_email.ex`
     - `web/lib/memba/messaging/inbound_email_attachment.ex`
   - Added command wrapper:
     - `web/lib/memba/messaging/commands/receive_inbound_email.ex`
   - Added public Messaging API for building the provider-neutral command:
     - `Memba.Messaging.receive_inbound_club_email_command/1`
   - Added focused tests:
     - `web/test/memba/messaging/inbound_email_api_test.exs`
   - Checked off only task `004` in:
     - `docs/iterations/019-inbound-club-messages-by-email/todo.md`

3. **Validation**
   - `cd web && ../bin/mix format` — passed.
   - Direct focused test attempt:
     - `env -u PGHOST -u PGPORT bash -lc 'cd web && ../bin/mix test test/memba/messaging/inbound_email_api_test.exs'`
     - Compiled the new modules, then failed during DB setup because no local Postgres was listening.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed:
     - `406 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - ExUnit: `406 tests, 0 failures`
     - Acceptance: `31 scenarios (31 passed), 205 steps (205 passed)`
   - `git diff --check` — passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.`
   - To:
     - `- [x] 004 Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, provider event id if present, and provider name.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Adds a Messaging command shape as preparation for the event-sourced inbound workflow, without adding projection-only state.
   - ADR 0007: Keeps the new API inside the Messaging bounded context and does not mutate or query Membership internals.
   - ADR 0016: Keeps inbound provider handling provider-neutral; no Resend-specific payload assumptions or HTTP/provider code were introduced.
   - ADR 0004/0005: Does not alter the existing Message aggregate or send-message recipient resolution flow.