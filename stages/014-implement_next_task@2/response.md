1. **Selected todo line**
   - `002 Add a membership_person_email_addresses projection table and Memba.Membership.Projections.PersonEmailAddress schema with:`

2. **Changes made**
   - Added migration:
     - `web/priv/repo/migrations/20260602023706_create_membership_person_email_addresses_projection.exs`
     - Creates `membership_person_email_addresses` with:
       - `id` UUID primary key
       - `person_id` FK to `membership_people.person_id` with `on_delete: :delete_all`
       - `email`
       - `normalized_email`
       - `is_primary` default `false`, `null: false`
       - UTC microsecond timestamps
   - Added schema:
     - `web/lib/memba/membership/projections/person_email_address.ex`
     - `Memba.Membership.Projections.PersonEmailAddress`
   - Added projection table to event-sourced projection reset config:
     - `web/config/config.exs`
   - Added focused tests:
     - `web/test/memba/membership/person_email_address_projection_test.exs`
     - Tests persistence/readback, generated UUID id, timestamps, `is_primary` default/non-null, and FK cascade delete.
   - Updated todo:
     - `docs/iterations/016-person-email-addresses/todo.md`

3. **Focused validation commands run and results**
   - `cd web && mix format ...`
     - Passed.
   - Initial focused test run:
     - `devenv shell -O services.postgres.port:int 15432 -- bash -lc 'cd web && mix test test/memba/membership/person_email_address_projection_test.exs'`
     - Failed once due `Repo.insert_all/2` using a raw table name, which bypassed schema UUID dumping.
     - Fixed by using `Repo.insert_all(PersonEmailAddress, ...)`.
   - Re-run focused test:
     - `devenv shell -O services.postgres.port:int 15432 -- bash -lc 'cd web && mix test test/memba/membership/person_email_address_projection_test.exs'`
     - Passed: `3 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Required full check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `301 tests, 0 failures`.
     - Devenv printed `Manager did not shut down within 30 seconds, sending SIGKILL`, but the command exited successfully.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Add a ...`
   - To:
     - `- [x] 002 Add a ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: Kept this as a read-model/projection persistence slice; no CRUD domain workflow was introduced.
   - ADR 0009: Used Ecto projection table/schema conventions for a read model.
   - ADR 0011: Did not use email as an aggregate identity; `person_id` remains the person reference, and the new `id` is only a projection-row UUID.
   - Acceptance feature files were not touched.