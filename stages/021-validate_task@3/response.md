### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Live working tree is clean (`git status --short` empty).
  - `/tmp/fabro-pre-validate-snapshot.md` shows the implementation checkpoint was clean after `23fadce`.
  - Current `docs/iterations/002-membership-model/todo.md` has task 003 checked and tasks 004–005 still unchecked.
  - `git show 23fadce -- docs/iterations/002-membership-model/todo.md` shows exactly one ordinary task line changed:
    - `- [ ] 003 Implement list_active_members_of_club/1 and supporting queries on the`
    - to `- [x] 003 Implement list_active_members_of_club/1 and supporting queries on the`
  - Parent todo state had tasks 001–002 checked and task 003 as the first unchecked task.

- Implementation artifacts found:
  - `web/lib/memba/membership.ex`
    - Added `list_active_members_of_club/1`.
    - Added supporting `active_member_of_club?/2`.
    - Query returns `%{id, name, email}` maps from active membership/person projections.
    - Invalid UUIDs return safe empty/false results.
  - `web/test/memba/membership/query_test.exs`
    - Covers active members for a club.
    - Excludes other clubs.
    - Excludes inactive memberships.
    - Handles missing/invalid IDs.
    - Covers `active_member_of_club?/2`.
  - `web/test/memba/membership/no_crud_spike_test.exs`
    - Updated guard to allow the planned `list_active_members_of_club/1` while still rejecting generic CRUD helpers.

- Tests run/results found:
  - Live validation run:
    - `PATH="$PWD/bin:$PATH" dev check`
    - Passed: `53 tests, 0 failures`.
  - Working tree remained clean after the check.

- ADR/plan conformance notes:
  - Matches implementation-plan task 003: public Membership query API and supporting boundary query.
  - ADR 0007 respected: query remains inside Membership public API; no Messaging code or direct cross-context schema access was added.
  - ADR 0011 respected: UUIDs are cast/validated at the boundary; supporting query uses `club_id`/`person_id` without natural-key aggregate identity coupling.
  - No `.feature` files or `acceptance-tests/` files were edited in the implementation checkpoint.
  - The task is independently useful and small enough for a clean checkpoint.

{"context_updates":{"task_valid":true,"task_retry_available":false}}