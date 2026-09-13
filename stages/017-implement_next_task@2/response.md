Implemented task 002: “Add a club-scoped discovery summary for an authenticated active club member.”

1. Changes made

   - Hardened `Membership.list_discoverable_groups_for_member/2` in [membership.ex](/workspace/memba/web/lib/memba/membership.ex:972) so discovery requires:
     - a valid club and person ID;
     - an active membership in the selected club;
     - a matching projected person, preventing orphan membership rows from disclosing group names.
   - Discovery remains limited to safe fields: `club_id`, `group_id`, `group_key`, and `name`.
   - Expanded [query_test.exs](/workspace/memba/web/test/memba/membership/query_test.exs:363) to prove:
     - system and custom groups are discoverable without joining them;
     - groups from another club are excluded;
     - inactive members, other-club members, outsiders, orphan identities, unknown IDs, and malformed IDs receive no summaries.

2. TDD evidence

   - Red run: `dev test test/memba/membership/query_test.exs` — 31 tests, 1 expected failure. An orphan active membership incorrectly received Admin and Everyone summaries.
   - Green run: `dev test test/memba/membership/query_test.exs test/memba/membership/no_crud_spike_test.exs` — 35 tests, 0 failures.

3. Additional validation

   - `mix format lib/memba/membership.ex test/memba/membership/query_test.exs` — passed.
   - `dev check --quick` — 1,261 tests, 0 failures.
   - `git diff --check` — passed.
   - Full browser-inclusive `dev check` was not run in this ordinary per-task node, per workflow instructions.

4. Todo check-off

   Changed only [todo.md](/workspace/memba/docs/iterations/061-discover-club-groups/todo.md:4):

   `- [x] 002 Add a club-scoped discovery summary for an authenticated active club member.`

5. Todo structure

   No tasks were split, added, removed, or reordered. Task 003 remains the first unchecked task.

6. ADR conformance

   - ADR 0007: discovery stays behind Membership’s public query boundary and returns plain maps.
   - ADR 0009: the query uses existing Ecto projections without changing the write model.
   - ADRs 0021 and 0022: no projector, publication, or synchronization behavior changed.
   - ADR 0024: no aggregate or membership invariant changed; this remains a read-side authorization boundary.