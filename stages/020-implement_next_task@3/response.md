1. **Selected todo line**
   - `003 Introduce MembaWeb.MemberDashboardLive, rendered for signed-in selected-club home while preserving public/logged-out handling for /?club_id=. Keep the existing GET / controller route as a small dispatcher/public page...`

2. **Changes made**
   - Added `web/lib/memba_web/live/member_dashboard_live.ex`.
     - Loads the signed-in identity from the LiveView session.
     - Loads selected-club dashboard assigns in `mount/3`.
     - Renders the existing club dashboard template via `MembaWeb.PageHTML.club/1`.
     - Raises `MembaWeb.ForbiddenError` if the signed-in session is not authorized.
   - Updated `PageController.home/2`.
     - Signed-in `GET /?club_id=<club_id>` now dispatches to `MembaWeb.MemberDashboardLive` using `Phoenix.LiveView.Controller.live_render/3`.
     - Logged-out/public `GET /?club_id=<club_id>` continues to render `MembaWeb.ClubMarketingLive`.
     - `GET /` without `club_id` remains controller-rendered.
   - Added `data-live-view="member-dashboard"` to `#member-club-home`.
   - Added focused tests in `web/test/memba_web/live/member_dashboard_live_test.exs` for:
     - signed-in active member receives the dashboard LiveView at the same `/?club_id=` URL;
     - logged-out public club marketing behaviour is preserved;
     - signed-in non-member is still forbidden.
   - Checked off task `003` in `todo.md`.

3. **Focused validation commands run**
   - Focused LiveView test:
     - `mix test test/memba_web/live/member_dashboard_live_test.exs` inside devenv with Postgres
     - Result: `3 tests, 0 failures`
   - Required full project check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `246 tests, 0 failures`
   - Whitespace check:
     - `git diff --check`
     - Result: passed

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 003 Introduce MembaWeb.MemberDashboardLive...`
   - To:
     - `- [x] 003 Introduce MembaWeb.MemberDashboardLive...`

5. **Todo splits/additions/reordering**
   - None. No todo items were split, added, removed, or reordered.

6. **ADR conformance evidence**
   - ADR 0015 says member application pages, including “club home / member dashboard,” should use LiveView by default.
   - This task makes signed-in selected-club home a LiveView-backed member application page.
   - The controller remains only as the route/public dispatch boundary, preserving ADR 0015’s allowance for logged-out marketing/public pages to remain outside the member app LiveView requirement.