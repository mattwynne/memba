Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 009 Add sender resolution that finds a person by any primary or alternate email address.`

2. **Changes made**
   - Added `Memba.Messaging.InboundClubSender`
     - Resolves sender from `%InboundEmail{}` or a raw from-address.
     - Normalizes casing/whitespace.
     - Uses `Memba.Membership.get_person_by_email/1`, so both primary and alternate email addresses are supported via Membership’s public API.
     - Returns:
       - `{:ok, %InboundClubSender{person_id, name, from_address}}`
       - `{:error, :unknown_sender, normalized_address_or_nil}`
   - Added public Messaging API:
     - `Memba.Messaging.resolve_inbound_club_email_sender/1`
   - Added tests:
     - Primary email sender resolution.
     - Alternate email sender resolution.
     - Unknown/blank/missing sender rejection.
   - Updated Messaging public API guardrail test.
   - Checked off task 009 only.

3. **Validation run**
   - `cd web && ../bin/mix format` — passed.
   - Initial direct focused `../bin/mix test ...` attempt hit the known local PGHOST socket mismatch.
   - Focused retry:
     - `PATH="$PWD/bin:$PATH" devenv shell -O services.postgres.port:int 15432 -- bash -lc 'cd web && mix test test/memba/messaging/inbound_club_sender_test.exs test/memba/messaging/no_crud_spike_test.exs'`
     - Result: `7 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: `428 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - ExUnit: `428 tests, 0 failures`.
     - Acceptance: `31 scenarios (31 passed), 205 steps (205 passed)`.
   - `git diff --check` — passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Add sender resolution that finds a person by any primary or alternate email address.`
   - To:
     - `- [x] 009 Add sender resolution that finds a person by any primary or alternate email address.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007: Messaging depends on Membership’s public query API (`get_person_by_email/1`) and does not query Membership projection tables directly.
   - ADR 0002: No CRUD/state mutation added; this is query-side sender resolution for the inbound workflow.
   - ADR 0005: Did not change message recipient resolution or delivery creation.
   - ADR 0011: No new aggregate identity behavior introduced.