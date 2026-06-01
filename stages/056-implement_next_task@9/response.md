Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `009 Ensure the club home has no inline compose form; remove any remaining inline compose markup/handlers so compose is only reached through the CTA link to /messages/new?club_id=<club_id>.`

2. **Changes made**
   - Added a focused LiveView regression test in:
     - `web/test/memba_web/live/member_dashboard_live_test.exs`
   - New test verifies the member dashboard:
     - exposes the CTA link to `/messages/new?club_id=<club_id>`;
     - does **not** render legacy inline compose form/select/input/textarea/button controls;
     - does **not** render a compose form or `phx-submit="send_message"` handler on the club home.
   - Inspected code/search results confirmed remaining compose form/handlers are only on the dedicated `/messages/new` LiveView and admin surfaces, not club home.

3. **Validation commands run**
   - `devenv shell -- bash -lc 'MEMBA_DEVENV_SHELL=1 bin/dev postgres; cd web && mix test test/memba_web/live/member_dashboard_live_test.exs; status=$?; cd ..; MEMBA_DEVENV_SHELL=1 bin/dev down >/dev/null 2>&1 || true; exit $status'`
     - Passed: `8 tests, 0 failures`
   - `cd web && mix format --check-formatted`
     - Passed
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `254 tests, 0 failures`
   - `git diff --check`
     - Passed

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Ensure the club home has no inline compose form; remove any remaining inline compose markup/handlers so compose is only reached through the CTA link to /messages/new?club_id=<club_id>.`
   - To:
     - `- [x] 009 Ensure the club home has no inline compose form; remove any remaining inline compose markup/handlers so compose is only reached through the CTA link to /messages/new?club_id=<club_id>.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015 remains satisfied: the signed-in selected-club home remains LiveView-backed via `MembaWeb.MemberDashboardLive`.
   - Compose remains a dedicated member LiveView at `/messages/new?club_id=<club_id>`, not an inline controller/template form on club home.