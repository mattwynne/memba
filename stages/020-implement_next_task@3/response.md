1. **Selected todo line**
   - `003 Add slug to CreateClub, ClubCreated, Memba.Membership.Club, and Memba.Membership.Projections.Club.`

2. **Changes made**
   - Added `:slug` to:
     - `Memba.Membership.Commands.CreateClub`
     - `Memba.Membership.Events.ClubCreated`
     - `Memba.Membership.Club`
     - `Memba.Membership.Projections.Club`
   - Updated the club aggregate to:
     - copy `command.slug` into `ClubCreated`;
     - apply `event.slug` into aggregate state.
   - Added `slug` assertions to Membership aggregate/dispatch tests.
   - Added a projection struct test proving `Memba.Membership.Projections.Club` exposes `slug`.
   - Added the projection field as `virtual: true` for this task because the persistence migration is explicitly a later todo (`006`); this keeps current DB-backed queries passing until the real column/index is added.

3. **Validation commands run**
   - `git log --oneline --decorate -20` — inspected recent Fabro checkpoints.
   - `git status --short` — confirmed clean tree before editing.
   - `cd web && mix test ...` targeted Membership test attempt — failed because bare shell had no Postgres socket available.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `258 tests, 0 failures`
   - `git diff --check` — passed.

4. **Todo check-off made**
   - Changed exactly:
     ```md
     - [ ] 003 Add `slug` to `CreateClub`, `ClubCreated`, `Memba.Membership.Club`, and `Memba.Membership.Projections.Club`.
     ```
     to:
     ```md
     - [x] 003 Add `slug` to `CreateClub`, `ClubCreated`, `Memba.Membership.Club`, and `Memba.Membership.Projections.Club`.
     ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: Kept Membership club creation in the Commanded command/aggregate/event flow.
   - ADR 0007: Did not add cross-context projection access; Membership boundaries remain intact.
   - ADR 0008: Validation used the project’s persistent EventStore/test setup through `dev check`.
   - ADR 0009: Left the projection model aligned with Commanded Ecto Projections.
   - ADR 0011: Preserved `club_id` as the caller-generated UUID aggregate identity; `slug` is only an addressable attribute.