Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `014 Replace the existing inline person creation form on MembaWeb.Admin.ClubsLive.Show with a “New person” link to the create LiveView. Keep the people list on the club show page, show each person's primary email plus alternate-count or alternate-list summary, and add an “Edit” link for each person.`

2. **Changes made**
   - Updated `MembaWeb.Admin.ClubsLive.Show`:
     - Removed the inline person creation form and `create_person` event handler.
     - Added `#new-person-link` to `/admin/clubs/:club_id/people/new`.
     - Kept the streamed people list.
     - Added primary email display per person.
     - Added alternate email summary with `data-alternate-count`.
     - Added per-person edit links to `/admin/clubs/:club_id/people/:person_id/edit`.
   - Updated tests:
     - Added focused club show coverage for the new link, removed form, primary email display, alternate summary, and edit link.
     - Updated browser harness expectations away from the removed inline form.
     - Browser harness now seeds people through `Membership.create_person/2` and reloads the current club page until the dedicated create form is implemented in todo `015`.

3. **Focused validation**
   - `cd web && mix format --check-formatted lib/memba_web/live/admin/clubs_live/show.ex test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/browser_acceptance_harness_test.exs`
     - Passed.
   - Initial bare `mix test` failed because the default Postgres socket was unavailable.
   - Restarted repo-managed Postgres after clearing a stale zombie lock/socket.
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/browser_acceptance_harness_test.exs`
     - Passed: `9 tests, 0 failures`.
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba_web/live/admin_people_live_test.exs`
     - Passed: `2 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `340 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 014 ...`
   - To:
     - `- [x] 014 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Continued using Phoenix/LiveView for the admin app surface.
   - ADR 0013: Added/updated user-facing web tests around route/link/display behaviour.
   - ADR 0015: Kept staff workflow on LiveView surfaces and linked to dedicated LiveViews.
   - ADR 0007: Used Membership public query APIs from the LiveView; no cross-context persistence reach-through.
   - ADR 0009: Displayed projection-backed Membership read-model data.
   - ADR 0011: Routes and selectors use UUID person/club identifiers, not email as identity.