1. **Selected todo line**
   - `007 Add the historic-event replay-safety regression test.`

2. **Changes made**
   - Added `web/test/memba/messaging/email_delivery_opened_replay_test.exs`.
     - Persists a historic `EmailDeliveryOpened` event directly to the message aggregate stream.
     - Waits for member/staff delivery projectors to process it.
     - Asserts member and staff delivery read models remain `sent`.
     - Stops aggregate instances to force aggregate replay from EventStore and asserts state remains unchanged.
     - Rebuilds projections from retained EventStore history and asserts read models are still unaffected.
   - Extended `web/test/support/event_sourced_case.ex` with test helpers to:
     - Stop cached Commanded aggregate instances.
     - Rebuild event-sourced projections without deleting EventStore history.
     - Reset projection tables, in-memory Commanded subscription tracking, and persistent EventStore subscription checkpoints before restarting projectors.
   - Checked off only todo `007`.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/support/event_sourced_case.ex test/memba/messaging/email_delivery_opened_replay_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `799 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Note: a direct focused `bin/mix test test/memba/messaging/email_delivery_opened_replay_test.exs` hit the same sandbox Postgres socket readiness issue seen in the previous task; `dev check --quick` started the environment correctly and passed the full ExUnit suite including the new regression.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 007 Add the historic-event replay-safety regression test.`
   - To:
     - `- [x] 007 Add the historic-event replay-safety regression test.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Inspected relevant ADRs: 0004, 0006, 0007, 0008, 0009, and 0012.
   - The regression respects ADR 0004’s one-message-aggregate stream model, ADR 0007’s separate Messaging Commanded app, ADR 0008’s persistent PostgreSQL EventStore usage in tests, and ADR 0009’s Commanded Ecto projection rebuild/checkpoint model.
   - ADRs 0006/0012 contain the historical opened-status decision; this task does not revive opened as live behaviour. It only proves the iteration-plan-required tombstone/replay compatibility for historic ADR-era events.