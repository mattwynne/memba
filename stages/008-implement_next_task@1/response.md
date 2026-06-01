1. **Selected todo line**
   - `001 Inspect current PageController.home/2, club.html.heex, UserAuth club-member plugs, route tests, and browser helpers that rely on club-home selectors.`

2. **Changes made**
   - Added durable inspection notes:
     - `docs/iterations/014-member-dashboard-liveview-polish/task-001-inspection.md`
   - Notes summarize:
     - current `GET /?club_id=...` controller/auth flow;
     - current `club.html.heex` selectors and compose links;
     - route/auth/controller tests currently covering club-home behavior;
     - browser acceptance helper dependencies on club-home selectors;
     - ADR 0015 implications for later LiveView conversion.
   - Updated only the selected todo item in:
     - `docs/iterations/014-member-dashboard-liveview-polish/todo.md`

3. **Focused validation run**
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed.
     - ExUnit: `243 tests, 0 failures`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect current ...`
   - To:
     - `- [x] 001 Inspect current ...`

5. **Todo splits/additions/reordering**
   - No todo splits, additions, or reordering.
   - Added a separate inspection-notes document only, to preserve findings for subsequent tasks.

6. **ADR conformance evidence**
   - Read `docs/adr/0015-use-liveview-for-member-application-pages.md`.
   - Captured in the notes that ADR 0015 requires member app surfaces such as the club home/member dashboard to default to LiveView, while logged-out marketing/public pages may remain separate/static where appropriate.