Task 002 is complete: “Add a public Membership query for the active groups of a given active member in a given club.”

1. Implementation

   Added `Membership.list_active_groups_for_member/2` in [membership.ex](/workspace/memba/web/lib/memba/membership.ex:966). The query:

   - Requires valid club and person IDs.
   - Joins group memberships to their matching group and underlying club membership.
   - Requires both membership records to be active.
   - Scopes results to the supplied club and person.
   - Returns distinct plain maps rather than projection structs.
   - Returns `[]` for invalid or unknown identities.

2. Tests

   Added focused coverage in [query_test.exs](/workspace/memba/web/test/memba/membership/query_test.exs:360) proving:

   - Everyone and a generic custom group are returned.
   - Groups belonging to another club are excluded.
   - Inactive group memberships are excluded.
   - All groups are excluded once the underlying club membership is inactive.
   - Invalid and unknown IDs return an empty list.
   - Projection structs do not escape the Membership boundary.

   Updated the approved public query inventory in [no_crud_spike_test.exs](/workspace/memba/web/test/memba/membership/no_crud_spike_test.exs:26).

3. Validation

   TDD red phase:

   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/query_test.exs test/memba/membership/no_crud_spike_test.exs`
   - Failed as expected because `list_active_groups_for_member/2` did not exist.

   Passing validation:

   - Same focused command: 33 tests, 0 failures.
   - `PATH="$PWD/bin:$PATH" dev check --quick`: 1,143 tests, 0 failures.
   - `git diff --check`: passed.

   Full browser acceptance was not run because this task does not change browser-facing behavior; the prescribed per-task gate is `dev check --quick`.

4. Todo check-off

   Checked off exactly [task 002](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:4):

   `- [x] 002 Add a public Membership query for the active groups of a given active member in a given club.`

5. Todo structure

   No tasks were split, added, removed, or reordered. Task 003 remains unchecked for stable display ordering, active-member counts, derived address information, and further relationship validation.

6. ADR conformance

   - ADR 0007: callers receive a public Membership API and plain maps, without projection-schema leakage.
   - ADR 0009: the query uses Membership-owned Ecto projections as query-side read models.
   - ADRs 0021–0022: no projector or synchronization behavior changed; tests write through Commanded with strong consistency before querying.