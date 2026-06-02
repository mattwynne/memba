Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 Add migration/backfill that creates one email-address row for every existing membership_people.email, sets it as primary, stores the lowercase trimmed value in normalized_email, and keeps membership_people.email as a denormalized primary-email field for compatibility and efficient recipient reads during this iteration.`

2. **Changes made**
   - Added generated migration:
     - `web/priv/repo/migrations/20260602024629_backfill_membership_person_email_addresses.exs`
     - Backfills `membership_person_email_addresses` from existing `membership_people` rows.
     - Sets:
       - `id` via `gen_random_uuid()`
       - `person_id` from `membership_people.person_id`
       - `email` to `btrim(person.email)`
       - `normalized_email` to `lower(btrim(person.email))`
       - `is_primary` to `TRUE`
       - timestamps to `now()`
     - Does **not** update `membership_people.email`, preserving it as the denormalized primary-email field.
   - Updated focused projection/backfill test:
     - `web/test/memba/membership/person_email_address_projection_test.exs`
     - Added coverage proving the backfill creates one primary email-address row per existing person, trims display email, lowercases normalized email, and leaves `membership_people.email` unchanged.
   - Updated todo:
     - `docs/iterations/016-person-email-addresses/todo.md`

3. **Validation commands run**
   - Generated migration with:
     - `mix ecto.gen.migration backfill_membership_person_email_addresses`
   - Formatted changed files:
     - `mix format priv/repo/migrations/20260602024629_backfill_membership_person_email_addresses.exs test/memba/membership/person_email_address_projection_test.exs`
     - Passed.
   - Focused test:
     - Initial run failed because Postgres was not running.
     - Started Postgres with `PATH="$PWD/bin:$PATH" dev postgres`.
     - Re-ran:
       - `mix test test/memba/membership/person_email_address_projection_test.exs`
       - Passed: `4 tests, 0 failures`.
   - Whitespace check:
     - `git diff --check`
     - Passed.
   - Full required check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `302 tests, 0 failures`.
     - Devenv again printed `Manager did not shut down within 30 seconds, sending SIGKILL`, but the command exited successfully.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Add migration/backfill ...`
   - To:
     - `- [x] 003 Add migration/backfill ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Kept this as projection/read-model persistence work; no CRUD/domain workflow was introduced.
   - ADR 0009: Backfill targets the Ecto projection table used by Commanded projections.
   - ADR 0011: Preserved `person_id` as the person identity; email is not used as aggregate identity.
   - Acceptance feature files were not touched.