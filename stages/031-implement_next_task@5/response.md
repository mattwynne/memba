Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 005 Add projections and queries for messages and recipient deliveries.`

2. **Changes made**
   - Added messaging projection migration:
     - `web/priv/repo/migrations/20260529202746_create_messaging_projections.exs`
     - Creates `messaging_messages` and `messaging_recipient_deliveries`.
   - Added Messaging read-model schemas:
     - `Memba.Messaging.Projections.Message`
     - `Memba.Messaging.Projections.RecipientDelivery`
   - Added Commanded Ecto projectors:
     - `Memba.Messaging.Projectors.Message`
     - `Memba.Messaging.Projectors.RecipientDelivery`
   - Wired projectors into supervision:
     - `web/lib/memba/application.ex`
   - Added projection reset configuration for tests:
     - `web/config/config.exs`
     - `web/test/support/event_sourced_case.ex`
   - Added public Messaging query APIs:
     - `Memba.Messaging.get_message/1`
     - `Memba.Messaging.get_recipient_delivery/1`
     - `Memba.Messaging.list_recipient_deliveries/1`
   - Added ExUnit coverage:
     - `web/test/memba/messaging/message_projection_test.exs`

3. **Validation commands run**
   - `cd web && mix format` — passed.
   - `cd web && mix compile --warnings-as-errors` — passed.
   - Focused test:
     - `devenv shell -- bash -lc 'export MEMBA_DEVENV_SHELL=1; ./bin/dev up; trap "cd /workspace/memba && ./bin/dev down" EXIT; cd web && mix test test/memba/messaging/message_projection_test.exs'`
     - Result: `2 tests, 0 failures`.
   - Required project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `73 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Add projections and queries for messages and recipient deliveries.`
   - To:
     - `- [x] 005 Add projections and queries for messages and recipient deliveries.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0004: kept one message aggregate/message projection per message, with per-recipient delivery read models belonging to that message.
   - ADR 0005: recipient delivery projections are derived from `RecipientDeliveryCreated` events emitted from resolved recipients already carried in `SendMessage`.
   - ADR 0007: Messaging owns its own projections and query API; no direct Membership projection access was added.
   - ADR 0009: used `commanded_ecto_projections` for Ecto-backed read models with strong consistency.
   - ADR 0011: projections use caller-supplied UUIDs (`message_id`, `delivery_id`) and do not generate aggregate identities.