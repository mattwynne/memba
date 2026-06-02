Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Add projector handling so:`

2. **Changes made**
   - Updated `Memba.Membership.Projectors.Person` so:
     - legacy `PersonCreated` projects the `membership_people` row and creates/upserts one primary `membership_person_email_addresses` row;
     - `PersonEmailAddressesReplaced` updates `membership_people.email` to `primary_email`;
     - `PersonEmailAddressesReplaced` atomically deletes and reinserts that person’s projected email-address rows via `Ecto.Multi`.
   - Added focused projection tests proving:
     - legacy single-email create projects one primary email-address row;
     - multi-address create replaces the initial legacy primary projection;
     - replace-all updates projected rows and the denormalized primary email.
   - Adjusted existing test/support fixtures that created duplicate normalized emails now that the projector writes to the globally unique email-address projection:
     - reused the same person for multi-club lookup tests;
     - made Cucumber step-generated test emails scenario-scoped.

3. **Focused validation commands/results**
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/membership/person_projection_test.exs`
     - Passed: `5 tests, 0 failures`
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/membership`
     - Passed: `99 tests, 0 failures`
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/accounts_test.exs test/memba/membership`
     - Passed: `107 tests, 0 failures`
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/features`
     - Passed: `5 tests, 0 failures`
   - `cd web && mix format --check-formatted ...`
     - Passed for touched files
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `325 tests, 0 failures`
   - `git diff --check`
     - Passed

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Add projector handling so:`
   - To:
     - `- [x] 006 Add projector handling so:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Kept behavior in the Commanded event/projector read-model path.
   - ADR 0009: Used `commanded_ecto_projections` and `Ecto.Multi` for projection updates/replay behavior.
   - ADR 0011: Continued using stable `person_id` UUID identity; email remains mutable projected data.
   - ADR 0007: Did not introduce Messaging-to-Membership storage coupling.
   - Acceptance feature files were not edited.