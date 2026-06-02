Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `013 Add dedicated staff routes and LiveViews under the existing /admin staff LiveSession:`

2. **Changes made**
   - Added staff routes inside the existing `/admin` `:memba_staff` LiveSession:
     - `/admin/clubs/:club_id/people/new` → `MembaWeb.Admin.PeopleLive.New`
     - `/admin/clubs/:club_id/people/:person_id/edit` → `MembaWeb.Admin.PeopleLive.Edit`
   - Added `MembaWeb.Admin.PeopleLive.New`
     - Staff admin layout.
     - Club-context page.
     - Back-to-club link.
     - Dedicated create-person form shell with name input and email-address section placeholder for later repeated-row form work.
   - Added `MembaWeb.Admin.PeopleLive.Edit`
     - Staff admin layout.
     - Club/person-context page.
     - Back-to-club link.
     - Dedicated edit-person form shell with name input.
     - Displays the person’s projected email-address rows enough to anchor the edit route.
   - Added focused PhoenixTest coverage in `web/test/memba_web/live/admin_people_live_test.exs`.
   - Checked off only todo line `013`.

3. **Validation run**
   - `cd web && mix format --check-formatted lib/memba_web/router.ex lib/memba_web/live/admin/people_live/new.ex lib/memba_web/live/admin/people_live/edit.ex test/memba_web/live/admin_people_live_test.exs`
     - Passed.
   - Initial focused test attempt failed because the default Postgres socket was unavailable; restarted devenv Postgres.
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba_web/live/admin_people_live_test.exs`
     - Passed: `2 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `339 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 013 Add dedicated staff routes and LiveViews under the existing /admin staff LiveSession:`
   - To:
     - `- [x] 013 Add dedicated staff routes and LiveViews under the existing /admin staff LiveSession:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015: New staff pages use LiveView, consistent with app-surface direction.
   - ADR 0013: Added PhoenixTest-style feature coverage for route/render behaviour.
   - ADR 0007: LiveViews use Membership’s public query API; they do not reach across bounded contexts.
   - ADR 0009: Displayed person/email data comes from projection-backed Membership queries.
   - ADR 0011: Routes and assigns use UUID `club_id`/`person_id`; email is not used as identity.
   - Acceptance feature files were not edited.