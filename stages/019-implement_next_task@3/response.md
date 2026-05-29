Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 003 Add the operator deliverability projection and query, preserving reason`

2. **Changes made**
   - Added operator deliverability projection table:
     - `messaging_operator_deliverabilities`
   - Added:
     - `Memba.Messaging.Projections.OperatorDeliverability`
     - `Memba.Messaging.Projectors.OperatorDeliverability`
   - Projector now handles:
     - created → `sent`, no reason
     - delivered → `delivered`, clears reason
     - delayed → `delayed`, preserves reason
     - bounced → `bounced`, preserves reason
     - spam complaint → `spam complaint`, preserves reason
     - opened → `opened`, no reason
   - Added public Messaging query APIs:
     - `Messaging.get_operator_deliverability(delivery_id)`
     - `Messaging.get_operator_deliverability(message_id, recipient_id)`
     - `Messaging.list_operator_deliverabilities(message_id)`
   - Wired the projector into:
     - application supervision
     - event-sourced test reset/projector lifecycle
     - configured projection table list
   - Added focused ExUnit coverage:
     - `web/test/memba/messaging/operator_deliverability_projection_test.exs`
   - Did not edit any `*.feature` files.

3. **Validation commands run**
   - `cd web && mix ecto.gen.migration create_messaging_operator_deliverabilities_projection` — generated migration.
   - `cd web && mix format` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed.
   - Final re-run: `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `87 tests, 0 failures`

   Note: a direct `mix test ...` attempt outside the dev wrapper failed because Postgres was not running on the expected socket; validation was completed through the required `dev check` wrapper.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Add the operator deliverability projection and query, preserving reason`
   - To:
     - `- [x] 003 Add the operator deliverability projection and query, preserving reason`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0004: operator read model is projected from Message aggregate delivery events.
   - ADR 0006: operator view keeps detailed status and reason text, unlike the simplified member receipt mapping.
   - ADR 0009: implemented using `Commanded.Projections.Ecto`.
   - ADR 0012: opened remains a simple status; no open counts, timestamps, devices, or analytics were added.