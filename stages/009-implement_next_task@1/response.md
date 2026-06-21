1. **Selected todo line**
   - `001 Add outbound message-id support: generate Memba-controlled RFC Message-ID values for outbound club/reply emails and persist a mapping from message id to Memba message/conversation/club...`

2. **Changes made**
   - Added `Memba.Messaging.OutboundMessageID` to generate deterministic Memba-controlled RFC `Message-ID` values from `delivery_id` + `message_id`.
   - Added migration `20260621171600_add_outbound_message_id_to_messaging_email_deliveries.exs`:
     - adds `messaging_email_deliveries.outbound_message_id`
     - backfills existing rows deterministically
     - makes it `NOT NULL`
     - adds a unique index
   - Updated the email delivery projection to persist outbound message IDs on replay.
   - Added `outbound_message_id` to `EmailDeliveryRequest` and dispatcher-created provider requests.
   - Added `MemberMessageEmail.message_id/1`.
   - Set RFC `Message-ID` headers in Local, Postmark, and Resend member-message providers.
   - Added `Messaging.get_outbound_message_reference/1` to resolve persisted outbound message IDs to `%{club_id, conversation_id, message_id, delivery_id}`.
   - Updated focused tests and helpers to assert persisted IDs, lookup behavior, and provider headers.
   - Updated `LocalDeliveryFacts` to expose `outbound_message_id`.

3. **Validation**
   - `PATH="$PWD/bin:$PATH" mix format --check-formatted ...` — passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed on final diff:
     - `871 tests, 0 failures`
   - Earlier attempted focused `bin/mix test ...` did not run tests because the sandbox mix wrapper failed its Postgres readiness check with a PGHOST mismatch; validation was completed through the required `dev check --quick` path.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 ...`
     - to
     - `- [x] 001 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADRs were explicitly referenced by the plan. I inspected relevant accepted ADRs: 0002, 0004, 0005, 0007, 0009, 0011, 0016, 0021, 0022.
   - Conformance:
     - ADR 0004: kept message/delivery state within the existing message/email-delivery model.
     - ADR 0007: stayed inside Messaging context; no Membership storage coupling added.
     - ADR 0009: used the existing Commanded Ecto projection/read-model path.
     - ADR 0011: derived IDs from stable caller-generated Memba IDs, no aggregate-generated identity.
     - ADR 0016: preserved provider-neutral delivery request shape and Swoosh provider boundary for Postmark/Resend/Local; no new HTTP provider code.
     - ADR 0021/0022: did not alter read-model publishing/barrier architecture.