Implemented and checked off task 001: “Separate discovery from participation in the Membership public query API.”

1. Changes made

   - Added `Membership.list_discoverable_groups_for_member/2` in [membership.ex](/workspace/memba/web/lib/memba/membership.ex:963).
   - Discovery returns only safe identity/display fields: `club_id`, `group_id`, `group_key`, and `name`.
   - The query requires an active membership in the selected club and includes groups the member has not joined.
   - It deliberately omits participation-only metadata such as member counts and group email addresses.
   - Left `list_active_groups_for_member/2` unchanged for participation and Messaging authorization.
   - Registered the new public query in [no_crud_spike_test.exs](/workspace/memba/web/test/memba/membership/no_crud_spike_test.exs:26).
   - Added a regression proving an active club member can discover an unjoined group without receiving participation metadata in [query_test.exs](/workspace/memba/web/test/memba/membership/query_test.exs:363).

2. Focused validation

   - TDD red run: `dev test test/memba/membership/query_test.exs` failed as expected because the new API was undefined.
   - Green run: `dev test test/memba/membership/query_test.exs test/memba/membership/no_crud_spike_test.exs` — 34 tests, 0 failures.
   - Broader validation: `dev check --quick` — 1,260 tests, 0 failures.
   - `git diff --check` passed.
   - Full `dev check` was not run in this per-task node, as required by the workflow.

3. Todo check-off

   - Changed only task 001 to checked in [todo.md](/workspace/memba/docs/iterations/061-discover-club-groups/todo.md:3):
     `- [x] 001 Separate discovery from participation in the Membership public query API.`

4. Todo structure

   - No tasks were split, added, removed, or reordered.
   - Task 002 remains available for the fuller discovery contract and authorization/scoping regression matrix.

5. ADR conformance

   - ADR 0007: discovery remains behind Membership’s public API and returns plain maps; callers do not access Membership projection schemas.
   - ADR 0009: the read is implemented over existing Ecto projections without changing the write model.
   - ADRs 0021–0022: no projector or write path changed, so committed-change publication and projection-barrier behavior remain intact.
   - ADR 0024: authorization is based on active club membership without changing the Club aggregate or its consistency responsibilities.