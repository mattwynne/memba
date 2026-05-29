1. **Selected todo line**
   - `- [ ] 001 Add Memba.Messaging.App and Memba.Messaging.Router.`

2. **Changes made**
   - Added `Memba.Messaging.App` as a separate Commanded application.
   - Added `Memba.Messaging.Router` as the Messaging command router.
   - Added `Memba.Messaging.EventStore` so the separate Messaging Commanded context can run without conflicting with the existing Membership EventStore process.
   - Wired `Memba.Messaging.App` into the Phoenix supervision tree.
   - Configured Messaging Commanded/EventStore settings for dev, test, and prod runtime.
   - Added focused tests for:
     - Messaging app supervision.
     - Messaging router registration.
     - Dispatch through the Messaging app/router.
     - Messaging Commanded/EventStore configuration.

3. **Validation run**
   - `cd web && mix compile --warnings-as-errors` — passed.
   - `cd web && MIX_ENV=test mix compile --force --warnings-as-errors` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `58 tests, 0 failures`
     - command exited successfully.

   Notes:
   - An initial direct `mix test` attempt failed because Postgres was not running outside `dev`.
   - An initial `dev check` exposed an EventStore process-name conflict; this was fixed by giving Messaging its own EventStore module configured to the same dedicated EventStore schema.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 Add Memba.Messaging.App and Memba.Messaging.Router.`
   - To:
     - `- [x] 001 Add Memba.Messaging.App and Memba.Messaging.Router.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0007: Implemented a separate Messaging Commanded context with `Memba.Messaging.App` and `Memba.Messaging.Router`.
   - ADR 0008: Messaging uses the persistent Postgres EventStore path and the same dedicated `event_store` schema configuration pattern.
   - ADR 0004 / ADR 0005 / ADR 0011: No aggregate, command, recipient resolution, or identity behavior was added in this task, so those later requirements remain untouched for subsequent todo items.