Implemented task 006 and left it unchecked for independent review.

1. Selected todo line

`- [ ] 006 Extend aggregate state/projection constraints only as necessary for normalized name uniqueness; keep projections as projections.`

2. Changes made

- Added shared trim-and-case-fold semantics in [group_name.ex](/workspace/memba/web/lib/memba/membership/group_name.ex:1), preserving unrestricted Unicode display names.
- Extended the [Club aggregate](/workspace/memba/web/lib/memba/membership/club.ex:46) with an event-rehydrated normalized-name index.
- Both custom and trusted group creation now reject normalized duplicate names at the authoritative aggregate boundary, while preserving existing group-key error precedence and idempotent retries.
- Added a club-scoped expression index in [20260913221054_add_normalized_group_name_uniqueness.exs](/workspace/memba/web/priv/repo/migrations/20260913221054_add_normalized_group_name_uniqueness.exs:1). It constrains `lower(btrim(name))` without turning the projection into the source of authority or adding redundant projection state.
- Added tests proving aggregate indexing, trusted-command enforcement, projection independence when a row is missing, and club-scoped read-model uniqueness in [club_test.exs](/workspace/memba/web/test/memba/membership/club_test.exs:846), [create_custom_group_dispatch_test.exs](/workspace/memba/web/test/memba/membership/create_custom_group_dispatch_test.exs:314), and [group_projection_test.exs](/workspace/memba/web/test/memba/membership/group_projection_test.exs:132).

3. Focused validation

- TDD red run failed on the absent normalized-name constraint as expected.
- `dev test test/memba/membership/club_test.exs test/memba/membership/create_custom_group_dispatch_test.exs test/memba/membership/group_projection_test.exs`
  - 70 tests, 0 failures.
- `dev check --quick`
  - 1,311 tests, 0 failures on the exact staged candidate state.
- `mix format --check-formatted` for all touched Elixir files passed.
- `git diff --cached --check` passed.
- Full browser-inclusive `dev check` was not run in this ordinary per-task node; the workflow’s final validation stage retains ownership of that gate.

4. Todo state

The selected line remains unchanged and unchecked:

`- [ ] 006 Extend aggregate state/projection constraints only as necessary for normalized name uniqueness; keep projections as projections.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked.

6. ADR conformance

- ADR 0002 and ADR 0024: normalized-name authority remains in replayable Club aggregate state on the Club stream.
- ADR 0009: PostgreSQL supplies a defensive, rebuildable read-model constraint through the existing Ecto projection table.
- ADR 0007: all behavior remains inside Membership.
- ADR 0011: caller-generated group identities and retry semantics are unchanged.
- Historical events remain unchanged and replay supplies the new aggregate index through existing `GroupCreated` facts.