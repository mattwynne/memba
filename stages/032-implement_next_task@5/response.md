Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Evolve Membership commands/events using an atomic replace-all model:`

2. **Changes made**
   - Updated `CreatePerson` to keep the legacy `email` field while adding optional `email_addresses`.
   - Added:
     - `Memba.Membership.Commands.ReplacePersonEmailAddresses`
     - `Memba.Membership.Events.PersonEmailAddressesReplaced`
   - Registered `ReplacePersonEmailAddresses` in `Memba.Membership.Router`.
   - Updated `Memba.Membership.Person` aggregate so:
     - legacy single-email `CreatePerson` still emits only `PersonCreated`;
     - multi-address `CreatePerson` emits `PersonCreated` followed by `PersonEmailAddressesReplaced`;
     - `ReplacePersonEmailAddresses` emits one atomic replace-all event for existing people;
     - replacement validation uses the existing shared email-address validator.
   - Added `Membership.replace_person_email_addresses/2` public command-service entrypoint.
   - Added tests covering:
     - aggregate command/event behavior;
     - Commanded app dispatch for create and replace flows;
     - router command registration;
     - public Membership command APIs.

3. **Focused validation run**
   - `cd web && mix format --check-formatted ...` — passed.
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/membership` — passed: `96 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check` — passed: `322 tests, 0 failures`.
   - `git diff --check` — passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Evolve Membership commands/events using an atomic replace-all model:`
   - To:
     - `- [x] 005 Evolve Membership commands/events using an atomic replace-all model:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Kept behavior in Commanded commands/events/aggregate rather than CRUD changesets.
   - ADR 0009: Did not implement projector behavior yet; that remains task 006.
   - ADR 0011: Continued using stable caller-generated `person_id`; email remains mutable data.
   - ADR 0007: Did not change Messaging internals or make Messaging depend on Membership storage.
   - ADR 0010 / acceptance gate: Did not edit acceptance feature files.