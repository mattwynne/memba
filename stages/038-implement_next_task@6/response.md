1. **Selected todo line**
   - `006 Add a migration to add slug to membership_clubs, backfill existing rows deterministically, set non-null, and create a unique index.`

2. **Changes made**
   - Generated a new Ecto migration with `mix ecto.gen.migration add_slug_to_membership_clubs`.
   - Added migration `web/priv/repo/migrations/20260602001447_add_slug_to_membership_clubs.exs` that:
     - adds `membership_clubs.slug`;
     - deterministically backfills slugs from existing club names;
     - handles same-base collisions with numeric suffixes;
     - sets `slug` to `NOT NULL`;
     - creates unique index `membership_clubs_slug_index`;
     - adds a migration-level trigger to fill missing slugs for inserts before the later projector task writes event slugs directly.
   - Added persistence coverage in `web/test/event_sourced_setup_test.exs` verifying:
     - the slug column exists and is non-null;
     - the unique slug index exists;
     - a missing slug is deterministically generated from the club name;
     - duplicate slug insertion is rejected by the database constraint.
   - No acceptance feature files were changed.

3. **Focused validation commands run**
   - `cd web && mix format --check-formatted priv/repo/migrations/20260602001447_add_slug_to_membership_clubs.exs test/event_sourced_setup_test.exs`
     - Passed.
   - `mix test test/event_sourced_setup_test.exs` inside a dev shell with Postgres running
     - Passed: `4 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `270 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   ```md
   - [ ] 006 Add a migration to add `slug` to `membership_clubs`, backfill existing rows deterministically, set non-null, and create a unique index.
   ```
   changed to:
   ```md
   - [x] 006 Add a migration to add `slug` to `membership_clubs`, backfill existing rows deterministically, set non-null, and create a unique index.
   ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0008: Kept EventStore and normal Ecto projections in the same Postgres database while modifying only the projection/read-model table.
   - ADR 0009: Continued using Ecto projection storage; this task only changed projection persistence shape and did not replace Commanded projection machinery.
   - ADR 0011: Preserved `club_id` as the primary aggregate/projection identity; slug is added as a unique addressable attribute, not as the aggregate identity.
   - ADR 0007: Changes remain within Membership projection persistence and shared test setup; no Messaging boundary coupling was introduced.