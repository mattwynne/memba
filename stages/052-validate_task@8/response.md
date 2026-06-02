### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Read `/tmp/fabro-pre-validate-snapshot.md`: snapshot captured clean working tree at implementation checkpoint `eb6df06`.
  - Live `git status --short` is clean.
  - Recent log shows `45c1fc5 pre_validate_snapshot` on top of `eb6df06 implement_next_task`.
  - `git show eb6df06 -- docs/iterations/016-person-email-addresses/todo.md` shows exactly one ordinary task line changed:
    - `- [ ] 008 Enforce global duplicate normalized-email rejection...`
    - to `- [x] 008 Enforce global duplicate normalized-email rejection...`
  - `git show eb6df06^:.../todo.md` confirms task `008` was the first unchecked task before the implementation commit.
  - No todo split/reorder/deletion found.

- Implementation artifacts found:
  - `web/lib/memba/membership.ex` now validates submitted/command email-address sets before dispatch for:
    - `create_person/2`
    - `replace_person_email_addresses/2`
  - It normalizes command email addresses via `Memba.Membership.EmailAddresses` and rejects addresses already attached to another person with `{:error, :email_address_taken}`.
  - The duplicate check allows a person to retain their own addresses while preventing cross-person normalized-email duplicates.
  - Existing database-level evidence remains present:
    - migration `20260602025515_add_constraints_to_membership_person_email_addresses.exs` has a unique index on `normalized_email`;
    - `PersonEmailAddress.changeset/2` has the matching `unique_constraint`.
  - `web/test/memba/membership/public_api_test.exs` adds focused tests for duplicate normalized-email rejection on create and replace flows.
  - Implementation commit changed only:
    - `docs/iterations/016-person-email-addresses/todo.md`
    - `web/lib/memba/membership.ex`
    - `web/test/memba/membership/public_api_test.exs`
  - No `*.feature` or `acceptance-tests/` files were edited.

- Tests run/results found:
  - Live `git diff --check eb6df06^ eb6df06` passed.
  - Live `PATH="$PWD/bin:$PATH" dev check` passed: `332 tests, 0 failures`.
  - Working tree remained clean after validation.

- ADR/plan conformance notes:
  - Matches plan task `008`: adds application-level duplicate normalized-email rejection while preserving the database unique-index enforcement.
  - ADR 0002 respected: validation remains in the Membership application service before Commanded dispatch; no CRUD write path introduced.
  - ADR 0007 respected: duplicate-email ownership remains in Membership; no Messaging storage coupling.
  - ADR 0009 respected: enforcement continues to use Ecto projections/read models and projection constraints.
  - ADR 0010 respected: shared acceptance feature files were not changed.
  - ADR 0011 respected: `person_id` remains the stable aggregate identity; email remains mutable projected data.
  - The checkpoint is small, coherent, and independently useful.

{"context_updates":{"task_valid":true,"task_retry_available":false}}