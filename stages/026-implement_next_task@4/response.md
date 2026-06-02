Implemented the next unchecked task.

1. **Selected todo line**
   - `004 Add database constraints and matching changeset/command validation:`

2. **Changes made**
   - Added migration:
     - `web/priv/repo/migrations/20260602025515_add_constraints_to_membership_person_email_addresses.exs`
     - Enforces:
       - `person_id`, `email`, `normalized_email` as non-null.
       - Global unique index on `normalized_email`.
       - Partial unique index on `person_id WHERE is_primary = true`.
   - Added shared Membership email-address validation:
     - `web/lib/memba/membership/email_addresses.ex`
     - Validates/normalizes address sets:
       - at least one address;
       - exactly one primary;
       - trimmed display email;
       - lowercase trimmed normalized email;
       - malformed/blank rejection;
       - duplicate normalized emails within the submitted set.
   - Updated legacy `CreatePerson` aggregate validation to use the shared email-address validator while preserving existing single-email command/event behaviour.
   - Added `PersonEmailAddress.changeset/2` with normalization, required fields, malformed-address validation, FK constraint, unique normalized-email constraint, and one-primary constraint handling.
   - Added/updated tests for:
     - email-address set validation;
     - legacy primary-email command validation;
     - projection changeset normalization and constraint errors;
     - DB non-null constraints;
     - global duplicate normalized-email DB constraint;
     - at-most-one-primary DB constraint.

3. **Focused validation run**
   - `cd web && mix format --check-formatted ...` — passed.
   - `PATH="$PWD/bin:$PATH" dev postgres` — started Postgres for focused tests.
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/membership/email_addresses_test.exs test/memba/membership/person_test.exs test/memba/membership/person_email_address_projection_test.exs`
     - Passed: `19 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `311 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Add database constraints and matching changeset/command validation:`
   - To:
     - `- [x] 004 Add database constraints and matching changeset/command validation:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Kept validation in the Membership command/aggregate path and projection changeset; no CRUD workflow introduced.
   - ADR 0007: Did not change Messaging internals or make Messaging depend on Membership storage.
   - ADR 0011: Preserved `person_id` as the stable aggregate identity; email remains mutable data, not identity.
   - ADR 0010 / acceptance gate: Did not edit acceptance feature files.