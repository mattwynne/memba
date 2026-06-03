Implemented task 008.

1. **Selected todo line**
   - `- [ ] 008 Add destination resolution for <club-slug>@clubs.memba.io that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.`

2. **Changes made**
   - Added `Memba.Messaging.InboundClubDestination`
     - Resolves `<club-slug>@<configured inbound domain>` to a club using `Membership.get_club_by_slug/1`.
     - Returns:
       - `{:ok, %InboundClubDestination{club_id, club_slug, to_address}}`
       - `{:error, :unsupported_recipient_address, address_or_nil}`
       - `{:error, :unknown_club_slug, to_address}`
     - Normalizes address casing/whitespace.
     - Uses configured inbound domain via `Memba.ClubInboundEmailAddress.domain/0`.
     - Ignores unrelated copied recipients when a valid club destination is present.
   - Added public Messaging API:
     - `Memba.Messaging.resolve_inbound_club_email_destination/1`
   - Added tests:
     - `web/test/memba/messaging/inbound_club_destination_test.exs`
     - Covers valid slug resolution, casing normalization, configured domain, unsupported addresses, unknown slugs, and malformed/missing input.
   - Updated Messaging public API guardrail test.

3. **Validation**
   - `cd web && ../bin/mix format` — passed.
   - Focused `../bin/mix test ...` attempts were blocked by the known local devenv Postgres socket mismatch:
     - `Postgres did not become ready at PGHOST=/tmp/devenv/postgres PGPORT=5432`
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed:
     - `425 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - ExUnit: `425 tests, 0 failures`
     - Acceptance: `31 scenarios (31 passed), 205 steps (205 passed)`
   - `git diff --check` — passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 008 Add destination resolution for <club-slug>@clubs.memba.io that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.`
   - To:
     - `- [x] 008 Add destination resolution for <club-slug>@clubs.memba.io that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: no CRUD/state mutation added; destination resolution is a query/service step in the Commanded-oriented flow.
   - ADR 0005: did not change message send recipient resolution; this only resolves inbound destination club.
   - ADR 0007: Messaging uses Membership’s public `get_club_by_slug/1` API and does not query Membership projections directly.
   - ADR 0016: implementation is provider-neutral and does not add Resend-specific parsing or webhook coupling.