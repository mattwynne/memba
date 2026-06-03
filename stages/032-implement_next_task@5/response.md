Implemented the next unchecked task.

1. **Selected todo line**
   - `005 Model inbound email as a small aggregate/process keyed by deterministic identity such as inbound-email:<provider>:<provider_message_id>. The aggregate handles exactly one provider inbound message id and makes duplicate handling explicit.`

2. **Changes made**
   - Added deterministic inbound email aggregate identity:
     - `Memba.Messaging.InboundEmail.identity/1`
     - `ReceiveInboundEmail.inbound_email_id`
     - `Messaging.receive_inbound_club_email_command/1` now derives `inbound-email:<provider>:<provider_message_id>`.
   - Added inbound email aggregate:
     - `web/lib/memba/messaging/inbound_email_receipt.ex`
     - First receipt emits a state event.
     - Duplicate receipt for the same provider/provider message id returns `[]` explicitly.
     - Mismatched command identity is rejected.
   - Added minimal receipt event needed for event-sourced aggregate state:
     - `web/lib/memba/messaging/events/inbound_email_received.ex`
     - Did **not** add the accepted/rejected business outcome events from task 006.
   - Routed `ReceiveInboundEmail` through `Memba.Messaging.Router` to the new aggregate.
   - Updated/added tests:
     - `web/test/memba/messaging/inbound_email_api_test.exs`
     - `web/test/memba/messaging/inbound_email_receipt_test.exs`
     - `web/test/memba/messaging/inbound_email_dispatch_test.exs`
     - `web/test/memba/messaging/app_test.exs`

3. **Validation**
   - `cd web && ../bin/mix format` — passed.
   - Focused direct `../bin/mix test ...inbound_email...` attempts failed before test execution due the local wrapper not seeing the devenv Postgres socket as ready (`PGHOST=/tmp/devenv...`). No test failures were reported.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed:
     - `412 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - ExUnit: `412 tests, 0 failures`
     - Acceptance: `31 scenarios (31 passed), 205 steps (205 passed)`
   - `git diff --check` — passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as ...`
   - To:
     - `- [x] 005 Model inbound email as a small aggregate/process keyed by deterministic identity such as ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Uses Commanded aggregate/event-sourced state for inbound email identity.
   - ADR 0007: Keeps work inside the Messaging bounded context and does not reach into Membership internals.
   - ADR 0008/0009: Uses the existing Commanded/EventStore path; no projection/read model was introduced ahead of task 007.
   - ADR 0011: Uses Commanded aggregate routing conventions with a deterministic inbound provider identity required by this iteration.
   - ADR 0016: Keeps provider-specific parsing out; the aggregate remains provider-neutral.