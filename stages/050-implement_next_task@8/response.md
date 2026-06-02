Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 Enforce global duplicate normalized-email rejection before unsafe sign-in or sender matching can occur, using both application validation and the database unique index.`

2. **Changes made**
   - Updated `web/lib/memba/membership.ex`:
     - `create_person/2` now normalizes submitted email addresses before dispatch and rejects any normalized address already attached to another person.
     - `replace_person_email_addresses/2` now does the same, while allowing a person to keep their own existing addresses.
     - Added `:email_address_taken` application-level rejection before command dispatch.
   - Updated `web/test/memba/membership/public_api_test.exs`:
     - Added coverage for duplicate normalized email rejection on legacy single-email person creation.
     - Added coverage for duplicate normalized email rejection when a duplicate appears in a multi-address create payload.
     - Added coverage for rejecting replacement email sets containing an address attached to another person.
     - Asserted rejected duplicate creates do not produce person projections and rejected replacements leave the existing email set unchanged.
   - Updated `docs/iterations/016-person-email-addresses/todo.md` to check off task `008` only.

3. **Focused validation commands run**
   - `cd /workspace/memba/web && mix format --check-formatted lib/memba/membership.ex test/memba/membership/public_api_test.exs`
     - Passed.
   - `cd /workspace/memba/web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/membership/public_api_test.exs test/memba/membership/person_email_address_projection_test.exs`
     - Passed: `19 tests, 0 failures`.
   - `cd /workspace/memba/web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/membership`
     - Passed: `106 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `332 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 008 Enforce global duplicate normalized-email rejection before unsafe sign-in or sender matching can occur, using both application validation and the database unique index.`
   - To:
     - `- [x] 008 Enforce global duplicate normalized-email rejection before unsafe sign-in or sender matching can occur, using both application validation and the database unique index.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: Kept validation in the Membership application service before Commanded dispatch; no CRUD write path was introduced.
   - ADR 0007: Kept duplicate-email rules inside the Membership bounded context; no Messaging storage coupling.
   - ADR 0009: Continued relying on Ecto projections/read models and the existing projection unique index for database enforcement.
   - ADR 0011: Email remains mutable projected data; person identity remains caller-generated `person_id`.
   - ADR 0010 / acceptance lock: No acceptance feature files were changed.