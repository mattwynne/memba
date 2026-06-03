Implemented the next unchecked task.

1. **Selected todo line**
   - `007 Add a projection/read model such as messaging_inbound_email_sources ...`

2. **Changes made**
   - Added migration:
     - `web/priv/repo/migrations/20260603034844_create_messaging_inbound_email_sources_projection.exs`
     - Creates `messaging_inbound_email_sources`
     - Includes defensive unique index on `{provider, provider_message_id}`
   - Added read model schema:
     - `Memba.Messaging.Projections.InboundEmailSource`
   - Added event-driven projector:
     - `Memba.Messaging.Projectors.InboundEmailSource`
     - Projects only `InboundClubEmailAccepted` and `InboundClubEmailRejected`
   - Added support/audit query:
     - `Messaging.get_inbound_email_source/2`
     - Explicitly documented as read-model only; not command-side idempotency source of truth
   - Wired the projector into:
     - Phoenix supervision tree
     - event-sourced test reset support
     - acceptance reset support
     - release schema drift verification
     - projection table reset config
   - Added tests covering:
     - Accepted inbound event projection
     - Rejected inbound event projection
     - defensive unique constraint
     - invalid/missing source lookup
     - supervision wiring
     - public Messaging API no-CRUD expectations

3. **Validation**
   - `cd web && ../bin/mix format` — passed
   - Focused `../bin/mix test ...` attempt was blocked by the known local devenv Postgres socket mismatch:
     - `Postgres did not become ready at PGHOST=/tmp/devenv/postgres PGPORT=5432`
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed
     - `419 tests, 0 failures`
   - Initial full `dev check` exposed acceptance reset wiring for the new projector; fixed by adding the projector to `DevTestSupportController` reset handling.
   - Final `PATH="$PWD/bin:$PATH" dev check` — passed
     - ExUnit: `419 tests, 0 failures`
     - Acceptance: `31 scenarios (31 passed), 205 steps (205 passed)`
   - `git diff --check` — passed

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 007 Add a projection/read model such as ...`
   - To:
     - `- [x] 007 Add a projection/read model such as ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: projection is driven from explicit domain events.
   - ADR 0007: implementation stays inside Messaging and does not query/mutate Membership internals.
   - ADR 0008: projection table lives in the app schema, separate from EventStore schema.
   - ADR 0009: uses `Commanded.Projections.Ecto` rather than custom projection plumbing.
   - ADR 0016: remains provider-neutral; no Resend-specific parsing or webhook coupling added.