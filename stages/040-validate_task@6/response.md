### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - `/tmp/fabro-pre-validate-snapshot.md` shows a clean validation snapshot at implement checkpoint `7978a0b`.
  - Live `git status --short` is clean.
  - Recent commits show latest checkpoint `06c955e pre_validate_snapshot` and implement checkpoint `7978a0b`.
  - `git show 7978a0b -- docs/iterations/016-person-email-addresses/todo.md` shows exactly one ordinary todo line changed:
    - `- [ ] 006 Add projector handling so:`
    - to `- [x] 006 Add projector handling so:`
  - Live `todo.md` has tasks `001`–`006` checked and `007` as the first unchecked task, so task `006` was the next required task.

- Implementation artifacts found:
  - `web/lib/memba/membership/projectors/person.ex` now handles:
    - legacy `PersonCreated` by inserting the person projection and upserting a primary `membership_person_email_addresses` row;
    - `PersonEmailAddressesReplaced` by updating `membership_people.email`, deleting existing projected email-address rows for the person, and inserting the replacement set in an `Ecto.Multi`.
  - `web/test/memba/membership/person_projection_test.exs` adds focused projection coverage for:
    - legacy single-email projection into the new email-address table;
    - multi-address create replacing the initial legacy primary row;
    - replace-all updating both email-address rows and denormalized primary email.
  - Supporting test fixture changes in Accounts/query/Cucumber step definitions avoid duplicate normalized emails now that projector writes enforce global uniqueness.
  - No `*.feature` files or `acceptance-tests/` files were changed.

- Tests run/results found:
  - Live `git diff --check 7978a0b^ 7978a0b` passed.
  - Live `PATH="$PWD/bin:$PATH" dev check` passed: `325 tests, 0 failures`.
  - Working tree remained clean after validation.

- ADR/plan conformance notes:
  - Matches plan task `006` and implements all listed projector requirements.
  - ADR 0002 respected: work remains in the Commanded command/event/projection path.
  - ADR 0009 respected: uses `commanded_ecto_projections` and `Ecto.Multi` for read-model projection updates.
  - ADR 0011 respected: person identity remains `person_id`; email remains mutable projected data.
  - ADR 0007 respected: no Messaging-to-Membership storage coupling introduced.
  - ADR 0010 / acceptance feature gate respected: feature files were not edited; only Elixir step support changed.
  - The checkpoint is small, coherent, and independently useful.

{"context_updates":{"task_valid":true,"task_retry_available":false}}