Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 010 Add a minimal staff/admin club edit page for name/slug editing or, if creation already exists, extend the creation/edit flow with slug controls.`

2. **Changes made**
   - Added Membership update support:
     - `Memba.Membership.Commands.UpdateClub`
     - `Memba.Membership.Events.ClubUpdated`
     - `Memba.Membership.update_club/2`
     - aggregate execution/application for updating club `name` and `slug`
     - router dispatch registration for `UpdateClub`
     - club projector handling for `ClubUpdated`
   - Added duplicate-slug protection for `Membership.update_club/2` against another projected club.
   - Extended the staff/admin club show LiveView with an `#edit-club-form` for editing name and slug.
   - Added slug display on the admin club show page and club index rows.
   - Added/updated tests for:
     - aggregate update behavior;
     - Commanded dispatch registration/routing;
     - projection update behavior;
     - public Membership API update behavior;
     - admin edit form display/save behavior;
     - invalid edit submission leaving the form editable.

3. **Validation commands run**
   - `cd web && mix format --check-formatted` — passed.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `287 tests, 0 failures`.
   - I also attempted bare-shell targeted `mix test ...` runs, but they failed because Postgres was not reachable from the bare shell (`/tmp/devenv/postgres/.s.PGSQL.5432` missing). Final validation was completed through the required `dev check`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 010 Add a minimal staff/admin club edit page for name/slug editing or, if creation already exists, extend the creation/edit flow with slug controls.`
   - To:
     - `- [x] 010 Add a minimal staff/admin club edit page for name/slug editing or, if creation already exists, extend the creation/edit flow with slug controls.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0007: kept club mutation/query behavior inside the Membership bounded context.
   - ADR 0008: validated through the persistent EventStore/Postgres-backed `dev check`.
   - ADR 0009: used Commanded Ecto projection handling for the club read model update.
   - ADR 0011: preserved `club_id` as aggregate identity; slug remains an editable public attribute.
   - ADR 0013/0015: added user-facing LiveView coverage for the admin edit flow without converting unrelated surfaces.