Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 005 Build the outbound email from DeliveryRequest, including recipient, configured sender/from, configured reply-to, subject, text body, minimal safe HTML body, and Postmark metadata/custom fields for memba_message_id, memba_delivery_id, and memba_club_id.`

2. **Changes made**
   - Added `club_id` to `Memba.Messaging.DeliveryRequest` and populated it from `SendMessage.club_id`.
   - Implemented `Memba.Messaging.DeliveryProviders.Postmark.deliver/1` to:
     - validate Postmark app config,
     - build a `Swoosh.Email`,
     - set configured `from`,
     - set configured optional `reply_to`,
     - set recipient name/address,
     - set subject,
     - include both text body and minimal escaped HTML body,
     - attach Postmark metadata:
       - `memba_message_id`
       - `memba_delivery_id`
       - `memba_club_id`
     - deliver through `Memba.Mailer`.
   - Added optional `MEMBA_POSTMARK_REPLY_TO_ADDRESS` support in Postmark runtime/provider config.
   - Updated existing tests for the new `club_id` field and for Postmark delivery no longer being a placeholder.
   - Added focused Postmark provider tests using Swoosh’s test adapter, with no real email sent.
   - Updated small module docs for `DeliveryRequest` and `PostmarkConfig`.

3. **Validation commands run**
   - `cd web && mix format --check-formatted` — passed.
   - `cd web && mix compile --warnings-as-errors` — passed.
   - `cd web && MIX_ENV=test mix run --no-start -e ...` — passed; verified Swoosh test email payload contents, HTML escaping, reply-to, and metadata.
   - `cd web && MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark ... mix run --no-start -e ...` — passed; verified runtime reply-to config.
   - `PATH="$PWD/bin:$PATH" dev check` — passed: `124 tests, 0 failures`.
   - `git diff --check` — passed.
   - Note: an initial direct `mix test ...` attempt failed because Postgres was unavailable outside the dev-managed environment; the final required `dev check` ran successfully with services.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Build the outbound email from DeliveryRequest...`
   - To:
     - `- [x] 005 Build the outbound email from DeliveryRequest...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0004: Delivery state remains owned by the message aggregate; Postmark metadata only carries Memba correlation IDs.
   - ADR 0005: Provider still consumes resolved recipient deliveries via `DeliveryRequest`; no new recipient resolution path added.
   - ADR 0006: No delivery status vocabulary changes.
   - ADR 0007: No Membership storage/query coupling introduced.
   - ADR 0012: No open-tracking semantics added in this task; that remains for task 006.