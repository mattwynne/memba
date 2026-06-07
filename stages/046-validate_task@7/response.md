### Decision

**VALID**

### Evidence

- **Completed todo/check-off evidence found**
  - Live working tree is clean; `/tmp/fabro-pre-validate-snapshot.md` confirms the implementation was checkpointed.
  - Recent checkpoint `c945f75 fabro(...): implement_next_task (succeeded)` changed exactly one ordinary todo line:
    - `- [ ] 007 Add a public Membership query/API for permission checks...`
    - to `- [x] 007 Add a public Membership query/API for permission checks...`
  - Immediately before that checkpoint, `007` was the first unchecked task in `todo.md`.
  - No todo deletion, weakening, split, or reorder was found.

- **Implementation artifacts found**
  - Added `web/lib/memba/membership/authorization.ex`, an internal Membership authorization helper querying the flattened `membership_member_permissions` projection.
  - Added public Membership context API:
    - `Memba.Membership.person_has_club_permission?/3`
  - The implementation validates/casts club/person IDs and only accepts app-defined permissions via `Memba.Membership.Permissions.valid?/1`.
  - No acceptance `*.feature` files were edited.

- **Tests run/results found**
  - Added `web/test/memba/membership/authorization_test.exs`.
  - Updated `web/test/memba/membership/public_api_test.exs`.
  - Validator reran focused tests successfully:
    - `13 tests, 0 failures`
  - `git diff --check c945f75^ c945f75` passed.
  - Implementation summary also reports formatting passed and `dev check --quick` passed with `648 tests, 0 failures`.

- **ADR/plan conformance notes**
  - Matches plan task `007`: exposes a public Membership permission-check API answering whether a person has `club.manage_members` in a club.
  - Respects ADR 0002 and ADR 0009 by querying CQRS/Ecto projection state rather than aggregate internals or ad hoc mutable state.
  - Respects ADR 0007 by keeping projection-table access encapsulated inside the Membership bounded context and exposing a Membership query API.
  - Respects ADR 0008 by testing through persistent EventStore-backed domain paths.
  - Respects ADR 0022 patterns by using strong consistency in tests before reading projected permission state.
  - Scope is appropriately small and independently checkpointable; later authorization/grant/revoke work remains unchecked.

{"context_updates":{"task_valid":true,"task_retry_available":false}}