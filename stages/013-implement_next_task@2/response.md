1. **Selected todo line**
   - `- [ ] 002 Add the `Message` aggregate, `SendMessage` command, and `MessageSent` +`

2. **Changes made**
   - Added Messaging domain modules:
     - `Memba.Messaging.Message`
     - `Memba.Messaging.Recipient`
     - `Memba.Messaging.Commands.SendMessage`
     - `Memba.Messaging.Events.MessageSent`
     - `Memba.Messaging.Events.RecipientDeliveryCreated`
   - Registered `SendMessage` in `Memba.Messaging.Router`, routed to the `Message` aggregate by caller-supplied `message_id`.
   - Updated Messaging app/router tests to expect `SendMessage` registration.
   - Added aggregate tests covering:
     - `MessageSent` emission.
     - One `RecipientDeliveryCreated` per resolved recipient.
     - UUID, subject/body, recipient, duplicate, sender-in-recipient-list, and already-sent validation.
     - Event application into aggregate state.
   - Added dispatch tests proving `Memba.Messaging.App.dispatch/2` routes `SendMessage` to `Message`.

3. **Validation run**
   - `cd web && mix compile --warnings-as-errors` — passed.
   - Final `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `68 tests, 0 failures`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Add the `Message` aggregate, `SendMessage` command, and `MessageSent` +`
   - To:
     - `- [x] 002 Add the `Message` aggregate, `SendMessage` command, and `MessageSent` +`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0004: Implemented one `Message` aggregate per `message_id`, with per-recipient delivery state on the same aggregate stream.
   - ADR 0005: `SendMessage` carries the resolved recipient list; the aggregate emits `MessageSent` plus one `RecipientDeliveryCreated` event per recipient.
   - ADR 0007: Work stays inside the separate Messaging Commanded context and router.
   - ADR 0011: `message_id` and per-delivery IDs are caller-supplied; the aggregate does not generate identities.