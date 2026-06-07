Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `012 Preserve or migrate existing test data/seeds so current acceptance tests still have valid clubs and memberships. Existing clubs in test/dev may need default role setup in seeds or migration/backfill.`

2. **Changes made**
   - Added a new migration:
     - `web/priv/repo/migrations/20260607233402_backfill_membership_administrator_roles.exs`
     - Backfills the default Membership Administrator role, `club.manage_members` role permission, one active administrator assignment per existing club with active members, and flattened member permissions.
     - Uses the same deterministic role ID algorithm as `Memba.ID.deterministic/2`.
   - Updated dev/test seeds:
     - `web/priv/repo/seeds.exs`
     - Seeds Membership Administrator roles, permissions, assignments, and flattened permissions for representative seeded clubs/members.
   - Added focused seed coverage:
     - `web/test/memba/seed_data_test.exs`
     - Proves seeded Kootenay data includes the default role, grant, Alice’s active role assignment, and flattened permission.
   - Checked off task 012 in `todo.md`.

3. **Validation run**
   - Formatting:
     - `devenv shell -- bash -lc 'cd web && mix format --check-formatted priv/repo/seeds.exs priv/repo/migrations/20260607233402_backfill_membership_administrator_roles.exs test/memba/seed_data_test.exs'`
     - Passed.
   - Focused tests:
     - `devenv shell -- bash -lc 'cd web && mix test test/memba/seed_data_test.exs'`
     - Passed: `1 test, 0 failures`.
     - `devenv shell -- bash -lc 'cd web && mix test test/memba/membership/role_projection_test.exs test/memba/seed_data_test.exs'`
     - Passed: `6 tests, 0 failures`.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `657 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.
     - New-file trailing-whitespace Python check passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 012 Preserve or migrate existing test data/seeds so current acceptance tests still have valid clubs and memberships. Existing clubs in test/dev may need default role setup in seeds or migration/backfill.`
   - To:
     - `- [x] 012 Preserve or migrate existing test data/seeds so current acceptance tests still have valid clubs and memberships. Existing clubs in test/dev may need default role setup in seeds or migration/backfill.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Kept domain role behavior in Commanded/event-sourced code; this task only adds seed/backfill projection data for existing data.
   - ADR 0007: Changes remain in Membership data/read-model setup; Messaging remains separate.
   - ADR 0009: Backfill/seed targets the existing Ecto projection tables and preserves idempotent projection shape.
   - ADR 0011: Uses deterministic role IDs derived from existing club IDs; no natural aggregate identity coupling introduced.
   - ADR 0017: Added a new migration rather than editing an existing migration, preserving release-state discipline.