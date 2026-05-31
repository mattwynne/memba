Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 Reshape the public Messaging operator-deliverability query toward a deliveries-overview API, for example an options-shaped list function. Preserve any existing message-scoped needs through options or a compatibility wrapper only if still required by current code.`

2. **Changes made**
   - Added `Messaging.list_operator_deliveries/1` as the new options-shaped deliveries overview query.
     - Defaults to all operator delivery records.
     - Supports `message_id: ...` filtering.
     - Returns `[]` for invalid option shapes or invalid message IDs.
     - Orders by newest delivery event timestamp first using the projection update timestamp.
   - Added virtual fields to `Memba.Messaging.Projections.OperatorDeliverability`:
     - `message_subject`
     - `event_at`
   - Joined operator deliverability records to projected messages so the overview query includes message subject/title data.
   - Preserved existing message-scoped API:
     - `Messaging.list_operator_deliverabilities(message_id)` remains unchanged for current domain/acceptance plumbing.
   - Updated focused tests:
     - Added coverage proving `list_operator_deliveries/1` lists deliveries across multiple messages, includes message subject/reason/status/channel/recipient details, orders newest first, and supports `message_id:` filtering.
     - Updated the public API/no-CRUD guard test to allow the new list query.

3. **Focused validation**
   - `cd web && mix format --check-formatted lib/memba/messaging.ex lib/memba/messaging/projections/operator_deliverability.ex test/memba/messaging/operator_deliverability_projection_test.exs test/memba/messaging/no_crud_spike_test.exs`
     - Passed.
   - Focused tests with managed Postgres:
     - `mix test test/memba/messaging/operator_deliverability_projection_test.exs test/memba/messaging/no_crud_spike_test.exs`
     - Result: `9 tests, 0 failures`.
   - Required gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: still fails with the known pending `/deliveries` route failure from task 002:
       - `111 tests, 1 failure`
       - Failure: `"/deliveries" path doesn't exist`
     - I did not fix this here because adding the route/LiveView is explicitly task 004/005.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Reshape the public Messaging operator-deliverability query...`
   - To:
     - `- [x] 003 Reshape the public Messaging operator-deliverability query...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0004: Query continues to read recipient delivery state owned/projected from per-message aggregates.
   - ADR 0006: Operator query keeps detailed status and reason text for diagnosis.
   - ADR 0009: Implementation remains projection-query based over Commanded/Ecto read models; no direct event-store querying or CRUD surface was added.