Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `002 Add verification state to the Person email-address read model/projection and database schema, with all existing rows backfilled as verified.`

2. **Changes made**
   - Added migration:
     - `web/priv/repo/migrations/20260713161015_add_verified_at_to_membership_person_email_addresses.exs`
     - Adds nullable `verified_at :utc_datetime_usec` to `membership_person_email_addresses`.
     - Backfills existing rows with `COALESCE(updated_at, inserted_at, now())`.
   - Updated read-model schema:
     - `web/lib/memba/membership/projections/person_email_address.ex`
     - Added `verified_at` field and allowed it in the changeset.
   - Updated projector:
     - `web/lib/memba/membership/projectors/person.ex`
     - Existing `PersonCreated` and `PersonEmailAddressesReplaced` projection paths now write `verified_at` so historical/current pre-verification-domain events remain verified.
   - Updated focused tests:
     - `web/test/memba/membership/person_email_address_projection_test.exs`
       - Verifies migration backfill marks existing rows verified.
       - Verifies schema can persist/read `verified_at`.
     - `web/test/memba/membership/public_api_test.exs`
       - Verifies command-through-projection paths populate `verified_at`.

3. **Validation**
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/person_email_address_projection_test.exs test/memba/membership/public_api_test.exs`
     - Result: `27 tests, 0 failures`
   - Formatting check:
     - `cd web && mix format --check-formatted ...`
     - Result: passed.
   - Final project validation after todo check-off:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: passed, `962 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Add verification state ...`
   - To:
     - `- [x] 002 Add verification state ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0009: Kept read-model changes in Commanded Ecto projections and Ecto schema/migration, not custom projection plumbing.
   - ADR 0021: Preserved the existing projector `after_update/3` read-model publishing boundary; no extra PubSub behavior was added in this task.
   - ADRs 0015/0023 were reviewed; this task did not add member UI/routes, so their LiveView URL-state requirements remain for later `/my/settings` tasks.