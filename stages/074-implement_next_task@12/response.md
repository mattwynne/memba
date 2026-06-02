Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 012 Add host-based public club-page resolution for \`*.clubs.memba.io\`:`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_controller.ex`
     - Detects hosts under `*.clubs.memba.io`.
     - Extracts the left-most slug label.
     - Looks up the club through `Membership.get_club_by_slug/1`.
     - Renders the existing `ClubMarketingLive` page for found clubs.
     - Returns 404 for unknown club subdomain slugs.
     - Preserves existing non-subdomain behavior, including `club_id` query-based pages.
   - Updated `web/test/memba_web/controllers/page_controller_test.exs`
     - Added coverage for `kmc.clubs.memba.io` rendering the KMC marketing page.
     - Added coverage for `unknown.clubs.memba.io` returning 404.
     - Extended the local test helper to optionally insert a known slug.
   - Updated `docs/iterations/015-club-slugs/todo.md`
     - Checked off only task 012.

3. **Validation run**
   - `cd web && mix format --check-formatted` — passed.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `291 tests, 0 failures`.
   - Note: I first attempted the focused test file with bare `mix test`, but the bare shell could not reach the devenv Postgres socket. The project `dev check` wrapper was then used and passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 012 Add host-based public club-page resolution for \`*.clubs.memba.io\`:`
   - To:
     - `- [x] 012 Add host-based public club-page resolution for \`*.clubs.memba.io\`:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Conforms to ADR 0001 by implementing the behavior in the Phoenix web app.
   - Conforms to ADR 0007 by using the Membership context public query API (`Membership.get_club_by_slug/1`) rather than reaching into projections directly from web routing code.
   - Conforms to ADR 0013 by adding user-facing Phoenix controller tests for routing/rendering behavior.
   - Conforms to ADR 0015 by reusing the existing LiveView-backed club marketing page rather than introducing a parallel implementation.
   - No locked acceptance feature files were changed.